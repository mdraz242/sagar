import { query } from "../config/db.js";
export async function findByPhone(phone) {
  return (await query("select * from users where phone=$1", [phone])).rows[0];
}
export async function findById(id) {
  return (
    await query(
      "select id,name,shop_name,phone,address,area,pincode,role,created_at from users where id=$1",
      [id],
    )
  ).rows[0];
}
export async function createUser(u) {
  return (
    await query(
      "insert into users(name,shop_name,phone,password_hash,address,area,pincode,role) values($1,$2,$3,$4,$5,$6,$7,$8) returning id,name,shop_name,phone,address,area,pincode,role",
      [
        u.name,
        u.shopName,
        u.phone,
        u.passwordHash,
        u.address,
        u.area,
        u.pincode || "",
        u.role || "customer",
      ],
    )
  ).rows[0];
}
export async function updateUser(id, u) {
  return (
    await query(
      "update users set name=coalesce($2,name), shop_name=coalesce($3,shop_name), address=coalesce($4,address), area=coalesce($5,area), pincode=coalesce($6,pincode), fcm_token=coalesce($7,fcm_token), updated_at=now() where id=$1 returning id,name,shop_name,phone,address,area,pincode,role,fcm_token",
      [id, u.name, u.shopName, u.address, u.area, u.pincode, u.fcmToken],
    )
  ).rows[0];
}
