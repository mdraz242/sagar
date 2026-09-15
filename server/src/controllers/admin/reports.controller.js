import { query } from "../../config/db.js";

export async function reports(_req, res, next) {
  try {
    const [sales, categories, topProducts] = await Promise.all([
      query(`
        select
          to_char(created_at::date, 'DD Mon') as label,
          coalesce(sum(total), 0)::numeric as total,
          count(*)::int as orders
        from orders
        where created_at >= now() - interval '14 days'
          and status in ('delivered','partially_refunded','refunded')
        group by created_at::date
        order by created_at::date
      `),
      query(`
        select c.name_en as category, coalesce(sum(oi.buy_price * oi.quantity), 0)::numeric as revenue
        from order_items oi
        join orders o on o.id = oi.order_id and o.status in ('delivered','partially_refunded','refunded')
        join products p on p.id = oi.product_id
        left join categories c on c.id = p.category_id
        group by c.name_en
        order by revenue desc
        limit 8
      `),
      query(`
        select p.name_en, p.image_url, coalesce(sum(oi.quantity) filter(where o.id is not null), 0)::int as sold
        from products p
        left join order_items oi on oi.product_id = p.id
        left join orders o on o.id = oi.order_id and o.status in ('delivered','partially_refunded','refunded')
        group by p.id
        order by sold desc, p.created_at desc
        limit 8
      `),
    ]);
    res.json({
      success: true,
      data: {
        sales: sales.rows,
        categories: categories.rows,
        topProducts: topProducts.rows,
      },
    });
  } catch (e) {
    next(e);
  }
}

export async function payments(_req, res, next) {
  try {
    const result = await query(`
      select p.*, o.status as order_status
      from payments p
      left join orders o on o.id = p.order_id
      order by p.created_at desc
      limit 100
    `);
    res.json({ success: true, data: result.rows });
  } catch (e) {
    next(e);
  }
}

export async function payouts(_req, res, next) {
  try {
    const result = await query(`
      select
        brand as vendor,
        count(*)::int as products,
        coalesce(sum((mrp - buy_price) * greatest(stock, 0)), 0)::numeric as pending_amount,
        max(updated_at) as updated_at
      from products
      where brand is not null and brand <> ''
      group by brand
      order by pending_amount desc
    `);
    res.json({ success: true, data: result.rows });
  } catch (e) {
    next(e);
  }
}
