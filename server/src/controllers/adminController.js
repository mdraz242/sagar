import fs from "fs";
import path from "path";
import multer from "multer";
import bcrypt from "bcryptjs";
import { pool, query } from "../config/db.js";
import {
  notifyOrderStatus,
  notifyUser,
  orderStatusNotification,
  sendAdminNotification,
} from "../services/notificationService.js";
import {
  emitAdmin,
  emitCustomer,
  emitCustomers,
} from "../services/realtimeService.js";
import { ApiError, notFound } from "../utils/apiError.js";

const uploadRoot = path.resolve("uploads");
if (!fs.existsSync(uploadRoot)) fs.mkdirSync(uploadRoot, { recursive: true });

export const uploadMiddleware = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    if (!file.mimetype.startsWith("image/"))
      return cb(new ApiError(422, "Only image uploads are allowed"));
    cb(null, true);
  },
}).single("file");

const hasOwn = (body, key) => Object.prototype.hasOwnProperty.call(body, key);
const pick = (body, camelKey, snakeKey, fallback = null) => {
  if (hasOwn(body, camelKey)) return body[camelKey];
  if (snakeKey && hasOwn(body, snakeKey)) return body[snakeKey];
  return fallback;
};
const boolValue = (value, fallback = true) =>
  value === undefined || value === null ? fallback : Boolean(value);
const nullable = (value) => (value === undefined ? null : value);
const slugValue = (value) =>
  String(value || "")
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
const importVariantSku = (row, productSku) => {
  const rawSku = String(row.sku || "").trim();
  const productPart = slugValue(productSku);
  const variantPart = slugValue(rawSku || row.variant_name || row.pack_quantity || "default");
  if (!productPart) return rawSku;
  if (!variantPart) return productPart;
  return `${productPart}-${variantPart}`;
};

