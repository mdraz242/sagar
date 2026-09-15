import { pool, query } from "../config/db.js";
import { ApiError, notFound } from "../utils/apiError.js";
import { emitAdmin, emitCustomer } from "../services/realtimeService.js";

function isAdmin(user) {
  return ["admin", "super_admin"].includes(user.role);
}

function pageParams(req) {
  const page = Math.max(1, Number.parseInt(req.query.page || "1", 10) || 1);
  const limit = Math.min(
    100,
    Math.max(1, Number.parseInt(req.query.limit || "20", 10) || 20),
  );
  return { page, limit, offset: (page - 1) * limit };
}

async function loadOrder(id, user) {
  const params = [id];
  let where = "where o.id = $1";

  if (!isAdmin(user)) {
    params.push(user.sub);
    where += " and o.user_id = $2";
  }

  const result = await query(
    `
      select
        o.*,
        coalesce(
          json_agg(
            json_build_object(
              'id', oi.id,
              'productId', oi.product_id,
              'quantity', oi.quantity,
              'mrp', oi.mrp::float,
              'buyPrice', oi.buy_price::float,
              'product', json_build_object(
                'sku', p.sku,
                'brand', p.brand,
                'name', p.name_en,
                'imageUrl', p.image_url,
                'size', p.size,
                'pack', p.pack
              )
            )
            order by oi.id
          ) filter (where oi.id is not null),
          '[]'
        ) as items,
        row_to_json(a.*) as address,
        coalesce(
          (
            select json_agg(
              json_build_object(
                'status', h.status,
                'changed_at', h.changed_at,
                'admin_id', h.changed_by_admin_id
              )
              order by h.changed_at
            )
            from order_status_history h
            where h.order_id = o.id
          ),
          '[]'::json
        ) as status_history
        ,
        coalesce(
          (
            select json_agg(
              json_build_object(
                'id', rr.id,
                'request_type', rr.request_type,
                'status', rr.status,
                'reason', rr.reason,
                'refund_method', rr.refund_method,
                'amount', rr.amount::float,
                'items', rr.items_json,
                'created_at', rr.created_at,
                'updated_at', rr.updated_at,
                'rejection_reason', rr.rejection_reason
              )
              order by rr.created_at desc
            )
            from refund_requests rr
            where rr.order_id = o.id
          ),
          '[]'::json
        ) as return_requests,
        (
          select json_build_object('mode', p.mode, 'status', p.status, 'amount', p.amount::float)
          from payments p
          where p.order_id = o.id
          order by p.created_at desc
          limit 1
        ) as payment
      from orders o
      left join order_items oi on oi.order_id = o.id
      left join products p on p.id = oi.product_id
      left join addresses a on a.id = o.address_id
      ${where}
      group by o.id, a.id
    `,
    params,
  );

  return result.rows[0];
}

async function snapshotItem(client, item) {
  if (!item.productId) {
    throw new ApiError(422, "Each order item requires productId");
  }

  const quantity = Math.max(1, Number.parseInt(item.quantity ?? "1", 10) || 1);
  const productResult = await client.query(
    `
      select id, sku, brand, name_en, image_url, size, pack, mrp, buy_price
      from products
      where id::text = $1 and is_active = true
    `,
    [item.productId],
  );

  const product = productResult.rows[0];

  if (!product) {
    throw notFound("Product");
  }

  let mrp = product.mrp;
  let buyPrice = product.buy_price;

  if (item.variantKey) {
    const variantResult = await client.query(
      `
        select
          coalesce(nullif(variant_name, ''), size) as size,
          coalesce(nullif(pack, ''), nullif(unit, '')) as pack,
          mrp,
          coalesce(selling_price, buy_price) as buy_price
        from product_variants
        where product_id = $1
          and (id::text = $2 or replace(coalesce(nullif(variant_name, ''), size, ''), ' ', '_') = $2)
          and coalesce(status, 'active') = 'active'
        limit 1
      `,
      [product.id, item.variantKey],
    );

    if (variantResult.rows[0]) {
      mrp = variantResult.rows[0].mrp ?? mrp;
      buyPrice = variantResult.rows[0].buy_price ?? buyPrice;
      product.size = variantResult.rows[0].size ?? product.size;
      product.pack = variantResult.rows[0].pack ?? product.pack;
    }
  }

  return {
    product,
    quantity,
    mrp: Number(mrp),
    buyPrice: Number(buyPrice),
    lineTotal: Number(buyPrice) * quantity,
  };
}

