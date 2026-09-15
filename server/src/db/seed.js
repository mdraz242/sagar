import bcrypt from "bcryptjs";
import { pool } from "../config/db.js";
import { categories, products } from "../data/demoData.js";
const adminHash = await bcrypt.hash("Admin@123", 12);
const customerHash = await bcrypt.hash("Demo@123", 12);
await pool.query(
  "insert into users(name,shop_name,phone,password_hash,address,area,pincode,role) values($1,$2,$3,$4,$5,$6,$7,$8) on conflict(phone) do nothing",
  [
    "Admin",
    "VyparHub HQ",
    "9999999999",
    adminHash,
    "HQ",
    "Delhi",
    "110001",
    "super_admin",
  ],
);
await pool.query(
  "insert into users(name,shop_name,phone,password_hash,address,area,pincode,role) values($1,$2,$3,$4,$5,$6,$7,$8) on conflict(phone) do nothing",
  [
    "Ramesh Sharma",
    "Sharma Kirana Store",
    "9876543210",
    customerHash,
    "Main Market, Sector 12",
    "Delhi",
    "110001",
    "customer",
  ],
);
for (const c of categories)
  await pool.query(
    "insert into categories(slug,name_en,image_url,tint) values($1,$2,$3,$4) on conflict(slug) do update set name_en=excluded.name_en, image_url=excluded.image_url, tint=excluded.tint",
    [c.slug, c.name_en, c.image_url, c.tint],
  );
for (const p of products) {
  const cat = (
    await pool.query("select id from categories where slug=$1", [
      p.category_slug,
    ])
  ).rows[0];
  await pool.query(
    "insert into brands(name) values($1) on conflict(name) do nothing",
    [p.brand],
  );
  await pool.query(
    "insert into products(sku,category_id,brand,name_en,size,pack,image_url,mrp,buy_price,stock,regional,high_margin,trending_areas,is_active) values($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14) on conflict(sku) do update set stock=excluded.stock",
    [
      p.sku,
      cat?.id,
      p.brand,
      p.name_en,
      p.size,
      p.pack,
      p.image_url,
      p.mrp,
      p.buy_price,
      p.stock,
      p.regional,
      p.high_margin,
      p.trending_areas,
      p.is_active,
    ],
  );
}
const prod = (
  await pool.query("select id,name_en,image_url from products limit 4")
).rows;
for (const [i, p] of prod.entries())
  await pool.query(
    "insert into offers(title,subtitle,image_url,product_id,discount_percent) values($1,$2,$3,$4,$5)",
    [
      p.name_en + " Bulk Deal",
      "Investor demo promotional offer",
      p.image_url,
      p.id,
      20 + i * 5,
    ],
  );
console.log("seeded demo users, catalog, offers");
await pool.end();
