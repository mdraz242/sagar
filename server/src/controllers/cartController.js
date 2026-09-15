import { query } from "../config/db.js";
import { ApiError } from "../utils/apiError.js";

function parseCartBody(body) {
  let productId = body.productId;
  let variantKey = body.variantKey ?? null;

  if (!productId && body.cartKey) {
    const [id, ...variantParts] = String(body.cartKey).split("__");
    productId = id;
    variantKey = variantParts.length ? variantParts.join("__") : variantKey;
  }

  if (productId && String(productId).includes("__") && !body.variantKey) {
    const [id, ...variantParts] = String(productId).split("__");
    productId = id;
    variantKey = variantParts.length ? variantParts.join("__") : variantKey;
  }

  const quantity = Math.max(1, Number.parseInt(body.quantity ?? "1", 10) || 1);
  return { productId, variantKey, quantity };
}

async function resolveVariantKey(productId, variantKey) {
  if (!variantKey) return { variantKey: null, aliases: [] };

  const variants = await query(
    `
      select
        id::text as id,
        replace(coalesce(nullif(variant_name, ''), size, ''), ' ', '_') as key
      from product_variants
      where product_id = $1
        and coalesce(status, 'active') = 'active'
    `,
    [productId],
  );

  const match = variants.rows.find(
    (variant) => variant.id === variantKey || variant.key === variantKey,
  );

  if (variants.rows.length <= 1) {
    return {
      variantKey: null,
      aliases: [...new Set([variantKey, match?.id, match?.key].filter(Boolean))],
    };
  }

  if (!match) {
    throw new ApiError(404, "Selected pack size is unavailable");
  }

  return {
    variantKey: match.id,
    aliases: [...new Set([variantKey, match.id, match.key].filter(Boolean))],
  };
}

async function mergeCartItems(userId, productId, variantKey, aliases = []) {
  const aliasList = [...new Set(aliases.filter(Boolean))];
  const result = variantKey
    ? await query(
        `
          select id, quantity, variant_key
          from cart_items
          where user_id = $1
            and product_id = $2
            and (variant_key = $3 or variant_key = any($4::text[]))
        `,
        [userId, productId, variantKey, aliasList],
      )
    : await query(
        `
          select id, quantity, variant_key
          from cart_items
          where user_id = $1
            and product_id = $2
            and (variant_key is null or variant_key = any($3::text[]))
        `,
        [userId, productId, aliasList],
      );

  if (result.rows.length === 1) {
    const item = result.rows[0];
    if ((item.variant_key ?? null) !== (variantKey ?? null)) {
      await query("update cart_items set variant_key = $2, updated_at = now() where id = $1", [
        item.id,
        variantKey,
      ]);
    }
    return;
  }

  if (result.rows.length === 0) return;

  const quantity = result.rows.reduce(
    (sum, item) => sum + Number(item.quantity || 0),
    0,
  );
  const ids = result.rows.map((item) => item.id);

  await query("delete from cart_items where id = any($1::uuid[])", [ids]);
  if (quantity > 0) {
    await query(
      `
        insert into cart_items(user_id, product_id, variant_key, quantity)
        values($1, $2, $3, $4)
      `,
      [userId, productId, variantKey, quantity],
    );
  }
}

async function loadCart(userId) {
  const result = await query(
    `
      select
        ci.id,
        ci.product_id as "productId",
        ci.variant_key as "variantKey",
        ci.quantity,
        p.sku,
        p.brand,
        p.name_en as "name",
        p.name_hi as "nameHi",
        coalesce(nullif(pv.variant_name, ''), pv.size, p.size) as size,
        coalesce(nullif(pv.pack, ''), nullif(pv.unit, ''), p.pack) as pack,
        p.image_url as "imageUrl",
        coalesce(pv.mrp, p.mrp)::float as "mrp",
        coalesce(pv.selling_price, pv.buy_price, p.buy_price)::float as "buyPrice",
        (coalesce(pv.mrp, p.mrp) * ci.quantity)::float as "lineMrp",
        (coalesce(pv.selling_price, pv.buy_price, p.buy_price) * ci.quantity)::float as "lineTotal"
      from cart_items ci
      join products p on p.id = ci.product_id
      left join product_variants pv
        on pv.product_id = p.id
       and (pv.id::text = ci.variant_key or replace(coalesce(nullif(pv.variant_name, ''), pv.size, ''), ' ', '_') = ci.variant_key)
       and coalesce(pv.status, 'active') = 'active'
      where ci.user_id = $1
      order by ci.created_at desc
    `,
    [userId],
  );

  const items = result.rows;
  const totalMrp = items.reduce((sum, item) => sum + Number(item.lineMrp), 0);
  const total = items.reduce((sum, item) => sum + Number(item.lineTotal), 0);

  return {
    items,
    summary: {
      count: items.reduce((sum, item) => sum + Number(item.quantity), 0),
      totalMrp,
      total,
      savings: Math.max(0, totalMrp - total),
    },
  };
}

