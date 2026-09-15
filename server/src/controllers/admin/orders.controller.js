import { pool, query } from "../../config/db.js";
import { notifyOrderStatus, notifyUser, orderStatusNotification } from "../../services/notificationService.js";
import { emitAdmin, emitCustomer } from "../../services/realtimeService.js";
import { ApiError, notFound } from "../../utils/apiError.js";
import { resolveAdminId, logAdminActivity, logNotification, assertLegalOrderTransition, isRefundEligibleStatus, paymentCaptured, orderRefundSummary, refundSettings, writeWalletTransaction } from "./helpers.js";

export const orders = async (_req, res, next) => {
  try {
    const result = await query(`
      select o.*, u.name as customer, u.phone,
        coalesce(o.delivery_address, row_to_json(a.*)::jsonb) as address,
        coalesce(r.refunded_total, 0)::numeric as refunded_total,
        coalesce(pay.mode, 'cod') as payment_mode,
        pay.status as payment_status,
        coalesce(
          json_agg(json_build_object('status', h.status, 'changed_at', h.changed_at, 'admin_id', h.changed_by_admin_id) order by h.changed_at)
          filter (where h.id is not null),
          '[]'::json
        ) as status_history
      from orders o
      left join users u on u.id = o.user_id
      left join addresses a on a.id = o.address_id
      left join order_status_history h on h.order_id = o.id
      left join (
        select order_id, sum(amount) as refunded_total
        from refunds
        where status in ('pending','processed')
        group by order_id
      ) r on r.order_id = o.id
      left join lateral (
        select mode, status
        from payments
        where order_id=o.id
        order by created_at desc
        limit 1
      ) pay on true
      group by o.id, a.id, u.name, u.phone, r.refunded_total, pay.mode, pay.status
      order by o.created_at desc
    `);
    res.json({ success: true, data: result.rows });
  } catch (e) {
    next(e);
  }
};

export const orderDetail = async (req, res, next) => {
  try {
    const result = await query(
      `
        select o.*, u.name as customer, u.phone,
          coalesce(o.delivery_address, row_to_json(a.*)::jsonb) as address,
          coalesce(r.refunded_total, 0)::numeric as refunded_total,
          coalesce(pay.mode, 'cod') as payment_mode,
          pay.status as payment_status,
          coalesce(
            json_agg(json_build_object('status', h.status, 'changed_at', h.changed_at, 'admin_id', h.changed_by_admin_id) order by h.changed_at)
            filter (where h.id is not null),
            '[]'::json
          ) as status_history
        from orders o
        left join users u on u.id = o.user_id
        left join addresses a on a.id = o.address_id
        left join order_status_history h on h.order_id = o.id
        left join (
          select order_id, sum(amount) as refunded_total
          from refunds
          where status in ('pending','processed')
          group by order_id
        ) r on r.order_id = o.id
        left join lateral (
          select mode, status
          from payments
          where order_id=o.id
          order by created_at desc
          limit 1
        ) pay on true
        where o.id=$1
        group by o.id, a.id, u.name, u.phone, r.refunded_total, pay.mode, pay.status
      `,
      [req.params.id],
    );
    if (!result.rows[0]) throw notFound("Order");
    res.json({ success: true, data: result.rows[0] });
  } catch (e) {
    next(e);
  }
};