function assertCustomerCanModifyOrder(order) {
  if (!order) {
    throw notFound("Order");
  }

  if (String(order.status).toLowerCase() !== "placed") {
    throw new ApiError(
      422,
      "Only placed orders can be changed by the customer",
    );
  }

  const createdAt = new Date(order.created_at);
  const ageMs = Date.now() - createdAt.getTime();
  const twoDaysMs = 2 * 24 * 60 * 60 * 1000;

  if (!Number.isFinite(ageMs) || ageMs > twoDaysMs) {
    throw new ApiError(
      422,
      "Orders can be changed only within 2 days of placing",
    );
  }
}

function assertCustomerCanCancelOrder(order) {
  if (!order) throw notFound("Order");
  const status = String(order.status).toLowerCase();
  if (!["placed", "confirmed", "packed"].includes(status)) {
    throw new ApiError(422, "Orders can be cancelled only before shipping");
  }
}

function isPrepaidPayment(payment) {
  if (!payment) return false;
  const mode = String(payment.mode || "").toLowerCase();
  return mode && mode !== "cod";
}

async function loadEditableOrder(client, orderId, userId) {
  const order = await client.query(
    "select * from orders where id=$1 and user_id=$2 for update",
    [orderId, userId],
  );
  assertCustomerCanModifyOrder(order.rows[0]);
  return order.rows[0];
}

function cleanIdempotencyKey(value) {
  const key = String(value || "").trim();
  if (!key) return null;
  if (key.length > 120) {
    throw new ApiError(422, "Order idempotency key is too long");
  }
  if (!/^[a-zA-Z0-9._:-]+$/.test(key)) {
    throw new ApiError(422, "Order idempotency key has an invalid format");
  }
  return key;
}

