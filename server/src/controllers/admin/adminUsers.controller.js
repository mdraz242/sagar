import bcrypt from "bcryptjs";
import { query } from "../../config/db.js";
import { ApiError, notFound } from "../../utils/apiError.js";
import { logAdminActivity } from "./helpers.js";

export async function adminUsers(_req, res, next) {
  try {
    const result = await query(`
      select a.id, a.name, a.email, a.status, a.role_id, r.name as role, a.created_at, a.updated_at
      from admins a
      left join roles r on r.id = a.role_id
      order by a.created_at desc
    `);
    res.json({ success: true, data: result.rows });
  } catch (e) {
    next(e);
  }
}

export async function roles(_req, res, next) {
  try {
    const result = await query(`
      select r.*,
        coalesce(json_agg(json_build_object('module', rp.module, 'action', rp.action, 'allowed', rp.allowed) order by rp.module, rp.action) filter (where rp.id is not null), '[]'::json) as permissions
      from roles r
      left join role_permissions rp on rp.role_id = r.id
      group by r.id
      order by r.name
    `);
    res.json({ success: true, data: result.rows });
  } catch (e) {
    next(e);
  }
}

export async function createRole(req, res, next) {
  try {
    const { name, description, permissions = [] } = req.body;
    if (!name) throw new ApiError(422, "name is required");
    const result = await query(
      "insert into roles(name,description,status) values($1,$2,$3) returning *",
      [name, description || null, req.body.status || "active"],
    );
    for (const permission of permissions) {
      await query(
        `insert into role_permissions(role_id,module,action,allowed) values($1,$2,$3,$4)
         on conflict(role_id,module,action) do update set allowed=excluded.allowed, updated_at=now()`,
        [
          result.rows[0].id,
          permission.module,
          permission.action,
          permission.allowed !== false,
        ],
      );
    }
    await logAdminActivity(req, "create", "role", result.rows[0].id, null, {
      ...result.rows[0],
      permissions,
    });
    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (e) {
    next(e);
  }
}

export async function updateRole(req, res, next) {
  try {
    const before = await query("select * from roles where id=$1", [
      req.params.id,
    ]);
    const { name, description, permissions = [] } = req.body;
    const result = await query(
      "update roles set name=$2,description=$3,status=$4,updated_at=now() where id=$1 returning *",
      [req.params.id, name, description || null, req.body.status || "active"],
    );
    if (!result.rows[0]) throw notFound("Role");
    for (const permission of permissions) {
      await query(
        `insert into role_permissions(role_id,module,action,allowed) values($1,$2,$3,$4)
         on conflict(role_id,module,action) do update set allowed=excluded.allowed, updated_at=now()`,
        [
          req.params.id,
          permission.module,
          permission.action,
          permission.allowed !== false,
        ],
      );
    }
    await logAdminActivity(
      req,
      "update",
      "role",
      req.params.id,
      before.rows[0],
      { ...result.rows[0], permissions },
    );
    res.json({ success: true, data: result.rows[0] });
  } catch (e) {
    next(e);
  }
}

export async function deleteRole(req, res, next) {
  try {
    const before = await query("select * from roles where id=$1", [
      req.params.id,
    ]);
    const result = await query("delete from roles where id=$1 returning id", [
      req.params.id,
    ]);
    if (!result.rows[0]) throw notFound("Role");
    await logAdminActivity(
      req,
      "delete",
      "role",
      req.params.id,
      before.rows[0],
      null,
    );
    res.json({ success: true, data: { id: result.rows[0].id, deleted: true } });
  } catch (e) {
    next(e);
  }
}

export async function createAdminUser(req, res, next) {
  try {
    const { name, email, password, roleId, status = "active" } = req.body;
    if (!name || !email || !password || !roleId)
      throw new ApiError(422, "name, email, password and roleId are required");
    const existing = await query(
      "select id from admins where lower(email)=lower($1)",
      [email],
    );
    if (existing.rows[0]) throw new ApiError(409, "Email already registered");
    const passwordHash = await bcrypt.hash(password, 12);
    const result = await query(
      "insert into admins(name,email,password_hash,role_id,status) values($1,$2,$3,$4,$5) returning id,name,email,role_id,status,created_at,updated_at",
      [name, email, passwordHash, roleId, status],
    );
    await logAdminActivity(
      req,
      "create",
      "admin_user",
      result.rows[0].id,
      null,
      result.rows[0],
    );
    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (e) {
    next(e);
  }
}

export async function updateAdminUser(req, res, next) {
  try {
    const before = await query(
      "select id,name,email,role_id,status from admins where id=$1",
      [req.params.id],
    );
    const { name, email, password, roleId, status } = req.body;
    const passwordHash = password ? await bcrypt.hash(password, 12) : null;
    const result = await query(
      `update admins set
        name=coalesce($2,name),
        email=coalesce($3,email),
        password_hash=coalesce($4,password_hash),
        role_id=coalesce($5,role_id),
        status=coalesce($6,status),
        updated_at=now()
      where id=$1
      returning id,name,email,role_id,status,created_at,updated_at`,
      [
        req.params.id,
        name || null,
        email || null,
        passwordHash,
        roleId || null,
        status || null,
      ],
    );
    if (!result.rows[0]) throw notFound("Admin user");
    await logAdminActivity(
      req,
      "update",
      "admin_user",
      req.params.id,
      before.rows[0],
      result.rows[0],
    );
    res.json({ success: true, data: result.rows[0] });
  } catch (e) {
    next(e);
  }
}