export async function updateOrderStatus(req, res, next) {
  const client = await pool.connect();
  try {
    const { status } = req.body;
    if (!status) throw new ApiError(422, "status is required");
    await client.query("begin");
    const before = await client.query(
      "select * from orders where id=$1 for update",
      [req.params.id],
    );
    if (!before.rows[0]) throw notFound("Order");
    assertLegalOrderTransition(String(before.rows[0].status), String(status));
    const adminId = await resolveAdminId(req.admin?.id, client);
    const result = await client.query(
      "update orders set status=$2, updated_at=now() where id=$1 returning *",
      [req.params.id, status],
    );
    if (!result.rows[0]) throw notFound("Order");
    await client.query(
      "insert into order_status_history(order_id,status,changed_by_admin_id) values($1,$2,$3)",
      [req.params.id, status, adminId],
    );
    await client.query(
      `insert into admin_activity_log(admin_id,action,entity_type,entity_id,before_json,after_json)
       values($1,$2,$3,$4,$5,$6)`,
      [
        adminId,
        "update_status",
        "order",
        req.params.id,
        before.rows[0],
        result.rows[0],
      ],
    );

    const message = orderStatusNotification(status, req.params.id);
    let notification = { sent: false, reason: "not attempted" };
    const notificationLog = await client.query(
      `insert into notifications_log(target,title,body,segment_json,sent_by_admin_id,delivery_status)
       values($1,$2,$3,$4,$5,$6)
       returning id`,
      [
        "user",
        message.title,
        message.body,
        { orderId: req.params.id, status },
        adminId,
        "queued",
      ],
    );

    try {
      notification = await notifyOrderStatus(req.params.id, status);
    } catch (notificationError) {
      notification = {
        sent: false,
        reason: notificationError.message || "notification failed",
      };
      console.error("Order status notification failed", notificationError);
    }

    await client.query(
      "update notifications_log set delivery_status=$2 where id=$1",
      [
        notificationLog.rows[0].id,
        notification.sent
          ? "sent"
          : `skipped: ${notification.reason || "unknown"}`,
      ],
    );

    await client.query("commit");

    try {
      emitAdmin("order.status_changed", { orderId: req.params.id, status });
      emitAdmin("dashboard.updated", {
        reason: "order.status_changed",
        orderId: req.params.id,
      });
      emitCustomer(result.rows[0].user_id, "order.status_changed", {
        orderId: req.params.id,
        status,
        route: `/orders/${req.params.id}/tracking`,
      });
    } catch (socketError) {
      console.error("Order status socket emit failed", socketError);
    }

    res.json({
      success: true,
      data: result.rows[0],
      meta: { notification },
    });
  } catch (e) {
    try {
      await client.query("rollback");
    } catch (_) {
      /* noop */
    }
    next(e);
  } finally {
    client.release();
  }
}

