import bcrypt from "bcryptjs";
import { pool } from "../config/db.js";

const json = (value) => JSON.stringify(value);
const seedDemoData =
  process.env.SEED_DEMO_DATA === "true" ||
  (process.env.NODE_ENV !== "production" && process.env.SEED_DEMO_DATA !== "false");

async function one(text, params = []) {
  return (await pool.query(text, params)).rows[0];
}

async function ensureUser({ name, shopName, phone, role = "customer" }) {
  const passwordHash = await bcrypt.hash(
    role === "customer" ? "Demo@123" : "Admin@123",
    12,
  );
  await pool.query(
    `insert into users(name,shop_name,phone,password_hash,address,area,pincode,role)
     values($1,$2,$3,$4,$5,$6,$7,$8)
     on conflict(phone) do update set name=excluded.name, shop_name=excluded.shop_name, role=excluded.role`,
    [
      name,
      shopName,
      phone,
      passwordHash,
      "Main Market",
      "Birpur",
      "854340",
      role,
    ],
  );
  return one("select * from users where phone=$1", [phone]);
}

async function ensureAdminAccount() {
  const passwordHash = await bcrypt.hash("Admin@123", 12);
  const role = await one("select id from roles where name='Super Admin'");
  await pool.query(
    `insert into admins(name,email,password_hash,role_id,status)
     values($1,$2,$3,$4,'active')
     on conflict(email) do update
       set name=excluded.name,
           password_hash=excluded.password_hash,
           role_id=excluded.role_id,
           status='active',
           updated_at=now()`,
    ["Admin", "admin@vyparhub.com", passwordHash, role?.id || null],
  );
  return one("select * from admins where email=$1", ["admin@vyparhub.com"]);
}

async function ensureCatalog() {
  await pool.query(
    `insert into categories(slug,name_en,image_url,tint)
     values
      ('beverages','Beverages','products/coke.png','#F8DFC7'),
      ('snacks','Snacks','products/lays.png','#F8DFC7'),
      ('home-care','Home Care','products/surf.png','#EEF5FF'),
      ('atta-dal','Atta & Dal','products/atta.png','#FFF2DF'),
      ('dairy','Dairy','products/amul-milk.png','#F5F7FF')
     on conflict(slug) do update set name_en=excluded.name_en`,
  );

  const categoryRows = (await pool.query("select id, slug from categories"))
    .rows;
  const categoryId = (slug) => categoryRows.find((c) => c.slug === slug)?.id;
  const products = [
    [
      "COCA-750",
      categoryId("beverages"),
      "Coca Cola",
      "Coca Cola 750ml",
      "750ml",
      "1 bottle",
      "products/coke.png",
      58,
      45,
      160,
    ],
    [
      "LAYS-52",
      categoryId("snacks"),
      "Lay's",
      "Lay's Classic Salted 52g",
      "52g",
      "1 pack",
      "products/lays.png",
      25,
      20,
      240,
    ],
    [
      "SURF-1KG",
      categoryId("home-care"),
      "HUL",
      "Surf Excel 1kg",
      "1kg",
      "1 pack",
      "products/surf.png",
      165,
      140,
      80,
    ],
    [
      "ATTA-5KG",
      categoryId("atta-dal"),
      "Aashirvaad",
      "Aashirvaad Atta 5kg",
      "5kg",
      "1 bag",
      "products/atta.png",
      310,
      249,
      100,
    ],
    [
      "AMUL-1L",
      categoryId("dairy"),
      "Amul",
      "Amul Milk 1L",
      "1L",
      "1 pouch",
      "products/amul-milk.png",
      75,
      60,
      120,
    ],
  ];

  for (const p of products) {
    await pool.query(
      `insert into products(sku,category_id,brand,name_en,size,pack,image_url,mrp,buy_price,stock,is_active,description,images_json)
       values($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,true,$11,$12)
       on conflict(sku) do update set category_id=excluded.category_id, brand=excluded.brand, name_en=excluded.name_en, updated_at=now()`,
      [...p, `${p[3]} for kirana bulk ordering.`, json([p[6]])],
    );
  }
}

