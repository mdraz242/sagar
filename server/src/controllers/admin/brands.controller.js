import { query } from "../../config/db.js";
import { emitCustomers } from "../../services/realtimeService.js";
import { ApiError, notFound } from "../../utils/apiError.js";
import { broadcastCatalogChange, idsFromBody, parseCsvRecords, assertImportSizeAndRows, validateCatalogImageUrl, logAdminActivity, brandPayload } from "./helpers.js";

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
    await broadcastCatalogChange("brand.updated", { imported });
    res.json({ success: true, data: { imported } });
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
    broadcastCatalogChange("brand.updated", {
      brandId: result.rows[0].id,
      brand: result.rows[0],
    });
    broadcastCatalogChange("catalog.updated", {
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
    broadcastCatalogChange("brand.updated", {
      brandId: req.params.id,
      brand: result.rows[0],
    });
    broadcastCatalogChange("catalog.updated", {
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
    broadcastCatalogChange("brand.deleted", {
      brandId: req.params.id,
      brandName: before.rows[0].name,
      productIds: affectedProducts.rows.map((row) => row.id),
    });
    broadcastCatalogChange("catalog.updated", {
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
    broadcastCatalogChange("brand.deleted", {
      brandIds: result.rows.map((row) => String(row.id)),
      productIds: affectedProducts.rows.map((row) => String(row.id)),
    });
    broadcastCatalogChange("catalog.updated", {
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