export async function createRefund(req, res, next) {
  const client = await pool.connect();
  try {
    const idempotencyKey = String(
      req.get("Idempotency-Key") || req.body?.idempotencyKey || "",
    ).trim();
    const amount = Number(req.body?.amount);
    const reason = String(req.body?.reason || "").trim();
    const destination = String(
      req.body?.destination || req.body?.refundMethod || "wallet",
    ).trim();
    const items = Array.isArray(req.body?.items) ? req.body.items : [];
    const notes = String(req.body?.notes || "").trim();

    if (!idempotencyKey)
      throw new ApiError(422, "Idempotency key is required for refunds");
    if (!Number.isFinite(amount) || amount <= 0)
      throw new ApiError(422, "Refund amount must be greater than zero");
    if (!reason) throw new ApiError(422, "Refund reason is required");

    await client.query("begin");
    const adminId = await resolveAdminId(req.admin?.id, client);

    const duplicate = await client.query(
      "select * from refunds where initiated_by=$1 and idempotency_key=$2",
      [adminId, idempotencyKey],
    );
    if (duplicate.rows[0]) {
      await client.query("commit");
      return res.json({
        success: true,
        data: duplicate.rows[0],
        meta: { idempotent: true },
      });
    }

    const orderResult = await client.query(
      `
        select o.*,
          coalesce(pay.mode, 'cod') as payment_mode,
          pay.status as payment_status
        from orders o
        left join lateral (
          select mode, status
          from payments
          where order_id=o.id
          order by created_at desc
          limit 1
        ) pay on true
        where o.id=$1
        for update of o
      `,
      [req.params.id],
    );
    const order = orderResult.rows[0];
    if (!order) throw notFound("Order");
    if (!isRefundEligibleStatus(order.status)) {
      throw new ApiError(
        422,
        "Refunds are available only for delivered, partially refunded, or prepaid cancelled orders",
      );
    }
    if (order.status === "cancelled" && !paymentCaptured(order)) {
      throw new ApiError(
        422,
        "COD cancelled orders do not have a captured payment to refund",
      );
    }
    if (order.status === "refunded")
      throw new ApiError(422, "This order is already fully refunded");

    const settings = await refundSettings(client);
    if (!settings.enabledDestinations.includes(destination)) {
      throw new ApiError(
        422,
        `Refund destination ${destination} is disabled in settings`,
      );
    }
    if (
      ["original_payment", "upi"].includes(destination) &&
      !paymentCaptured(order)
    ) {
      throw new ApiError(
        422,
        "Original payment or UPI refund is only available for paid orders",
      );
    }

    const { refundedTotal } = await orderRefundSummary(order.id, client);
    const orderTotal = Number(order.total || 0);
    const remaining = Math.max(0, orderTotal - refundedTotal);
    if (remaining <= 0)
      throw new ApiError(422, "This order is already fully refunded");
    if (amount > remaining) {
      throw new ApiError(
        422,
        `Refund amount cannot exceed remaining refundable balance of Rs ${remaining.toFixed(2)}`,
      );
    }

    let status = ["wallet", "store_credit"].includes(destination)
      ? "processed"
      : "pending";
    let walletTransaction = null;
    const metadata = {
      notes,
      paymentMode: order.payment_mode,
      paymentStatus: order.payment_status,
      remainingBeforeRefund: remaining,
    };

    const refundResult = await client.query(
      `
        insert into refunds(order_id,amount,reason,destination,items_json,initiated_by,status,idempotency_key,metadata_json,processed_at)
        values($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
        returning *
      `,
      [
        order.id,
        amount,
        reason,
        destination,
        JSON.stringify(items),
        adminId,
        status,
        idempotencyKey,
        metadata,
        status === "processed" ? new Date() : null,
      ],
    );
    const refund = refundResult.rows[0];

    if (status === "processed") {
      walletTransaction = await writeWalletTransaction(
        {
          customerId: order.user_id,
          type: "credit",
          amount,
          reason: "order_refund",
          referenceType: "refund",
          referenceId: refund.id,
          adminId,
        },
        client,
      );
    }

    const nextRefundedTotal = refundedTotal + amount;
    const nextOrderStatus =
      nextRefundedTotal >= orderTotal ? "refunded" : "partially_refunded";
    const updatedOrder = await client.query(
      "update orders set status=$2, updated_at=now() where id=$1 returning *",
      [order.id, nextOrderStatus],
    );
    if (String(order.status) !== nextOrderStatus) {
      await client.query(
        "insert into order_status_history(order_id,status,changed_by_admin_id) values($1,$2,$3)",
        [order.id, nextOrderStatus, adminId],
      );
    }

    await client.query(
      `insert into admin_activity_log(admin_id,action,entity_type,entity_id,before_json,after_json)
       values($1,$2,$3,$4,$5,$6)`,
      [
        adminId,
        "refund",
        "refund",
        refund.id,
        order,
        { refund, order: updatedOrder.rows[0], walletTransaction },
      ],
    );

    const notificationLog = await client.query(
      `insert into notifications_log(target,title,body,segment_json,sent_by_admin_id,delivery_status)
       values($1,$2,$3,$4,$5,$6) returning id`,
      [
        "user",
        "Refund update",
        status === "processed"
          ? `Refund of Rs ${amount.toFixed(2)} has been processed.`
          : `Refund of Rs ${amount.toFixed(2)} is pending gateway processing.`,
        { orderId: order.id, refundId: refund.id, destination, status },
        adminId,
        "queued",
      ],
    );

    await client.query("commit");

    let notification = { sent: false, reason: "not attempted" };
    try {
      notification = await notifyUser(order.user_id, {
        title: "Refund update",
        body:
          status === "processed"
            ? `Refund of Rs ${amount.toFixed(2)} has been processed.`
            : `Refund of Rs ${amount.toFixed(2)} is pending gateway processing.`,
        data: {
          orderId: order.id,
          refundId: refund.id,
          status: nextOrderStatus,
        },
      });
    } catch (notificationError) {
      notification = {
        sent: false,
        reason: notificationError.message || "notification failed",
      };
      console.error("Refund notification failed", notificationError);
    }

    await query("update notifications_log set delivery_status=$2 where id=$1", [
      notificationLog.rows[0].id,
      notification.sent
        ? "sent"
        : `skipped: ${notification.reason || "unknown"}`,
    ]);

    emitCustomer(order.user_id, "refund.status_changed", {
      refundId: refund.id,
      orderId: order.id,
      status,
      orderStatus: nextOrderStatus,
    });
    emitCustomer(order.user_id, "order.status_changed", {
      orderId: order.id,
      status: nextOrderStatus,
      route: `/orders/${order.id}/tracking`,
    });
    emitAdmin("refund.created", {
      refundId: refund.id,
      orderId: order.id,
      status,
    });
    emitAdmin("order.status_changed", {
      orderId: order.id,
      status: nextOrderStatus,
    });
    emitAdmin("dashboard.updated", {
      reason: "refund.created",
      refundId: refund.id,
      orderId: order.id,
    });

    res.status(201).json({
      success: true,
      data: refund,
      meta: { order: updatedOrder.rows[0], notification },
    });
  } catch (e) {
    try {
      await client.query("rollback");
    } catch (_) {
      /* noop */
    }
    next(e);
  } finally {
    client.release();
  }
}

