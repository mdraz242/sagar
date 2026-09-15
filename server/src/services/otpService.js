import bcrypt from "bcryptjs";
import { query } from "../config/db.js";
import { ApiError } from "../utils/apiError.js";
import { createUser, findByPhone } from "../repositories/userRepository.js";
import { signAccess, signRefresh } from "../middleware/auth.js";

const provider = process.env.OTP_PROVIDER || "mock";
const ttlMinutes = Number.parseInt(
  process.env.OTP_CODE_TTL_MINUTES || "10",
  10,
);
const allowDevOtpBypass = () =>
  process.env.NODE_ENV !== "production" &&
  process.env.ALLOW_DEV_OTP_BYPASS === "true" &&
  Boolean(process.env.OTP_DEV_CODE);

function normalizePhone(phone) {
  return String(phone || "").replace(/\D/g, "");
}

function generateCode() {
  if (provider === "mock") {
    return process.env.OTP_DEV_CODE || "123456";
  }

  if (process.env.NODE_ENV !== "production" && process.env.OTP_DEV_CODE) {
    return process.env.OTP_DEV_CODE;
  }

  return String(Math.floor(100000 + Math.random() * 900000));
}

function validateIndiaProfile(body) {
  const pincode = String(body.pincode || "").trim();
  if (pincode && !/^\d{6}$/.test(pincode)) {
    throw new ApiError(422, "A valid 6 digit Indian pincode is required");
  }

  const addressText = [body.address, body.area, body.city, body.state]
    .filter(Boolean)
    .join(" ")
    .toLowerCase();
  if (
    addressText.includes("nepal") ||
    addressText.includes("kathmandu") ||
    addressText.includes("bagmati")
  ) {
    throw new ApiError(422, "VyparHub currently supports India only");
  }
}

async function sendViaMsg91(phone, code) {
  if (!process.env.MSG91_AUTH_KEY || !process.env.MSG91_TEMPLATE_ID) {
    return { provider: "mock", skipped: true };
  }

  const authKey = String(process.env.MSG91_AUTH_KEY || "").trim();
  const templateId = String(process.env.MSG91_TEMPLATE_ID || "").trim();
  const senderId = String(process.env.MSG91_SENDER_ID || "").trim();
  const msg91Phone = phone.length === 10 ? `91${phone}` : phone;
  const params = new URLSearchParams({
    template_id: templateId,
    mobile: msg91Phone,
    authkey: authKey,
    otp_expiry: String(ttlMinutes),
  });

  if (senderId) {
    params.set("sender", senderId);
  }

  // Only the variable actually defined in the DLT-approved OTP template
  // ("##OTP##") should be sent here. Extra keys that don't match a template
  // variable are ignored by MSG91, but keeping the payload exact avoids
  // ambiguity while we're debugging template issues.
  const requestBody = {
    OTP: code,
  };

  const response = await fetch(`https://control.msg91.com/api/v5/otp?${params}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      authkey: authKey,
    },
    body: JSON.stringify(requestBody),
  });

  const text = await response.text();
  let payload = null;
  try {
    payload = text ? JSON.parse(text) : null;
  } catch {
    payload = null;
  }

  // Log enough to diagnose provider-side rejections from Render logs without
  // printing the auth key or the OTP code itself.
  console.log("[msg91] sendOTP response", {
    status: response.status,
    templateId,
    mobile: msg91Phone,
    payload,
  });

  if (!response.ok) {
    throw new ApiError(502, "OTP provider failed", {
      status: response.status,
      message: payload?.message || text,
    });
  }

  const responseType = String(
    payload?.type || payload?.status || "",
  ).toLowerCase();
  if (
    payload &&
    responseType &&
    !["success", "sent", "true"].includes(responseType)
  ) {
    throw new ApiError(502, payload.message || "OTP provider did not send SMS", {
      provider: "msg91",
      response: payload,
    });
  }

  return {
    provider: "msg91",
    requestId: payload?.request_id || payload?.requestId || null,
  };
}

export async function requestOtp(body) {
  const phone = normalizePhone(body.phone);

  if (phone.length < 10) {
    throw new ApiError(422, "Valid phone number is required");
  }

  const code = generateCode();
  const codeHash = await bcrypt.hash(code, 10);

  await query(
    `
      insert into otp_codes(phone, code_hash, expires_at)
      values($1, $2, now() + ($3 || ' minutes')::interval)
    `,
    [phone, codeHash, ttlMinutes],
  );

  const sendResult =
    provider === "msg91"
      ? await sendViaMsg91(phone, code)
      : { provider: "mock" };
  const data = {
    phone,
    expiresInSeconds: ttlMinutes * 60,
    provider: sendResult.provider,
  };

  if (allowDevOtpBypass()) {
    data.devCode = code;
  }

  return data;
}

export async function verifyOtp(body) {
  const phone = normalizePhone(body.phone);
  const code = String(body.code || "").trim();
  validateIndiaProfile(body);

  if (phone.length < 10 || code.length !== 6) {
    throw new ApiError(422, "Valid phone number and 6 digit OTP are required");
  }

  const otpResult = await query(
    `
      select *
      from otp_codes
      where phone = $1
        and consumed_at is null
        and expires_at > now()
      order by created_at desc
      limit 1
    `,
    [phone],
  );

  const otp = otpResult.rows[0];

  if (!otp && allowDevOtpBypass() && code === process.env.OTP_DEV_CODE) {
    return upsertOtpUserSession(phone, body);
  }

  if (!otp) {
    throw new ApiError(401, "OTP expired or not requested");
  }

  if (Number(otp.attempts) >= 5) {
    throw new ApiError(429, "Too many OTP attempts");
  }

  const ok = await bcrypt.compare(code, otp.code_hash);

  if (!ok) {
    await query("update otp_codes set attempts = attempts + 1 where id = $1", [
      otp.id,
    ]);
    throw new ApiError(401, "Invalid OTP");
  }

  const session = await upsertOtpUserSession(phone, body);
  await query("update otp_codes set consumed_at = now() where id = $1", [
    otp.id,
  ]);
  return session;
}

async function upsertOtpUserSession(phone, body) {
  let user = await findByPhone(phone);

  if (!user) {
    const requiredFields = [
      ["name", "Owner name is required for signup"],
      ["shopName", "Shop name is required for signup"],
      ["password", "Password is required for signup"],
      ["address", "Shop address is required for signup"],
      ["area", "City or area is required for signup"],
      ["pincode", "Pincode is required for signup"],
    ];
    for (const [field, message] of requiredFields) {
      if (!String(body[field] || "").trim()) throw new ApiError(422, message);
    }
    if (String(body.password).trim().length < 6) {
      throw new ApiError(422, "Password must be at least 6 characters");
    }

    const passwordHash = await bcrypt.hash(
      body.password || `otp:${phone}:${Date.now()}`,
      12,
    );
    user = await createUser({
      name: body.name || "VyparHub User",
      shopName: body.shopName || "Retail Store",
      phone,
      passwordHash,
      address: body.address || "Address pending",
      area: body.area || "Area pending",
      pincode: body.pincode || "",
      role: "customer",
    });
  }

  const publicUser = {
    id: user.id,
    name: user.name,
    shopName: user.shop_name || user.shopName,
    phone: user.phone,
    role: user.role,
  };

  return {
    user: publicUser,
    accessToken: signAccess(user),
    refreshToken: signRefresh(user),
  };
}
