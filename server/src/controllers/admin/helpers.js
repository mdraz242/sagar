import { query } from "../../config/db.js";
import { emitAdmin, emitCustomer, emitCustomers } from "../../services/realtimeService.js";
import { ApiError, notFound } from "../../utils/apiError.js";

export const hasOwn = (body, key) => Object.prototype.hasOwnProperty.call(body, key);

export const pick = (body, camelKey, snakeKey, fallback = null) => {
  if (hasOwn(body, camelKey)) return body[camelKey];
  if (snakeKey && hasOwn(body, snakeKey)) return body[snakeKey];
  return fallback;
};

export const boolValue = (value, fallback = true) =>
  value === undefined || value === null ? fallback : Boolean(value);

export const nullable = (value) => (value === undefined ? null : value);

export const slugValue = (value) =>
  String(value || "")
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");

export const importVariantSku = (row, productSku) => {
  const rawSku = String(row.sku || "").trim();
  const productPart = slugValue(productSku);
  const variantPart = slugValue(rawSku || row.variant_name || row.pack_quantity || "default");
  if (!productPart) return rawSku;
  if (!variantPart) return productPart;
  return `${productPart}-${variantPart}`;
};

export const orderFlow = [
  "placed",
  "confirmed",
  "packed",
  "shipped",
  "out_for_delivery",
  "delivered",
];

export const refundOrderStatuses = ["partially_refunded", "refunded"];

export const revenueOrderStatuses = ["delivered", ...refundOrderStatuses];

export const validOrderStatuses = [...orderFlow, "cancelled", ...refundOrderStatuses];

export const numericValue = (value, fallback = 0) => {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
};

export const csvCell = (value) => JSON.stringify(value ?? "");

export const MAX_CATALOG_IMPORT_BYTES = 2 * 1024 * 1024;

export const MAX_CATALOG_IMPORT_ROWS = 5000;

export const PRODUCT_IMPORT_HEADERS = [
  "name_en",
  "product_sku",
  "category",
  "brand",
  "description",
  "image_url",
  "variant_name",
  "sku",
  "Pack Of",
  "Unit MRP",
  "selling_price",
  "cost_price",
  "stock_quantity",
  "unit",
  "is_default",
  "is_active",
  "status",
  "Total MRP",
];

export const PRODUCT_IMPORT_REQUIRED_COLUMNS = PRODUCT_IMPORT_HEADERS.map((header) =>
  normalizeCsvHeader(header),
);

export const PRODUCT_IMPORT_REQUIRED_VALUES = [
  "name_en",
  "product_sku",
  "category",
  "brand",
  "variant_name",
  "sku",
  "pack_quantity",
  "unit_mrp",
  "selling_price",
  "cost_price",
  "stock_quantity",
  "unit",
  "total_mrp",
];

export const idsFromBody = (body) =>
  Array.isArray(body?.ids)
    ? [...new Set(body.ids.map((id) => String(id || "").trim()).filter(Boolean))]
    : [];

export function parseCsvLine(line) {
  const cells = [];
  let current = "";
  let quoted = false;
  for (let index = 0; index < line.length; index += 1) {
    const char = line[index];
    if (char === '"' && quoted && line[index + 1] === '"') {
      current += '"';
      index += 1;
      continue;
    }
    if (char === '"') {
      quoted = !quoted;
      continue;
    }
    if (char === "," && !quoted) {
      cells.push(current.trim());
      current = "";
      continue;
    }
    current += char;
  }
  cells.push(current.trim());
  return cells;
}

export function parseCsvRecords(csv) {
  const [headerLine, ...lines] = String(csv || "")
    .trim()
    .split(/\r?\n/);
  const headers = parseCsvLine(headerLine || "").map((header) =>
    normalizeCsvHeader(header),
  );
  return lines
    .filter((line) => line.trim())
    .map((line) => {
      const values = parseCsvLine(line);
      return Object.fromEntries(headers.map((header, i) => [header, values[i] || ""]));
    });
}

export function parseCsvHeaders(csv) {
  const [headerLine] = String(csv || "")
    .trim()
    .split(/\r?\n/);
  return new Set(parseCsvLine(headerLine || "").map((header) => normalizeCsvHeader(header)));
}

export function normalizeCsvHeader(header) {
  const normalized = String(header || "")
    .trim()
    .replace(/^\uFEFF/, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "");
  if (["pack_of", "packof", "pack_qty", "pack_quantity"].includes(normalized)) {
    return "pack_quantity";
  }
  if (
    [
      "unit_mrp",
      "unit_mrp_per_piece",
      "mrp_per_piece",
      "mrp_per_pc",
      "mrp",
    ].includes(normalized)
  ) {
    return "unit_mrp";
  }
  if (["total_mrp", "pack_mrp", "mrp_total"].includes(normalized)) {
    return "total_mrp";
  }
  return normalized;
}

export function parsePackQuantity(row) {
  const raw = row.pack_quantity;
  if (raw === undefined || raw === null || String(raw).trim() === "") return 1;
  const value = Number.parseInt(String(raw), 10);
  if (!Number.isFinite(value) || value < 1) {
    throw new ApiError(422, "Pack Of must be a whole number of at least 1");
  }
  return value;
}