const orderFlow = [
  "placed",
  "confirmed",
  "packed",
  "shipped",
  "out_for_delivery",
  "delivered",
];
const refundOrderStatuses = ["partially_refunded", "refunded"];
const revenueOrderStatuses = ["delivered", ...refundOrderStatuses];
const validOrderStatuses = [...orderFlow, "cancelled", ...refundOrderStatuses];
const numericValue = (value, fallback = 0) => {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
};
const csvCell = (value) => JSON.stringify(value ?? "");
const MAX_CATALOG_IMPORT_BYTES = 2 * 1024 * 1024;
const MAX_CATALOG_IMPORT_ROWS = 5000;
const PRODUCT_IMPORT_HEADERS = [
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
const PRODUCT_IMPORT_REQUIRED_COLUMNS = PRODUCT_IMPORT_HEADERS.map((header) =>
  normalizeCsvHeader(header),
);
const PRODUCT_IMPORT_REQUIRED_VALUES = [
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
const idsFromBody = (body) =>
  Array.isArray(body?.ids)
    ? [...new Set(body.ids.map((id) => String(id || "").trim()).filter(Boolean))]
    : [];

function parseCsvLine(line) {
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

function parseCsvRecords(csv) {
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

function parseCsvHeaders(csv) {
  const [headerLine] = String(csv || "")
    .trim()
    .split(/\r?\n/);
  return new Set(parseCsvLine(headerLine || "").map((header) => normalizeCsvHeader(header)));
}

function normalizeCsvHeader(header) {
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

function parsePackQuantity(row) {
  const raw = row.pack_quantity;
  if (raw === undefined || raw === null || String(raw).trim() === "") return 1;
  const value = Number.parseInt(String(raw), 10);
  if (!Number.isFinite(value) || value < 1) {
    throw new ApiError(422, "Pack Of must be a whole number of at least 1");
  }
  return value;
}

function csvBoolean(value, fallback = true) {
  if (value === undefined || value === null || String(value).trim() === "") {
    return fallback;
  }
  const normalized = String(value).trim().toLowerCase();
  if (["true", "yes", "1", "active"].includes(normalized)) return true;
  if (["false", "no", "0", "inactive"].includes(normalized)) return false;
  return fallback;
}

function assertImportSizeAndRows(csv, records) {
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

function positiveCsvNumber(value) {
  const number = Number(value);
  return Number.isFinite(number) && number > 0 ? number : null;
}

function buildProductImportReport(records) {
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

function validateCatalogImageUrl(imageUrl) {
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

function importFailureReason(error) {
  if (error?.code === "23505") return "A record with the same SKU or unique value already exists";
  if (error?.code === "23503") return "Selected category, brand, or linked record does not exist";
  if (error?.code === "23502") return "Please fill all required fields";
  if (error?.code === "42P10") return "Import conflict index is missing or mismatched for this row";
  return error?.details?.message || error?.detail || error?.message || "Row import failed";
}

async function resolveAdminId(adminId, client = null) {
  if (!adminId) return null;
  const executor = client || { query };
  const result = await executor.query("select id from admins where id=$1", [
    adminId,
  ]);
  return result.rows[0]?.id || null;
}

async function logAdminActivity(
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

async function logNotification({
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

function assertLegalOrderTransition(current, next) {
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

function isRefundEligibleStatus(status) {
  return ["delivered", "partially_refunded", "cancelled"].includes(
    String(status || "").toLowerCase(),
  );
}

function paymentCaptured(order) {
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

async function orderRefundSummary(orderId, client = null) {
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

async function refundSettings(client = null) {
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

function dashboardRangeFilters(queryParams = {}) {
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

async function ensureWalletAccount(customerId, client = null) {
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

async function writeWalletTransaction(
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

async function writePointsLedger(
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

const variantPayload = (body) => ({
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

function productPayload(body, current = {}) {
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

function categoryPayload(body) {
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

function brandPayload(body) {
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

async function productRealtimePayload(productId, fallback = {}) {
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

async function emitProductRealtime(event, productId, extra = {}) {
  try {
    const payload = await productRealtimePayload(
      productId,
      extra.product || {},
    );
    emitCustomers(event, { ...payload, ...extra });
  } catch (error) {
    console.error(`Failed to emit ${event}`, error);
  }
}

async function validateProductPayloadForSave(p, productId = null) {
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

async function validateVariantPayloadForSave(v, productId, variantId = null) {
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

function offerPayload(body) {
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

export const dashboard = async (req, res, next) => {
  try {
    const range = dashboardRangeFilters(req.query);
    const [p, c, b, o] = await Promise.all([
      query(
        "select count(*)::int count, coalesce(sum(mrp-buy_price),0) margin, count(*) filter(where stock<=5)::int low_stock from products",
      ),
      query("select count(*)::int count from categories"),
      query("select count(*)::int count from brands"),
      query(
        `
        with order_rows as (
          select o.*,
            (
              select max(h.changed_at)
              from order_status_history h
              where h.order_id=o.id and h.status='delivered'
            ) as delivered_at
          from orders o
        ),
        scoped_orders as (
          select *
          from order_rows
          where ${range.orderFilter}
        ),
        scoped_refunds as (
          select amount from refund_requests
          where status in ('credited_to_wallet','store_credit_issued','pending_manual_gateway_refund','refunded')
            and ${range.refundFilter}
          union all
          select amount from refunds
          where status in ('pending','processed')
            and ${range.refundFilter}
        )
        select
          count(*)::int as count,
          count(*) filter(where status in ('placed','confirmed','packed','shipped','out_for_delivery'))::int as pending_count,
          count(*) filter(where status in ('delivered','partially_refunded','refunded'))::int as delivered_count,
          coalesce(sum(total) filter(where status in ('delivered','partially_refunded','refunded')),0)::numeric as gross_sales,
          coalesce(sum(total) filter(where status in ('placed','confirmed','packed','shipped','out_for_delivery')),0)::numeric as pending_revenue,
          count(*) filter(where status='cancelled')::int as cancelled_count,
          coalesce(sum(total) filter(where status='cancelled'),0)::numeric as cancelled_value,
          coalesce((select sum(amount) from scoped_refunds), 0)::numeric as refunded_amount,
          now() as last_updated_at,
          $1::text as time_zone
        from scoped_orders
      `,
        range.params,
      ),
    ]);
    const orderMetrics = o.rows[0];
    const grossSales = Number(orderMetrics.gross_sales || 0);
    const refundedAmount = Number(orderMetrics.refunded_amount || 0);
    res.json({
      success: true,
      data: {
        products: p.rows[0],
        categories: c.rows[0],
        brands: b.rows[0],
        orders: {
          ...orderMetrics,
          revenue: orderMetrics.gross_sales,
          net_sales: grossSales - refundedAmount,
          range: range.range,
        },
      },
    });
  } catch (e) {
    next(e);
  }
};

async function catalogVisibilityData(productIds = []) {
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

async function assertImportedCatalogVisible(productIds) {
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

async function ensureSingleDefaultVariant(productId) {
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

export async function catalogVisibility(_req, res, next) {
  try {
    res.json({ success: true, data: await catalogVisibilityData() });
  } catch (e) {
    next(e);
  }
}

async function catalogPricingHealthData() {
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

export async function catalogPricingHealth(_req, res, next) {
  try {
    res.json({ success: true, data: await catalogPricingHealthData() });
  } catch (e) {
    next(e);
  }
}

export const orders = async (_req, res, next) => {
  try {
    const result = await query(`
      select o.*, u.name as customer, u.phone,
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
      group by o.id, u.name, u.phone, r.refunded_total, pay.mode, pay.status
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
        group by o.id, u.name, u.phone, r.refunded_total, pay.mode, pay.status
      `,
      [req.params.id],
    );
    if (!result.rows[0]) throw notFound("Order");
    res.json({ success: true, data: result.rows[0] });
  } catch (e) {
    next(e);
  }
};

export const products = async (_req, res, next) => {
  try {
    const result = await query(`
      select p.*, b.name as brand_name,
        coalesce(
          json_agg(
            json_build_object(
              'id', pv.id,
              'variant_name', pv.variant_name,
              'sku', pv.sku,
              'mrp', pv.mrp,
              'selling_price', pv.selling_price,
              'cost_price', pv.cost_price,
              'pack_quantity', pv.pack_quantity,
              'tax_percent', pv.tax_percent,
              'discount_percent', pv.discount_percent,
              'low_stock_alert', pv.low_stock_alert,
              'barcode', pv.barcode,
              'stock_quantity', pv.stock_quantity,
              'unit', pv.unit,
              'is_default', pv.is_default,
              'is_active', pv.is_active,
              'status', pv.status
            )
          ) filter (where pv.id is not null),
          '[]'::json
        ) as variants
      from products p
      left join brands b on b.id = p.brand_id
      left join product_variants pv on pv.product_id = p.id
      group by p.id, b.name
      order by p.created_at desc
    `);
    res.json({ success: true, data: result.rows });
  } catch (e) {
    next(e);
  }
};

export async function createProduct(req, res, next) {
  try {
    const p = productPayload(req.body);
    p.sku = p.sku || `sku-${slugValue(p.nameEn)}-${Date.now()}`;
    await validateProductPayloadForSave(p);
    const result = await query(
      `insert into products(sku,category_id,brand,brand_id,name_en,name_hi,size,pack,image_url,mrp,buy_price,stock,regional,high_margin,trending_areas,is_active,description,images_json,hsn_code,meta_title,meta_description,ingredients,storage_instructions,shelf_life,country_of_origin,highlights)
       values($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26) returning *`,
      [
        p.sku,
        p.categoryId,
        p.brand,
        p.brandId,
        p.nameEn,
        p.nameHi,
        p.size,
        p.pack,
        p.imageUrl,
        p.mrp,
        p.buyPrice,
        p.stock,
        p.regional,
        p.highMargin,
        p.trendingAreas,
        p.isActive,
        p.description,
        JSON.stringify(p.imagesJson || []),
        p.hsnCode,
        p.metaTitle,
        p.metaDescription,
        p.ingredients,
        p.storageInstructions,
        p.shelfLife,
        p.countryOfOrigin,
        JSON.stringify(p.highlights || []),
      ],
    );
    await logAdminActivity(
      req,
      "create",
      "product",
      result.rows[0].id,
      null,
      result.rows[0],
    );
    await emitProductRealtime("product.created", result.rows[0].id, {
      categoryId: String(result.rows[0].category_id),
      product: result.rows[0],
    });
    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (e) {
    next(e);
  }
}

export async function updateProduct(req, res, next) {
  try {
    const current = await query("select * from products where id=$1", [
      req.params.id,
    ]);
    if (!current.rows[0]) throw notFound("Product");
    const p = productPayload(req.body, current.rows[0]);
    await validateProductPayloadForSave(p, req.params.id);
    const result = await query(
      `update products set sku=$2,category_id=$3,brand=$4,brand_id=$5,name_en=$6,name_hi=$7,size=$8,pack=$9,image_url=$10,mrp=$11,buy_price=$12,stock=$13,regional=$14,high_margin=$15,trending_areas=$16,is_active=$17,description=$18,images_json=$19,hsn_code=$20,meta_title=$21,meta_description=$22,ingredients=$23,storage_instructions=$24,shelf_life=$25,country_of_origin=$26,highlights=$27,updated_at=now() where id=$1 returning *`,
      [
        req.params.id,
        p.sku,
        p.categoryId,
        p.brand,
        p.brandId,
        p.nameEn,
        p.nameHi,
        p.size,
        p.pack,
        p.imageUrl,
        p.mrp,
        p.buyPrice,
        p.stock,
        p.regional,
        p.highMargin,
        p.trendingAreas,
        p.isActive,
        p.description,
        JSON.stringify(p.imagesJson || []),
        p.hsnCode,
        p.metaTitle,
        p.metaDescription,
        p.ingredients,
        p.storageInstructions,
        p.shelfLife,
        p.countryOfOrigin,
        JSON.stringify(p.highlights || []),
      ],
    );
    await logAdminActivity(
      req,
      "update",
      "product",
      req.params.id,
      current.rows[0],
      result.rows[0],
    );
    await emitProductRealtime("product.updated", req.params.id, {
      previousCategoryId: current.rows[0].category_id
        ? String(current.rows[0].category_id)
        : null,
      categoryId: result.rows[0].category_id
        ? String(result.rows[0].category_id)
        : null,
      product: result.rows[0],
    });
    res.json({ success: true, data: result.rows[0] });
  } catch (e) {
    next(e);
  }
}

export async function deleteProduct(req, res, next) {
  try {
    const before = await query("select * from products where id=$1", [
      req.params.id,
    ]);
    const result = await query(
      "update products set is_active=false, updated_at=now() where id=$1 returning id, category_id",
      [req.params.id],
    );
    if (!result.rows[0]) throw notFound("Product");
    await query(
      "update product_variants set status='inactive', is_active=false, updated_at=now() where product_id=$1",
      [req.params.id],
    );
    await logAdminActivity(
      req,
      "delete",
      "product",
      req.params.id,
      before.rows[0],
      null,
    );
    emitCustomers("product.deleted", {
      productId: String(req.params.id),
      categoryId: before.rows[0]?.category_id
        ? String(before.rows[0].category_id)
        : null,
      product: before.rows[0] || { id: req.params.id },
      deleted: true,
    });
    res.json({
      success: true,
      data: {
        id: result.rows[0].id,
        deleted: true,
      },
    });
  } catch (e) {
    next(e);
  }
}

export async function bulkDeleteProducts(req, res, next) {
  try {
    const ids = idsFromBody(req.body);
    if (!ids.length) throw new ApiError(422, "Select at least one product");
    const before = await query("select * from products where id = any($1::uuid[])", [
      ids,
    ]);
    const result = await query(
      "update products set is_active=false, updated_at=now() where id = any($1::uuid[]) returning id, category_id",
      [ids],
    );
    await query(
      "update product_variants set status='inactive', is_active=false, updated_at=now() where product_id = any($1::uuid[])",
      [ids],
    );
    await logAdminActivity(req, "bulk_delete", "product", null, before.rows, {
      ids: result.rows.map((row) => row.id),
      count: result.rowCount,
    });
    emitCustomers("product.deleted", {
      productIds: result.rows.map((row) => String(row.id)),
      deleted: true,
    });
    emitCustomers("catalog.updated", {
      reason: "products.bulk_deleted",
      productIds: result.rows.map((row) => String(row.id)),
      categoryIds: [
        ...new Set(result.rows.map((row) => row.category_id).filter(Boolean)),
      ],
    });
    res.json({ success: true, data: { deleted: result.rowCount } });
  } catch (e) {
    next(e);
  }
}

export async function productVariants(req, res, next) {
  try {
    const result = await query(
      "select * from product_variants where product_id=$1 order by is_default desc, created_at",
      [req.params.id],
    );
    res.json({ success: true, data: result.rows });
  } catch (e) {
    next(e);
  }
}

export async function createProductVariant(req, res, next) {
  try {
    const v = variantPayload(req.body);
    await validateVariantPayloadForSave(v, req.params.id);
    if (v.isDefault)
      await query(
        "update product_variants set is_default=false where product_id=$1",
        [req.params.id],
      );
    const existing = await query(
      "select * from product_variants where sku=$1",
      [v.sku],
    );
    if (
      existing.rows[0] &&
      String(existing.rows[0].product_id) !== String(req.params.id)
    ) {
      throw new ApiError(422, "SKU is already used by another product");
    }
    if (existing.rows[0]) {
      const result = await query(
        `update product_variants set variant_name=$2,mrp=$3,selling_price=$4,stock_quantity=$5,unit=$6,is_default=$7,status=$8,pack_quantity=$9,cost_price=$10,is_active=$11,tax_percent=$12,discount_percent=$13,low_stock_alert=$14,barcode=$15,updated_at=now()
         where id=$1 returning *`,
        [
          existing.rows[0].id,
          v.variantName,
          v.mrp,
          v.sellingPrice,
          v.stockQuantity,
          v.unit,
          v.isDefault,
          v.status,
          v.packQuantity,
          v.costPrice,
          v.isActive,
          v.taxPercent,
          v.discountPercent,
          v.lowStockAlert,
          v.barcode,
        ],
      );
      await logAdminActivity(
        req,
        "update",
        "product_variant",
        result.rows[0].id,
        existing.rows[0],
        result.rows[0],
      );
      await emitProductRealtime("product.updated", req.params.id, {
        variantId: String(result.rows[0].id),
        variant: result.rows[0],
      });
      return res.json({ success: true, data: result.rows[0] });
    }
    const result = await query(
      `insert into product_variants(product_id,variant_name,sku,mrp,selling_price,stock_quantity,unit,is_default,status,pack_quantity,cost_price,is_active,tax_percent,discount_percent,low_stock_alert,barcode)
       values($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16) returning *`,
      [
        req.params.id,
        v.variantName,
        v.sku,
        v.mrp,
        v.sellingPrice,
        v.stockQuantity,
        v.unit,
        v.isDefault,
        v.status,
        v.packQuantity,
        v.costPrice,
        v.isActive,
        v.taxPercent,
        v.discountPercent,
        v.lowStockAlert,
        v.barcode,
      ],
    );
    await logAdminActivity(
      req,
      "create",
      "product_variant",
      result.rows[0].id,
      null,
      result.rows[0],
    );
    await emitProductRealtime("product.updated", req.params.id, {
      variantId: String(result.rows[0].id),
      variant: result.rows[0],
    });
    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (e) {
    next(e);
  }
}

export async function updateProductVariant(req, res, next) {
  try {
    const before = await query(
      "select * from product_variants where id=$1 and product_id=$2",
      [req.params.variantId, req.params.id],
    );
    if (!before.rows[0]) throw notFound("Product variant");
    const v = variantPayload(req.body);
    await validateVariantPayloadForSave(v, req.params.id, req.params.variantId);
    if (v.isDefault)
      await query(
        "update product_variants set is_default=false where product_id=$1 and id<>$2",
        [req.params.id, req.params.variantId],
      );
    const result = await query(
      `update product_variants set variant_name=$3,sku=$4,mrp=$5,selling_price=$6,stock_quantity=$7,unit=$8,is_default=$9,status=$10,pack_quantity=$11,cost_price=$12,is_active=$13,tax_percent=$14,discount_percent=$15,low_stock_alert=$16,barcode=$17,updated_at=now()
       where id=$1 and product_id=$2 returning *`,
      [
        req.params.variantId,
        req.params.id,
        v.variantName,
        v.sku,
        v.mrp,
        v.sellingPrice,
        v.stockQuantity,
        v.unit,
        v.isDefault,
        v.status,
        v.packQuantity,
        v.costPrice,
        v.isActive,
        v.taxPercent,
        v.discountPercent,
        v.lowStockAlert,
        v.barcode,
      ],
    );
    await logAdminActivity(
      req,
      "update",
      "product_variant",
      req.params.variantId,
      before.rows[0],
      result.rows[0],
    );
    if (
      Number(before.rows[0].selling_price) !==
        Number(result.rows[0].selling_price) ||
      Number(before.rows[0].mrp) !== Number(result.rows[0].mrp)
    ) {
      emitCustomers("product.price_changed", {
        productId: req.params.id,
        variantId: req.params.variantId,
        variant: result.rows[0],
      });
    }
    if (
      Number(before.rows[0].stock_quantity) !==
      Number(result.rows[0].stock_quantity)
    ) {
      emitCustomers("product.stock_changed", {
        productId: req.params.id,
        variantId: req.params.variantId,
        variant: result.rows[0],
      });
      if (Number(result.rows[0].stock_quantity) <= 5) {
        emitAdmin("low_stock.alert", {
          productId: req.params.id,
          variantId: req.params.variantId,
          stock: result.rows[0].stock_quantity,
        });
        emitAdmin("notification.created", {
          type: "stock",
          title: `Low stock alert: ${result.rows[0].sku}`,
        });
      }
    }
    await emitProductRealtime("product.updated", req.params.id, {
      variantId: String(req.params.variantId),
      variant: result.rows[0],
    });
    res.json({ success: true, data: result.rows[0] });
  } catch (e) {
    next(e);
  }
}

export async function deleteProductVariant(req, res, next) {
  try {
    const before = await query(
      "select * from product_variants where id=$1 and product_id=$2",
      [req.params.variantId, req.params.id],
    );
    const result = await query(
      "delete from product_variants where id=$1 and product_id=$2 returning id",
      [req.params.variantId, req.params.id],
    );
    if (!result.rows[0]) throw notFound("Product variant");
    await logAdminActivity(
      req,
      "delete",
      "product_variant",
      req.params.variantId,
      before.rows[0],
      null,
    );
    await emitProductRealtime("product.updated", req.params.id, {
      variantId: String(req.params.variantId),
      variant: before.rows[0],
      variantDeleted: true,
    });
    res.json({
      success: true,
      data: {
        id: result.rows[0].id,
        deleted: true,
      },
    });
  } catch (e) {
    next(e);
  }
}

export async function exportProductsCsv(_req, res, next) {
  try {
    const result = await query(`
      select p.sku as product_sku, p.name_en, c.name_en as category, b.name as brand, p.description, p.image_url,
             pv.variant_name, pv.sku, pv.pack_quantity, pv.mrp as unit_mrp, pv.selling_price, pv.cost_price, pv.stock_quantity, pv.unit, pv.is_default, pv.is_active, pv.status,
             (coalesce(pv.mrp, 0) * greatest(coalesce(pv.pack_quantity, 1), 1))::numeric as total_mrp
      from products p
      left join categories c on c.id = p.category_id
      left join brands b on b.id = p.brand_id
      left join product_variants pv on pv.product_id = p.id
      order by p.created_at desc, pv.is_default desc
    `);
    const fieldMap = {
      "Pack Of": "pack_quantity",
      "Unit MRP": "unit_mrp",
      "Total MRP": "total_mrp",
    };
    const csv = [
      PRODUCT_IMPORT_HEADERS.join(","),
      ...result.rows.map((row) =>
        PRODUCT_IMPORT_HEADERS.map((h) => JSON.stringify(row[fieldMap[h] || h] ?? "")).join(","),
      ),
    ].join("\n");
    res.setHeader("Content-Type", "text/csv");
    res.setHeader(
      "Content-Disposition",
      'attachment; filename="vyparhub-products.csv"',
    );
    res.send(csv);
  } catch (e) {
    next(e);
  }
}

export async function importTemplate(req, res, next) {
  try {
    const type = String(req.params.type || "products").toLowerCase();
    const templates = {
      products: [
        PRODUCT_IMPORT_HEADERS,
        [
          "CLOSEUP FRESH & BREATH TOOTHPASTE",
          "closeup-fresh-breath-toothpaste-1",
          "ORAL CARE",
          "CLOSEUP",
          "PACK OF 12 PCS, MRP RS 10 PER PCS",
          "https://example.com/closeup.jpg",
          "PACK OF 12",
          "ORAL-001",
          "12",
          "10",
          "100",
          "100",
          "5000",
          "pcs",
          "TRUE",
          "TRUE",
          "active",
          "120",
        ],
      ],
      brands: [
        ["name", "logo_url", "status"],
        ["Parle", "", "active"],
      ],
      categories: [
        ["name_en", "slug", "image_url", "sort_order", "status"],
        ["Biscuits", "biscuits", "", "10", "active"],
      ],
    };
    const rows = templates[type];
    if (!rows) throw new ApiError(404, "Unknown import template type");
    const csv = rows.map((row) => row.map(csvCell).join(",")).join("\n");
    res.setHeader("Content-Type", "text/csv");
    res.setHeader(
      "Content-Disposition",
      `attachment; filename="vyparhub-${type}-template.csv"`,
    );
    res.send(csv);
  } catch (e) {
    next(e);
  }
}

export async function importProductsCsv(req, res, next) {
  try {
    const csv = req.body?.csv;
    if (!csv || typeof csv !== "string")
      throw new ApiError(422, "csv text is required");
    const headers = parseCsvHeaders(csv);
    const hasColumn = (column) => headers.has(column);
    const missingColumns = PRODUCT_IMPORT_REQUIRED_COLUMNS.filter(
      (column) => !headers.has(column),
    );
    if (missingColumns.length) {
      throw new ApiError(
        422,
        `Missing required column(s): ${missingColumns.join(", ")}`,
      );
    }
    const records = parseCsvRecords(csv);
    assertImportSizeAndRows(csv, records);
    const importReport = buildProductImportReport(records);
    const summary = {
      created: 0,
      updated: 0,
      failed: 0,
      processed: records.length,
      failures: [],
    };
    const categoryIds = new Set();
    const brandIds = new Set();
    const touchedProductIds = new Set();
    for (const [index, row] of records.entries()) {
      const rowNumber = index + 2;
      try {
        if (!row.name_en) throw new ApiError(422, "Product name is required");
        if (!row.product_sku) throw new ApiError(422, "Product SKU is required");
        if (!row.category) throw new ApiError(422, "Category is required");
        if (!row.brand) throw new ApiError(422, "Brand is required");
        if (!row.variant_name) throw new ApiError(422, "Variant name is required");
        if (!row.sku) throw new ApiError(422, "Variant SKU is required");
        if (!row.pack_quantity) throw new ApiError(422, "Pack Of is required");
        if (!row.unit_mrp) throw new ApiError(422, "Unit MRP is required");
        if (!row.selling_price) throw new ApiError(422, "Selling price is required");
        if (!row.cost_price) throw new ApiError(422, "Cost price is required");
        if (!row.stock_quantity) throw new ApiError(422, "Stock quantity is required");
        if (!row.unit) throw new ApiError(422, "Unit is required");
        if (!row.total_mrp) throw new ApiError(422, "Total MRP is required");
        const packQuantity = parsePackQuantity(row);
        const unitMrp = Number(row.unit_mrp || 0);
        const totalMrp = row.total_mrp ? Number(row.total_mrp) : unitMrp * packQuantity;
        const sellingPrice = Number(row.selling_price || 0);
        if (!Number.isFinite(unitMrp) || unitMrp <= 0) {
          throw new ApiError(422, "Unit MRP must be a positive number");
        }
        if (!Number.isFinite(totalMrp) || totalMrp <= 0) {
          throw new ApiError(422, "Total MRP must be a positive number");
        }
        if (row.total_mrp && Math.abs(totalMrp - unitMrp * packQuantity) > 0.01) {
          throw new ApiError(422, "Total MRP must equal Unit MRP Ã— Pack Of");
        }
        if (sellingPrice > totalMrp) {
          throw new ApiError(422, "Selling price cannot be greater than Total MRP");
        }
        if (Number(row.cost_price || 0) < 0 || Number(row.stock_quantity || 0) < 0) {
          throw new ApiError(422, "Cost price and stock cannot be negative");
        }
        const imageUrl = validateCatalogImageUrl(row.image_url);

        const productSku = row.product_sku;
        const variantSku = importVariantSku(row, productSku);
        const existing = await query(
          "select id from products where lower(sku)=lower($1) limit 1",
          [productSku],
        );
        const action = existing.rows[0] ? "updated" : "created";

        let category = await query(
          "select id from categories where lower(name_en)=lower($1) or slug=$2",
          [row.category, slugValue(row.category)],
        );
        if (category.rows[0]) {
          category = await query(
            "update categories set name_en=$2,is_active=true,updated_at=now() where id=$1 returning id",
            [category.rows[0].id, row.category],
          );
        } else {
          category = await query(
            "insert into categories(slug,name_en,is_active) values($1,$2,true) on conflict(slug) do update set name_en=excluded.name_en,is_active=true,updated_at=now() returning id",
            [slugValue(row.category), row.category],
          );
        }
        if (category.rows[0]?.id) categoryIds.add(String(category.rows[0].id));

        let brand = { rows: [] };
        if (row.brand) {
          brand = await query(
            "select id from brands where lower(name)=lower($1)",
            [row.brand],
          );
          if (brand.rows[0]) {
            brand = await query(
              "update brands set name=$2,status='active',is_active=true,updated_at=now() where id=$1 returning id",
              [brand.rows[0].id, row.brand],
            );
          } else {
            brand = await query(
              "insert into brands(name,status,is_active) values($1,$2,true) on conflict(name) do update set status=excluded.status,is_active=true,updated_at=now() returning id",
              [row.brand, "active"],
            );
          }
          if (brand.rows[0]?.id) brandIds.add(String(brand.rows[0].id));
        }

        const product = existing.rows[0]
          ? await query(
              `update products
               set sku=$2,
                   category_id=$3,
                   name_en=$4,
                   brand=case when $5 then $6 else brand end,
                   brand_id=case when $5 then $7 else brand_id end,
                   description=case when $8 then $9 else description end,
                   image_url=case when $10 then coalesce($11, image_url) else image_url end,
                   is_active=true,
                   updated_at=now()
               where id=$1
               returning *`,
              [
                existing.rows[0].id,
                productSku,
                category.rows[0]?.id,
                row.name_en,
                hasColumn("brand"),
                row.brand || null,
                brand.rows[0]?.id,
                hasColumn("description"),
                row.description || null,
                hasColumn("image_url"),
                imageUrl || null,
              ],
            )
          : await query(
              `insert into products(sku,category_id,brand,brand_id,name_en,description,image_url,is_active)
               values($1,$2,$3,$4,$5,$6,$7,true)
               returning *`,
              [
                productSku,
                category.rows[0]?.id,
                row.brand || null,
                brand.rows[0]?.id,
                row.name_en,
                row.description || null,
                imageUrl || null,
              ],
            );
        const variantStatus =
          String(row.status || "active").trim().toLowerCase() === "inactive"
            ? "inactive"
            : "active";
        const variantActive = csvBoolean(row.is_active, true) && variantStatus !== "inactive";
        const existingVariant = await query(
          `select pv.id, pv.product_id, p.sku as product_sku, p.name_en as product_name
           from product_variants pv
           left join products p on p.id=pv.product_id
           where lower(pv.sku)=lower($1)
           limit 1`,
          [variantSku],
        );
        if (
          existingVariant.rows[0] &&
          String(existingVariant.rows[0].product_id) !== String(product.rows[0].id)
        ) {
          throw new ApiError(
            422,
            `Variant SKU "${variantSku}" already belongs to product "${existingVariant.rows[0].product_sku || existingVariant.rows[0].product_name}". Use a unique variant SKU for this row.`,
          );
        }
        if (existingVariant.rows[0]) {
          await query(
            `update product_variants
             set product_id=$2,
                 variant_name=$3,
                 sku=$4,
                 mrp=$5,
                 selling_price=$6,
                 stock_quantity=case when $13 then $7 else stock_quantity end,
                 unit=case when $14 then $8 else unit end,
                 is_default=$9,
                 status=$10,
                 pack_quantity=case when $15 then $11 else pack_quantity end,
                 cost_price=case when $16 then $12 else cost_price end,
                 is_active=$17,
                 updated_at=now()
             where id=$1`,
            [
              existingVariant.rows[0].id,
              product.rows[0].id,
              row.variant_name,
              variantSku,
              unitMrp,
              sellingPrice,
              Number(row.stock_quantity || 0),
              row.unit || "pcs",
              csvBoolean(row.is_default, false),
              variantStatus,
              packQuantity,
              Number(row.cost_price || sellingPrice || 0),
              hasColumn("stock_quantity"),
              hasColumn("unit"),
              hasColumn("pack_quantity"),
              hasColumn("cost_price"),
              variantActive,
            ],
          );
        } else {
          await query(
            `insert into product_variants(product_id,variant_name,sku,mrp,selling_price,stock_quantity,unit,is_default,status,pack_quantity,cost_price,is_active)
             values($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)`,
            [
              product.rows[0].id,
              row.variant_name,
              variantSku,
              unitMrp,
              sellingPrice,
              Number(row.stock_quantity || 0),
              row.unit || "pcs",
              csvBoolean(row.is_default, false),
              variantStatus,
              packQuantity,
              Number(row.cost_price || sellingPrice || 0),
              variantActive,
            ],
          );
        }

        const verification = await query(
          `select p.id
           from products p
           join product_variants pv on pv.product_id=p.id
          where p.id=$1 and p.is_active=true and lower(pv.sku)=lower($2) and pv.status='active' and coalesce(pv.is_active,true)=true
           limit 1`,
          [product.rows[0].id, variantSku],
        );
        if (!verification.rows[0]) {
          throw new ApiError(500, "Product import verification failed");
        }

        touchedProductIds.add(String(product.rows[0].id));
        await emitProductRealtime(
          action === "created" ? "product.created" : "product.updated",
          product.rows[0].id,
          {
            product: product.rows[0],
            source: "csv_import",
          },
        );
        summary[action] += 1;
      } catch (rowError) {
        summary.failed += 1;
        summary.failures.push({
          rowNumber,
          reason: importFailureReason(rowError),
        });
      }
    }
    for (const productId of touchedProductIds) {
      await ensureSingleDefaultVariant(productId);
    }
    const imported = summary.created + summary.updated;
    if (!imported && summary.failed) {
      throw new ApiError(422, "No products were imported", summary.failures);
    }
    await assertImportedCatalogVisible([...touchedProductIds]);
    await logAdminActivity(req, "import", "product", null, null, {
      imported,
      created: summary.created,
      updated: summary.updated,
      failed: summary.failed,
    });
    for (const categoryId of categoryIds) {
      emitCustomers("category.updated", { categoryId });
    }
    for (const brandId of brandIds) {
      emitCustomers("brand.updated", { brandId });
    }
    emitCustomers("catalog.updated", {
      reason: "products.imported",
      imported,
      created: summary.created,
      updated: summary.updated,
      failed: summary.failed,
      categoryIds: [...categoryIds],
      brandIds: [...brandIds],
    });
    res.json({
      success: true,
      data: {
        imported,
        created: summary.created,
        updated: summary.updated,
        failed: summary.failed,
        failures: summary.failures,
        report: {
          ...importReport,
          failedRows: summary.failures,
          totalProductsImportedOrUpdated: touchedProductIds.size,
        },
      },
    });
  } catch (e) {
    next(e);
  }
}

export async function importBrandsCsv(req, res, next) {
  try {
    const csv = req.body?.csv;
    if (!csv || typeof csv !== "string")
      throw new ApiError(422, "csv text is required");
    const records = parseCsvRecords(csv);
    assertImportSizeAndRows(csv, records);
    let imported = 0;
    for (const row of records) {
      if (!row.name) throw new ApiError(422, "Brand name is required");
      const logoUrl = validateCatalogImageUrl(row.logo_url);
      await query(
        `insert into brands(name,logo_url,status,is_active)
         values($1,$2,$3,$4)
         on conflict(name) do update set logo_url=coalesce(excluded.logo_url, brands.logo_url),status=excluded.status,is_active=excluded.is_active,updated_at=now()`,
        [
          row.name,
          logoUrl || null,
          row.status || "active",
          (row.status || "active") !== "inactive",
        ],
      );
      imported += 1;
    }
    await logAdminActivity(req, "import", "brand", null, null, { imported });
    await emitCustomers("brand.updated", { imported });
    res.json({ success: true, data: { imported } });
  } catch (e) {
    next(e);
  }
}

export async function importCategoriesCsv(req, res, next) {
  try {
    const csv = req.body?.csv;
    if (!csv || typeof csv !== "string")
      throw new ApiError(422, "csv text is required");
    const records = parseCsvRecords(csv);
    assertImportSizeAndRows(csv, records);
    let imported = 0;
    for (const row of records) {
      const name = row.name_en || row.name;
      if (!name) throw new ApiError(422, "Category name is required");
      const slug = row.slug || slugValue(name);
      const imageUrl = validateCatalogImageUrl(row.image_url);
      await query(
        `insert into categories(slug,name_en,image_url,sort_order,is_active)
         values($1,$2,$3,$4,$5)
         on conflict(slug) do update set name_en=excluded.name_en,image_url=coalesce(excluded.image_url, categories.image_url),sort_order=excluded.sort_order,is_active=excluded.is_active,updated_at=now()`,
        [
          slug,
          name,
          imageUrl || null,
          numericValue(row.sort_order, 0),
          (row.status || "active") !== "inactive",
        ],
      );
      imported += 1;
    }
    await logAdminActivity(req, "import", "category", null, null, {
      imported,
    });
    await emitCustomers("category.updated", { imported });
    res.json({ success: true, data: { imported } });
  } catch (e) {
    next(e);
  }
}

export async function search(req, res, next) {
  try {
    const q = `%${String(req.query.q || "").trim()}%`;
    if (q === "%%")
      return res.json({
        success: true,
        data: { orders: [], products: [], customers: [], brands: [], categories: [] },
      });
    const [ordersResult, productsResult, customersResult, brandsResult, categoriesResult] = await Promise.all([
      query(
        "select id,status,total,created_at from orders where id::text ilike $1 or status::text ilike $1 order by created_at desc limit 8",
        [q],
      ),
      query(
        "select id,sku,name_en,image_url,starting_price,buy_price from products where is_active=true and (name_en ilike $1 or sku ilike $1 or brand ilike $1 or id::text ilike $1) order by created_at desc limit 8",
        [q],
      ),
      query(
        "select id,name,shop_name,phone from users where role='customer' and (name ilike $1 or shop_name ilike $1 or phone ilike $1) order by created_at desc limit 8",
        [q],
      ),
      query(
        "select id,name,logo_url,status from brands where is_active=true and name ilike $1 order by name limit 8",
        [q],
      ),
      query(
        "select id,name_en,slug,image_url from categories where is_active=true and (name_en ilike $1 or slug ilike $1) order by sort_order,name_en limit 8",
        [q],
      ),
    ]);
    res.json({
      success: true,
      data: {
        orders: ordersResult.rows,
        products: productsResult.rows,
        customers: customersResult.rows,
        brands: brandsResult.rows,
        categories: categoriesResult.rows,
      },
    });
  } catch (e) {
    next(e);
  }
}

export async function categories(_req, res, next) {
  try {
    res.json({
      success: true,
      data: (
        await query("select * from categories order by sort_order, name_en")
      ).rows,
    });
  } catch (e) {
    next(e);
  }
}

export async function createCategory(req, res, next) {
  try {
    const c = categoryPayload(req.body);
    if (!c.slug || !c.nameEn)
      throw new ApiError(422, "slug and name_en are required");
    const before = await query("select * from categories where slug=$1", [
      c.slug,
    ]);
    const result = await query(
      `insert into categories(slug,name_en,name_hi,image_url,tint,sort_order,is_active,parent_id,description)
       values($1,$2,$3,$4,$5,$6,$7,$8,$9)
       on conflict(slug) do update set
         name_en=excluded.name_en,
         name_hi=excluded.name_hi,
         image_url=coalesce(excluded.image_url, categories.image_url),
         tint=excluded.tint,
         sort_order=excluded.sort_order,
         is_active=excluded.is_active,
         parent_id=excluded.parent_id,
         description=excluded.description,
         updated_at=now()
       returning *`,
      [
        c.slug,
        c.nameEn,
        c.nameHi,
        c.imageUrl,
        c.tint,
        c.sortOrder,
        c.isActive,
        c.parentId,
        c.description,
      ],
    );
    await logAdminActivity(
      req,
      before.rows[0] ? "restore" : "create",
      "category",
      result.rows[0].id,
      before.rows[0] || null,
      result.rows[0],
    );
    emitCustomers("category.updated", {
      categoryId: result.rows[0].id,
      category: result.rows[0],
    });
    emitCustomers("catalog.updated", {
      reason: "category.created",
      categoryId: result.rows[0].id,
    });
    res.status(before.rows[0] ? 200 : 201).json({
      success: true,
      data: result.rows[0],
    });
  } catch (e) {
    next(e);
  }
}

export async function updateCategory(req, res, next) {
  try {
    const before = await query("select * from categories where id=$1", [
      req.params.id,
    ]);
    const c = categoryPayload(req.body);
    const result = await query(
      "update categories set slug=$2,name_en=$3,name_hi=$4,image_url=$5,tint=$6,sort_order=$7,is_active=$8,parent_id=$9,description=$10,updated_at=now() where id=$1 returning *",
      [
        req.params.id,
        c.slug,
        c.nameEn,
        c.nameHi,
        c.imageUrl,
        c.tint,
        c.sortOrder,
        c.isActive,
        c.parentId,
        c.description,
      ],
    );
    if (!result.rows[0]) throw notFound("Category");
    await logAdminActivity(
      req,
      "update",
      "category",
      req.params.id,
      before.rows[0],
      result.rows[0],
    );
    emitCustomers("category.updated", {
      categoryId: req.params.id,
      category: result.rows[0],
    });
    emitCustomers("catalog.updated", {
      reason: "category.updated",
      categoryId: req.params.id,
    });
    res.json({ success: true, data: result.rows[0] });
  } catch (e) {
    next(e);
  }
}

export async function deleteCategory(req, res, next) {
  try {
    const before = await query("select * from categories where id=$1", [
      req.params.id,
    ]);
    if (!before.rows[0]) throw notFound("Category");
    const result = await query(
      "update categories set is_active=false, updated_at=now() where id=$1 returning *",
      [req.params.id],
    );
    if (!result.rows[0]) throw notFound("Category");
    const affectedProducts = await query(
      "update products set is_active=false, updated_at=now() where category_id=$1 returning id",
      [req.params.id],
    );
    await query(
      "update product_variants set status='inactive', is_active=false, updated_at=now() where product_id = any($1::uuid[])",
      [affectedProducts.rows.map((row) => row.id)],
    );
    await logAdminActivity(
      req,
      "delete",
      "category",
      req.params.id,
      before.rows[0],
      result.rows[0],
    );
    emitCustomers("category.deleted", {
      categoryId: req.params.id,
      productIds: affectedProducts.rows.map((row) => row.id),
    });
    emitCustomers("catalog.updated", {
      reason: "category.deleted",
      categoryId: req.params.id,
      productIds: affectedProducts.rows.map((row) => row.id),
    });
    res.json({
      success: true,
      data: {
        id: result.rows[0].id,
        deleted: true,
        productIds: affectedProducts.rows.map((row) => row.id),
        affectedProducts: affectedProducts.rowCount,
      },
    });
  } catch (e) {
    next(e);
  }
}

export async function bulkDeleteCategories(req, res, next) {
  try {
    const ids = idsFromBody(req.body);
    if (!ids.length) throw new ApiError(422, "Select at least one category");
    const before = await query(
      "select * from categories where id = any($1::uuid[])",
      [ids],
    );
    const result = await query(
      "update categories set is_active=false, updated_at=now() where id = any($1::uuid[]) returning id",
      [ids],
    );
    const affectedProducts = await query(
      "update products set is_active=false, updated_at=now() where category_id = any($1::uuid[]) returning id, category_id",
      [ids],
    );
    await query(
      "update product_variants set status='inactive', is_active=false, updated_at=now() where product_id = any($1::uuid[])",
      [affectedProducts.rows.map((row) => row.id)],
    );
    await logAdminActivity(req, "bulk_delete", "category", null, before.rows, {
      ids: result.rows.map((row) => row.id),
      productIds: affectedProducts.rows.map((row) => row.id),
    });
    emitCustomers("category.deleted", {
      categoryIds: result.rows.map((row) => String(row.id)),
      productIds: affectedProducts.rows.map((row) => String(row.id)),
    });
    emitCustomers("catalog.updated", {
      reason: "categories.bulk_deleted",
      categoryIds: result.rows.map((row) => String(row.id)),
      productIds: affectedProducts.rows.map((row) => String(row.id)),
    });
    res.json({ success: true, data: { deleted: result.rowCount, affectedProducts: affectedProducts.rowCount } });
  } catch (e) {
    next(e);
  }
}

export async function brands(_req, res, next) {
  try {
    res.json({
      success: true,
      data: (await query("select * from brands order by name")).rows,
    });
  } catch (e) {
    next(e);
  }
}

export async function createBrand(req, res, next) {
  try {
    const b = brandPayload(req.body);
    if (!b.name) throw new ApiError(422, "name is required");
    const before = await query("select * from brands where lower(name)=lower($1)", [
      b.name,
    ]);
    const result = before.rows[0]
      ? await query(
          `update brands set
             name=$2,
             logo_url=coalesce($3, logo_url),
             is_active=$4,
             status=$5,
             slug=coalesce($6, slug),
             description=$7,
             updated_at=now()
           where id=$1
           returning *`,
          [before.rows[0].id, b.name, b.logoUrl, b.isActive, b.status, b.slug, b.description],
        )
      : await query(
          `insert into brands(name,logo_url,is_active,status,slug,description)
           values($1,$2,$3,$4,$5,$6)
           on conflict(name) do update set
             logo_url=coalesce(excluded.logo_url, brands.logo_url),
             is_active=excluded.is_active,
             status=excluded.status,
             slug=coalesce(excluded.slug, brands.slug),
             description=excluded.description,
             updated_at=now()
           returning *`,
          [b.name, b.logoUrl, b.isActive, b.status, b.slug, b.description],
        );
    await logAdminActivity(
      req,
      before.rows[0] ? "restore" : "create",
      "brand",
      result.rows[0].id,
      before.rows[0] || null,
      result.rows[0],
    );
    emitCustomers("brand.updated", {
      brandId: result.rows[0].id,
      brand: result.rows[0],
    });
    emitCustomers("catalog.updated", {
      reason: "brand.created",
      brandId: result.rows[0].id,
    });
    res.status(before.rows[0] ? 200 : 201).json({
      success: true,
      data: result.rows[0],
    });
  } catch (e) {
    next(e);
  }
}

export async function updateBrand(req, res, next) {
  try {
    const before = await query("select * from brands where id=$1", [
      req.params.id,
    ]);
    const b = brandPayload(req.body);
    const result = await query(
      "update brands set name=$2,logo_url=$3,is_active=$4,status=$5,slug=coalesce($6, slug),description=$7,updated_at=now() where id=$1 returning *",
      [req.params.id, b.name, b.logoUrl, b.isActive, b.status, b.slug, b.description],
    );
    if (!result.rows[0]) throw notFound("Brand");
    await logAdminActivity(
      req,
      "update",
      "brand",
      req.params.id,
      before.rows[0],
      result.rows[0],
    );
    emitCustomers("brand.updated", {
      brandId: req.params.id,
      brand: result.rows[0],
    });
    emitCustomers("catalog.updated", {
      reason: "brand.updated",
      brandId: req.params.id,
    });
    res.json({ success: true, data: result.rows[0] });
  } catch (e) {
    next(e);
  }
}

export async function deleteBrand(req, res, next) {
  try {
    const before = await query("select * from brands where id=$1", [
      req.params.id,
    ]);
    if (!before.rows[0]) throw notFound("Brand");
    const result = await query(
      "update brands set is_active=false,status='inactive',updated_at=now() where id=$1 returning *",
      [req.params.id],
    );
    if (!result.rows[0]) throw notFound("Brand");

    const affectedProducts = await query(
      `
        update products
        set is_active=false, updated_at=now()
        where brand_id=$1 or lower(coalesce(brand, '')) = lower($2)
        returning id, category_id
      `,
      [req.params.id, before.rows[0].name || ""],
    );
    await query(
      "update product_variants set status='inactive', is_active=false, updated_at=now() where product_id = any($1::uuid[])",
      [affectedProducts.rows.map((row) => row.id)],
    );

    await logAdminActivity(
      req,
      "delete",
      "brand",
      req.params.id,
      before.rows[0],
      result.rows[0],
    );
    emitCustomers("brand.deleted", {
      brandId: req.params.id,
      brandName: before.rows[0].name,
      productIds: affectedProducts.rows.map((row) => row.id),
    });
    emitCustomers("catalog.updated", {
      reason: "brand.deleted",
      brandId: req.params.id,
      brandName: before.rows[0].name,
      productIds: affectedProducts.rows.map((row) => row.id),
      categoryIds: [
        ...new Set(
          affectedProducts.rows.map((row) => row.category_id).filter(Boolean),
        ),
      ],
    });
    res.json({
      success: true,
      data: {
        id: result.rows[0].id,
        deleted: true,
        productIds: affectedProducts.rows.map((row) => row.id),
        affectedProducts: affectedProducts.rowCount,
      },
    });
  } catch (e) {
    next(e);
  }
}

export async function bulkDeleteBrands(req, res, next) {
  try {
    const ids = idsFromBody(req.body);
    if (!ids.length) throw new ApiError(422, "Select at least one brand");
    const before = await query("select * from brands where id = any($1::uuid[])", [
      ids,
    ]);
    const names = before.rows.map((row) => String(row.name || "").toLowerCase());
    const result = await query(
      "update brands set is_active=false,status='inactive',updated_at=now() where id = any($1::uuid[]) returning id, name",
      [ids],
    );
    const affectedProducts = await query(
      `update products
       set is_active=false, updated_at=now()
       where brand_id = any($1::uuid[]) or lower(coalesce(brand, '')) = any($2::text[])
       returning id, category_id`,
      [ids, names],
    );
    await query(
      "update product_variants set status='inactive', is_active=false, updated_at=now() where product_id = any($1::uuid[])",
      [affectedProducts.rows.map((row) => row.id)],
    );
    await logAdminActivity(req, "bulk_delete", "brand", null, before.rows, {
      ids: result.rows.map((row) => row.id),
      productIds: affectedProducts.rows.map((row) => row.id),
    });
    emitCustomers("brand.deleted", {
      brandIds: result.rows.map((row) => String(row.id)),
      productIds: affectedProducts.rows.map((row) => String(row.id)),
    });
    emitCustomers("catalog.updated", {
      reason: "brands.bulk_deleted",
      brandIds: result.rows.map((row) => String(row.id)),
      productIds: affectedProducts.rows.map((row) => String(row.id)),
      categoryIds: [
        ...new Set(
          affectedProducts.rows.map((row) => row.category_id).filter(Boolean),
        ),
      ],
    });
    res.json({ success: true, data: { deleted: result.rowCount, affectedProducts: affectedProducts.rowCount } });
  } catch (e) {
    next(e);
  }
}

export async function resetCatalog(req, res, next) {
  const client = await pool.connect();
  try {
    const confirmation = String(req.body?.confirmation || "").trim();
    if (confirmation !== "DELETE CATALOG") {
      throw new ApiError(422, 'Type "DELETE CATALOG" to confirm catalog reset');
    }
    await client.query("begin");
    const adminId = await resolveAdminId(req.admin?.id, client);
    const counts = {
      cartItems: (await client.query("select count(*)::int as count from cart_items")).rows[0].count,
      homeItems: (await client.query("select count(*)::int as count from home_section_items")).rows[0].count,
      variants: (await client.query("select count(*)::int as count from product_variants")).rows[0].count,
      products: (await client.query("select count(*)::int as count from products")).rows[0].count,
      categories: (await client.query("select count(*)::int as count from categories")).rows[0].count,
      brands: (await client.query("select count(*)::int as count from brands")).rows[0].count,
    };

    await client.query("delete from cart_items");
    await client.query("delete from home_section_items");
    await client.query("update offers set product_id=null, category_id=null");
    await client.query("update order_items set product_id=null where product_id is not null");
    await client.query("delete from inventory");
    await client.query("delete from product_variants");
    await client.query("delete from products");
    await client.query("update categories set parent_id=null where parent_id is not null");
    await client.query("delete from categories");
    await client.query("delete from brands");
    await client.query(
      `insert into admin_activity_log(admin_id,action,entity_type,entity_id,before_json,after_json)
       values($1,'reset','catalog',null,$2,$3)`,
      [adminId, counts, { confirmation, resetAt: new Date().toISOString() }],
    );
    await client.query("commit");

    emitCustomers("catalog.reset", counts);
    emitCustomers("catalog.updated", { reason: "catalog.reset", counts });
    emitCustomers("home_section.updated", { reason: "catalog.reset" });
    emitAdmin("catalog.reset", counts);
    res.json({ success: true, data: { reset: true, counts } });
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

export async function offers(_req, res, next) {
  try {
    res.json({
      success: true,
      data: (await query("select * from offers order by created_at desc")).rows,
    });
  } catch (e) {
    next(e);
  }
}

export async function customers(_req, res, next) {
  try {
    const result = await query(`
      select
        u.id,
        u.name,
        u.shop_name,
        u.phone,
        u.area,
        u.pincode,
        u.role,
        u.created_at,
        count(o.id)::int as orders,
        coalesce(sum(o.total) filter(where o.status in ('delivered','partially_refunded','refunded')), 0)::numeric as total_spent
      from users u
      left join orders o on o.user_id = u.id
      where u.role = 'customer'
      group by u.id
      order by u.created_at desc
    `);
    res.json({ success: true, data: result.rows });
  } catch (e) {
    next(e);
  }
}

export async function reports(_req, res, next) {
  try {
    const [sales, categories, topProducts] = await Promise.all([
      query(`
        select
          to_char(created_at::date, 'DD Mon') as label,
          coalesce(sum(total), 0)::numeric as total,
          count(*)::int as orders
        from orders
        where created_at >= now() - interval '14 days'
          and status in ('delivered','partially_refunded','refunded')
        group by created_at::date
        order by created_at::date
      `),
      query(`
        select c.name_en as category, coalesce(sum(oi.buy_price * oi.quantity), 0)::numeric as revenue
        from order_items oi
        join orders o on o.id = oi.order_id and o.status in ('delivered','partially_refunded','refunded')
        join products p on p.id = oi.product_id
        left join categories c on c.id = p.category_id
        group by c.name_en
        order by revenue desc
        limit 8
      `),
      query(`
        select p.name_en, p.image_url, coalesce(sum(oi.quantity) filter(where o.id is not null), 0)::int as sold
        from products p
        left join order_items oi on oi.product_id = p.id
        left join orders o on o.id = oi.order_id and o.status in ('delivered','partially_refunded','refunded')
        group by p.id
        order by sold desc, p.created_at desc
        limit 8
      `),
    ]);
    res.json({
      success: true,
      data: {
        sales: sales.rows,
        categories: categories.rows,
        topProducts: topProducts.rows,
      },
    });
  } catch (e) {
    next(e);
  }
}

export async function payments(_req, res, next) {
  try {
    const result = await query(`
      select p.*, o.status as order_status
      from payments p
      left join orders o on o.id = p.order_id
      order by p.created_at desc
      limit 100
    `);
    res.json({ success: true, data: result.rows });
  } catch (e) {
    next(e);
  }
}

export async function payouts(_req, res, next) {
  try {
    const result = await query(`
      select
        brand as vendor,
        count(*)::int as products,
        coalesce(sum((mrp - buy_price) * greatest(stock, 0)), 0)::numeric as pending_amount,
        max(updated_at) as updated_at
      from products
      where brand is not null and brand <> ''
      group by brand
      order by pending_amount desc
    `);
    res.json({ success: true, data: result.rows });
  } catch (e) {
    next(e);
  }
}

export async function returnsRefunds(_req, res, next) {
  try {
    const result = await query(`
      select *
      from (
        select
          rr.id,
          rr.order_id,
          u.name as customer,
          u.phone,
          rr.amount as total,
          rr.status,
          rr.reason as notes,
          rr.refund_method,
          rr.request_type,
          rr.items_json,
          rr.quantity_total,
          rr.customer_notes,
          rr.admin_notes,
          rr.rejection_reason,
          rr.created_at,
          rr.updated_at,
          'request'::text as source
        from refund_requests rr
        left join users u on u.id = rr.customer_id
        union all
        select
          r.id,
          r.order_id,
          u.name as customer,
          u.phone,
          r.amount as total,
          r.status,
          r.reason as notes,
          r.destination as refund_method,
          'admin_refund'::text as request_type,
          r.items_json,
          0::int as quantity_total,
          null::text as customer_notes,
          (r.metadata_json->>'notes')::text as admin_notes,
          null::text as rejection_reason,
          r.created_at,
          coalesce(r.processed_at, r.created_at) as updated_at,
          'refund'::text as source
        from refunds r
        left join orders o on o.id = r.order_id
        left join users u on u.id = o.user_id
      ) rows
      order by updated_at desc
    `);
    res.json({ success: true, data: result.rows });
  } catch (e) {
    next(e);
  }
}

export async function supportTickets(_req, res, next) {
  try {
    const result = await query(`
      select
        o.id,
        u.name as customer,
        u.phone,
        o.status,
        coalesce(o.notes, 'Order support follow-up') as issue,
        o.updated_at
      from orders o
      left join users u on u.id = o.user_id
      where o.notes is not null and o.notes <> ''
      order by o.updated_at desc
      limit 100
    `);
    res.json({ success: true, data: result.rows });
  } catch (e) {
    next(e);
  }
}

export async function adminUsers(_req, res, next) {
  try {
    const result = await query(`
      select a.id, a.name, a.email, a.status, a.role_id, r.name as role, a.created_at, a.updated_at
      from admins a
      left join roles r on r.id = a.role_id
      order by a.created_at desc
    `);
    res.json({ success: true, data: result.rows });
  } catch (e) {
    next(e);
  }
}

export async function activityLogs(_req, res, next) {
  try {
    const result = await query(`
      select l.created_at as date_time, l.entity_type as module, l.action, coalesce(a.name, 'System') || ' - ' || l.entity_type as details
      from admin_activity_log l
      left join admins a on a.id = l.admin_id
      order by l.created_at desc
      limit 100
    `);
    res.json({ success: true, data: result.rows });
  } catch (e) {
    next(e);
  }
}

export async function roles(_req, res, next) {
  try {
    const result = await query(`
      select r.*,
        coalesce(json_agg(json_build_object('module', rp.module, 'action', rp.action, 'allowed', rp.allowed) order by rp.module, rp.action) filter (where rp.id is not null), '[]'::json) as permissions
      from roles r
      left join role_permissions rp on rp.role_id = r.id
      group by r.id
      order by r.name
    `);
    res.json({ success: true, data: result.rows });
  } catch (e) {
    next(e);
  }
}

export async function createRole(req, res, next) {
  try {
    const { name, description, permissions = [] } = req.body;
    if (!name) throw new ApiError(422, "name is required");
    const result = await query(
      "insert into roles(name,description,status) values($1,$2,$3) returning *",
      [name, description || null, req.body.status || "active"],
    );
    for (const permission of permissions) {
      await query(
        `insert into role_permissions(role_id,module,action,allowed) values($1,$2,$3,$4)
         on conflict(role_id,module,action) do update set allowed=excluded.allowed, updated_at=now()`,
        [
          result.rows[0].id,
          permission.module,
          permission.action,
          permission.allowed !== false,
        ],
      );
    }
    await logAdminActivity(req, "create", "role", result.rows[0].id, null, {
      ...result.rows[0],
      permissions,
    });
    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (e) {
    next(e);
  }
}

export async function updateRole(req, res, next) {
  try {
    const before = await query("select * from roles where id=$1", [
      req.params.id,
    ]);
    const { name, description, permissions = [] } = req.body;
    const result = await query(
      "update roles set name=$2,description=$3,status=$4,updated_at=now() where id=$1 returning *",
      [req.params.id, name, description || null, req.body.status || "active"],
    );
    if (!result.rows[0]) throw notFound("Role");
    for (const permission of permissions) {
      await query(
        `insert into role_permissions(role_id,module,action,allowed) values($1,$2,$3,$4)
         on conflict(role_id,module,action) do update set allowed=excluded.allowed, updated_at=now()`,
        [
          req.params.id,
          permission.module,
          permission.action,
          permission.allowed !== false,
        ],
      );
    }
    await logAdminActivity(
      req,
      "update",
      "role",
      req.params.id,
      before.rows[0],
      { ...result.rows[0], permissions },
    );
    res.json({ success: true, data: result.rows[0] });
  } catch (e) {
    next(e);
  }
}

export async function deleteRole(req, res, next) {
  try {
    const before = await query("select * from roles where id=$1", [
      req.params.id,
    ]);
    const result = await query("delete from roles where id=$1 returning id", [
      req.params.id,
    ]);
    if (!result.rows[0]) throw notFound("Role");
    await logAdminActivity(
      req,
      "delete",
      "role",
      req.params.id,
      before.rows[0],
      null,
    );
    res.json({ success: true, data: { id: result.rows[0].id, deleted: true } });
  } catch (e) {
    next(e);
  }
}

export async function settings(_req, res, next) {
  try {
    res.json({
      success: true,
      data: {
        appName: "VyparHub",
        supportEmail: "support@vyparhub.com",
        supportPhone: "+91 98765 43210",
        currency: "INR",
        timeZone: "Asia/Kolkata",
        currentVersion: "2.1.0",
        minimumVersion: "2.0.0",
        maintenanceMode: false,
      },
    });
  } catch (e) {
    next(e);
  }
}

export async function saveSettings(req, res, next) {
  try {
    await logAdminActivity(req, "update", "settings", null, null, req.body);
    res.json({ success: true, data: { ...req.body, saved: true } });
  } catch (e) {
    next(e);
  }
}

export async function sendNotification(req, res, next) {
  try {
    const { title, message, audience, userIds } = req.body;
    if (!title || !message)
      throw new ApiError(422, "title and message are required");
    const data = await sendAdminNotification({
      title,
      body: message,
      audience: audience || "all",
      userIds: Array.isArray(userIds) ? userIds : [],
    });
    await logNotification({
      target: audience || "all",
      title,
      body: message,
      segment: { userIds: Array.isArray(userIds) ? userIds : [] },
      sentByAdminId: req.admin?.id || null,
      deliveryStatus: data.sent
        ? `sent:${data.count || 0}`
        : `skipped: ${data.reason || "unknown"}`,
    });
    await logAdminActivity(req, "send", "notification", null, null, {
      title,
      message,
      audience,
    });
    res.json({ success: true, data });
  } catch (e) {
    next(e);
  }
}

export async function updateReturnStatus(req, res, next) {
  try {
    const { status, notes, refundMethod = "wallet" } = req.body;
    if (!status) throw new ApiError(422, "status is required");
    const order = await query(
      "select id,user_id,total from orders where id=$1",
      [req.params.id],
    );
    if (!order.rows[0]) throw notFound("Order");
    const result = await query(
      `insert into refund_requests(order_id,customer_id,amount,reason,refund_method,status,admin_notes)
       values($1,$2,$3,$4,$5,$6,$7)
       on conflict do nothing
       returning *`,
      [
        order.rows[0].id,
        order.rows[0].user_id,
        order.rows[0].total,
        notes ?? "Admin-created return/refund request",
        refundMethod,
        status,
        notes ?? null,
      ],
    );
    await logAdminActivity(
      req,
      "create",
      "refund_request",
      result.rows[0]?.id || req.params.id,
      null,
      result.rows[0] || { orderId: req.params.id, status },
    );
    res.json({ success: true, data: result.rows[0] });
  } catch (e) {
    next(e);
  }
}

export async function createAdminUser(req, res, next) {
  try {
    const { name, email, password, roleId, status = "active" } = req.body;
    if (!name || !email || !password || !roleId)
      throw new ApiError(422, "name, email, password and roleId are required");
    const existing = await query(
      "select id from admins where lower(email)=lower($1)",
      [email],
    );
    if (existing.rows[0]) throw new ApiError(409, "Email already registered");
    const passwordHash = await bcrypt.hash(password, 12);
    const result = await query(
      "insert into admins(name,email,password_hash,role_id,status) values($1,$2,$3,$4,$5) returning id,name,email,role_id,status,created_at,updated_at",
      [name, email, passwordHash, roleId, status],
    );
    await logAdminActivity(
      req,
      "create",
      "admin_user",
      result.rows[0].id,
      null,
      result.rows[0],
    );
    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (e) {
    next(e);
  }
}

export async function updateAdminUser(req, res, next) {
  try {
    const before = await query(
      "select id,name,email,role_id,status from admins where id=$1",
      [req.params.id],
    );
    const { name, email, password, roleId, status } = req.body;
    const passwordHash = password ? await bcrypt.hash(password, 12) : null;
    const result = await query(
      `update admins set
        name=coalesce($2,name),
        email=coalesce($3,email),
        password_hash=coalesce($4,password_hash),
        role_id=coalesce($5,role_id),
        status=coalesce($6,status),
        updated_at=now()
      where id=$1
      returning id,name,email,role_id,status,created_at,updated_at`,
      [
        req.params.id,
        name || null,
        email || null,
        passwordHash,
        roleId || null,
        status || null,
      ],
    );
    if (!result.rows[0]) throw notFound("Admin user");
    await logAdminActivity(
      req,
      "update",
      "admin_user",
      req.params.id,
      before.rows[0],
      result.rows[0],
    );
    res.json({ success: true, data: result.rows[0] });
  } catch (e) {
    next(e);
  }
}

export async function createOffer(req, res, next) {
  try {
    const o = offerPayload(req.body);
    if (!o.title) throw new ApiError(422, "title is required");
    const result = await query(
      `insert into offers(title,subtitle,image_url,media_type,product_id,discount_percent,link_url,is_active,starts_at,ends_at,coupon_code,applies_to,category_id,max_discount,min_order_amount)
       values($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15) returning *`,
      [
        o.title,
        o.subtitle,
        o.imageUrl,
        o.mediaType,
        o.productId,
        o.discountPercent,
        o.linkUrl,
        o.isActive,
        o.startsAt,
        o.endsAt,
        o.couponCode,
        o.appliesTo,
        o.categoryId,
        o.maxDiscount,
        o.minOrderAmount,
      ],
    );
    await logAdminActivity(
      req,
      "create",
      "offer",
      result.rows[0].id,
      null,
      result.rows[0],
    );
    emitCustomers(
      result.rows[0].image_url ? "banner.created" : "coupon.created",
      { offerId: result.rows[0].id },
    );
    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (e) {
    next(e);
  }
}

export async function updateOffer(req, res, next) {
  try {
    const before = await query("select * from offers where id=$1", [
      req.params.id,
    ]);
    const o = offerPayload(req.body);
    const result = await query(
      `update offers set title=$2,subtitle=$3,image_url=$4,media_type=$5,product_id=$6,discount_percent=$7,link_url=$8,is_active=$9,starts_at=$10,ends_at=$11,coupon_code=$12,applies_to=$13,category_id=$14,max_discount=$15,min_order_amount=$16,updated_at=now()
       where id=$1 returning *`,
      [
        req.params.id,
        o.title,
        o.subtitle,
        o.imageUrl,
        o.mediaType,
        o.productId,
        o.discountPercent,
        o.linkUrl,
        o.isActive,
        o.startsAt,
        o.endsAt,
        o.couponCode,
        o.appliesTo,
        o.categoryId,
        o.maxDiscount,
        o.minOrderAmount,
      ],
    );
    if (!result.rows[0]) throw notFound("Offer");
    await logAdminActivity(
      req,
      "update",
      "offer",
      req.params.id,
      before.rows[0],
      result.rows[0],
    );
    emitCustomers(
      result.rows[0].image_url ? "banner.updated" : "coupon.updated",
      { offerId: req.params.id },
    );
    res.json({ success: true, data: result.rows[0] });
  } catch (e) {
    next(e);
  }
}

export async function deleteOffer(req, res, next) {
  try {
    const before = await query("select * from offers where id=$1", [
      req.params.id,
    ]);
    const result = await query("delete from offers where id=$1 returning id", [
      req.params.id,
    ]);
    if (!result.rows[0]) throw notFound("Offer");
    await logAdminActivity(
      req,
      "delete",
      "offer",
      req.params.id,
      before.rows[0],
      null,
    );
    emitCustomers(
      before.rows[0]?.image_url ? "banner.deleted" : "coupon.deleted",
      { offerId: req.params.id },
    );
    emitCustomers("catalog.updated", {
      reason: before.rows[0]?.image_url ? "banner.deleted" : "coupon.deleted",
      offerId: req.params.id,
    });
    res.json({ success: true, data: { id: result.rows[0].id, deleted: true } });
  } catch (e) {
    next(e);
  }
}

export async function customerDetail(req, res, next) {
  try {
    const customer = await query(
      "select id,name,shop_name,phone,address,area,pincode,fcm_token,created_at from users where id=$1 and role='customer'",
      [req.params.id],
    );
    if (!customer.rows[0]) throw notFound("Customer");
    const [addresses, ordersResult, wallet, walletTransactions, points] =
      await Promise.all([
        query(
          "select * from addresses where user_id=$1 order by is_default desc, created_at desc",
          [req.params.id],
        ),
        query(
          "select * from orders where user_id=$1 order by created_at desc limit 50",
          [req.params.id],
        ),
        query("select * from wallet_accounts where customer_id=$1", [
          req.params.id,
        ]),
        query(
          `select wt.* from wallet_transactions wt join wallet_accounts wa on wa.id=wt.wallet_account_id where wa.customer_id=$1 order by wt.created_at desc limit 100`,
          [req.params.id],
        ),
        query(
          "select * from loyalty_ledger where customer_id=$1 order by created_at desc limit 100",
          [req.params.id],
        ),
      ]);
    res.json({
      success: true,
      data: {
        customer: customer.rows[0],
        addresses: addresses.rows,
        orders: ordersResult.rows,
        wallet: wallet.rows[0] || { balance: 0 },
        walletTransactions: walletTransactions.rows,
        pointsLedger: points.rows,
      },
    });
  } catch (e) {
    next(e);
  }
}

export async function customerWalletTransactions(req, res, next) {
  try {
    const result = await query(
      `select wt.* from wallet_transactions wt
       join wallet_accounts wa on wa.id=wt.wallet_account_id
       where wa.customer_id=$1
       order by wt.created_at desc`,
      [req.params.id],
    );
    res.json({ success: true, data: result.rows });
  } catch (e) {
    next(e);
  }
}

export async function adjustCustomerWallet(req, res, next) {
  try {
    const { amount, type = "credit", reason = "Admin adjustment" } = req.body;
    if (!amount || Number(amount) <= 0)
      throw new ApiError(422, "positive amount is required");
    if (!["credit", "debit"].includes(type))
      throw new ApiError(422, "type must be credit or debit");
    const tx = await writeWalletTransaction({
      customerId: req.params.id,
      type,
      amount: numericValue(amount),
      reason: "admin_adjustment",
      referenceType: "admin_adjustment",
      referenceId: req.admin?.id,
      adminId: req.admin?.id,
    });
    await logAdminActivity(
      req,
      "adjust_wallet",
      "customer",
      req.params.id,
      null,
      { transaction: tx, reason },
    );
    res.json({ success: true, data: tx });
  } catch (e) {
    next(e);
  }
}

export async function adjustCustomerPoints(req, res, next) {
  try {
    const { points, type = "earned", reason = "Admin adjustment" } = req.body;
    if (!points || Number(points) <= 0)
      throw new ApiError(422, "positive points are required");
    if (!["earned", "redeemed", "expired"].includes(type))
      throw new ApiError(422, "invalid points type");
    const ledger = await writePointsLedger({
      customerId: req.params.id,
      points: numericValue(points),
      type,
      reason,
      referenceType: "admin_adjustment",
      referenceId: req.admin?.id,
    });
    await logAdminActivity(
      req,
      "adjust_points",
      "customer",
      req.params.id,
      null,
      ledger,
    );
    res.json({ success: true, data: ledger });
  } catch (e) {
    next(e);
  }
}

const tableMap = {
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

async function listTable(res, table, order = "created_at desc") {
  res.json({
    success: true,
    data: (await query(`select * from ${table} order by ${order}`)).rows,
  });
}

async function createMapped(req, res, next, key, entityType) {
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

async function updateMapped(req, res, next, key, entityType) {
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

async function deleteMapped(req, res, next, key, entityType) {
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

function emitMappedChange(entityType, action, row) {
  if (entityType === "delivery_zone") {
    emitCustomers(`delivery_zone.${action}`, {
      zoneId: row.id,
      zoneName: row.name,
    });
  }
}

export const loyaltyTiers = async (_req, res, next) => {
  try {
    await listTable(res, "loyalty_tiers", "min_points");
  } catch (e) {
    next(e);
  }
};
export const createLoyaltyTier = (req, res, next) =>
  createMapped(req, res, next, "loyaltyTiers", "loyalty_tier");
export const updateLoyaltyTier = (req, res, next) =>
  updateMapped(req, res, next, "loyaltyTiers", "loyalty_tier");
export const deleteLoyaltyTier = (req, res, next) =>
  deleteMapped(req, res, next, "loyaltyTiers", "loyalty_tier");
export const loyaltyRules = async (_req, res, next) => {
  try {
    await listTable(res, "loyalty_rules", "action");
  } catch (e) {
    next(e);
  }
};
export const createLoyaltyRule = (req, res, next) =>
  createMapped(req, res, next, "loyaltyRules", "loyalty_rule");
export const updateLoyaltyRule = (req, res, next) =>
  updateMapped(req, res, next, "loyaltyRules", "loyalty_rule");
export const deleteLoyaltyRule = (req, res, next) =>
  deleteMapped(req, res, next, "loyaltyRules", "loyalty_rule");
export const loyaltyRewards = async (_req, res, next) => {
  try {
    await listTable(res, "redeemable_rewards", "points_cost");
  } catch (e) {
    next(e);
  }
};
export const createLoyaltyReward = (req, res, next) =>
  createMapped(req, res, next, "loyaltyRewards", "redeemable_reward");
export const updateLoyaltyReward = (req, res, next) =>
  updateMapped(req, res, next, "loyaltyRewards", "redeemable_reward");
export const deleteLoyaltyReward = (req, res, next) =>
  deleteMapped(req, res, next, "loyaltyRewards", "redeemable_reward");
export const deliveryZones = async (_req, res, next) => {
  try {
    await listTable(res, "delivery_zones", "name");
  } catch (e) {
    next(e);
  }
};
export const createDeliveryZone = (req, res, next) =>
  createMapped(req, res, next, "deliveryZones", "delivery_zone");
export const updateDeliveryZone = (req, res, next) =>
  updateMapped(req, res, next, "deliveryZones", "delivery_zone");
export const deleteDeliveryZone = (req, res, next) =>
  deleteMapped(req, res, next, "deliveryZones", "delivery_zone");

export async function referrals(req, res, next) {
  try {
    const [events, settingsResult] = await Promise.all([
      query(`
        select re.*, ru.name as referrer_name, uu.name as referred_name
        from referral_events re
        left join users ru on ru.id = re.referrer_customer_id
        left join users uu on uu.id = re.referred_customer_id
        order by re.created_at desc
      `),
      query("select * from referral_settings where id=true"),
    ]);
    res.json({
      success: true,
      data: {
        settings: settingsResult.rows[0] || { reward_amount: 200 },
        events: events.rows,
      },
    });
  } catch (e) {
    next(e);
  }
}

export async function saveReferralSettings(req, res, next) {
  try {
    const rewardAmount = numericValue(
      req.body.rewardAmount ?? req.body.reward_amount,
      200,
    );
    const result = await query(
      "insert into referral_settings(id,reward_amount) values(true,$1) on conflict(id) do update set reward_amount=excluded.reward_amount,updated_at=now() returning *",
      [rewardAmount],
    );
    await logAdminActivity(
      req,
      "update",
      "referral_settings",
      null,
      null,
      result.rows[0],
    );
    res.json({ success: true, data: result.rows[0] });
  } catch (e) {
    next(e);
  }
}

export async function homeSections(_req, res, next) {
  try {
    const result = await query(`
      select hs.*,
        coalesce(json_agg(json_build_object('id', hsi.id, 'product_id', hsi.product_id, 'variant_id', hsi.variant_id, 'display_order', hsi.display_order, 'product_name', p.name_en) order by hsi.display_order)
          filter (where hsi.id is not null), '[]'::json) as items
      from home_sections hs
      left join home_section_items hsi on hsi.home_section_id = hs.id
      left join products p on p.id = hsi.product_id
      group by hs.id
      order by hs.display_order, hs.title
    `);
    res.json({ success: true, data: result.rows });
  } catch (e) {
    next(e);
  }
}

export async function saveHomeSection(req, res, next) {
  const client = await pool.connect();
  try {
    await client.query("begin");
    const adminId = await resolveAdminId(req.admin?.id, client);
    const {
      sectionKey,
      section_key,
      title,
      displayOrder,
      display_order,
      active = true,
      startsAt,
      starts_at,
      endsAt,
      ends_at,
      items = [],
    } = req.body;
    const resolvedSectionKey = String(sectionKey ?? section_key ?? "").trim();
    const resolvedTitle = String(title || "").trim();
    if (!resolvedSectionKey) throw new ApiError(422, "Section key is required");
    if (!resolvedTitle) throw new ApiError(422, "Section title is required");
    if (!Array.isArray(items)) throw new ApiError(422, "Section items must be an array");
    const before = req.params.id
      ? await client.query("select * from home_sections where id=$1", [
          req.params.id,
        ])
      : { rows: [] };
    const result = req.params.id
      ? await client.query(
          "update home_sections set section_key=$2,title=$3,display_order=$4,active=$5,starts_at=$6,ends_at=$7,updated_at=now() where id=$1 returning *",
          [
            req.params.id,
            resolvedSectionKey,
            resolvedTitle,
            displayOrder ?? display_order ?? 0,
            boolValue(active, true),
            startsAt ?? starts_at ?? null,
            endsAt ?? ends_at ?? null,
          ],
        )
      : await client.query(
          "insert into home_sections(section_key,title,display_order,active,starts_at,ends_at) values($1,$2,$3,$4,$5,$6) returning *",
          [
            resolvedSectionKey,
            resolvedTitle,
            displayOrder ?? display_order ?? 0,
            boolValue(active, true),
            startsAt ?? starts_at ?? null,
            endsAt ?? ends_at ?? null,
          ],
        );
    if (!result.rows[0]) throw notFound("Home section");
    await client.query(
      "delete from home_section_items where home_section_id=$1",
      [result.rows[0].id],
    );
    for (const [index, item] of items.entries()) {
      const productId = item.productId ?? item.product_id;
      if (!productId) throw new ApiError(422, "Every home section item needs a product");
      const productExists = await client.query(
        "select id from products where id=$1 and coalesce(is_active,true)=true",
        [productId],
      );
      if (!productExists.rows[0]) {
        throw new ApiError(422, "Selected home section product is not active or does not exist");
      }
      await client.query(
        "insert into home_section_items(home_section_id,product_id,variant_id,display_order) values($1,$2,$3,$4)",
        [
          result.rows[0].id,
          productId,
          item.variantId ?? item.variant_id ?? null,
          item.displayOrder ?? item.display_order ?? index,
        ],
      );
    }
    await client.query(
      `insert into admin_activity_log(admin_id,action,entity_type,entity_id,before_json,after_json)
       values($1,$2,$3,$4,$5,$6)`,
      [
        adminId,
        req.params.id ? "update" : "create",
        "home_section",
        result.rows[0].id,
        before.rows[0] || null,
        { ...result.rows[0], items },
      ],
    );
    await client.query("commit");
    emitCustomers("home_section.updated", {
      sectionId: result.rows[0].id,
      sectionKey: result.rows[0].section_key,
    });
    emitCustomers("catalog.updated", {
      reason: "home_section.updated",
      sectionId: result.rows[0].id,
      sectionKey: result.rows[0].section_key,
    });
    emitAdmin("home_section.updated", {
      sectionId: result.rows[0].id,
      sectionKey: result.rows[0].section_key,
    });
    res
      .status(req.params.id ? 200 : 201)
      .json({ success: true, data: result.rows[0] });
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

export async function deleteHomeSection(req, res, next) {
  try {
    const before = await query("select * from home_sections where id=$1", [
      req.params.id,
    ]);
    const result = await query(
      "delete from home_sections where id=$1 returning id",
      [req.params.id],
    );
    if (!result.rows[0]) throw notFound("Home section");
    await logAdminActivity(
      req,
      "delete",
      "home_section",
      req.params.id,
      before.rows[0],
      null,
    );
    emitCustomers("home_section.deleted", {
      sectionId: req.params.id,
      sectionKey: before.rows[0]?.section_key,
    });
    emitCustomers("catalog.updated", {
      reason: "home_section.deleted",
      sectionId: req.params.id,
      sectionKey: before.rows[0]?.section_key,
    });
    emitAdmin("home_section.deleted", {
      sectionId: req.params.id,
      sectionKey: before.rows[0]?.section_key,
    });
    res.json({ success: true, data: { id: req.params.id, deleted: true } });
  } catch (e) {
    next(e);
  }
}

export async function notificationHistory(_req, res, next) {
  try {
    res.json({
      success: true,
      data: (
        await query(
          "select * from notifications_log order by sent_at desc limit 200",
        )
      ).rows,
    });
  } catch (e) {
    next(e);
  }
}

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

export async function upload(req, res, next) {
  try {
    if (!req.file) throw new ApiError(422, "file is required");
    const safe = req.file.originalname.replace(/[^a-zA-Z0-9.\-_]/g, "-");
    const filename = `${Date.now()}-${safe}`;
    const storageUrl = process.env.SUPABASE_URL;
    const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
    const bucket = process.env.SUPABASE_STORAGE_BUCKET || "vyparhub-assets";
    let filePath;
    let url;

    if (storageUrl && serviceKey) {
      filePath = `admin/${filename}`;
      const uploadUrl = `${storageUrl.replace(/\/$/, "")}/storage/v1/object/${bucket}/${filePath}`;
      const response = await fetch(uploadUrl, {
        method: "POST",
        headers: {
          authorization: `Bearer ${serviceKey}`,
          apikey: serviceKey,
          "content-type": req.file.mimetype,
          "x-upsert": "true",
        },
        body: req.file.buffer,
      });
      if (!response.ok) {
        const text = await response.text();
        throw new ApiError(502, "Cloud storage upload failed", text);
      }
      url = `${storageUrl.replace(/\/$/, "")}/storage/v1/object/public/${bucket}/${filePath}`;
    } else if (process.env.NODE_ENV === "production") {
      throw new ApiError(500, "Persistent cloud storage is not configured");
    } else {
      await fs.promises.writeFile(
        path.join(uploadRoot, filename),
        req.file.buffer,
      );
      filePath = `/uploads/${filename}`;
      const origin = `${req.protocol}://${req.get("host")}`;
      url = `${origin}${filePath}`;
    }

    const origin = `${req.protocol}://${req.get("host")}`;
    await logAdminActivity(req, "upload", "file", null, null, {
      path: filePath,
      url,
      storage: storageUrl ? "supabase" : "local",
    });
    res
      .status(201)
      .json({
        success: true,
        data: { path: url.startsWith(origin) ? filePath : url, url },
      });
  } catch (e) {
    next(e);
  }
}
