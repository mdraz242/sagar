import { query } from "../config/db.js";

export const adminDataModels = {
  brands: {
    table: "brands",
    columns: ["name", "logo_url", "status", "is_active"],
  },
  productVariants: {
    table: "product_variants",
    columns: [
      "product_id",
      "variant_name",
      "sku",
      "mrp",
      "selling_price",
      "stock_quantity",
      "unit",
      "is_default",
      "status",
    ],
  },
  walletAccounts: {
    table: "wallet_accounts",
    columns: ["customer_id"],
  },
  walletTransactions: {
    table: "wallet_transactions",
    columns: [
      "wallet_account_id",
      "type",
      "amount",
      "reason",
      "reference_type",
      "reference_id",
      "created_by",
    ],
    hasUpdatedAt: false,
  },
  loyaltyTiers: {
    table: "loyalty_tiers",
    columns: ["name", "min_points", "benefits_json"],
  },
  loyaltyRules: {
    table: "loyalty_rules",
    columns: ["action", "points_awarded", "active"],
  },
  loyaltyLedger: {
    table: "loyalty_ledger",
    columns: [
      "customer_id",
      "points",
      "type",
      "reason",
      "reference_type",
      "reference_id",
      "expires_at",
    ],
    hasUpdatedAt: false,
  },
  redeemableRewards: {
    table: "redeemable_rewards",
    columns: [
      "title",
      "points_cost",
      "reward_type",
      "reward_value_json",
      "active",
      "stock_limit",
    ],
  },
  referralCodes: {
    table: "referral_codes",
    columns: ["customer_id", "code"],
    hasUpdatedAt: false,
  },
  referralEvents: {
    table: "referral_events",
    columns: [
      "referrer_customer_id",
      "referred_customer_id",
      "status",
      "reward_amount",
    ],
    hasUpdatedAt: false,
  },
  deliveryZones: {
    table: "delivery_zones",
    columns: [
      "name",
      "pincodes_json",
      "estimated_delivery_minutes",
      "delivery_fee",
      "free_delivery_min_order",
      "active",
    ],
  },
  homeSections: {
    table: "home_sections",
    columns: [
      "section_key",
      "title",
      "display_order",
      "active",
      "starts_at",
      "ends_at",
    ],
  },
  homeSectionItems: {
    table: "home_section_items",
    columns: ["home_section_id", "product_id", "variant_id", "display_order"],
    hasUpdatedAt: false,
  },
  adminActivityLog: {
    table: "admin_activity_log",
    columns: [
      "admin_id",
      "action",
      "entity_type",
      "entity_id",
      "before_json",
      "after_json",
    ],
    hasUpdatedAt: false,
  },
  notificationsLog: {
    table: "notifications_log",
    columns: [
      "target",
      "title",
      "body",
      "segment_json",
      "sent_by_admin_id",
      "delivery_status",
    ],
    hasUpdatedAt: false,
  },
};

function modelConfig(model) {
  const config = adminDataModels[model];
  if (!config) throw new Error(`Unknown admin data model: ${model}`);
  return config;
}

function valuesFor(config, data) {
  const columns = config.columns.filter((column) =>
    Object.prototype.hasOwnProperty.call(data, column),
  );
  const values = columns.map((column) => data[column]);
  return { columns, values };
}

export async function listRecords(model, { limit = 100, offset = 0 } = {}) {
  const config = modelConfig(model);
  const result = await query(
    `select * from ${config.table} order by created_at desc limit $1 offset $2`,
    [limit, offset],
  );
  return result.rows;
}

export async function getRecord(model, id) {
  const config = modelConfig(model);
  const result = await query(`select * from ${config.table} where id=$1`, [id]);
  return result.rows[0] || null;
}

export async function createRecord(model, data) {
  const config = modelConfig(model);
  const { columns, values } = valuesFor(config, data);
  if (!columns.length)
    throw new Error(`No writable fields supplied for ${model}`);
  const placeholders = columns.map((_, index) => `$${index + 1}`).join(", ");
  const result = await query(
    `insert into ${config.table}(${columns.join(", ")}) values(${placeholders}) returning *`,
    values,
  );
  return result.rows[0];
}

export async function updateRecord(model, id, data) {
  const config = modelConfig(model);
  const { columns, values } = valuesFor(config, data);
  if (!columns.length) return getRecord(model, id);
  const assignments = columns.map((column, index) => `${column}=$${index + 2}`);
  if (config.hasUpdatedAt !== false) assignments.push("updated_at=now()");
  const result = await query(
    `update ${config.table} set ${assignments.join(", ")} where id=$1 returning *`,
    [id, ...values],
  );
  return result.rows[0] || null;
}

export async function deleteRecord(model, id) {
  const config = modelConfig(model);
  const result = await query(
    `delete from ${config.table} where id=$1 returning id`,
    [id],
  );
  return result.rows[0] || null;
}

export async function reconcileWallet(walletAccountId) {
  await query("select reconcile_wallet_balance($1)", [walletAccountId]);
  return getRecord("walletAccounts", walletAccountId);
}

export async function refreshStartingPrice(productId) {
  await query("select refresh_product_starting_price($1)", [productId]);
  const result = await query("select * from products where id=$1", [productId]);
  return result.rows[0] || null;
}