export function csvBoolean(value, fallback = true) {
  if (value === undefined || value === null || String(value).trim() === "") {
    return fallback;
  }
  const normalized = String(value).trim().toLowerCase();
  if (["true", "yes", "1", "active"].includes(normalized)) return true;
  if (["false", "no", "0", "inactive"].includes(normalized)) return false;
  return fallback;
}

export function assertImportSizeAndRows(csv, records) {
  const bytes = Buffer.byteLength(String(csv || ""), "utf8");
  if (bytes > MAX_CATALOG_IMPORT_BYTES) {
    throw new ApiError(
      413,
      `Import file is too large. Maximum size is ${MAX_CATALOG_IMPORT_BYTES / 1024 / 1024} MB.`,
    );
  }
  if (records.length > MAX_CATALOG_IMPORT_ROWS) {
    throw new ApiError(
      422,
      `Import has ${records.length} rows. Maximum allowed rows are ${MAX_CATALOG_IMPORT_ROWS}.`,
    );
  }
}

export function positiveCsvNumber(value) {
  const number = Number(value);
  return Number.isFinite(number) && number > 0 ? number : null;
}

export function buildProductImportReport(records) {
  const groups = new Map();
  const report = {
    totalRows: records.length,
    totalProducts: 0,
    pricingIssues: [],
    defaultVariantIssues: [],
    warnings: [],
  };

  for (const [index, row] of records.entries()) {
    const rowNumber = index + 2;
    const productSku = String(row.product_sku || "").trim();
    const productName = String(row.name_en || "").trim();
    if (!productSku) continue;
    if (!groups.has(productSku.toLowerCase())) {
      groups.set(productSku.toLowerCase(), {
        productSku,
        productName,
        rows: [],
      });
    }
    groups.get(productSku.toLowerCase()).rows.push({ rowNumber, row });

    for (const field of ["unit_mrp", "selling_price", "total_mrp"]) {
      if (positiveCsvNumber(row[field]) === null) {
        report.pricingIssues.push({
          rowNumber,
          productSku,
          productName,
          variantSku: importVariantSku(row, productSku),
          field,
          value: row[field] ?? "",
          reason: `${field} must be a number greater than 0`,
        });
      }
    }
  }

  report.totalProducts = groups.size;
  for (const group of groups.values()) {
    const defaultRows = group.rows.filter(({ row }) =>
      csvBoolean(row.is_default, false),
    );
    if (defaultRows.length !== 1) {
      report.defaultVariantIssues.push({
        productSku: group.productSku,
        productName: group.productName,
        defaultCount: defaultRows.length,
        rowNumbers: defaultRows.map(({ rowNumber }) => rowNumber),
        reason: "Exactly one default variant is expected per product SKU.",
      });
    }
    if (group.rows.length === 1) {
      report.warnings.push({
        productSku: group.productSku,
        productName: group.productName,
        type: "single_variant",
        reason:
          "Only one variant was imported for this product. This is allowed, but check it if this category normally has multiple packs.",
      });
    }
  }
  return report;
}

export function validateCatalogImageUrl(imageUrl) {
  const value = String(imageUrl || "").trim();
  if (!value) return null;
  if (!/^https?:\/\//i.test(value) && !value.startsWith("/uploads/")) {
    throw new ApiError(
      422,
      "Image URL must be an http(s) URL or an uploaded /uploads path",
    );
  }
  if (/^https?:\/\//i.test(value)) {
    const parsed = new URL(value);
    const host = parsed.hostname.toLowerCase();
    if (
      host === "localhost" ||
      host === "127.0.0.1" ||
      host === "::1" ||
      host.startsWith("10.") ||
      host.startsWith("192.168.") ||
      /^172\.(1[6-9]|2\d|3[0-1])\./.test(host)
    ) {
      throw new ApiError(
        422,
        "Image URL cannot point to a local or private network address",
      );
    }
  }
  return value;
}

export function importFailureReason(error) {
  if (error?.code === "23505") return "A record with the same SKU or unique value already exists";
  if (error?.code === "23503") return "Selected category, brand, or linked record does not exist";
  if (error?.code === "23502") return "Please fill all required fields";
  if (error?.code === "42P10") return "Import conflict index is missing or mismatched for this row";
  return error?.details?.message || error?.detail || error?.message || "Row import failed";
}

export async function resolveAdminId(adminId, client = null) {
  if (!adminId) return null;
  const executor = client || { query };
  const result = await executor.query("select id from admins where id=$1", [
    adminId,
  ]);
  return result.rows[0]?.id || null;
}

export async function logAdminActivity(
  req,
  action,
  entityType,
  entityId,
  beforeJson,
  afterJson,
) {
  if (!req.admin?.id) return;
  const adminId = await resolveAdminId(req.admin.id);
  if (!adminId) return;
  await query(
    `insert into admin_activity_log(admin_id,action,entity_type,entity_id,before_json,after_json)
     values($1,$2,$3,$4,$5,$6)`,
    [
      adminId,
      action,
      entityType,
      entityId || null,
      beforeJson || null,
      afterJson || null,
    ],
  );
}

export async function logNotification({
  target = "user",
  title,
  body,
  segment = {},
  sentByAdminId = null,
  deliveryStatus = "queued",
}) {
  const adminId = await resolveAdminId(sentByAdminId);
  await query(
    `insert into notifications_log(target,title,body,segment_json,sent_by_admin_id,delivery_status)
     values($1,$2,$3,$4,$5,$6)`,
    [target, title, body, segment, adminId, deliveryStatus],
  );
}

