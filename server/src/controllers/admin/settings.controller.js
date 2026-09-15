import { logAdminActivity } from "./helpers.js";

export async function settings(_req, res, next) {
  try {
    res.json({
      success: true,
      data: {
        appName: "VyparHub",
        supportEmail: "support@vyparhub.com",
        supportPhone: "+91 98765 43210",
        currency: "INR",
        timeZone: "Asia/Kolkata",
        currentVersion: "2.1.0",
        minimumVersion: "2.0.0",
        maintenanceMode: false,
      },
    });
  } catch (e) {
    next(e);
  }
}

export async function saveSettings(req, res, next) {
  try {
    await logAdminActivity(req, "update", "settings", null, null, req.body);
    res.json({ success: true, data: { ...req.body, saved: true } });
  } catch (e) {
    next(e);
  }
}
