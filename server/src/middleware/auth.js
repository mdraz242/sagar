import jwt from "jsonwebtoken";
import { ApiError } from "../utils/apiError.js";

const accessExpiry = () =>
  process.env.JWT_ACCESS_EXPIRES || process.env.JWT_ACCESS_EXPIRES_IN || "15m";

const refreshExpiry = () =>
  process.env.JWT_REFRESH_EXPIRES ||
  process.env.JWT_REFRESH_EXPIRES_IN ||
  "365d";

export function signAccess(user) {
  return jwt.sign(
    { sub: user.id, role: user.role },
    process.env.JWT_ACCESS_SECRET,
    { expiresIn: accessExpiry() },
  );
}

export function signRefresh(user) {
  return jwt.sign(
    { sub: user.id, role: user.role },
    process.env.JWT_REFRESH_SECRET,
    { expiresIn: refreshExpiry() },
  );
}

export function authenticate(req, res, next) {
  const h = req.headers.authorization || "";
  const token = h.startsWith("Bearer ") ? h.slice(7) : null;
  if (!token) return next(new ApiError(401, "Missing token"));
  try {
    req.user = jwt.verify(token, process.env.JWT_ACCESS_SECRET);
    next();
  } catch {
    next(new ApiError(401, "Invalid token"));
  }
}

export function authorize(...roles) {
  return (req, res, next) =>
    roles.includes(req.user?.role)
      ? next()
      : next(new ApiError(403, "Forbidden"));
}