async function seedBrands() {
  const brands = [
    ["Coca Cola", "products/coke.png", "active"],
    ["Lay's", "products/lays.png", "active"],
    ["HUL", "products/surf.png", "active"],
    ["Aashirvaad", "products/atta.png", "active"],
    ["Amul", "products/amul-milk.png", "active"],
    ["Britannia", "products/britannia.png", "inactive"],
  ];
  for (const brand of brands) {
    await pool.query(
      `insert into brands(name,logo_url,status,is_active)
       values($1,$2,$3,$4)
       on conflict(name) do update set logo_url=excluded.logo_url, status=excluded.status, is_active=excluded.is_active, updated_at=now()`,
      [brand[0], brand[1], brand[2], brand[2] === "active"],
    );
  }
}

async function seedVariants() {
  const products = (
    await pool.query(
      "select id, sku, name_en, mrp, buy_price, stock from products order by created_at limit 5",
    )
  ).rows;
  for (const [index, product] of products.entries()) {
    const variants = [
      [
        `${product.name_en} Regular`,
        `${product.sku || `SKU${index}`}-REG`,
        product.mrp,
        product.buy_price,
        product.stock,
        true,
      ],
      [
        `${product.name_en} Bulk Pack`,
        `${product.sku || `SKU${index}`}-BULK`,
        Number(product.mrp) * 10,
        Number(product.buy_price) * 9,
        Math.max(10, product.stock),
        false,
      ],
    ];
    for (const variant of variants) {
      const payload = [
        product.id,
        variant[0],
        variant[1],
        variant[2],
        variant[3],
        variant[4],
        "pcs",
        variant[5],
      ];
      const updated = await pool.query(
        `update product_variants
         set product_id=$1, variant_name=$2, mrp=$4, selling_price=$5, stock_quantity=$6, unit=$7, is_default=$8, status='active', updated_at=now()
         where sku=$3`,
        payload,
      );
      if (updated.rowCount === 0) {
        await pool.query(
          `insert into product_variants(product_id,variant_name,sku,mrp,selling_price,stock_quantity,unit,is_default,status)
           values($1,$2,$3,$4,$5,$6,$7,$8,'active')`,
          payload,
        );
      }
    }
  }
}

async function seedWalletsAndLoyalty(customers, admin) {
  for (const customer of customers) {
    await pool.query(
      "insert into wallet_accounts(customer_id) values($1) on conflict(customer_id) do nothing",
      [customer.id],
    );
    const wallet = await one(
      "select * from wallet_accounts where customer_id=$1",
      [customer.id],
    );
    const reasons = [
      "wallet_topup",
      "cashback",
      "order_payment",
      "admin_adjustment",
      "order_refund",
      "cashback",
    ];
    const reason = reasons[customers.indexOf(customer)];
    const type = reason === "order_payment" ? "debit" : "credit";
    await pool.query(
      `insert into wallet_transactions(wallet_account_id,type,amount,reason,reference_type,created_by)
       select $1,$2,$3,$4,'seed',$5
       where not exists (
         select 1 from wallet_transactions where wallet_account_id=$1 and reason=$4 and reference_type='seed'
       )`,
      [
        wallet.id,
        type,
        50 + customers.indexOf(customer) * 25,
        reason,
        admin.id,
      ],
    );
  }

  const tiers = [
    ["Bronze", 0, { cashback: "1%", support: "standard" }],
    ["Silver", 500, { cashback: "2%", freeDelivery: "monthly" }],
    ["Gold", 1500, { cashback: "3%", prioritySupport: true }],
    ["Platinum", 5000, { cashback: "5%", earlyDeals: true }],
    ["Diamond", 10000, { cashback: "7%", dedicatedManager: true }],
  ];
  for (const tier of tiers) {
    await pool.query(
      `insert into loyalty_tiers(name,min_points,benefits_json)
       values($1,$2,$3)
       on conflict(name) do update set min_points=excluded.min_points, benefits_json=excluded.benefits_json, updated_at=now()`,
      [tier[0], tier[1], json(tier[2])],
    );
  }

  const rules = [
    ["place_order", 10],
    ["write_review", 25],
    ["refer_friend", 100],
    ["daily_login", 2],
    ["bulk_order", 50],
  ];
  for (const rule of rules) {
    await pool.query(
      `insert into loyalty_rules(action,points_awarded,active)
       values($1,$2,true)
       on conflict(action) do update set points_awarded=excluded.points_awarded, active=true, updated_at=now()`,
      rule,
    );
  }

  for (const [index, customer] of customers.entries()) {
    await pool.query(
      `insert into loyalty_ledger(customer_id,points,type,reason,reference_type,expires_at)
       select $1,$2,'earned',$3,'seed',now() + interval '180 days'
       where not exists (select 1 from loyalty_ledger where customer_id=$1 and reason=$3 and reference_type='seed')`,
      [customer.id, 50 + index * 25, `Welcome points ${index + 1}`],
    );
  }
}

