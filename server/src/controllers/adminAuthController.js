import bcrypt from "bcryptjs";
import crypto from "crypto";
import jwt from "jsonwebtoken";
import { query } from "../config/db.js";
import { signAdminAccess, signAdminRefresh } from "../middleware/adminAuth.js";
import { ApiError } from "../utils/apiError.js";

const refreshSecret = () =>
  process.env.ADMIN_JWT_REFRESH_SECRET ||
  `${process.env.JWT_REFRESH_SECRET}-admin`;
const audience = "vyparhub-admin";

function publicAdmin(admin, permissions = []) {
  return {
    id: admin.id,
    name: admin.name,
    email: admin.email,
    roleId: admin.role_id,
    role: admin.role_name,
    permissions,
  };
}

async function loadPermissions(roleId) {
  const result = await query(
    "select module, action, allowed from role_permissions where role_id=$1 order by module, action",
    [roleId],
  );
  return result.rows;
}

async function verifyPassword(email, password, passwordHash) {
  if (String(passwordHash || "").startsWith("$2")) {
    return bcrypt.compare(password, passwordHash);
  }
  const cryptResult = await query("select $1 = crypt($2, $1) as ok", [
    passwordHash,
    password,
  ]);
  return Boolean(cryptResult.rows[0]?.ok);
}

async function issueTokens(admin) {
  const accessToken = signAdminAccess(admin);
  const refreshToken = signAdminRefresh(admin);
  const refreshHash = crypto
    .createHash("sha256")
    .update(refreshToken)
    .digest("hex");
  await query(
    "update admins set refresh_token_hash=$2,last_login_at=now(),updated_at=now() where id=$1",
    [admin.id, refreshHash],
  );
  const permissions = await loadPermissions(admin.role_id);
  return { admin: publicAdmin(admin, permissions), accessToken, refreshToken };
}

export async function login(req, res, next) {
  try {
    const { email, password } = req.body;
    if (!email || !password)
      throw new ApiError(422, "email and password are required");
    const result = await query(
      `select a.*, r.name as role_name
       from admins a
       left join roles r on r.id = a.role_id
       where lower(a.email)=lower($1)`,
      [email],
    );
    const admin = result.rows[0];
    if (
      !admin ||
      admin.status !== "active" ||
      !(await verifyPassword(email, password, admin.password_hash))
    ) {
      throw new ApiError(401, "Invalid admin email or password");
    }
    res.json({ success: true, data: await issueTokens(admin) });
  } catch (error) {
    next(error);
  }
}

export async function refresh(req, res, next) {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) throw new ApiError(422, "refreshToken is required");
    let payload;
    try {
      payload = jwt.verify(refreshToken, refreshSecret(), { audience });
    } catch {
      throw new ApiError(401, "Invalid admin refresh token");
    }
    if (payload.scope !== "admin-refresh")
      throw new ApiError(401, "Invalid admin refresh token");
    const refreshHash = crypto
      .createHash("sha256")
      .update(refreshToken)
      .digest("hex");
    const result = await query(
      `select a.*, r.name as role_name
       from admins a
       left join roles r on r.id = a.role_id
       where a.id=$1 and a.refresh_token_hash=$2 and a.status='active'`,
      [payload.sub, refreshHash],
    );
    if (!result.rows[0]) throw new ApiError(401, "Admin session expired");
    res.json({ success: true, data: await issueTokens(result.rows[0]) });
  } catch (error) {
    next(error);
  }
}

export async function logout(req, res, next) {
  try {
    const { refreshToken } = req.body || {};
    if (refreshToken) {
      const refreshHash = crypto
        .createHash("sha256")
        .update(refreshToken)
        .digest("hex");
      await query(
        "update admins set refresh_token_hash=null, updated_at=now() where refresh_token_hash=$1",
        [refreshHash],
      );
    }
    res.json({ success: true, data: { loggedOut: true } });
  } catch (error) {
    next(error);
  }
}
