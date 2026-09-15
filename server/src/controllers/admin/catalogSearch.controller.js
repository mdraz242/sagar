import { pool, query } from "../../config/db.js";
import { emitAdmin, emitCustomers } from "../../services/realtimeService.js";
import { ApiError } from "../../utils/apiError.js";
import { broadcastCatalogChange, resolveAdminId } from "./helpers.js";

export async function search(req, res, next) {
  try {
    const q = `%${String(req.query.q || "").trim()}%`;
    if (q === "%%")
      return res.json({
        success: true,
        data: { orders: [], products: [], customers: [], brands: [], categories: [] },
      });
    const [ordersResult, productsResult, customersResult, brandsResult, categoriesResult] = await Promise.all([
      query(
        "select id,status,total,created_at from orders where id::text ilike $1 or status::text ilike $1 order by created_at desc limit 8",
        [q],
      ),
      query(
        "select id,sku,name_en,image_url,starting_price,buy_price from products where is_active=true and (name_en ilike $1 or sku ilike $1 or brand ilike $1 or id::text ilike $1) order by created_at desc limit 8",
        [q],
      ),
      query(
        "select id,name,shop_name,phone from users where role='customer' and (name ilike $1 or shop_name ilike $1 or phone ilike $1) order by created_at desc limit 8",
        [q],
      ),
      query(
        "select id,name,logo_url,status from brands where is_active=true and name ilike $1 order by name limit 8",
        [q],
      ),
      query(
        "select id,name_en,slug,image_url from categories where is_active=true and (name_en ilike $1 or slug ilike $1) order by sort_order,name_en limit 8",
        [q],
      ),
    ]);
    res.json({
      success: true,
      data: {
        orders: ordersResult.rows,
        products: productsResult.rows,
        customers: customersResult.rows,
        brands: brandsResult.rows,
        categories: categoriesResult.rows,
      },
    });
  } catch (e) {
    next(e);
  }
}

export async function resetCatalog(req, res, next) {
  const client = await pool.connect();
  try {
    const confirmation = String(req.body?.confirmation || "").trim();
    if (confirmation !== "DELETE CATALOG") {
      throw new ApiError(422, 'Type "DELETE CATALOG" to confirm catalog reset');
    }
    await client.query("begin");
    const adminId = await resolveAdminId(req.admin?.id, client);
    const counts = {
      cartItems: (await client.query("select count(*)::int as count from cart_items")).rows[0].count,
      homeItems: (await client.query("select count(*)::int as count from home_section_items")).rows[0].count,
      variants: (await client.query("select count(*)::int as count from product_variants")).rows[0].count,
      products: (await client.query("select count(*)::int as count from products")).rows[0].count,
      categories: (await client.query("select count(*)::int as count from categories")).rows[0].count,
      brands: (await client.query("select count(*)::int as count from brands")).rows[0].count,
    };

    await client.query("delete from cart_items");
    await client.query("delete from home_section_items");
    await client.query("update offers set product_id=null, category_id=null");
    await client.query("update order_items set product_id=null where product_id is not null");
    await client.query("delete from inventory");
    await client.query("delete from product_variants");
    await client.query("delete from products");
    await client.query("update categories set parent_id=null where parent_id is not null");
    await client.query("delete from categories");
    await client.query("delete from brands");
    await client.query(
      `insert into admin_activity_log(admin_id,action,entity_type,entity_id,before_json,after_json)
       values($1,'reset','catalog',null,$2,$3)`,
      [adminId, counts, { confirmation, resetAt: new Date().toISOString() }],
    );
    await client.query("commit");

    emitCustomers("catalog.reset", counts);
    broadcastCatalogChange("catalog.updated", { reason: "catalog.reset", counts });
    emitCustomers("home_section.updated", { reason: "catalog.reset" });
    emitAdmin("home_section.updated", { reason: "catalog.reset" });
    emitAdmin("catalog.reset", counts);
    res.json({ success: true, data: { reset: true, counts } });
  } catch (e) {
    try {
      await client.query("rollback");
    } catch (_) {
      /* noop */
    }
    next(e);
  } finally {
    client.release();
  }
}