async function seedRewardsReferralsZones(customers) {
  const rewards = [
    ["Free Delivery Coupon", 100, "free_delivery", { maxDiscount: 60 }],
    ["Rs 50 Off Coupon", 150, "coupon", { code: "VYPAR50" }],
    ["Surf Trial Pack", 250, "product", { sku: "SURF-TRIAL" }],
    ["Bulk Buyer Bonus", 500, "coupon", { code: "BULK500" }],
    ["Priority Delivery", 300, "free_delivery", { priority: true }],
  ];
  for (const reward of rewards) {
    await pool.query(
      `insert into redeemable_rewards(title,points_cost,reward_type,reward_value_json,active,stock_limit)
       select $1,$2,$3,$4,true,100
       where not exists (select 1 from redeemable_rewards where title=$1)`,
      [reward[0], reward[1], reward[2], json(reward[3])],
    );
  }

  for (const [index, customer] of customers.entries()) {
    await pool.query(
      `insert into referral_codes(customer_id,code)
       values($1,$2)
       on conflict(customer_id) do update set code=excluded.code`,
      [customer.id, `VYPAR${200 + index}`],
    );
  }
  for (let i = 0; i < Math.min(customers.length - 1, 5); i += 1) {
    await pool.query(
      `insert into referral_events(referrer_customer_id,referred_customer_id,status,reward_amount)
       select $1,$2,$3,$4
       where not exists (select 1 from referral_events where referrer_customer_id=$1 and referred_customer_id=$2)`,
      [
        customers[i].id,
        customers[i + 1].id,
        i % 2 === 0 ? "rewarded" : "joined",
        200,
      ],
    );
  }

  const zones = [
    ["Birpur Express", "pincode", ["854340", "854341"], 120, 20, 999, null, null, null],
    ["Delhi Central", "pincode", ["110001", "110002"], 90, 30, 1499, null, null, null],
    ["Patna Trade Zone", "pincode", ["800001", "800002"], 150, 40, 1299, null, null, null],
    ["Noida Retail Belt", "pincode", ["201301", "201304"], 100, 25, 999, null, null, null],
    ["Gurugram Market", "pincode", ["122001", "122002"], 110, 35, 1199, null, null, null],
    ["Siwan 200km Radius", "radius", [], 120, 20, 999, 26.2196, 84.3567, 200],
  ];
  for (const zone of zones) {
    await pool.query(
      `insert into delivery_zones(name,zone_type,pincodes_json,estimated_delivery_minutes,delivery_fee,free_delivery_min_order,active,center_lat,center_lng,radius_km)
       values($1,$2,$3,$4,$5,$6,true,$7,$8,$9)
       on conflict(name) do update set zone_type=excluded.zone_type, pincodes_json=excluded.pincodes_json, estimated_delivery_minutes=excluded.estimated_delivery_minutes, delivery_fee=excluded.delivery_fee, free_delivery_min_order=excluded.free_delivery_min_order, center_lat=excluded.center_lat, center_lng=excluded.center_lng, radius_km=excluded.radius_km, updated_at=now()`,
      [zone[0], zone[1], json(zone[2]), zone[3], zone[4], zone[5], zone[6], zone[7], zone[8]],
    );
  }
}

