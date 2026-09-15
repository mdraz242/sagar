import { query } from "../config/db.js";

function pagination(params) {
  const page = Math.max(1, Number.parseInt(params.page || "1", 10) || 1);
  const limit = Math.min(
    500,
    Math.max(1, Number.parseInt(params.limit || "20", 10) || 20),
  );
  return { page, limit, offset: (page - 1) * limit };
}

function asNumber(value, fallback = 0) {
  const number = Number(value);
  return Number.isFinite(number) ? number : fallback;
}

function validVariantFilter(alias, productAlias = "p") {
  return `coalesce(${alias}.status, 'active') = 'active'
    and coalesce(${alias}.is_active, true) = true
    and coalesce(${alias}.mrp, ${productAlias}.mrp, 0) > 0
    and coalesce(${alias}.selling_price, ${alias}.buy_price, ${productAlias}.buy_price, 0) > 0
    and coalesce(${alias}.pack_quantity, 1) > 0`;
}

function hasValidVariantPrice(variant) {
  return (
    Boolean(variant) &&
    (variant.isActive ?? variant.is_active ?? true) !== false &&
    asNumber(variant.mrp) > 0 &&
    asNumber(variant.buyPrice ?? variant.buy_price) > 0 &&
    asNumber(variant.packQuantity ?? variant.pack_quantity, 1) > 0
  );
}

function normalizeProductPayload(product) {
  const variants = Array.isArray(product.variants)
    ? product.variants.filter(hasValidVariantPrice)
    : [];
  variants.sort((a, b) => {
    const aStock = asNumber(a.stock);
    const bStock = asNumber(b.stock);
    if (aStock > 0 && bStock <= 0) return -1;
    if (aStock <= 0 && bStock > 0) return 1;
    const aPack = asNumber(a.packQuantity ?? a.pack_quantity, 1);
    const bPack = asNumber(b.packQuantity ?? b.pack_quantity, 1);
    if (aPack !== bPack) return aPack - bPack;
    return asNumber(a.buyPrice ?? a.buy_price) - asNumber(b.buyPrice ?? b.buy_price);
  });

  const displayVariant = variants[0];
  const rawMrp = asNumber(product.mrp);
  const rawBuyPrice = asNumber(product.buyPrice ?? product.buy_price);
  const rawStock = asNumber(product.stock);
  const stock = variants.length
    ? variants.reduce((sum, variant) => sum + asNumber(variant.stock), 0)
    : rawStock;

  if (!displayVariant) {
    return {
      ...product,
      mrp: rawMrp,
      buy_price: rawBuyPrice,
      buyPrice: rawBuyPrice,
      stock,
      variants,
      default_variant: null,
      defaultVariant: null,
    };
  }

  const variantMrp = asNumber(displayVariant.mrp);
  const variantBuyPrice = asNumber(
    displayVariant.buyPrice ?? displayVariant.buy_price,
  );
  const effectiveMrp = variantMrp > 0 ? variantMrp : rawMrp;
  const effectiveBuyPrice = variantBuyPrice > 0 ? variantBuyPrice : rawBuyPrice;

  return {
    ...product,
    size: displayVariant.size || product.size || "",
    pack: displayVariant.pack || product.pack || "",
    mrp: effectiveMrp,
    buy_price: effectiveBuyPrice,
    buyPrice: effectiveBuyPrice,
    stock,
    variants,
    default_variant: displayVariant,
    defaultVariant: displayVariant,
  };
}