export async function createOrder(req, res, next) {
  const client = await pool.connect();
  let idempotencyKey = null;

  try {
    const { addressId, notes = "", paymentMode = null } = req.body;
    const items = Array.isArray(req.body.items) ? req.body.items : [];
    idempotencyKey = cleanIdempotencyKey(
      req.get("Idempotency-Key") || req.body.idempotencyKey,
    );

    if (!items.length) {
      throw new ApiError(422, "At least one order item is required");
    }

    await client.query("begin");

    if (idempotencyKey) {
      const existingOrder = await client.query(
        `select id
         from orders
         where user_id = $1 and idempotency_key = $2
         order by created_at desc
         limit 1`,
        [req.user.sub, idempotencyKey],
      );

      if (existingOrder.rows[0]) {
        await client.query("delete from cart_items where user_id = $1", [
          req.user.sub,
        ]);
        await client.query("commit");
        return res.json({
          success: true,
          data: await loadOrder(existingOrder.rows[0].id, req.user),
          meta: { idempotent: true },
        });
      }
    }

    if (!addressId) {
      throw new ApiError(422, "Delivery address is required");
    }

    const addressRow = await client.query(
      "select name, phone, line1, area, city, state, pincode from addresses where id = $1 and user_id = $2",
      [addressId, req.user.sub],
    );

    if (!addressRow.rows[0]) {
      throw notFound("Address");
    }

    const deliveryAddress = addressRow.rows[0];

    const snapshots = [];

    for (const item of items) {
      snapshots.push(await snapshotItem(client, item));
    }

    const total = snapshots.reduce((sum, item) => sum + item.lineTotal, 0);
    const orderItemsJson = snapshots.map((item) => ({
      productId: item.product.id,
      quantity: item.quantity,
      mrp: item.mrp,
      buyPrice: item.buyPrice,
      product: {
        sku: item.product.sku,
        brand: item.product.brand,
        name: item.product.name_en,
        imageUrl: item.product.image_url,
        size: item.product.size,
        pack: item.product.pack,
      },
    }));

    const orderResult = await client.query(
      `
        insert into orders(user_id, address_id, status, total, items, notes, idempotency_key, delivery_address)
        values($1, $2, 'placed', $3, $4, $5, $6, $7)
        returning *
      `,
      [
        req.user.sub,
        addressId,
        total,
        JSON.stringify(orderItemsJson),
        notes,
        idempotencyKey,
        JSON.stringify(deliveryAddress),
      ],
    );

    const order = orderResult.rows[0];
    await client.query(
      "insert into order_status_history(order_id,status) values($1,$2)",
      [order.id, "placed"],
    );

    for (const item of snapshots) {
      await client.query(
        `
          insert into order_items(order_id, product_id, quantity, mrp, buy_price)
          values($1, $2, $3, $4, $5)
        `,
        [order.id, item.product.id, item.quantity, item.mrp, item.buyPrice],
      );
    }

    if (paymentMode === "cod") {
      await client.query(
        `
          insert into payments(order_id, mode, status, amount, provider_ref)
          values($1, 'cod', 'pending', $2, null)
        `,
        [order.id, total],
      );
    }

    await client.query("delete from cart_items where user_id = $1", [
      req.user.sub,
    ]);

    await client.query("commit");
    emitAdmin("order.created", {
      orderId: order.id,
      userId: req.user.sub,
      total,
      status: order.status,
    });
    emitAdmin("dashboard.updated", {
      reason: "order.created",
      orderId: order.id,
    });
    emitAdmin("notification.created", {
      type: "order",
      title: `New order #${String(order.id).slice(0, 8)} received`,
    });
    emitCustomer(req.user.sub, "order.created", {
      orderId: order.id,
      status: order.status,
    });
    res
      .status(201)
      .json({ success: true, data: await loadOrder(order.id, req.user) });
  } catch (error) {
    await client.query("rollback");
    if (error?.code === "23505" && idempotencyKey) {
      const existingOrder = await query(
        `select id
         from orders
         where user_id = $1 and idempotency_key = $2
         order by created_at desc
         limit 1`,
        [req.user.sub, idempotencyKey],
      );
      if (existingOrder.rows[0]) {
        await query("delete from cart_items where user_id = $1", [
          req.user.sub,
        ]);
        return res.json({
          success: true,
          data: await loadOrder(existingOrder.rows[0].id, req.user),
          meta: { idempotent: true },
        });
      }
    }
    next(error);
  } finally {
    client.release();
  }
}

export async function listOrders(req, res, next) {
  try {
    const { page, limit, offset } = pageParams(req);
    const params = [];
    const filters = [];

    if (!isAdmin(req.user)) {
      params.push(req.user.sub);
      filters.push(`o.user_id = $${params.length}`);
    }

    if (req.query.status) {
      params.push(req.query.status);
      filters.push(`o.status = $${params.length}`);
    }

    const where = filters.length ? `where ${filters.join(" and ")}` : "";
    const totalResult = await query(
      `select count(*)::int as total from orders o ${where}`,
      params,
    );

    params.push(limit, offset);
    const result = await query(
      `
        select
          o.*,
          coalesce(
            json_agg(
              json_build_object(
                'id', oi.id,
                'productId', oi.product_id,
                'quantity', oi.quantity,
                'mrp', oi.mrp::float,
                'buyPrice', oi.buy_price::float,
                'product', json_build_object('name', p.name_en, 'imageUrl', p.image_url)
              )
              order by oi.id
            ) filter (where oi.id is not null),
            '[]'
          ) as items
          ,
          coalesce(
            (
              select json_agg(
                json_build_object(
                  'status', h.status,
                  'changed_at', h.changed_at,
                  'admin_id', h.changed_by_admin_id
                )
                order by h.changed_at
              )
              from order_status_history h
              where h.order_id = o.id
            ),
            '[]'::json
          ) as status_history
        from orders o
        left join order_items oi on oi.order_id = o.id
        left join products p on p.id = oi.product_id
        ${where}
        group by o.id
        order by o.created_at desc
        limit $${params.length - 1}
        offset $${params.length}
      `,
      params,
    );

    res.json({
      success: true,
      data: {
        items: result.rows,
        page,
        limit,
        total: totalResult.rows[0].total,
      },
    });
  } catch (error) {
    next(error);
  }
}

