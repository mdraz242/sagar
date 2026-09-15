# VyparHub Migration Notes

These notes cover one-time steps required before deploying the Phase 1-8 backend over existing production data.

## 1. Database Backup

Before running migrations on Supabase production:

1. Open Supabase dashboard.
2. Go to Project Settings > Database.
3. Take a backup/export or confirm point-in-time recovery is available for the project.

Do not run the migrations directly on production without a rollback path.

## 2. Required Migration Order

Run from `server/`:

```powershell
npm ci
npm run migrate
npm run seed:admin-data
```

The migration runner applies all SQL files in `server/migrations/` alphabetically, so the current order is:

1. Existing baseline migrations.
2. `003_admin_data_model.sql`
3. `004_admin_rbac_and_catalog_variants.sql`
4. `005_orders_wallet_loyalty_admin.sql`

## 3. Product Variant Backfill

Existing products originally stored SKU, price, and stock on the `products` row. Migration `003_admin_data_model.sql` backfills one default `product_variants` row for every product that does not already have variants.

After migration, verify:

```sql
select p.id, p.name_en
from products p
left join product_variants pv on pv.product_id = p.id
group by p.id
having count(pv.id) = 0;
```

This query should return zero rows.

## 4. Starting Price Backfill

Migration `003_admin_data_model.sql` creates triggers that keep `products.starting_price` in sync with active variants.

Verify:

```sql
select id, name_en, starting_price
from products
where starting_price is null
limit 20;
```

Products with no active variants may have a null starting price and should be fixed from the admin catalog screen.

## 5. Admin User and Roles

Migration `004_admin_rbac_and_catalog_variants.sql` creates default roles and an initial super-admin:

- Email: `admin@vyparhub.com`
- Password: `Admin@123`

Immediately after production migration:

1. Log into the admin portal.
2. Create a new personal super-admin account.
3. Change or deactivate the default demo admin account.

## 6. Wallet Balance Rule

Wallet balances are derived from `wallet_transactions`. Do not manually update `wallet_accounts.balance`.

If a balance correction is needed, create a wallet transaction with reason `admin_adjustment`.

## 7. Order Status History

Migration `005_orders_wallet_loyalty_admin.sql` backfills one `order_status_history` row for every existing order using its current status.

After migration, verify:

```sql
select o.id
from orders o
left join order_status_history h on h.order_id = o.id
group by o.id
having count(h.id) = 0;
```

This query should return zero rows.

## 8. Render Deployment

Recommended Render Web Service settings for the monorepo:

- Root Directory: `server`
- Build Command: `npm ci && npm run migrate && npm run seed:admin-data`
- Start Command: `npm start`
- Environment:
  - `NODE_ENV=production`
  - `PORT=10000`
  - `DATABASE_URL=<Supabase pooler connection string>`
  - `PGSSLMODE=require`
  - customer JWT secrets
  - admin JWT secrets
  - Firebase service account JSON
  - CORS origins

If you prefer manual migrations, use:

- Build Command: `npm ci`
- Start Command: `npm start`

Then run `npm run migrate && npm run seed:admin-data` locally against the production `DATABASE_URL` before deploying.

## 9. Smoke Test

After deployment:

```powershell
cd D:\DriveE\MobileApp\server
$env:SMOKE_API_BASE_URL="https://vyparhub.onrender.com/api"
$env:SMOKE_SOCKET_ORIGIN="https://vyparhub.onrender.com"
$env:SMOKE_ADMIN_EMAIL="admin@vyparhub.com"
$env:SMOKE_ADMIN_PASSWORD="Admin@123"
npm run smoke-test
```

The smoke test logs in as admin, creates a category, creates a product with two variants, publishes a coupon, connects a customer socket, updates stock, and verifies `product.stock_changed` is received.