export async function approveRefund(req, res, next) {
  const client = await pool.connect();
  try {
    await client.query("begin");
    const adminId = await resolveAdminId(req.admin?.id, client);
    const before = await client.query(
      "select * from refund_requests where id=$1 for update",
      [req.params.id],
    );
    if (!before.rows[0]) throw notFound("Refund request");
    if (before.rows[0].status !== "requested")
      throw new ApiError(422, "Only requested refunds can be approved");
    const request = before.rows[0];
    const orderResult = await client.query(
      "select * from orders where id=$1 for update",
      [request.order_id],
    );
    const order = orderResult.rows[0];
    if (!order) throw notFound("Order");
    let status = "approved";
    let transaction = null;
    if (
      request.refund_method === "wallet" ||
      request.refund_method === "store_credit"
    ) {
      transaction = await writeWalletTransaction(
        {
          customerId: request.customer_id,
          type: "credit",
          amount: request.amount,
          reason: "order_refund",
          referenceType: "refund_request",
          referenceId: request.id,
          adminId,
        },
        client,
      );
      status =
        request.refund_method === "wallet"
          ? "credited_to_wallet"
          : "store_credit_issued";
    } else if (
      request.refund_method === "original_payment" ||
      request.refund_method === "upi"
    ) {
      status = "pending_manual_gateway_refund";
    }
    const result = await client.query(
      "update refund_requests set status=$2, admin_notes=$3, updated_at=now() where id=$1 returning *",
      [req.params.id, status, req.body?.notes || null],
    );
    const totals = await client.query(
      `
        select coalesce(sum(amount), 0)::numeric as refunded_total
        from (
          select amount
          from refund_requests
          where order_id=$1
            and id <> $2
            and status in ('credited_to_wallet','store_credit_issued','pending_manual_gateway_refund','refunded')
          union all
          select amount
          from refunds
          where order_id=$1 and status in ('pending','processed')
        ) rows
      `,
      [request.order_id, request.id],
    );
    const nextRefundedTotal =
      Number(totals.rows[0]?.refunded_total || 0) + Number(request.amount || 0);
    const nextOrderStatus =
      nextRefundedTotal >= Number(order.total || 0)
        ? "refunded"
        : "partially_refunded";
    const updatedOrder = await client.query(
      "update orders set status=$2, updated_at=now() where id=$1 returning *",
      [request.order_id, nextOrderStatus],
    );
    if (String(order.status) !== nextOrderStatus) {
      await client.query(
        "insert into order_status_history(order_id,status,changed_by_admin_id) values($1,$2,$3)",
        [request.order_id, nextOrderStatus, adminId],
      );
    }
    await client.query(
      `insert into admin_activity_log(admin_id,action,entity_type,entity_id,before_json,after_json)
       values($1,$2,$3,$4,$5,$6)`,
      [
        adminId,
        "approve",
        "refund_request",
        req.params.id,
        before.rows[0],
        {
          ...result.rows[0],
          order: updatedOrder.rows[0],
          walletTransaction: transaction,
        },
      ],
    );
    await client.query("commit");
    const notification = await notifyUser(request.customer_id, {
      title: "Refund update",
      body:
        status === "credited_to_wallet"
          ? `Refund of Rs ${request.amount} has been credited to your wallet.`
          : "Your refund request has been approved.",
      data: { refundRequestId: request.id, status },
    });
    await logNotification({
      target: "user",
      title: "Refund update",
      body: `Refund request ${status}`,
      segment: { refundRequestId: request.id, userId: request.customer_id },
      sentByAdminId: req.admin?.id || null,
      deliveryStatus: notification.sent
        ? "sent"
        : `skipped: ${notification.reason || "unknown"}`,
    });
    emitCustomer(request.customer_id, "refund.status_changed", {
      refundRequestId: request.id,
      status,
    });
    emitCustomer(request.customer_id, "order.status_changed", {
      orderId: request.order_id,
      status: nextOrderStatus,
    });
    emitAdmin("refund.status_changed", {
      refundRequestId: request.id,
      orderId: request.order_id,
      status,
    });
    emitAdmin("order.status_changed", {
      orderId: request.order_id,
      status: nextOrderStatus,
    });
    emitAdmin("dashboard.updated", {
      reason: "refund.status_changed",
      refundRequestId: request.id,
    });
    res.json({ success: true, data: result.rows[0] });
  } catch (e) {
    try {
      await client.query("rollback");
    } catch (_) {
      /* noop */
    }
    next(e);
  } finally {
    client.release();
  }
}

