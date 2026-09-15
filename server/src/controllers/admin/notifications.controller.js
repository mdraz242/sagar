import { query } from "../../config/db.js";
import { sendAdminNotification } from "../../services/notificationService.js";
import { ApiError } from "../../utils/apiError.js";
import { logAdminActivity, logNotification } from "./helpers.js";

export async function sendNotification(req, res, next) {
  try {
    const { title, message, audience, userIds } = req.body;
    if (!title || !message)
      throw new ApiError(422, "title and message are required");
    const data = await sendAdminNotification({
      title,
      body: message,
      audience: audience || "all",
      userIds: Array.isArray(userIds) ? userIds : [],
    });
    await logNotification({
      target: audience || "all",
      title,
      body: message,
      segment: { userIds: Array.isArray(userIds) ? userIds : [] },
      sentByAdminId: req.admin?.id || null,
      deliveryStatus: data.sent
        ? `sent:${data.count || 0}`
        : `skipped: ${data.reason || "unknown"}`,
    });
    await logAdminActivity(req, "send", "notification", null, null, {
      title,
      message,
      audience,
    });
    res.json({ success: true, data });
  } catch (e) {
    next(e);
  }
}

export async function notificationHistory(_req, res, next) {
  try {
    res.json({
      success: true,
      data: (
        await query(
          "select * from notifications_log order by sent_at desc limit 200",
        )
      ).rows,
    });
  } catch (e) {
    next(e);
  }
}