export async function products(params = {}) {
  const { page, limit, offset } = pagination(params);
  const values = [];
  const filters = [
    "p.is_active = true",
    "(p.category_id is null or coalesce(c.is_active, true) = true)",
    "(p.brand_id is null or (coalesce(b.is_active, true) = true and coalesce(b.status, 'active') <> 'inactive'))",
    `not exists (
      select 1
      from brands bx
      where p.brand_id is null
        and lower(bx.name) = lower(coalesce(p.brand, ''))
        and (coalesce(bx.is_active, true) = false or coalesce(bx.status, 'active') = 'inactive')
    )`,
  ];

  const categoryFilter =
    params.categoryId ?? params.category_id ?? params.category;
  if (categoryFilter) {
    values.push(String(categoryFilter));
    filters.push(
      `(p.category_id::text = $${values.length} or c.slug = $${values.length})`,
    );
  }

  if (params.search) {
    values.push(`%${params.search}%`);
    filters.push(
      `(p.name_en ilike $${values.length} or coalesce(p.name_hi, '') ilike $${values.length})`,
    );
  }

  if (params.brand) {
    values.push(String(params.brand));
    filters.push(`p.brand ilike $${values.length}`);
  }

  const where = `where ${filters.join(" and ")}`;
  const totalResult = await query(
    `
      select count(*)::int as total
      from products p
      left join categories c on c.id = p.category_id
      left join brands b on b.id = p.brand_id
      ${where}
    `,
    values,
  );

  values.push(limit, offset);
  const result = await query(
    `
      select
        p.*,
        c.slug as category_slug,
        c.name_en as category_name,
        coalesce(
          json_agg(
            json_build_object(
              'id', pv.id,
              'product_id', pv.product_id,
              'size', coalesce(nullif(pv.variant_name, ''), pv.size, p.size),
              'pack', coalesce(nullif(pv.pack, ''), nullif(pv.unit, ''), p.pack),
              'pack_quantity', coalesce(pv.pack_quantity, 1),
              'packQuantity', coalesce(pv.pack_quantity, 1),
              'mrp', coalesce(pv.mrp, p.mrp, 0)::float,
              'buyPrice', coalesce(pv.selling_price, pv.buy_price, p.buy_price, 0)::float,
              'costPrice', coalesce(pv.cost_price, pv.selling_price, pv.buy_price, p.buy_price, 0)::float,
              'cost_price', coalesce(pv.cost_price, pv.selling_price, pv.buy_price, p.buy_price, 0)::float,
              'stock', coalesce(pv.stock_quantity, p.stock, 0),
              'is_active', coalesce(pv.is_active, coalesce(pv.status, 'active') = 'active'),
              'isActive', coalesce(pv.is_active, coalesce(pv.status, 'active') = 'active')
            )
            order by pv.is_default desc, pv.created_at
          ) filter (where pv.id is not null and ${validVariantFilter("pv")}),
          '[]'::json
        ) as variants,
        coalesce(min(coalesce(pv.selling_price, pv.buy_price, p.buy_price, p.mrp)) filter (where pv.id is not null and ${validVariantFilter("pv")}), p.buy_price) as starting_price
      from products p
      left join categories c on c.id = p.category_id
      left join brands b on b.id = p.brand_id
      left join product_variants pv on pv.product_id = p.id
      ${where}
      group by p.id, c.id
      order by p.created_at desc
      limit $${values.length - 1}
      offset $${values.length}
    `,
    values,
  );

  return {
    items: result.rows.map(normalizeProductPayload),
    page,
    limit,
    total: totalResult.rows[0].total,
  };
}

export async function productById(id) {
  const result = await query(
    `
      select
        p.*,
        c.slug as category_slug,
        c.name_en as category_name,
        coalesce(
          json_agg(
            json_build_object(
              'id', pv.id,
              'product_id', pv.product_id,
              'size', coalesce(nullif(pv.variant_name, ''), pv.size, p.size),
              'pack', coalesce(nullif(pv.pack, ''), nullif(pv.unit, ''), p.pack),
              'pack_quantity', coalesce(pv.pack_quantity, 1),
              'packQuantity', coalesce(pv.pack_quantity, 1),
              'mrp', coalesce(pv.mrp, p.mrp, 0)::float,
              'buyPrice', coalesce(pv.selling_price, pv.buy_price, p.buy_price, 0)::float,
              'costPrice', coalesce(pv.cost_price, pv.selling_price, pv.buy_price, p.buy_price, 0)::float,
              'cost_price', coalesce(pv.cost_price, pv.selling_price, pv.buy_price, p.buy_price, 0)::float,
              'stock', coalesce(pv.stock_quantity, p.stock, 0),
              'is_active', coalesce(pv.is_active, coalesce(pv.status, 'active') = 'active'),
              'isActive', coalesce(pv.is_active, coalesce(pv.status, 'active') = 'active')
            )
            order by pv.is_default desc, pv.created_at
          ) filter (where pv.id is not null and ${validVariantFilter("pv")}),
          '[]'
        ) as variants
      from products p
      left join categories c on c.id = p.category_id
      left join brands b on b.id = p.brand_id
      left join product_variants pv on pv.product_id = p.id
      where (
          p.id::text = $1
          or p.sku = $1
          or exists (
            select 1
            from product_variants pv_lookup
            where pv_lookup.product_id = p.id
              and (pv_lookup.id::text = $1 or pv_lookup.sku = $1)
          )
        )
        and p.is_active = true
        and (p.category_id is null or coalesce(c.is_active, true) = true)
        and (p.brand_id is null or (coalesce(b.is_active, true) = true and coalesce(b.status, 'active') <> 'inactive'))
        and not exists (
          select 1
          from brands bx
          where p.brand_id is null
            and lower(bx.name) = lower(coalesce(p.brand, ''))
            and (coalesce(bx.is_active, true) = false or coalesce(bx.status, 'active') = 'inactive')
        )
        and (pv.id is null or (${validVariantFilter("pv")}))
      group by p.id, c.id
    `,
    [id],
  );

  return result.rows[0] ? normalizeProductPayload(result.rows[0]) : null;
}