export function assertLegalOrderTransition(current, next) {
  if (!validOrderStatuses.includes(next))
    throw new ApiError(422, "Invalid order status");
  if (current === next) return;
  if (
    current === "cancelled" ||
    current === "delivered" ||
    refundOrderStatuses.includes(current)
  ) {
    throw new ApiError(422, `Cannot move an order from ${current} to ${next}`);
  }
  if (refundOrderStatuses.includes(next)) {
    throw new ApiError(
      422,
      "Refunded statuses can only be set by the refund workflow",
    );
  }
  if (next === "cancelled") return;
  const fromIndex = orderFlow.indexOf(current);
  const toIndex = orderFlow.indexOf(next);
  if (fromIndex === -1 || toIndex === -1 || toIndex !== fromIndex + 1) {
    throw new ApiError(
      422,
      `Next valid status after ${current} is ${orderFlow[fromIndex + 1] || "cancelled"}`,
    );
  }
}

export function isRefundEligibleStatus(status) {
  return ["delivered", "partially_refunded", "cancelled"].includes(
    String(status || "").toLowerCase(),
  );
}

export function paymentCaptured(order) {
  const mode = String(
    order.payment_mode || order.paymentMode || "cod",
  ).toLowerCase();
  const paymentStatus = String(
    order.payment_status || order.paymentStatus || "",
  ).toLowerCase();
  return (
    mode !== "cod" ||
    ["paid", "captured", "success", "completed"].includes(paymentStatus)
  );
}

export async function orderRefundSummary(orderId, client = null) {
  const executor = client || { query };
  const result = await executor.query(
    `
      select coalesce(sum(amount), 0)::numeric as refunded_total
      from refunds
      where order_id=$1 and status in ('pending','processed')
    `,
    [orderId],
  );
  return { refundedTotal: Number(result.rows[0]?.refunded_total || 0) };
}

export async function refundSettings(client = null) {
  const executor = client || { query };
  const result = await executor.query(
    "select value_json from app_settings where key='refunds'",
  );
  const value = result.rows[0]?.value_json || {};
  const enabled =
    Array.isArray(value.enabledDestinations) && value.enabledDestinations.length
      ? value.enabledDestinations
      : ["wallet", "store_credit", "original_payment", "upi"];
  return {
    enabledDestinations: enabled,
    defaultDestination: value.defaultDestination || "wallet",
  };
}

export function dashboardRangeFilters(queryParams = {}) {
  const range = String(queryParams.range || "month").toLowerCase();
  const timeZone = String(
    queryParams.timeZone || process.env.STORE_TIMEZONE || "Asia/Kolkata",
  );
  const params = [timeZone];
  if (range === "today") {
    return {
      range,
      params,
      orderFilter:
        "coalesce(delivered_at, created_at) >= (timezone($1, now())::date at time zone $1)",
      refundFilter: "created_at >= (timezone($1, now())::date at time zone $1)",
    };
  }
  if (range === "week") {
    return {
      range,
      params,
      orderFilter:
        "coalesce(delivered_at, created_at) >= ((timezone($1, now())::date - interval '6 days') at time zone $1)",
      refundFilter:
        "created_at >= ((timezone($1, now())::date - interval '6 days') at time zone $1)",
    };
  }
  if (range === "custom" && queryParams.startDate && queryParams.endDate) {
    params.push(queryParams.startDate, queryParams.endDate);
    return {
      range,
      params,
      orderFilter:
        "coalesce(delivered_at, created_at) >= ($2::date at time zone $1) and coalesce(delivered_at, created_at) < (($3::date + interval '1 day') at time zone $1)",
      refundFilter:
        "created_at >= ($2::date at time zone $1) and created_at < (($3::date + interval '1 day') at time zone $1)",
    };
  }
  return {
    range: "month",
    params,
    orderFilter:
      "coalesce(delivered_at, created_at) >= (date_trunc('month', timezone($1, now())) at time zone $1)",
    refundFilter:
      "created_at >= (date_trunc('month', timezone($1, now())) at time zone $1)",
  };
}

export async function ensureWalletAccount(customerId, client = null) {
  const executor = client || { query };
  const existing = await executor.query(
    "select * from wallet_accounts where customer_id=$1",
    [customerId],
  );
  if (existing.rows[0]) return existing.rows[0];
  const created = await executor.query(
    "insert into wallet_accounts(customer_id,balance) values($1,0) returning *",
    [customerId],
  );
  return created.rows[0];
}

export async function writeWalletTransaction(
  { customerId, type, amount, reason, referenceType, referenceId, adminId },
  client = null,
) {
  const executor = client || { query };
  const wallet = await ensureWalletAccount(customerId, client);
  const result = await executor.query(
    `insert into wallet_transactions(wallet_account_id,type,amount,reason,reference_type,reference_id,created_by)
     values($1,$2,$3,$4,$5,$6,$7) returning *`,
    [
      wallet.id,
      type,
      amount,
      reason,
      referenceType || null,
      referenceId || null,
      null,
    ],
  );
  emitCustomer(customerId, "wallet.transaction_created", {
    transaction: result.rows[0],
  });
  return result.rows[0];
}

