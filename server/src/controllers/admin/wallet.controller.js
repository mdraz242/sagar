import { query } from "../../config/db.js";
import { ApiError, notFound } from "../../utils/apiError.js";
import { numericValue, logAdminActivity, writeWalletTransaction, writePointsLedger } from "./helpers.js";

export async function customers(_req, res, next) {
  try {
    const result = await query(`
      select
        u.id,
        u.name,
        u.shop_name,
        u.phone,
        u.area,
        u.pincode,
        u.role,
        u.created_at,
        count(o.id)::int as orders,
        coalesce(sum(o.total) filter(where o.status in ('delivered','partially_refunded','refunded')), 0)::numeric as total_spent
      from users u
      left join orders o on o.user_id = u.id
      where u.role = 'customer'
      group by u.id
      order by u.created_at desc
    `);
    res.json({ success: true, data: result.rows });
  } catch (e) {
    next(e);
  }
}

export async function customerDetail(req, res, next) {
  try {
    const customer = await query(
      "select id,name,shop_name,phone,address,area,pincode,fcm_token,created_at from users where id=$1 and role='customer'",
      [req.params.id],
    );
    if (!customer.rows[0]) throw notFound("Customer");
    const [addresses, ordersResult, wallet, walletTransactions, points] =
      await Promise.all([
        query(
          "select * from addresses where user_id=$1 order by is_default desc, created_at desc",
          [req.params.id],
        ),
        query(
          "select * from orders where user_id=$1 order by created_at desc limit 50",
          [req.params.id],
        ),
        query("select * from wallet_accounts where customer_id=$1", [
          req.params.id,
        ]),
        query(
          `select wt.* from wallet_transactions wt join wallet_accounts wa on wa.id=wt.wallet_account_id where wa.customer_id=$1 order by wt.created_at desc limit 100`,
          [req.params.id],
        ),
        query(
          "select * from loyalty_ledger where customer_id=$1 order by created_at desc limit 100",
          [req.params.id],
        ),
      ]);
    res.json({
      success: true,
      data: {
        customer: customer.rows[0],
        addresses: addresses.rows,
        orders: ordersResult.rows,
        wallet: wallet.rows[0] || { balance: 0 },
        walletTransactions: walletTransactions.rows,
        pointsLedger: points.rows,
      },
    });
  } catch (e) {
    next(e);
  }
}

export async function customerWalletTransactions(req, res, next) {
  try {
    const result = await query(
      `select wt.* from wallet_transactions wt
       join wallet_accounts wa on wa.id=wt.wallet_account_id
       where wa.customer_id=$1
       order by wt.created_at desc`,
      [req.params.id],
    );
    res.json({ success: true, data: result.rows });
  } catch (e) {
    next(e);
  }
}

export async function adjustCustomerWallet(req, res, next) {
  try {
    const { amount, type = "credit", reason = "Admin adjustment" } = req.body;
    if (!amount || Number(amount) <= 0)
      throw new ApiError(422, "positive amount is required");
    if (!["credit", "debit"].includes(type))
      throw new ApiError(422, "type must be credit or debit");
    const tx = await writeWalletTransaction({
      customerId: req.params.id,
      type,
      amount: numericValue(amount),
      reason: "admin_adjustment",
      referenceType: "admin_adjustment",
      referenceId: req.admin?.id,
      adminId: req.admin?.id,
    });
    await logAdminActivity(
      req,
      "adjust_wallet",
      "customer",
      req.params.id,
      null,
      { transaction: tx, reason },
    );
    res.json({ success: true, data: tx });
  } catch (e) {
    next(e);
  }
}

export async function adjustCustomerPoints(req, res, next) {
  try {
    const { points, type = "earned", reason = "Admin adjustment" } = req.body;
    if (!points || Number(points) <= 0)
      throw new ApiError(422, "positive points are required");
    if (!["earned", "redeemed", "expired"].includes(type))
      throw new ApiError(422, "invalid points type");
    const ledger = await writePointsLedger({
      customerId: req.params.id,
      points: numericValue(points),
      type,
      reason,
      referenceType: "admin_adjustment",
      referenceId: req.admin?.id,
    });
    await logAdminActivity(
      req,
      "adjust_points",
      "customer",
      req.params.id,
      null,
      ledger,
    );
    res.json({ success: true, data: ledger });
  } catch (e) {
    next(e);
  }
}