export async function categories(params = {}) {
  const values = [];
  const filters = [];

  if (params.isActive !== "all") {
    values.push(params.isActive === "false" ? false : true);
    filters.push(`is_active = $${values.length}`);
  }

  const where = filters.length ? `where ${filters.join(" and ")}` : "";
  return (
    await query(
      `select * from categories ${where} order by sort_order, name_en`,
      values,
    )
  ).rows;
}

export async function offers() {
  return (
    await query(
      "select * from offers where is_active = true order by created_at desc",
    )
  ).rows;
}

export async function homeSections(params = {}) {
  const values = [];
  const filters = ["hs.active = true"];

  if (params.sectionKey) {
    values.push(String(params.sectionKey));
    filters.push(`hs.section_key = $${values.length}`);
  }

  const result = await query(
    `
      select
        hs.id,
        hs.section_key,
        hs.title,
      COALESCE(hs.type, 'product_carousel') AS section_type,
      COALESCE(hs.config, '{}'::jsonb) AS section_config,
        hs.display_order,
        hs.starts_at,
        hs.ends_at,
        hsi.id as item_id,
        hsi.variant_id,
        hsi.display_order as item_display_order,
        p.id as product_id,
        p.category_id,
        c.slug as category_slug,
        c.name_en as category_name,
        p.brand,
        p.name_en,
        p.name_hi,
        p.size,
        p.pack,
        p.description,
        p.image_url,
        coalesce(pv.mrp, p.mrp, 0) as mrp,
        coalesce(pv.selling_price, pv.buy_price, p.buy_price, p.mrp, 0) as buy_price,
        coalesce(pv.stock_quantity, p.stock, 0) as stock,
        pv.variant_name,
        pv.sku as variant_sku,
        coalesce((
          select json_agg(
            json_build_object(
              'id', pv2.id,
              'product_id', pv2.product_id,
              'size', coalesce(nullif(pv2.variant_name, ''), pv2.size, p.size),
              'pack', coalesce(nullif(pv2.pack, ''), nullif(pv2.unit, ''), p.pack),
              'pack_quantity', coalesce(pv2.pack_quantity, 1),
              'packQuantity', coalesce(pv2.pack_quantity, 1),
              'mrp', coalesce(pv2.mrp, p.mrp, 0)::float,
              'buyPrice', coalesce(pv2.selling_price, pv2.buy_price, p.buy_price, 0)::float,
              'costPrice', coalesce(pv2.cost_price, pv2.selling_price, pv2.buy_price, p.buy_price, 0)::float,
              'cost_price', coalesce(pv2.cost_price, pv2.selling_price, pv2.buy_price, p.buy_price, 0)::float,
              'stock', coalesce(pv2.stock_quantity, p.stock, 0),
              'is_active', coalesce(pv2.is_active, coalesce(pv2.status, 'active') = 'active'),
              'isActive', coalesce(pv2.is_active, coalesce(pv2.status, 'active') = 'active')
            )
            order by pv2.is_default desc, pv2.created_at
          )
          from product_variants pv2
          where pv2.product_id = p.id
            and ${validVariantFilter("pv2")}
        ), '[]'::json) as variants
      from home_sections hs
      left join home_section_items hsi on hsi.home_section_id = hs.id
      left join products p on p.id = hsi.product_id
      left join categories c on c.id = p.category_id
      left join brands b on b.id = p.brand_id
      left join product_variants pv on pv.id = hsi.variant_id
      where ${filters.join(" and ")}
        and (hs.starts_at is null or hs.starts_at <= now())
        and (hs.ends_at is null or hs.ends_at > now())
        and (p.id is null or p.is_active = true)
        and (p.category_id is null or coalesce(c.is_active, true) = true)
        and (p.brand_id is null or (coalesce(b.is_active, true) = true and coalesce(b.status, 'active') <> 'inactive'))
        and not exists (
          select 1
          from brands bx
          where p.brand_id is null
            and lower(bx.name) = lower(coalesce(p.brand, ''))
            and (coalesce(bx.is_active, true) = false or coalesce(bx.status, 'active') = 'inactive')
        )
        and (pv.id is null or (${validVariantFilter("pv")}))
      order by hs.display_order, hs.title,
      COALESCE(hs.type, 'product_carousel') AS section_type,
      COALESCE(hs.config, '{}'::jsonb) AS section_config, hsi.display_order
    `,
    values,
  );

  const bySection = new Map();
  for (const row of result.rows) {
    if (!bySection.has(row.id)) {
      bySection.set(row.id, {
        id: row.id,
        sectionKey: row.section_key,
        section_key: row.section_key,
        title: row.title,
        type: row.section_type,
        displayOrder: row.display_order,
        position: row.display_order,
        display_order: row.display_order,
        startsAt: row.starts_at,
        starts_at: row.starts_at,
        endsAt: row.ends_at,
        ends_at: row.ends_at,
        items: [],
      });
    }
    if (!row.product_id) continue;
    const product = normalizeProductPayload({
      id: row.product_id,
      category_id: row.category_id,
      category_slug: row.category_slug,
      category_name: row.category_name,
      brand: row.brand,
      name_en: row.name_en,
      name_hi: row.name_hi,
      size: row.variant_name || row.size || "",
      pack: row.pack || "",
      description: row.description || "",
      image_url: row.image_url,
      mrp: Number(row.mrp || 0),
      buy_price: Number(row.buy_price || 0),
      stock: Number(row.stock || 0),
      variants: row.variants,
    });
    bySection.get(row.id).items.push({
      id: row.item_id,
      variantId: row.variant_id,
      variant_id: row.variant_id,
      displayOrder: row.item_display_order,
      display_order: row.item_display_order,
      product,
    });
  }

  return [...bySection.values()].filter((section) => section.items.length > 0);
}

