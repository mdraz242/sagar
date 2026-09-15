import { query } from "../../config/db.js";
import { emitAdmin, emitCustomers } from "../../services/realtimeService.js";
import { ApiError, notFound } from "../../utils/apiError.js";
import { broadcastCatalogChange, slugValue, importVariantSku, csvCell, PRODUCT_IMPORT_HEADERS, PRODUCT_IMPORT_REQUIRED_COLUMNS, idsFromBody, parseCsvRecords, parseCsvHeaders, parsePackQuantity, csvBoolean, assertImportSizeAndRows, buildProductImportReport, validateCatalogImageUrl, importFailureReason, logAdminActivity, variantPayload, productPayload, emitProductRealtime, validateProductPayloadForSave, validateVariantPayloadForSave, assertImportedCatalogVisible, ensureSingleDefaultVariant } from "./helpers.js";

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
    broadcastCatalogChange("product.deleted", {
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
    broadcastCatalogChange("product.deleted", {
      productIds: result.rows.map((row) => String(row.id)),
      deleted: true,
    });
    broadcastCatalogChange("catalog.updated", {
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
      broadcastCatalogChange("category.updated", { categoryId });
    }
    for (const brandId of brandIds) {
      broadcastCatalogChange("brand.updated", { brandId });
    }
    broadcastCatalogChange("catalog.updated", {
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