export async function getOrder(req, res, next) {
  try {
    const order = await loadOrder(req.params.id, req.user);

    if (!order) {
      throw notFound("Order");
    }

    res.json({ success: true, data: order });
  } catch (error) {
    next(error);
  }
}

export async function cancelOrder(req, res, next) {
  const client = await pool.connect();

  try {
    const reason = String(req.body.reason || "").trim();
    if (!reason) throw new ApiError(422, "Cancellation reason is required");
    await client.query("begin");
    const orderResult = await client.query(
      "select * from orders where id=$1 and user_id=$2 for update",
      [req.params.id, req.user.sub],
    );
    const order = orderResult.rows[0];
    assertCustomerCanCancelOrder(order);
    const paymentResult = await client.query(
      "select * from payments where order_id=$1 order by created_at desc limit 1",
      [req.params.id],
    );
    const payment = paymentResult.rows[0];
    const result = await client.query(
      `update orders
       set status='cancelled', notes=concat_ws(E'\n', nullif(notes, ''), $3::text), updated_at=now()
       where id=$1 and user_id=$2
       returning *`,
      [req.params.id, req.user.sub, `Cancellation reason: ${reason}`],
    );
    await client.query(
      "insert into order_status_history(order_id,status) values($1,$2)",
      [req.params.id, "cancelled"],
    );
    let refundRequest = null;
    if (isPrepaidPayment(payment)) {
      const refund = await client.query(
        `insert into refund_requests(order_id,customer_id,amount,reason,refund_method,status,request_type,items_json,quantity_total,customer_notes)
         values($1,$2,$3,$4,'original_payment','requested','cancel_refund',$5,$6,$7)
         returning *`,
        [
          req.params.id,
          req.user.sub,
          order.total,
          reason,
          JSON.stringify(order.items || []),
          Array.isArray(order.items)
            ? order.items.reduce(
                (sum, item) => sum + Number(item.quantity || 0),
                0,
              )
            : 0,
          "Refund required for prepaid cancelled order",
        ],
      );
      refundRequest = refund.rows[0];
    }
    await client.query("commit");

    emitAdmin("order.status_changed", {
      orderId: req.params.id,
      userId: req.user.sub,
      status: "cancelled",
      refundRequestId: refundRequest?.id || null,
    });
    emitAdmin("dashboard.updated", {
      reason: "order.cancelled",
      orderId: req.params.id,
    });
    if (refundRequest) {
      emitAdmin("refund.created", {
        refundRequestId: refundRequest.id,
        orderId: req.params.id,
        userId: req.user.sub,
      });
    }
    emitAdmin("notification.created", {
      type: "order",
      title: `Order #${String(req.params.id).slice(0, 8)} cancelled by customer`,
    });
    emitCustomer(req.user.sub, "order.status_changed", {
      orderId: req.params.id,
      status: "cancelled",
    });

    res.json({ success: true, data: result.rows[0] });
  } catch (error) {
    await client.query("rollback");
    next(error);
  } finally {
    client.release();
  }
}

export async function updateOrderItems(req, res, next) {
  const client = await pool.connect();

  try {
    const items = Array.isArray(req.body.items) ? req.body.items : [];

    if (!items.length) {
      throw new ApiError(422, "At least one order item is required");
    }

    await client.query("begin");
    await loadEditableOrder(client, req.params.id, req.user.sub);

    const snapshots = [];

    for (const item of items) {
      snapshots.push(await snapshotItem(client, item));
    }

    const total = snapshots.reduce((sum, item) => sum + item.lineTotal, 0);
    const orderItemsJson = snapshots.map((item) => ({
      productId: item.product.id,
      quantity: item.quantity,
      mrp: item.mrp,
      buyPrice: item.buyPrice,
      product: {
        sku: item.product.sku,
        brand: item.product.brand,
        name: item.product.name_en,
        imageUrl: item.product.image_url,
        size: item.product.size,
        pack: item.product.pack,
      },
    }));

    await client.query("delete from order_items where order_id=$1", [
      req.params.id,
    ]);

    for (const item of snapshots) {
      await client.query(
        `
          insert into order_items(order_id, product_id, quantity, mrp, buy_price)
          values($1, $2, $3, $4, $5)
        `,
        [
          req.params.id,
          item.product.id,
          item.quantity,
          item.mrp,
          item.buyPrice,
        ],
      );
    }

    const result = await client.query(
      `update orders
       set total=$3, items=$4, updated_at=now()
       where id=$1 and user_id=$2
       returning *`,
      [req.params.id, req.user.sub, total, JSON.stringify(orderItemsJson)],
    );

    await client.query("commit");

    emitAdmin("order.updated", {
      orderId: req.params.id,
      userId: req.user.sub,
      total,
    });
    emitCustomer(req.user.sub, "order.updated", {
      orderId: req.params.id,
      total,
    });

    res.json({
      success: true,
      data: await loadOrder(result.rows[0].id, req.user),
    });
  } catch (error) {
    await client.query("rollback");
    next(error);
  } finally {
    client.release();
  }
}

