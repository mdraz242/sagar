import bcrypt from "bcryptjs";

import { pool, query } from "../config/db.js";
import { findById, updateUser } from "../repositories/userRepository.js";
import { ApiError } from "../utils/apiError.js";

export const getProfile = async (req, res, next) => {
  try {
    res.json({ success: true, data: await findById(req.user.sub) });
  } catch (e) {
    next(e);
  }
};

export const updateProfile = async (req, res, next) => {
  try {
    res.json({ success: true, data: await updateUser(req.user.sub, req.body) });
  } catch (e) {
    next(e);
  }
};

export const deleteAccount = async (req, res, next) => {
  const client = await pool.connect();
  try {
    const code = req.body?.code?.toString().trim();
    if (!code) throw new ApiError(422, "Enter the OTP sent to your phone.");

    const user = (
      await query("select id, phone from users where id=$1", [req.user.sub])
    ).rows[0];
    if (!user) throw new ApiError(404, "Account not found");

    const otp = (
      await query(
        `select *
         from otp_codes
         where phone=$1 and consumed_at is null and expires_at > now()
         order by created_at desc
         limit 1`,
        [user.phone],
      )
    ).rows[0];

    if (!otp) throw new ApiError(401, "OTP expired. Please request a new OTP.");
    if (Number(otp.attempts) >= 5) {
      throw new ApiError(
        429,
        "Too many wrong OTP attempts. Please request a new code.",
      );
    }

    const ok = await bcrypt.compare(code, otp.code_hash);
    if (!ok) {
      await query("update otp_codes set attempts = attempts + 1 where id=$1", [
        otp.id,
      ]);
      throw new ApiError(401, "Invalid OTP. Please try again.");
    }

    await client.query("begin");
    await client.query("update otp_codes set consumed_at=now() where id=$1", [
      otp.id,
    ]);
    await client.query("delete from cart_items where user_id=$1", [user.id]);
    await client.query(
      `update users
       set name='Deleted User',
           shop_name='Deleted Account',
           phone=concat('deleted-', id::text),
           address=null,
           area=null,
           pincode=null,
           fcm_token=null,
           updated_at=now()
       where id=$1`,
      [user.id],
    );
    await client.query("commit");

    res.json({ success: true, data: { deleted: true } });
  } catch (e) {
    try {
      await client.query("rollback");
    } catch (_) {
      // No active transaction is fine here.
    }
    next(e);
  } finally {
    client.release();
  }
};