export async function writePointsLedger(
  { customerId, points, type, reason, referenceType, referenceId, expiresAt },
  client = null,
) {
  const executor = client || { query };
  const result = await executor.query(
    `insert into loyalty_ledger(customer_id,points,type,reason,reference_type,reference_id,expires_at)
     values($1,$2,$3,$4,$5,$6,$7) returning *`,
    [
      customerId,
      points,
      type,
      reason,
      referenceType || null,
      referenceId || null,
      expiresAt || null,
    ],
  );
  return result.rows[0];
}

export const variantPayload = (body) => ({
  variantName: body.variantName ?? body.variant_name,
  sku: body.sku,
  mrp: Number(body.mrp ?? 0),
  sellingPrice: Number(body.sellingPrice ?? body.selling_price ?? 0),
  costPrice: Number(body.costPrice ?? body.cost_price ?? 0),
  packQuantity:
    Number.parseInt(body.packQuantity ?? body.pack_quantity ?? 1, 10) || 1,
  stockQuantity:
    Number.parseInt(body.stockQuantity ?? body.stock_quantity ?? 0, 10) || 0,
  unit: body.unit || "pcs",
  taxPercent: Number(body.taxPercent ?? body.tax_percent ?? 0) || 0,
  discountPercent:
    Number(body.discountPercent ?? body.discount_percent ?? 0) || 0,
  lowStockAlert:
    Number.parseInt(body.lowStockAlert ?? body.low_stock_alert ?? 0, 10) || 0,
  barcode: nullable(body.barcode ?? body.barcode_ean_upc ?? null),
  isDefault: boolValue(body.isDefault ?? body.is_default, false),
  isActive: boolValue(body.isActive ?? body.is_active, body.status !== "inactive"),
  status:
    body.status ||
    ((body.isActive ?? body.is_active) === false ? "inactive" : "active"),
});

export function productPayload(body, current = {}) {
  const trendingAreas = pick(
    body,
    "trendingAreas",
    "trending_areas",
    current.trending_areas ?? [],
  );
  return {
    sku: nullable(pick(body, "sku", null, current.sku ?? null)),
    categoryId: pick(
      body,
      "categoryId",
      "category_id",
      current.category_id ?? null,
    ),
    brand: pick(body, "brand", null, current.brand ?? null),
    nameEn: pick(body, "nameEn", "name_en", current.name_en),
    nameHi: pick(body, "nameHi", "name_hi", current.name_hi ?? null),
    size: pick(body, "size", null, current.size ?? null),
    pack: pick(body, "pack", null, current.pack ?? null),
    imageUrl: pick(body, "imageUrl", "image_url", current.image_url ?? null),
    mrp: Number(pick(body, "mrp", null, current.mrp ?? 0)),
    buyPrice: Number(
      pick(body, "buyPrice", "buy_price", current.buy_price ?? 0),
    ),
    stock:
      Number.parseInt(pick(body, "stock", null, current.stock ?? 0), 10) || 0,
    regional: boolValue(pick(body, "regional", null, current.regional), false),
    highMargin: boolValue(
      pick(body, "highMargin", "high_margin", current.high_margin),
      false,
    ),
    trendingAreas: Array.isArray(trendingAreas) ? trendingAreas : [],
    isActive: boolValue(
      pick(body, "isActive", "is_active", current.is_active),
      true,
    ),
    description: pick(body, "description", null, current.description ?? null),
    imagesJson: pick(
      body,
      "imagesJson",
      "images_json",
      current.images_json ?? [],
    ),
    brandId: pick(body, "brandId", "brand_id", current.brand_id ?? null),
    hsnCode: nullable(pick(body, "hsnCode", "hsn_code", current.hsn_code ?? null)),
    metaTitle: nullable(
      pick(body, "metaTitle", "meta_title", current.meta_title ?? null),
    ),
    metaDescription: nullable(
      pick(
        body,
        "metaDescription",
        "meta_description",
        current.meta_description ?? null,
      ),
    ),
    ingredients: nullable(
      pick(body, "ingredients", null, current.ingredients ?? null),
    ),
    storageInstructions: nullable(
      pick(
        body,
        "storageInstructions",
        "storage_instructions",
        current.storage_instructions ?? null,
      ),
    ),
    shelfLife: nullable(
      pick(body, "shelfLife", "shelf_life", current.shelf_life ?? null),
    ),
    countryOfOrigin: pick(
      body,
      "countryOfOrigin",
      "country_of_origin",
      current.country_of_origin ?? "India",
    ),
    highlights: (() => {
      const raw = pick(
        body,
        "highlights",
        null,
        current.highlights ?? [],
      );
      if (Array.isArray(raw)) return raw.map((v) => String(v)).filter(Boolean);
      if (typeof raw === "string") {
        return raw
          .split(",")
          .map((v) => v.trim())
          .filter(Boolean);
      }
      return [];
    })(),
  };
}

export function categoryPayload(body) {
  return {
    slug: body.slug,
    nameEn: body.nameEn ?? body.name_en ?? body.name,
    nameHi: nullable(body.nameHi ?? body.name_hi),
    imageUrl: nullable(body.imageUrl ?? body.image_url),
    tint: nullable(body.tint),
    sortOrder: Number.parseInt(body.sortOrder ?? body.sort_order ?? 0, 10) || 0,
    isActive: boolValue(body.isActive ?? body.is_active),
    parentId: nullable(body.parentId ?? body.parent_id),
    description: nullable(body.description),
  };
}