async function seedHomeSectionsLogsNotifications(customers, admin) {
  const sections = [
    ["top_deals", "Top Deals for You", 1, null, null],
    [
      "flash_sale",
      "Flash Sale",
      2,
      new Date(),
      new Date(Date.now() + 24 * 60 * 60 * 1000),
    ],
    ["hot_right_now", "Hot Right Now", 3, null, null],
    ["featured", "Featured Essentials", 4, null, null],
    ["featured", "Recommended for Your Shop", 5, null, null],
  ];
  for (const section of sections) {
    await pool.query(
      `insert into home_sections(section_key,title,display_order,active,starts_at,ends_at)
       select $1,$2,$3,true,$4,$5
       where not exists (select 1 from home_sections where title=$2)`,
      section,
    );
  }

  const products = (
    await pool.query("select id from products order by created_at limit 8")
  ).rows;
  const variants = (
    await pool.query(
      "select id, product_id from product_variants order by created_at limit 8",
    )
  ).rows;
  const homeSections = (
    await pool.query("select id, section_key from home_sections")
  ).rows;
  for (const [index, section] of homeSections.slice(0, 5).entries()) {
    await pool.query(
      `insert into home_section_items(home_section_id,product_id,variant_id,display_order)
       select $1,$2,$3,$4
       where not exists (select 1 from home_section_items where home_section_id=$1 and product_id=$2 and coalesce(variant_id, '00000000-0000-0000-0000-000000000000'::uuid)=coalesce($3::uuid, '00000000-0000-0000-0000-000000000000'::uuid))`,
      [
        section.id,
        products[index % products.length].id,
        variants[index % variants.length]?.id || null,
        index + 1,
      ],
    );
  }

  const actions = [
    ["created_product", "product"],
    ["updated_order_status", "order"],
    ["created_coupon", "offer"],
    ["approved_refund", "order"],
    ["sent_push_notification", "notification"],
  ];
  for (const [index, action] of actions.entries()) {
    await pool.query(
      `insert into admin_activity_log(admin_id,action,entity_type,before_json,after_json)
       select $1,$2,$3,$4,$5
       where not exists (select 1 from admin_activity_log where admin_id=$1 and action=$2 and entity_type=$3)`,
      [
        admin.id,
        action[0],
        action[1],
        json({ status: "before" }),
        json({ status: "after", sample: index + 1 }),
      ],
    );
  }

  const notifications = [
    [
      "all",
      "Mega Sale is Live",
      "Get up to 50% off on daily essentials.",
      { area: "all" },
    ],
    [
      "segment",
      "Birpur Express Delivery",
      "2 hour delivery is active in your area.",
      { pincode: "854340" },
    ],
    [
      "user",
      "Order Delivered",
      "Your order has been delivered.",
      { customerId: customers[0]?.id },
    ],
    [
      "all",
      "New Rewards Added",
      "Redeem points for coupons and free delivery.",
      { rewards: true },
    ],
    [
      "segment",
      "Bulk Buyer Deal",
      "Extra margin on carton purchases today.",
      { tier: "Gold" },
    ],
  ];
  for (const notification of notifications) {
    await pool.query(
      `insert into notifications_log(target,title,body,segment_json,sent_by_admin_id,delivery_status)
       select $1,$2,$3,$4,$5,'sent'
       where not exists (select 1 from notifications_log where title=$2 and sent_by_admin_id=$5)`,
      [
        notification[0],
        notification[1],
        notification[2],
        json(notification[3]),
        admin.id,
      ],
    );
  }
}

try {
  const adminUser = await ensureUser({
    name: "Admin",
    shopName: "VyparHub HQ",
    phone: "9999999999",
    role: "super_admin",
  });
  const adminAccount = await ensureAdminAccount();
  const customers = [];
  if (seedDemoData) {
    const customerSeeds = [
      ["Ramesh Sharma", "Sharma Kirana Store", "9876543210"],
      ["Neha Gupta", "Gupta Daily Needs", "9876543211"],
      ["Amit Verma", "Verma General Store", "9876543212"],
      ["Pooja Patel", "Patel Mini Mart", "9876543213"],
      ["Vikram Singh", "Singh Provision", "9876543214"],
      ["Karan Mehta", "Mehta FMCG Point", "9876543215"],
    ];
    for (const [name, shopName, phone] of customerSeeds) {
      customers.push(await ensureUser({ name, shopName, phone }));
    }

    await ensureCatalog();
    await seedBrands();
    await seedVariants();
    await seedWalletsAndLoyalty(customers, adminUser);
    await seedRewardsReferralsZones(customers);
    await seedHomeSectionsLogsNotifications(customers, adminAccount);
  } else {
    console.log(
      "skipped demo catalog/customer seed data; set SEED_DEMO_DATA=true to seed sample products",
    );
  }

  console.log("seeded admin data model tables");
} finally {
  await pool.end();
}
