# VyparHub Workflow QA Report

Last updated: 8 July 2026

This report separates local code verification from live two-device validation. The live checklist must be re-run after redeploying Render and installing the latest APK on a real device.

| Check | Status | Notes |
| --- | --- | --- |
| Admin login with RBAC | Pending live run | Requires deployed backend/admin URL and seeded admin. |
| Add/edit/delete product with variants and image | Pending live run | Upload endpoint now requires Supabase Storage in production. |
| Add category, home section item, delivery zone | Pending live run | Category delete now soft-deactivates and emits customer sync. |
| Full order lifecycle updates customer tracking | Pending live run | Backend status flow and events exist; needs real device/FCM check. |
| Approve/reject refund and reflect in customer app | Pending live run | Refund ledger/events exist; needs live customer order. |
| Send push notification to device | Pending live run | Requires valid FCM device token and service account. |
| New user MSG91 OTP signup | Pending live run | Requires Render env `OTP_PROVIDER=msg91` and valid MSG91 credentials. |
| Existing user MSG91 OTP login | Pending live run | Same as above. |
| Cancel eligible order from customer app | Pending live run | Previously fixed backend parameter typing; retest after redeploy. |
| Return/exchange delivered order | Pending live run | Requires delivered test order within return window. |
| Customer/admin total amount consistency | Pending live run | Compare one real order across both clients. |

## Local Verification Notes

- Static legal pages are now served from `/legal`.
- Delivery zone matching no longer uses a radius fallback; it only matches configured `delivery_zones.pincodes_json`.
- Brand/category/home-section/catalog events are wired for customer-side refresh.
- Image uploads are no longer allowed to silently rely on Render's ephemeral disk in production.

## Manual Retest Steps After Deploy

1. Redeploy Render with the environment variables listed in `PRODUCTION_INFRA_VERIFICATION.md`.
2. Open `https://vyparhub.onrender.com/health` and confirm `{"success":true}`.
3. Open `https://vyparhub.onrender.com/admin` in a fresh browser and log in.
4. Install the APK from `mobile/build/app/outputs/flutter-apk/app-release.apk`.
5. Run each checklist row above using the same live Supabase database.