export function brandPayload(body) {
  const name = body.name;
  return {
    name,
    logoUrl: nullable(body.logoUrl ?? body.logo_url),
    isActive: boolValue(body.isActive ?? body.is_active),
    status:
      body.status ||
      ((body.isActive ?? body.is_active) === false ? "inactive" : "active"),
    slug: nullable(body.slug) || slugValue(name),
    description: nullable(body.description),
  };
}

export async function productRealtimePayload(productId, fallback = {}) {
  const result = await query(
    "select id, category_id, name_en, sku, stock, is_active, updated_at from products where id=$1",
    [productId],
  );
  const product = result.rows[0] || fallback;
  return {
    productId: String(product.id ?? productId),
    categoryId: product.category_id ? String(product.category_id) : null,
    product,
  };
}

// Catalog-change events (products, categories, brands) must reach BOTH the
// customer app (/customer namespace) and the admin panel's own UI (/admin
// namespace) -- these are two isolated Socket.IO namespaces. Previously these
// events only went to emitCustomers, so the admin panel never saw its own
// changes reflected live and required a manual reload.
export function broadcastCatalogChange(event, payload = {}) {
  emitCustomers(event, payload);
  emitAdmin(event, payload);
}

export async function emitProductRealtime(event, productId, extra = {}) {
  try {
    const payload = await productRealtimePayload(
      productId,
      extra.product || {},
    );
    broadcastCatalogChange(event, { ...payload, ...extra });
  } catch (error) {
    console.error(`Failed to emit ${event}`, error);
  }
}

export async function validateProductPayloadForSave(p, productId = null) {
  if (!String(p.nameEn || "").trim()) {
    throw new ApiError(422, "Product name is required", {
      fields: { nameEn: "Product name is required" },
    });
  }
  if (!p.categoryId) {
    throw new ApiError(422, "Please select a category before saving", {
      fields: { categoryId: "Please select a category before saving" },
    });
  }
  const category = await query(
    "select id from categories where id::text = $1 and is_active = true",
    [p.categoryId],
  );
  if (!category.rows[0]) {
    throw new ApiError(422, "Selected category does not exist or is inactive", {
      fields: { categoryId: "Selected category does not exist or is inactive" },
    });
  }
  if (p.brandId) {
    const brand = await query("select id from brands where id::text = $1", [
      p.brandId,
    ]);
    if (!brand.rows[0]) {
      throw new ApiError(422, "Selected brand does not exist", {
        fields: { brandId: "Selected brand does not exist" },
      });
    }
  }
  if (p.sku) {
    const sku = await query(
      "select id from products where sku=$1 and ($2::uuid is null or id<>$2::uuid)",
      [p.sku, productId],
    );
    if (sku.rows[0]) {
      throw new ApiError(409, "SKU already exists", {
        fields: {
          sku: "SKU already exists. Use a unique SKU for this product.",
        },
      });
    }
  }
}

export async function validateVariantPayloadForSave(v, productId, variantId = null) {
  if (!String(v.variantName || "").trim()) {
    throw new ApiError(422, "Variant size label is required", {
      fields: { variantName: "Variant size label is required" },
    });
  }
  if (!String(v.sku || "").trim()) {
    throw new ApiError(422, "Variant SKU is required", {
      fields: { sku: "Variant SKU is required" },
    });
  }
  if (
    Number(v.mrp) < 0 ||
    Number(v.sellingPrice) < 0 ||
    Number(v.costPrice) < 0 ||
    Number(v.stockQuantity) < 0
  ) {
    throw new ApiError(422, "Variant price and stock cannot be negative", {
      fields: { variant: "Variant price and stock cannot be negative" },
    });
  }
  if (Number(v.packQuantity) < 1) {
    throw new ApiError(422, "Pack quantity must be at least 1", {
      fields: { packQuantity: "Pack quantity must be at least 1" },
    });
  }
  if (Number(v.mrp) > 0 && Number(v.sellingPrice) > Number(v.mrp)) {
    throw new ApiError(422, "Selling price cannot be greater than MRP", {
      fields: { sellingPrice: "Selling price cannot be greater than MRP" },
    });
  }
  const sku = await query(
    `select id, product_id from product_variants
     where sku=$1 and ($2::uuid is null or id<>$2::uuid)`,
    [v.sku, variantId],
  );
  if (sku.rows[0] && String(sku.rows[0].product_id) !== String(productId)) {
    throw new ApiError(409, "SKU already exists", {
      fields: { sku: "SKU already exists. Use a unique SKU for this variant." },
    });
  }
}

export function offerPayload(body) {
  return {
    title: body.title,
    subtitle: nullable(body.subtitle),
    imageUrl: nullable(body.imageUrl ?? body.image_url),
    mediaType: body.mediaType ?? body.media_type ?? "image",
    productId: nullable(body.productId ?? body.product_id),
    discountPercent:
      Number.parseInt(body.discountPercent ?? body.discount_percent ?? 0, 10) ||
      null,
    linkUrl: nullable(body.linkUrl ?? body.link_url),
    isActive: boolValue(body.isActive ?? body.is_active),
    startsAt: nullable(body.startsAt ?? body.starts_at),
    endsAt: nullable(body.endsAt ?? body.ends_at),
    couponCode: nullable(body.couponCode ?? body.coupon_code),
    appliesTo: body.appliesTo ?? body.applies_to ?? "all",
    categoryId: nullable(body.categoryId ?? body.category_id),
    maxDiscount: nullable(body.maxDiscount ?? body.max_discount),
    minOrderAmount: nullable(body.minOrderAmount ?? body.min_order_amount),
  };
}

