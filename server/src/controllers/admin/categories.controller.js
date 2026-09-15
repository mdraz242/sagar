import { query } from "../../config/db.js";
import { emitCustomers } from "../../services/realtimeService.js";
import { ApiError, notFound } from "../../utils/apiError.js";
import { broadcastCatalogChange, slugValue, numericValue, idsFromBody, parseCsvRecords, assertImportSizeAndRows, validateCatalogImageUrl, logAdminActivity, categoryPayload } from "./helpers.js";

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
    await broadcastCatalogChange("category.updated", { imported });
    res.json({ success: true, data: { imported } });
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
    broadcastCatalogChange("category.updated", {
      categoryId: result.rows[0].id,
      category: result.rows[0],
    });
    broadcastCatalogChange("catalog.updated", {
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
    broadcastCatalogChange("category.updated", {
      categoryId: req.params.id,
      category: result.rows[0],
    });
    broadcastCatalogChange("catalog.updated", {
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
    broadcastCatalogChange("category.deleted", {
      categoryId: req.params.id,
      productIds: affectedProducts.rows.map((row) => row.id),
    });
    broadcastCatalogChange("catalog.updated", {
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
    broadcastCatalogChange("category.deleted", {
      categoryIds: result.rows.map((row) => String(row.id)),
      productIds: affectedProducts.rows.map((row) => String(row.id)),
    });
    broadcastCatalogChange("catalog.updated", {
      reason: "categories.bulk_deleted",
      categoryIds: result.rows.map((row) => String(row.id)),
      productIds: affectedProducts.rows.map((row) => String(row.id)),
    });
    res.json({ success: true, data: { deleted: result.rowCount, affectedProducts: affectedProducts.rowCount } });
  } catch (e) {
    next(e);
  }
}