export async function rejectRefund(req, res, next) {
  try {
    const { reason } = req.body;
    if (!reason) throw new ApiError(422, "rejection reason is required");
    const before = await query("select * from refund_requests where id=$1", [
      req.params.id,
    ]);
    if (!before.rows[0]) throw notFound("Refund request");
    const result = await query(
      "update refund_requests set status=$2,rejection_reason=$3,updated_at=now() where id=$1 returning *",
      [req.params.id, "rejected", reason],
    );
    await logAdminActivity(
      req,
      "reject",
      "refund_request",
      req.params.id,
      before.rows[0],
      result.rows[0],
    );
    const notification = await notifyUser(result.rows[0].customer_id, {
      title: "Refund request rejected",
      body: reason,
      data: { refundRequestId: req.params.id, status: "rejected" },
    });
    await logNotification({
      target: "user",
      title: "Refund request rejected",
      body: reason,
      segment: {
        refundRequestId: req.params.id,
        userId: result.rows[0].customer_id,
      },
      sentByAdminId: req.admin?.id || null,
      deliveryStatus: notification.sent
        ? "sent"
        : `skipped: ${notification.reason || "unknown"}`,
    });
    emitCustomer(result.rows[0].customer_id, "refund.status_changed", {
      refundRequestId: req.params.id,
      status: "rejected",
    });
    emitAdmin("refund.status_changed", {
      refundRequestId: req.params.id,
      orderId: result.rows[0].order_id,
      status: "rejected",
    });
    emitAdmin("dashboard.updated", {
      reason: "refund.status_changed",
      refundRequestId: req.params.id,
    });
    res.json({ success: true, data: result.rows[0] });
  } catch (e) {
    next(e);
  }
}
