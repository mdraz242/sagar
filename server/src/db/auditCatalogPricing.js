import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { pool, query } from "../config/db.js";

function positiveNumber(value) {
  const number = Number(value);
  return Number.isFinite(number) && number > 0 ? number : null;
}

async function auditCatalogPricing() {
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
      if (positiveNumber(variant.mrp) === null) invalidFields.push("mrp");
      if (positiveNumber(variant.selling_price) === null) {
        invalidFields.push("selling_price");
      }
      if (positiveNumber(variant.pack_quantity) === null) {
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

  const report = {
    generatedAt: new Date().toISOString(),
    productsChecked: products.size,
    issueCount: issues.length,
    issues,
  };
  const __dirname = path.dirname(fileURLToPath(import.meta.url));
  const reportsDir = path.resolve(__dirname, "../../reports");
  fs.mkdirSync(reportsDir, { recursive: true });
  const outputPath = path.join(reportsDir, "catalog-pricing-health.json");
  fs.writeFileSync(outputPath, `${JSON.stringify(report, null, 2)}\n`);
  console.log(
    `Catalog pricing audit complete: ${report.productsChecked} products checked, ${report.issueCount} issue(s).`,
  );
  console.log(`Report written to ${outputPath}`);
}

auditCatalogPricing()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await pool.end();
  });
