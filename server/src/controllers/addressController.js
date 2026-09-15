import { pool, query } from "../config/db.js";
import { ApiError, notFound } from "../utils/apiError.js";

function addressPayload(body) {
  return {
    name: body.name ?? null,
    phone: body.phone ?? null,
    line1: body.line1,
    area: body.area ?? null,
    city: body.city ?? null,
    state: body.state ?? null,
    pincode: body.pincode ?? null,
    isDefault: Boolean(body.isDefault),
  };
}

function rejectOutsideIndia(data, { partial = false } = {}) {
  const pincode = String(data.pincode || "").trim();
  if ((!partial || pincode) && !/^\d{6}$/.test(pincode)) {
    throw new ApiError(422, "A valid 6 digit Indian pincode is required");
  }

  const addressText = [data.line1, data.area, data.city, data.state]
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

export async function listAddresses(req, res, next) {
  try {
    const result = await query(
      "select * from addresses where user_id = $1 order by is_default desc, created_at desc",
      [req.user.sub],
    );
    res.json({ success: true, data: result.rows });
  } catch (error) {
    next(error);
  }
}

export async function createAddress(req, res, next) {
  const client = await pool.connect();

  try {
    const data = addressPayload(req.body);

    if (!data.line1) {
      throw new ApiError(422, "line1 is required");
    }
    rejectOutsideIndia(data);

    await client.query("begin");

    if (data.isDefault) {
      await client.query(
        "update addresses set is_default = false where user_id = $1",
        [req.user.sub],
      );
    }

    const result = await client.query(
      `
        insert into addresses(user_id, name, phone, line1, area, city, state, pincode, is_default)
        values($1, $2, $3, $4, $5, $6, $7, $8, $9)
        returning *
      `,
      [
        req.user.sub,
        data.name,
        data.phone,
        data.line1,
        data.area,
        data.city,
        data.state,
        data.pincode,
        data.isDefault,
      ],
    );

    await client.query("commit");
    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (error) {
    await client.query("rollback");
    next(error);
  } finally {
    client.release();
  }
}

export async function updateAddress(req, res, next) {
  const client = await pool.connect();

  try {
    const data = addressPayload(req.body);
    rejectOutsideIndia(data, { partial: true });
    await client.query("begin");

    const existing = await client.query(
      "select id from addresses where id = $1 and user_id = $2",
      [req.params.id, req.user.sub],
    );

    if (!existing.rows[0]) {
      throw notFound("Address");
    }

    if (data.isDefault) {
      await client.query(
        "update addresses set is_default = false where user_id = $1",
        [req.user.sub],
      );
    }

    const result = await client.query(
      `
        update addresses
        set
          name = coalesce($3, name),
          phone = coalesce($4, phone),
          line1 = coalesce($5, line1),
          area = coalesce($6, area),
          city = coalesce($7, city),
          state = coalesce($8, state),
          pincode = coalesce($9, pincode),
          is_default = case when $10 then true else is_default end
        where id = $1 and user_id = $2
        returning *
      `,
      [
        req.params.id,
        req.user.sub,
        data.name,
        data.phone,
        data.line1,
        data.area,
        data.city,
        data.state,
        data.pincode,
        data.isDefault,
      ],
    );

    await client.query("commit");
    res.json({ success: true, data: result.rows[0] });
  } catch (error) {
    await client.query("rollback");
    next(error);
  } finally {
    client.release();
  }
}

export async function setDefaultAddress(req, res, next) {
  const client = await pool.connect();

  try {
    await client.query("begin");

    const existing = await client.query(
      "select id from addresses where id = $1 and user_id = $2",
      [req.params.id, req.user.sub],
    );

    if (!existing.rows[0]) {
      throw notFound("Address");
    }

    await client.query(
      "update addresses set is_default = false where user_id = $1",
      [req.user.sub],
    );
    const result = await client.query(
      "update addresses set is_default = true where id = $1 and user_id = $2 returning *",
      [req.params.id, req.user.sub],
    );

    await client.query("commit");
    res.json({ success: true, data: result.rows[0] });
  } catch (error) {
    await client.query("rollback");
    next(error);
  } finally {
    client.release();
  }
}

export async function deleteAddress(req, res, next) {
  try {
    const result = await query(
      "delete from addresses where id = $1 and user_id = $2 returning id",
      [req.params.id, req.user.sub],
    );

    if (!result.rows[0]) {
      throw notFound("Address");
    }

    res.json({ success: true, data: { id: result.rows[0].id, deleted: true } });
  } catch (error) {
    next(error);
  }
}
