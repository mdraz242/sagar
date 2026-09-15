import jwt from "jsonwebtoken";
import { query } from "../config/db.js";
import { ApiError } from "../utils/apiError.js";

const accessSecret = () =>
  process.env.ADMIN_JWT_ACCESS_SECRET ||
  `${process.env.JWT_ACCESS_SECRET}-admin`;
const refreshSecret = () =>
  process.env.ADMIN_JWT_REFRESH_SECRET ||
  `${process.env.JWT_REFRESH_SECRET}-admin`;
const accessExpires = () => process.env.ADMIN_JWT_ACCESS_EXPIRES || "15m";
const refreshExpires = () => process.env.ADMIN_JWT_REFRESH_EXPIRES || "7d";
const audience = "vyparhub-admin";

export function signAdminAccess(admin) {
  return jwt.sign(
    {
      sub: admin.id,
      roleId: admin.role_id,
      role: admin.role_name,
      scope: "admin",
    },
    accessSecret(),
    { expiresIn: accessExpires(), audience },
  );
}

export function signAdminRefresh(admin) {
  return jwt.sign(
    {
      sub: admin.id,
      roleId: admin.role_id,
      role: admin.role_name,
      scope: "admin-refresh",
    },
    refreshSecret(),
    { expiresIn: refreshExpires(), audience },
  );
}

export async function requireAdminAuth(req, _res, next) {
  const header = req.headers.authorization || "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : null;
  if (!token) return next(new ApiError(401, "Missing admin token"));

  try {
    const payload = jwt.verify(token, accessSecret(), { audience });
    if (payload.scope !== "admin") throw new Error("Invalid scope");
    const admin = await query(
      `select a.id, a.name, a.email, a.status, a.role_id, r.name as role_name
       from admins a
       left join roles r on r.id = a.role_id
       where a.id=$1 and a.status='active'`,
      [payload.sub],
    );
    if (!admin.rows[0]) throw new ApiError(401, "Admin account is inactive");
    req.admin = admin.rows[0];
    next();
  } catch (error) {
    next(
      error instanceof ApiError
        ? error
        : new ApiError(401, "Invalid admin token"),
    );
  }
}

export function requirePermission(module, action = "view") {
  return async (req, _res, next) => {
    try {
      if (!req.admin?.role_id) throw new ApiError(401, "Admin auth required");
      if (req.admin.role_name === "Super Admin") return next();
      const allowed = await query(
        `select allowed from role_permissions where role_id=$1 and module=$2 and action=$3`,
        [req.admin.role_id, module, action],
      );
      if (allowed.rows[0]?.allowed) return next();
      next(new ApiError(403, `Permission denied: ${module}.${action}`));
    } catch (error) {
      next(error);
    }
  };
}

export function requireAnyPermission(...checks) {
  return async (req, _res, next) => {
    try {
      if (!req.admin?.role_id) throw new ApiError(401, "Admin auth required");
      if (req.admin.role_name === "Super Admin") return next();
      const result = await query(
        `select 1
         from role_permissions
         where role_id=$1
           and allowed=true
           and (${checks.map((_, index) => `(module=$${index * 2 + 2} and action=$${index * 2 + 3})`).join(" or ")})
         limit 1`,
        [
          req.admin.role_id,
          ...checks.flatMap((check) => [check.module, check.action]),
        ],
      );
      if (result.rows[0]) return next();
      next(new ApiError(403, "Permission denied"));
    } catch (error) {
      next(error);
    }
  };
}
