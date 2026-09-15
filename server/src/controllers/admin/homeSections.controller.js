import { pool, query } from "../../config/db.js";
import { emitAdmin, emitCustomers } from "../../services/realtimeService.js";
import { ApiError, notFound } from "../../utils/apiError.js";
import { broadcastCatalogChange, boolValue, resolveAdminId, logAdminActivity } from "./helpers.js";

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
    broadcastCatalogChange("catalog.updated", {
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
    broadcastCatalogChange("catalog.updated", {
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
