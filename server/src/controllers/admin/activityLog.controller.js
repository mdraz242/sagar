import { query } from "../../config/db.js";

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