export async function catalogVisibilityData(productIds = []) {
  const idFilter = productIds.length ? "where p.id = any($1::uuid[])" : "";
  const params = productIds.length ? [productIds] : [];
  const summary = await query(
    `
      with catalog as (
        select
          p.id,
          p.name_en,
          p.sku,
          p.category_id,
          p.brand_id,
          p.brand,
          coalesce(p.is_active, true) as product_active,
          c.id as matched_category_id,
          coalesce(c.is_active, true) as category_active,
          b.id as matched_brand_id,
          coalesce(b.is_active, true) as brand_active,
          coalesce(b.status, 'active') as brand_status,
          exists (
            select 1
            from product_variants pv
            where pv.product_id = p.id
              and coalesce(pv.status, 'active') = 'active'
              and coalesce(pv.is_active, true) = true
          ) as has_active_variant,
          exists (
            select 1
            from brands bx
            where p.brand_id is null
              and lower(bx.name) = lower(coalesce(p.brand, ''))
              and (
                coalesce(bx.is_active, true) = false
                or coalesce(bx.status, 'active') = 'inactive'
              )
          ) as inactive_brand_name_match
        from products p
        left join categories c on c.id = p.category_id
        left join brands b on b.id = p.brand_id
        ${idFilter}
      ),
      visibility as (
        select *,
          (
            product_active = true
            and (category_id is null or (matched_category_id is not null and category_active = true))
            and (
              brand_id is null
              or (
                matched_brand_id is not null
                and brand_active = true
                and brand_status <> 'inactive'
              )
            )
            and inactive_brand_name_match = false
            and has_active_variant = true
          ) as customer_visible,
          case
            when product_active = false then 'inactive product'
            when category_id is not null and matched_category_id is null then 'missing category'
            when category_id is not null and category_active = false then 'inactive category'
            when brand_id is not null and matched_brand_id is null then 'missing brand'
            when brand_id is not null and (brand_active = false or brand_status = 'inactive') then 'inactive brand'
            when inactive_brand_name_match = true then 'inactive brand name match'
            when has_active_variant = false then 'no active variant'
            else 'visible'
          end as visibility_reason
        from catalog
      )
      select
        count(*)::int as total_products,
        count(*) filter (where customer_visible)::int as visible_products,
        count(*) filter (where not customer_visible)::int as hidden_products,
        count(*) filter (where visibility_reason = 'inactive product')::int as inactive_products,
        count(*) filter (where visibility_reason in ('missing category', 'inactive category'))::int as category_issues,
        count(*) filter (where visibility_reason in ('missing brand', 'inactive brand', 'inactive brand name match'))::int as brand_issues,
        count(*) filter (where visibility_reason = 'no active variant')::int as variant_issues
      from visibility
    `,
    params,
  );
  const samples = await query(
    `
      with catalog as (
        select
          p.id,
          p.name_en,
          p.sku,
          p.category_id,
          p.brand_id,
          p.brand,
          coalesce(p.is_active, true) as product_active,
          c.id as matched_category_id,
          coalesce(c.is_active, true) as category_active,
          b.id as matched_brand_id,
          coalesce(b.is_active, true) as brand_active,
          coalesce(b.status, 'active') as brand_status,
          exists (
            select 1
            from product_variants pv
            where pv.product_id = p.id
              and coalesce(pv.status, 'active') = 'active'
              and coalesce(pv.is_active, true) = true
          ) as has_active_variant,
          exists (
            select 1
            from brands bx
            where p.brand_id is null
              and lower(bx.name) = lower(coalesce(p.brand, ''))
              and (
                coalesce(bx.is_active, true) = false
                or coalesce(bx.status, 'active') = 'inactive'
              )
          ) as inactive_brand_name_match
        from products p
        left join categories c on c.id = p.category_id
        left join brands b on b.id = p.brand_id
        ${idFilter}
      )
      select
        id,
        name_en,
        sku,
        case
          when product_active = false then 'inactive product'
          when category_id is not null and matched_category_id is null then 'missing category'
          when category_id is not null and category_active = false then 'inactive category'
          when brand_id is not null and matched_brand_id is null then 'missing brand'
          when brand_id is not null and (brand_active = false or brand_status = 'inactive') then 'inactive brand'
          when inactive_brand_name_match = true then 'inactive brand name match'
          when has_active_variant = false then 'no active variant'
          else 'visible'
        end as reason
      from catalog
      where not (
        product_active = true
        and (category_id is null or (matched_category_id is not null and category_active = true))
        and (
          brand_id is null
          or (
            matched_brand_id is not null
            and brand_active = true
            and brand_status <> 'inactive'
          )
        )
        and inactive_brand_name_match = false
        and has_active_variant = true
      )
      order by name_en
      limit 20
    `,
    params,
  );
  return {
    ...summary.rows[0],
    samples: samples.rows,
    checkedProductIds: productIds.length,
  };
}

