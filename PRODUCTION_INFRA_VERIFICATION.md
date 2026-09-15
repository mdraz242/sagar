# Production Infrastructure Verification

Last updated: 8 July 2026

## Migration Files Expected On Live Supabase

The backend migration runner executes every SQL file in `server/migrations` in sorted order:

1. `001_init.sql`
2. `002_cart_and_otp.sql`
3. `003_admin_data_model.sql`
4. `004_admin_rbac_and_catalog_variants.sql`
5. `005_orders_wallet_loyalty_admin.sql`
6. `006_live_home_sections_delivery.sql`
7. `007_return_exchange_flow.sql`
8. `008_admin_refund_ledger.sql`

Render build command should include:

```bash
npm ci && npm run migrate && npm run seed:admin-data
```

## Required Render Environment

Set these in the backend Render service:

- `DATABASE_URL`: Supabase transaction-pooler PostgreSQL URL.
- `PGSSLMODE=require`
- `NODE_ENV=production`
- `PORT=10000` or Render-provided default.
- `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`
- `ADMIN_JWT_ACCESS_SECRET`, `ADMIN_JWT_REFRESH_SECRET`
- `STORE_TIMEZONE=Asia/Kolkata`
- `OTP_PROVIDER=msg91`
- `OTP_CODE_TTL_MINUTES=10`
- `MSG91_AUTH_KEY`, `MSG91_TEMPLATE_ID`, `MSG91_SENDER_ID`
- `FIREBASE_SERVICE_ACCOUNT_JSON` for FCM push notifications.
- `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_STORAGE_BUCKET`

## Persistent Upload Storage

Admin uploads now use Supabase Storage when `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are configured. Local disk uploads remain only as a development fallback. Production requests fail clearly if persistent storage is missing, because Render filesystem is ephemeral.

Create a public Supabase Storage bucket named `vyparhub-assets`, or set `SUPABASE_STORAGE_BUCKET` to your chosen public bucket name.

## Admin URL

The backend serves the admin app at:

```text
https://vyparhub.onrender.com/admin
```

The bare API root returning `{"success":false,"error":{"message":"Route not found"}}` is expected. Use `/health`, `/api/...`, `/admin`, or `/legal/...`.
