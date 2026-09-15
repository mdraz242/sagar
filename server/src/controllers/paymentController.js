import crypto from "crypto";
import Razorpay from "razorpay";
import { pool, query } from "../config/db.js";
import { notifyOrderStatus } from "../services/notificationService.js";
import { emitAdmin, emitCustomer } from "../services/realtimeService.js";
import { ApiError, notFound } from "../utils/apiError.js";

function razorpayClient() {
  const keyId = process.env.RAZORPAY_KEY_ID;
  const keySecret = process.env.RAZORPAY_KEY_SECRET;
  if (!keyId || !keySecret) {
    throw new ApiError(500, "Razorpay is not configured");
  }
  return new Razorpay({ key_id: keyId, key_secret: keySecret });
}

function verifyWebhookSignature(rawBody, signature) {
  const secret = process.env.RAZORPAY_WEBHOOK_SECRET;
  if (!secret)
    throw new ApiError(500, "Razorpay webhook secret is not configured");
  if (!signature) throw new ApiError(400, "Missing Razorpay signature");

  const expected = crypto
    .createHmac("sha256", secret)
    .update(rawBody)
    .digest("hex");
  const expectedBuffer = Buffer.from(expected);
  const actualBuffer = Buffer.from(signature);

  if (
    expectedBuffer.length !== actualBuffer.length ||
    !crypto.timingSafeEqual(expectedBuffer, actualBuffer)
  ) {
    throw new ApiError(400, "Invalid Razorpay signature");
  }
}

async function loadOwnedOrder(orderId, userId) {
  const result = await query(
    "select id, user_id, total, status from orders where id = $1 and user_id = $2",
    [orderId, userId],
  );
  return result.rows[0];
}

export async function createRazorpayOrder(req, res, next) {
  try {
    const { orderId } = req.body;
    if (!orderId) throw new ApiError(422, "orderId is required");

    const order = await loadOwnedOrder(orderId, req.user.sub);
    if (!order) throw notFound("Order");
    if (order.status === "confirmed") {
      throw new ApiError(409, "Order is already confirmed");
    }

    const amount = Math.round(Number(order.total) * 100);
    if (amount <= 0)
      throw new ApiError(422, "Order amount must be greater than zero");

    const razorpayOrder = await razorpayClient().orders.create({
      amount,
      currency: "INR",
      receipt: order.id,
      notes: {
        internalOrderId: order.id,
        userId: req.user.sub,
      },
    });

    await query(
      `
        insert into payments(order_id, mode, status, amount, provider_ref)
        values($1, 'razorpay', 'created', $2, $3)
      `,
      [order.id, Number(order.total), razorpayOrder.id],
    );

    res.status(201).json({
      success: true,
      data: {
        keyId: process.env.RAZORPAY_KEY_ID,
        razorpayOrderId: razorpayOrder.id,
        amount,
        currency: "INR",
        internalOrderId: order.id,
      },
    });
  } catch (error) {
    next(error);
  }
}

export async function webhook(req, res, next) {
  const client = await pool.connect();

  try {
    verifyWebhookSignature(
      req.rawBody ?? JSON.stringify(req.body),
      req.headers["x-razorpay-signature"],
    );

    const event = req.body;
    const payment = event?.payload?.payment?.entity;
    const razorpayOrderId = payment?.order_id;

    if (event.event !== "payment.captured" || !payment || !razorpayOrderId) {
      res.json({ success: true, data: { ignored: true } });
      return;
    }

    await client.query("begin");

    const existing = await client.query(
      "select order_id from payments where provider_ref = $1 order by created_at desc limit 1",
      [razorpayOrderId],
    );

    const orderId =
      existing.rows[0]?.order_id ?? payment.notes?.internalOrderId;
    if (!orderId)
      throw new ApiError(422, "Internal order id not found for payment");

    await client.query(
      `
        insert into payments(order_id, mode, status, amount, provider_ref)
        values($1, 'razorpay', 'paid', $2, $3)
      `,
      [orderId, Number(payment.amount ?? 0) / 100, payment.id],
    );

    await client.query(
      "update orders set status = 'confirmed', updated_at = now() where id = $1",
      [orderId],
    );
    await client.query(
      "insert into order_status_history(order_id,status) values($1,'confirmed')",
      [orderId],
    );

    await client.query("commit");
    await notifyOrderStatus(orderId, "confirmed");
    emitAdmin("order.status_changed", { orderId, status: "confirmed" });
    emitCustomer(order.user_id, "order.status_changed", {
      orderId,
      status: "confirmed",
    });

    res.json({ success: true, data: { orderId, status: "confirmed" } });
  } catch (error) {
    await client.query("rollback");
    next(error);
  } finally {
    client.release();
  }
}
