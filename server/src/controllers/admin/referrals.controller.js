import { query } from "../../config/db.js";
import { numericValue, logAdminActivity } from "./helpers.js";

export async function referrals(req, res, next) {
  try {
    const [events, settingsResult] = await Promise.all([
      query(`
        select re.*, ru.name as referrer_name, uu.name as referred_name
        from referral_events re
        left join users ru on ru.id = re.referrer_customer_id
        left join users uu on uu.id = re.referred_customer_id
        order by re.created_at desc
      `),
      query("select * from referral_settings where id=true"),
    ]);
    res.json({
      success: true,
      data: {
        settings: settingsResult.rows[0] || { reward_amount: 200 },
        events: events.rows,
      },
    });
  } catch (e) {
    next(e);
  }
}

export async function saveReferralSettings(req, res, next) {
  try {
    const rewardAmount = numericValue(
      req.body.rewardAmount ?? req.body.reward_amount,
      200,
    );
    const result = await query(
      "insert into referral_settings(id,reward_amount) values(true,$1) on conflict(id) do update set reward_amount=excluded.reward_amount,updated_at=now() returning *",
      [rewardAmount],
    );
    await logAdminActivity(
      req,
      "update",
      "referral_settings",
      null,
      null,
      result.rows[0],
    );
    res.json({ success: true, data: result.rows[0] });
  } catch (e) {
    next(e);
  }
}
