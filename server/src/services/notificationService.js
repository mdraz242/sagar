import { getMessaging } from "firebase-admin/messaging";
import { query } from "../config/db.js";
import { getFirebaseApp } from "./firebaseService.js";

export function orderStatusNotification(status, orderId) {
  const shortId = String(orderId).slice(0, 8).toUpperCase();
  const copy = {
    placed: ["Order Placed", `Your order #${shortId} has been placed.`],
    confirmed: [
      "Order Confirmed",
      `Your order #${shortId} has been confirmed.`,
    ],
    packed: ["Order Packed", `Your order #${shortId} has been packed.`],
    shipped: ["Order Shipped", `Your order #${shortId} is on the way.`],
    out_for_delivery: [
      "Out for Delivery",
      `Your order #${shortId} is out for delivery.`,
    ],
    delivered: [
      "Order Delivered",
      `Your order #${shortId} has been delivered.`,
    ],
    cancelled: [
      "Order Cancelled",
      `Your order #${shortId} has been cancelled.`,
    ],
  };
  const [title, body] = copy[String(status)] || [
    "VyparHub order update",
    `Your order #${shortId} is ${String(status).replaceAll("_", " ")}.`,
  ];
  return { title, body };
}

export async function notifyOrderStatus(orderId, status) {
  const app = getFirebaseApp();
  if (!app) return { sent: false, reason: "Firebase Admin is not configured" };

  const result = await query(
    `
      select u.fcm_token
      from orders o
      join users u on u.id = o.user_id
      where o.id = $1
    `,
    [orderId],
  );

  const token = result.rows[0]?.fcm_token;
  if (!token) return { sent: false, reason: "User has no FCM token" };
  const message = orderStatusNotification(status, orderId);

  await getMessaging(app).send({
    token,
    notification: message,
    data: {
      type: "order_status",
      orderId: String(orderId),
      status: String(status),
      route: `/orders/${String(orderId)}/tracking`,
      title: message.title,
      body: message.body,
    },
  });

  return { sent: true, ...message };
}

export async function notifyUser(userId, { title, body, data = {} }) {
  const app = getFirebaseApp();
  if (!app) return { sent: false, reason: "Firebase Admin is not configured" };

  const result = await query("select fcm_token from users where id=$1", [
    userId,
  ]);
  const token = result.rows[0]?.fcm_token;
  if (!token) return { sent: false, reason: "User has no FCM token" };

  await getMessaging(app).send({
    token,
    notification: { title, body },
    data: Object.fromEntries(
      Object.entries(data).map(([key, value]) => [key, String(value)]),
    ),
  });

  return { sent: true };
}

export async function sendAdminNotification({
  title,
  body,
  audience = "all",
  userIds = [],
}) {
  const app = getFirebaseApp();
  if (!app)
    return {
      sent: false,
      count: 0,
      reason: "Firebase Admin is not configured",
    };

  const params = [];
  let where = "where fcm_token is not null and fcm_token <> ''";
  if (audience === "specific" && userIds.length) {
    params.push(userIds);
    where += ` and id = any($${params.length}::uuid[])`;
  }

  const result = await query(`select fcm_token from users ${where}`, params);
  const tokens = result.rows.map((row) => row.fcm_token).filter(Boolean);
  if (!tokens.length)
    return {
      sent: false,
      count: 0,
      reason: "No matching users have FCM tokens",
    };

  const response = await getMessaging(app).sendEachForMulticast({
    tokens,
    notification: { title, body },
    data: {
      source: "admin",
      audience: String(audience),
    },
  });

  return {
    sent: true,
    count: response.successCount,
    failed: response.failureCount,
  };
}
