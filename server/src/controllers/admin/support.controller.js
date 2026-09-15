import { query } from "../../config/db.js";

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