export async function deliveryContext(params = {}) {
  const area = cleanArea(params.area || params.city || params.locality);
  const city = cleanArea(params.city);
  const pincode = String(params.pincode || "").trim();
  const latitude = finiteNumber(params.latitude ?? params.lat);
  const longitude = finiteNumber(params.longitude ?? params.lng);
  const zones = (
    await query(
      "select * from delivery_zones where active = true order by name",
    )
  ).rows;

  let matched = null;
  if (pincode) {
    matched = zones.find((zone) => {
      if (String(zone.zone_type || "pincode") !== "pincode") return false;
      const pincodes = Array.isArray(zone.pincodes_json)
        ? zone.pincodes_json
        : [];
      return pincodes.map(String).includes(pincode);
    });
  }
  if (!matched && latitude != null && longitude != null) {
    matched = zones.find((zone) => {
      if (String(zone.zone_type || "pincode") !== "radius") return false;
      const centerLat = finiteNumber(zone.center_lat);
      const centerLng = finiteNumber(zone.center_lng);
      const radiusKm = finiteNumber(zone.radius_km);
      if (centerLat == null || centerLng == null || radiusKm == null) {
        return false;
      }
      return haversineKm(latitude, longitude, centerLat, centerLng) <= radiusKm;
    });
  }

  const etaMinutes = matched
    ? Number(matched.estimated_delivery_minutes || 120)
    : 0;
  const displayArea = area || city || matched?.name || "your area";

  return {
    area: displayArea,
    zoneId: matched?.id || null,
    zoneName: matched?.name || null,
    zoneType: matched?.zone_type || null,
    etaMinutes,
    etaLabel: matched ? etaLabel(etaMinutes) : "",
    deliveryFee: matched ? Number(matched.delivery_fee || 0) : null,
    freeDeliveryMinOrder: matched
      ? Number(matched.free_delivery_min_order || 999)
      : null,
    matched: Boolean(matched),
    serviceable: Boolean(matched),
    fallbackText: matched
      ? null
      : `Not currently serviceable in ${displayArea}`,
  };
}

function finiteNumber(value) {
  if (value === null || value === undefined || value === "") return null;
  const number = Number(value);
  return Number.isFinite(number) ? number : null;
}

function haversineKm(lat1, lon1, lat2, lon2) {
  const radius = 6371;
  const dLat = toRadians(lat2 - lat1);
  const dLon = toRadians(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRadians(lat1)) *
      Math.cos(toRadians(lat2)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  return radius * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function toRadians(value) {
  return (value * Math.PI) / 180;
}

function cleanArea(value) {
  const text = String(value || "").trim();
  if (!text || text === "Area pending" || text === "Address pending") return "";
  return text.split(",")[0].trim();
}

function etaLabel(minutes) {
  if (!Number.isFinite(minutes) || minutes <= 0) return "standard time";
  if (minutes % 60 === 0) {
    const hours = minutes / 60;
    return `${hours} ${hours === 1 ? "hour" : "hours"}`;
  }
  return `${minutes} min`;
}