export async function requestRefund(req, res, next) {
  try {
    const {
      reason,
      refundMethod = "wallet",
      amount,
      requestType = "return",
      items = [],
      customerNotes = "",
    } = req.body;
    if (!reason) throw new ApiError(422, "reason is required");
    if (
      !["original_payment", "wallet", "upi", "store_credit"].includes(
        refundMethod,
      )
    ) {
      throw new ApiError(422, "invalid refund method");
    }
    if (!["return", "exchange"].includes(requestType)) {
      throw new ApiError(422, "invalid request type");
    }
    if (!Array.isArray(items) || items.length === 0) {
      throw new ApiError(422, "Select at least one item");
    }
    const order = await query(
      "select id,user_id,total,status,items from orders where id=$1 and user_id=$2",
      [req.params.id, req.user.sub],
    );
    if (!order.rows[0]) throw notFound("Order");
    if (String(order.rows[0].status) !== "delivered") {
      throw new ApiError(
        422,
        "Return or exchange can be requested only after delivery",
      );
    }
    const validItems = normalizeReturnItems(order.rows[0].items, items);
    const requestAmount =
      amount ||
      validItems.reduce(
        (sum, item) =>
          sum + Number(item.buyPrice || 0) * Number(item.quantity || 0),
        0,
      ) ||
      order.rows[0].total;
    const result = await query(
      `insert into refund_requests(order_id,customer_id,amount,reason,refund_method,status,request_type,items_json,quantity_total,customer_notes)
       values($1,$2,$3,$4,$5,'requested',$6,$7,$8,$9) returning *`,
      [
        order.rows[0].id,
        req.user.sub,
        requestAmount,
        reason,
        requestType === "exchange" ? "store_credit" : refundMethod,
        requestType,
        JSON.stringify(validItems),
        validItems.reduce((sum, item) => sum + Number(item.quantity || 0), 0),
        customerNotes,
      ],
    );
    emitAdmin("refund.created", {
      refundRequestId: result.rows[0].id,
      orderId: order.rows[0].id,
      userId: req.user.sub,
    });
    emitAdmin("dashboard.updated", {
      reason: "refund.created",
      refundRequestId: result.rows[0].id,
    });
    emitAdmin("notification.created", {
      type: "refund",
      title: `New refund request #${String(result.rows[0].id).slice(0, 8)}`,
    });
    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (error) {
    next(error);
  }
}

function normalizeReturnItems(orderItems, requestedItems) {
  const source = Array.isArray(orderItems) ? orderItems : [];
  return requestedItems.map((requested) => {
    const productId = String(requested.productId || requested.product_id || "");
    const original = source.find(
      (item) => String(item.productId || item.product_id) === productId,
    );
    if (!original)
      throw new ApiError(422, "Selected item is not part of this order");
    const requestedQty = Math.max(
      1,
      Number.parseInt(requested.quantity ?? "1", 10) || 1,
    );
    const maxQty = Number(original.quantity || 1);
    if (requestedQty > maxQty) {
      throw new ApiError(
        422,
        `Quantity for ${original.product?.name || "selected item"} exceeds ordered quantity`,
      );
    }
    return {
      productId,
      quantity: requestedQty,
      name: original.product?.name || requested.name || "",
      imageUrl: original.product?.imageUrl || requested.imageUrl || "",
      size: original.product?.size || "",
      pack: original.product?.pack || "",
      buyPrice: Number(original.buyPrice || original.buy_price || 0),
    };
  });
}
