import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { signAccess, signRefresh } from "../middleware/auth.js";
import {
  createUser,
  findById,
  findByPhone,
} from "../repositories/userRepository.js";
import { ApiError } from "../utils/apiError.js";

function toPublicUser(user) {
  return {
    id: user.id,
    name: user.name,
    shopName: user.shopName ?? user.shop_name,
    phone: user.phone,
    address: user.address,
    area: user.area,
    pincode: user.pincode,
    role: user.role,
  };
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

export async function register(body) {
  validateIndiaProfile(body);
  if (await findByPhone(body.phone)) {
    throw new ApiError(409, "Phone already registered");
  }

  const passwordHash = await bcrypt.hash(body.password, 12);
  const user = await createUser({ ...body, passwordHash });

  return {
    user: toPublicUser(user),
    accessToken: signAccess(user),
    refreshToken: signRefresh(user),
  };
}

export async function login(body) {
  const user = await findByPhone(body.phone);
  if (!user || !(await bcrypt.compare(body.password, user.password_hash))) {
    throw new ApiError(401, "Invalid phone or password");
  }

  return {
    user: toPublicUser(user),
    accessToken: signAccess(user),
    refreshToken: signRefresh(user),
  };
}

export async function lookup(body) {
  const phone = String(body.phone || "").replace(/\D/g, "");
  if (phone.length < 10)
    throw new ApiError(422, "Valid phone number is required");

  return { phone, registered: Boolean(await findByPhone(phone)) };
}

export async function refresh(body) {
  const token = body?.refreshToken;
  if (!token) throw new ApiError(400, "Refresh token is required");

  try {
    const payload = jwt.verify(token, process.env.JWT_REFRESH_SECRET);
    const user = await findById(payload.sub);
    if (!user) throw new ApiError(401, "Invalid refresh token");

    return {
      user: toPublicUser(user),
      accessToken: signAccess(user),
      refreshToken: signRefresh(user),
    };
  } catch (error) {
    if (error instanceof ApiError) throw error;
    throw new ApiError(401, "Invalid refresh token");
  }
}
