import { query } from "../../config/db.js";
import { emitCustomers } from "../../services/realtimeService.js";
import { ApiError, notFound } from "../../utils/apiError.js";
import { broadcastCatalogChange, logAdminActivity, offerPayload } from "./helpers.js";

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
    broadcastCatalogChange("catalog.updated", {
      reason: before.rows[0]?.image_url ? "banner.deleted" : "coupon.deleted",
      offerId: req.params.id,
    });
    res.json({ success: true, data: { id: result.rows[0].id, deleted: true } });
  } catch (e) {
    next(e);
  }
}
