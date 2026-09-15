import { query } from "../../config/db.js";
import { ApiError, notFound } from "../../utils/apiError.js";
import { logAdminActivity } from "./helpers.js";

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
