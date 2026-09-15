import { query } from "../../config/db.js";
import { dashboardRangeFilters } from "./helpers.js";

export const dashboard = async (req, res, next) => {
  try {
    const range = dashboardRangeFilters(req.query);
    const [p, c, b, o] = await Promise.all([
      query(
        "select count(*)::int count, coalesce(sum(mrp-buy_price),0) margin, count(*) filter(where stock<=5)::int low_stock from products",
      ),
      query("select count(*)::int count from categories"),
      query("select count(*)::int count from brands"),
      query(
        `
        with order_rows as (
          select o.*,
            (
              select max(h.changed_at)
              from order_status_history h
              where h.order_id=o.id and h.status='delivered'
            ) as delivered_at
          from orders o
        ),
        scoped_orders as (
          select *
          from order_rows
          where ${range.orderFilter}
        ),
        scoped_refunds as (
          select amount from refund_requests
          where status in ('credited_to_wallet','store_credit_issued','pending_manual_gateway_refund','refunded')
            and ${range.refundFilter}
          union all
          select amount from refunds
          where status in ('pending','processed')
            and ${range.refundFilter}
        )
        select
          count(*)::int as count,
          count(*) filter(where status in ('placed','confirmed','packed','shipped','out_for_delivery'))::int as pending_count,
          count(*) filter(where status in ('delivered','partially_refunded','refunded'))::int as delivered_count,
          coalesce(sum(total) filter(where status in ('delivered','partially_refunded','refunded')),0)::numeric as gross_sales,
          coalesce(sum(total) filter(where status in ('placed','confirmed','packed','shipped','out_for_delivery')),0)::numeric as pending_revenue,
          count(*) filter(where status='cancelled')::int as cancelled_count,
          coalesce(sum(total) filter(where status='cancelled'),0)::numeric as cancelled_value,
          coalesce((select sum(amount) from scoped_refunds), 0)::numeric as refunded_amount,
          now() as last_updated_at,
          $1::text as time_zone
        from scoped_orders
      `,
        range.params,
      ),
    ]);
    const orderMetrics = o.rows[0];
    const grossSales = Number(orderMetrics.gross_sales || 0);
    const refundedAmount = Number(orderMetrics.refunded_amount || 0);
    res.json({
      success: true,
      data: {
        products: p.rows[0],
        categories: c.rows[0],
        brands: b.rows[0],
        orders: {
          ...orderMetrics,
          revenue: orderMetrics.gross_sales,
          net_sales: grossSales - refundedAmount,
          range: range.range,
        },
      },
    });
  } catch (e) {
    next(e);
  }
};