export async function assertImportedCatalogVisible(productIds) {
  if (!productIds.length) return;
  const visibility = await catalogVisibilityData(productIds);
  if (Number(visibility.hidden_products || 0) > 0) {
    throw new ApiError(
      422,
      `${visibility.hidden_products} imported product(s) are not visible to customers. Check category, brand, active status, and variants.`,
      visibility.samples,
    );
  }
}

export async function ensureSingleDefaultVariant(productId) {
  const variants = await query(
    `select id
     from product_variants
     where product_id=$1
       and coalesce(status, 'active') = 'active'
       and coalesce(is_active, true) = true
     order by is_default desc, coalesce(pack_quantity, 1), coalesce(selling_price, buy_price, mrp, 0), created_at`,
    [productId],
  );
  if (!variants.rows.length) return null;
  const defaultId = variants.rows[0].id;
  await query(
    `update product_variants
     set is_default = (id = $2), updated_at = now()
     where product_id = $1`,
    [productId, defaultId],
  );
  return defaultId;
}

export async function catalogPricingHealthData() {
  const rows = (
    await query(
      `select
         p.id as product_id,
         p.sku as product_sku,
         p.name_en as product_name,
         pv.id as variant_id,
         pv.sku as variant_sku,
         pv.variant_name,
         pv.mrp,
         pv.selling_price,
         pv.pack_quantity,
         pv.is_default,
         pv.status,
         pv.is_active
       from products p
       left join product_variants pv
         on pv.product_id = p.id
        and coalesce(pv.status, 'active') = 'active'
        and coalesce(pv.is_active, true) = true
       where p.is_active = true
       order by p.name_en, coalesce(pv.pack_quantity, 1), pv.created_at`,
    )
  ).rows;

  const products = new Map();
  for (const row of rows) {
    if (!products.has(row.product_id)) {
      products.set(row.product_id, {
        productId: row.product_id,
        productSku: row.product_sku,
        productName: row.product_name,
        variants: [],
      });
    }
    if (row.variant_id) products.get(row.product_id).variants.push(row);
  }

  const issues = [];
  for (const product of products.values()) {
    if (!product.variants.length) {
      issues.push({
        productId: product.productId,
        productSku: product.productSku,
        productName: product.productName,
        reason: "No active variants found",
      });
      continue;
    }

    const defaultCount = product.variants.filter((variant) =>
      Boolean(variant.is_default),
    ).length;
    if (defaultCount !== 1) {
      issues.push({
        productId: product.productId,
        productSku: product.productSku,
        productName: product.productName,
        reason: `Expected exactly one default variant, found ${defaultCount}`,
      });
    }

    for (const variant of product.variants) {
      const invalidFields = [];
      if (positiveCsvNumber(variant.mrp) === null) invalidFields.push("mrp");
      if (positiveCsvNumber(variant.selling_price) === null) {
        invalidFields.push("selling_price");
      }
      if (positiveCsvNumber(variant.pack_quantity) === null) {
        invalidFields.push("pack_quantity");
      }
      if (invalidFields.length) {
        issues.push({
          productId: product.productId,
          productSku: product.productSku,
          productName: product.productName,
          variantId: variant.variant_id,
          variantSku: variant.variant_sku,
          variantName: variant.variant_name,
          invalidFields,
          reason: `Invalid variant field(s): ${invalidFields.join(", ")}`,
        });
      }
    }
  }

  return {
    summary: {
      productsChecked: products.size,
      issueCount: issues.length,
      generatedAt: new Date().toISOString(),
    },
    issues,
  };
}