export async function getCart(req, res, next) {
  try {
    res.json({ success: true, data: await loadCart(req.user.sub) });
  } catch (error) {
    next(error);
  }
}

export async function add(req, res, next) {
  try {
    const parsed = parseCartBody(req.body);
    const { productId, quantity } = parsed;

    if (!productId) {
      throw new ApiError(422, "productId is required");
    }

    const product = await query(
      "select id from products where id::text = $1 and is_active = true",
      [productId],
    );

    if (!product.rows[0]) {
      throw new ApiError(404, "Product not found");
    }

    const resolved = await resolveVariantKey(productId, parsed.variantKey);
    const variantKey = resolved.variantKey;

    if (variantKey) {
      const variant = await query(
        `
          select id
          from product_variants
          where product_id = $1
            and (
              id::text = $2
              or replace(coalesce(nullif(variant_name, ''), size, ''), ' ', '_') = $2
            )
            and coalesce(status, 'active') = 'active'
            and coalesce(stock_quantity, 0) > 0
          limit 1
        `,
        [productId, variantKey],
      );

      if (!variant.rows[0]) {
        throw new ApiError(404, "Selected pack size is unavailable");
      }
    }

    await mergeCartItems(req.user.sub, productId, variantKey, resolved.aliases);

    const existing = await query(
      `
        select id, quantity
        from cart_items
        where user_id = $1
          and product_id = $2
          and variant_key is not distinct from $3
      `,
      [req.user.sub, productId, variantKey],
    );

    if (existing.rows[0]) {
      await query(
        "update cart_items set quantity = quantity + $2, updated_at = now() where id = $1",
        [existing.rows[0].id, quantity],
      );
    } else {
      await query(
        `
          insert into cart_items(user_id, product_id, variant_key, quantity)
          values($1, $2, $3, $4)
        `,
        [req.user.sub, productId, variantKey, quantity],
      );
    }

    res.status(201).json({ success: true, data: await loadCart(req.user.sub) });
  } catch (error) {
    next(error);
  }
}

export async function remove(req, res, next) {
  try {
    const parsed = parseCartBody(req.body);
    const { productId, quantity } = parsed;

    if (!productId) {
      throw new ApiError(422, "productId is required");
    }

    let resolved;
    try {
      resolved = await resolveVariantKey(productId, parsed.variantKey);
    } catch (error) {
      if (error.status === 404 && parsed.variantKey) {
        await query(
          `
            delete from cart_items
            where user_id = $1
              and product_id = $2
              and variant_key = $3
          `,
          [req.user.sub, productId, parsed.variantKey],
        );
        res.json({ success: true, data: await loadCart(req.user.sub) });
        return;
      }
      throw error;
    }
    const variantKey = resolved.variantKey;
    await mergeCartItems(req.user.sub, productId, variantKey, resolved.aliases);

    const existing = await query(
      `
        select id, quantity
        from cart_items
        where user_id = $1
          and product_id = $2
          and variant_key is not distinct from $3
      `,
      [req.user.sub, productId, variantKey],
    );

    const item = existing.rows[0];

    if (item) {
      if (Number(item.quantity) <= quantity) {
        await query("delete from cart_items where id = $1", [item.id]);
      } else {
        await query(
          "update cart_items set quantity = quantity - $2, updated_at = now() where id = $1",
          [item.id, quantity],
        );
      }
    }

    res.json({ success: true, data: await loadCart(req.user.sub) });
  } catch (error) {
    next(error);
  }
}
