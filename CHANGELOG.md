# VyparHub Changelog

## Phase 0 - Audit

- Added `AUDIT.md` documenting the monorepo structure, backend routes, database tables, Flutter routes, admin routes, and known inconsistencies.

## Phase 1 - Data Model Additions

- Added migrations for wallet accounts and transactions, loyalty tiers/rules/ledger, redeemable rewards, referrals, delivery zones, home sections, admin activity logs, and notification logs.
- Added product variant support while keeping the legacy product columns backward compatible.
- Added seed support for realistic admin/demo data.

## Phase 2 - Admin Auth and RBAC

- Added `admins`, `roles`, and `role_permissions`.
- Added admin-scoped JWT login, refresh, and logout endpoints.
- Added `requireAdminAuth` and permission middleware.
- Gated admin endpoints by module/action permissions.

## Phase 3 - Catalog Admin

- Added admin CRUD for brands, categories, products, variants, offers, uploads, and product CSV import/export.
- Updated the admin portal forms for product creation/editing, variants, brands, categories, coupons, banners, and confirmation flows.

## Phase 4 - Orders, Returns, and Refunds

- Added explicit order status workflow: `placed`, `confirmed`, `packed`, `shipped`, `out_for_delivery`, `delivered`, `cancelled`.
- Added `order_status_history`.
- Added refund request approval/rejection logic with wallet credit handling.
- Added mobile return/exchange refund-method submission.

## Phase 5 - Wallet, Loyalty, Referrals, and Merchandising

- Added admin APIs and screens for loyalty tiers, earning rules, rewards, referral settings, home sections, delivery zones, notification history, wallet adjustments, and customer drill-down data.
- Extended coupons/banners with validity and applies-to metadata.

## Phase 6 - Real-Time Sync

- Added Socket.io to the backend.
- Added `/admin` and `/customer` socket namespaces authenticated by existing admin/customer JWTs.
- Added realtime emits for orders, refunds, wallet transactions, product price/stock changes, coupons, banners, home sections, and low-stock alerts.
- Wired the admin portal to live socket events with toast notifications and bell updates.
- Added Flutter foreground realtime service with `socket_io_client`, invalidating Riverpod data providers on relevant events.

## Phase 7 - Cross-Cutting UX Fixes

- Added dev-mode OTP bypass gated by `ALLOW_DEV_OTP_BYPASS=true`, `OTP_DEV_CODE`, and non-production `NODE_ENV`.
- Collapsed duplicate admin "System Settings" navigation into one Settings section.
- Added mobile refund-method selection and persistence for returns/exchanges.
- Fixed analyzer-clean Flutter changes around the new return/refund flow.

## Phase 8 - Testing and Deployment

- Extended backend integration tests for admin auth/RBAC, catalog CRUD, variants, coupons, loyalty, delivery zones, home sections, order status workflow, refunds, wallet adjustments, and socket namespace/event behavior.
- Added `npm run smoke-test`.
- Documented all backend environment variables in `server/.env.example`.
- Added migration and deployment notes for Render/Supabase production rollout.