export const tableMap = {
  loyaltyTiers: {
    table: "loyalty_tiers",
    validate: (body) => {
      if (!String(body.name || "").trim())
        throw new ApiError(422, "name is required");
    },
    payload: (body) => [
      body.name,
      Number.parseInt(body.minPoints ?? body.min_points ?? 0, 10) || 0,
      JSON.stringify(body.benefitsJson ?? body.benefits_json ?? {}),
    ],
    insert:
      "insert into loyalty_tiers(name,min_points,benefits_json) values($1,$2,$3) returning *",
    update:
      "update loyalty_tiers set name=$2,min_points=$3,benefits_json=$4,updated_at=now() where id=$1 returning *",
  },
  loyaltyRules: {
    table: "loyalty_rules",
    validate: (body) => {
      if (!String(body.action || "").trim())
        throw new ApiError(422, "action is required");
    },
    payload: (body) => [
      body.action,
      Number.parseInt(body.pointsAwarded ?? body.points_awarded ?? 0, 10) || 0,
      boolValue(body.active, true),
    ],
    insert:
      "insert into loyalty_rules(action,points_awarded,active) values($1,$2,$3) returning *",
    update:
      "update loyalty_rules set action=$2,points_awarded=$3,active=$4,updated_at=now() where id=$1 returning *",
  },
  loyaltyRewards: {
    table: "redeemable_rewards",
    validate: (body) => {
      if (!String(body.title || "").trim())
        throw new ApiError(422, "title is required");
      const rewardType = body.rewardType ?? body.reward_type ?? "coupon";
      if (!["coupon", "free_delivery", "product"].includes(rewardType))
        throw new ApiError(422, "invalid reward_type");
    },
    payload: (body) => [
      body.title,
      Number.parseInt(body.pointsCost ?? body.points_cost ?? 0, 10) || 0,
      body.rewardType ?? body.reward_type ?? "coupon",
      JSON.stringify(body.rewardValueJson ?? body.reward_value_json ?? {}),
      boolValue(body.active, true),
      Number.parseInt(body.stockLimit ?? body.stock_limit ?? 0, 10) || null,
    ],
    insert:
      "insert into redeemable_rewards(title,points_cost,reward_type,reward_value_json,active,stock_limit) values($1,$2,$3,$4,$5,$6) returning *",
    update:
      "update redeemable_rewards set title=$2,points_cost=$3,reward_type=$4,reward_value_json=$5,active=$6,stock_limit=$7,updated_at=now() where id=$1 returning *",
  },
  deliveryZones: {
    table: "delivery_zones",
    validate: (body) => {
      if (!String(body.name || "").trim())
        throw new ApiError(422, "name is required");
      const zoneType = body.zoneType ?? body.zone_type ?? "pincode";
      if (!["pincode", "radius"].includes(zoneType)) {
        throw new ApiError(422, "zone_type must be pincode or radius");
      }
      if (zoneType === "radius") {
        if (
          body.centerLat === undefined &&
          body.center_lat === undefined
        ) {
          throw new ApiError(422, "center latitude is required");
        }
        if (
          body.centerLng === undefined &&
          body.center_lng === undefined
        ) {
          throw new ApiError(422, "center longitude is required");
        }
        if (body.radiusKm === undefined && body.radius_km === undefined) {
          throw new ApiError(422, "radius is required");
        }
      }
    },
    payload: (body) => [
      body.name,
      body.zoneType ?? body.zone_type ?? "pincode",
      JSON.stringify(
        body.pincodesJson ??
          body.pincodes_json ??
          String(body.pincodes || "")
            .split(",")
            .map((p) => p.trim())
            .filter(Boolean),
      ),
      Number.parseInt(
        body.estimatedDeliveryMinutes ?? body.estimated_delivery_minutes ?? 120,
        10,
      ),
      numericValue(body.deliveryFee ?? body.delivery_fee, 0),
      numericValue(
        body.freeDeliveryMinOrder ?? body.free_delivery_min_order,
        999,
      ),
      boolValue(body.active, true),
      numericValue(body.centerLat ?? body.center_lat, null),
      numericValue(body.centerLng ?? body.center_lng, null),
      numericValue(body.radiusKm ?? body.radius_km, null),
    ],
    insert:
      "insert into delivery_zones(name,zone_type,pincodes_json,estimated_delivery_minutes,delivery_fee,free_delivery_min_order,active,center_lat,center_lng,radius_km) values($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) returning *",
    update:
      "update delivery_zones set name=$2,zone_type=$3,pincodes_json=$4,estimated_delivery_minutes=$5,delivery_fee=$6,free_delivery_min_order=$7,active=$8,center_lat=$9,center_lng=$10,radius_km=$11,updated_at=now() where id=$1 returning *",
  },
};

export async function listTable(res, table, order = "created_at desc") {
  res.json({
    success: true,
    data: (await query(`select * from ${table} order by ${order}`)).rows,
  });
}

export async function createMapped(req, res, next, key, entityType) {
  try {
    const mapped = tableMap[key];
    mapped.validate?.(req.body);
    const result = await query(mapped.insert, mapped.payload(req.body));
    await logAdminActivity(
      req,
      "create",
      entityType,
      result.rows[0].id,
      null,
      result.rows[0],
    );
    emitMappedChange(entityType, "updated", result.rows[0]);
    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (e) {
    next(e);
  }
}

export async function updateMapped(req, res, next, key, entityType) {
  try {
    const mapped = tableMap[key];
    mapped.validate?.(req.body);
    const before = await query(`select * from ${mapped.table} where id=$1`, [
      req.params.id,
    ]);
    const result = await query(mapped.update, [
      req.params.id,
      ...mapped.payload(req.body),
    ]);
    if (!result.rows[0]) throw notFound(entityType);
    await logAdminActivity(
      req,
      "update",
      entityType,
      req.params.id,
      before.rows[0],
      result.rows[0],
    );
    emitMappedChange(entityType, "updated", result.rows[0]);
    res.json({ success: true, data: result.rows[0] });
  } catch (e) {
    next(e);
  }
}

export async function deleteMapped(req, res, next, key, entityType) {
  try {
    const mapped = tableMap[key];
    const before = await query(`select * from ${mapped.table} where id=$1`, [
      req.params.id,
    ]);
    const result = await query(
      `delete from ${mapped.table} where id=$1 returning id`,
      [req.params.id],
    );
    if (!result.rows[0]) throw notFound(entityType);
    await logAdminActivity(
      req,
      "delete",
      entityType,
      req.params.id,
      before.rows[0],
      null,
    );
    emitMappedChange(
      entityType,
      "deleted",
      before.rows[0] || { id: req.params.id },
    );
    res.json({ success: true, data: { id: req.params.id, deleted: true } });
  } catch (e) {
    next(e);
  }
}

export function emitMappedChange(entityType, action, row) {
  if (entityType === "delivery_zone") {
    emitCustomers(`delivery_zone.${action}`, {
      zoneId: row.id,
      zoneName: row.name,
    });
  }
}
