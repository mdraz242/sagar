# VyparHub Repo Audit

Generated: 2026-07-03

## 1. Folder Structure

### Repository Root

- `.github/` - GitHub metadata/workflows if configured.
- `.vscode/` - local editor settings.
- `docs/` - project documentation assets.
- `mobile/` - Flutter Android-first mobile app.
- `preview/` - preview/reference assets.
- `server/` - Node.js/Express API plus static admin PWA.
- `.gitignore`
- `README.md`
- `DEPLOYMENT_NOTES.md`
- `HYBRID_FIREBASE_SUPABASE.md`
- `PHASE7_TEST_REPORT.md`
- `PLAY_STORE_DATA_SAFETY.md`
- `PROJECT_ANALYSIS.md`
- `RESPONSIVENESS_REPORT.md`
- `CHANGES_MADE.md`

### Backend: `server/`

- `package.json` / `package-lock.json` - Node package metadata and scripts.
- `.env.example` - environment variable template.
- `docker-compose.yml` - local Postgres setup.
- `API.md`, `FIREBASE.md`, `LOCAL_SETUP.md` - backend/API documentation.
- `migrations/`
  - `001_init.sql`
  - `002_cart_and_otp.sql`
- `sql/`
  - `schema.sql`
  - `seed.sql`
- `src/`
  - `app.js` - Express app, `/health`, `/uploads`, `/admin`, `/api`.
  - `server.js` - server bootstrap.
  - `routes/index.js` - all REST route declarations.
  - `config/db.js` - raw `pg` Pool and query helper.
  - `controllers/` - auth, catalog, cart, orders, addresses, profile, payments, admin.
  - `middleware/` - auth, error handling, security.
  - `repositories/` - current user/catalog data access.
  - `services/` - auth, OTP, Firebase, notifications.
  - `validators/` - Zod auth schemas.
  - `db/` - migration and seed runners.
  - `data/demoData.js` - seed catalog data.
- `public/admin/`
  - `index.html` - static/PWA admin portal.
  - `manifest.webmanifest`
  - `sw.js`
  - `icons/`
- `test/api.integration.test.js`

### Mobile: `mobile/`

Key app source under `mobile/lib/`:

- `main.dart`
- `core/`
  - `analytics/analytics_service.dart`
  - `config/app_config.dart`
  - `i18n/translations.dart`
  - `location/india_location_service.dart`
  - `network/api_client.dart`, `api_providers.dart`, `api_services.dart`
  - `notifications/notification_service.dart`
  - `router/app_router.dart`
  - `storage/secure_token_storage.dart`
  - `theme/app_theme.dart`
  - `utils/money.dart`, `responsive.dart`
- `data/`
  - `datasources/mock_catalog_datasource.dart`
  - `models/catalog_models.dart`
  - `repositories/api_catalog_repository.dart`, `catalog_repository.dart`, `catalog_providers.dart`
- `features/`
  - `auth/`
  - `home/`
  - `products/`
  - `quickbuy/`
  - `cart/`
  - `checkout/`
  - `orders/`
  - `offers/`
  - `profile/`
  - `ai/`
  - `admin/`
  - `styleguide/`
- `shared/widgets/`
  - `app_shell.dart`
  - `vypar_ui.dart`
  - `product_card.dart`
  - `catalog_image.dart`
  - `app_network_image.dart`

### Admin App

This working copy does not contain a separate React source tree such as `fix-it-fast-main`. The admin panel currently present in the repo is a static/PWA admin portal served from `server/public/admin/index.html` at `/admin`. It calls the same Node API under `/api`.

## 2. Existing REST Endpoints

Base path for API routes: `/api`.

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/health` | Server health check outside `/api`. |
| POST | `/api/auth/register` | Register phone/password user. |
| POST | `/api/auth/login` | Login by phone/password; returns JWT tokens. |
| GET | `/api/auth/lookup` | Check whether a phone number is registered. |
| POST | `/api/auth/refresh` | Refresh JWT access token. |
| POST | `/api/auth/otp/request` | Request backend OTP. |
| POST | `/api/auth/otp/verify` | Verify backend OTP. |
| POST | `/api/auth/logout` | Authenticated logout endpoint. |
| GET | `/api/products` | Public product list. |
| GET | `/api/products/:id` | Public product detail. |
| GET | `/api/categories` | Public category list. |
| GET | `/api/offers` | Public offers list. |
| GET | `/api/cart` | Authenticated cart list. |
| POST | `/api/cart/add` | Add/update cart item. |
| POST | `/api/cart/remove` | Remove/decrement cart item. |
| GET | `/api/addresses` | Authenticated address list. |
| POST | `/api/addresses` | Create address. |
| PUT | `/api/addresses/:id` | Update address. |
| PATCH | `/api/addresses/:id/default` | Set default address. |
| DELETE | `/api/addresses/:id` | Delete address. |
| POST | `/api/orders` | Create order. |
| GET | `/api/orders` | List current user's orders. |
| GET | `/api/orders/:id` | Get current user's order detail. |
| POST | `/api/payments/create-order` | Create Razorpay order. |
| POST | `/api/payments/webhook` | Razorpay webhook handler. |
| GET | `/api/profile` | Current user profile. |
| PUT | `/api/profile` | Update current user profile. |
| GET | `/api/admin/dashboard` | Admin dashboard metrics. |
| GET | `/api/admin/orders` | Admin orders list. |
| PATCH | `/api/admin/orders/:id/status` | Admin order status update. |
| GET | `/api/admin/products` | Admin product list. |
| POST | `/api/admin/products` | Create product. |
| PUT | `/api/admin/products/:id` | Update product. |
| DELETE | `/api/admin/products/:id` | Delete product. |
| GET | `/api/admin/categories` | Admin category list. |
| POST | `/api/admin/categories` | Create category. |
| PUT | `/api/admin/categories/:id` | Update category. |
| DELETE | `/api/admin/categories/:id` | Delete category. |
| GET | `/api/admin/brands` | Admin brand list. |
| POST | `/api/admin/brands` | Create brand. |
| PUT | `/api/admin/brands/:id` | Update brand. |
| DELETE | `/api/admin/brands/:id` | Delete brand. |
| GET | `/api/admin/offers` | Admin offers/coupons list. |
| POST | `/api/admin/offers` | Create offer/coupon/banner. |
| PUT | `/api/admin/offers/:id` | Update offer/coupon/banner. |
| DELETE | `/api/admin/offers/:id` | Delete offer/coupon/banner. |
| GET | `/api/admin/customers` | Admin customer list. |
| GET | `/api/admin/reports` | Admin reporting data. |
| GET | `/api/admin/payments` | Admin payment list. |
| GET | `/api/admin/payouts` | Admin payout summary. |
| GET | `/api/admin/returns` | Admin returns/refunds list. |
| PATCH | `/api/admin/returns/:id/status` | Update return/refund status. |
| GET | `/api/admin/support` | Admin support/ticket list. |
| GET | `/api/admin/users` | Admin user list. |
| POST | `/api/admin/users` | Create admin user. |
| PUT | `/api/admin/users/:id` | Update admin user. |
| GET | `/api/admin/logs` | Admin activity log data. |
| GET | `/api/admin/settings` | Admin app/settings payload. |
| PUT | `/api/admin/settings` | Save admin app/settings payload. |
| POST | `/api/admin/notifications` | Send/log admin notification. |
| POST | `/api/admin/uploads` | Multipart admin image upload. |

## 3. Existing Postgres Tables and Columns

The backend currently uses raw `pg`; no Sequelize, Prisma, or Knex ORM is present.

### `users`

- `id uuid primary key default gen_random_uuid()`
- `name text not null`
- `shop_name text`
- `phone text unique not null`
- `password_hash text not null`
- `address text`
- `area text`
- `pincode text`
- `role user_role not null default 'customer'`
- `fcm_token text`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

### `categories`

- `id uuid primary key default gen_random_uuid()`
- `slug text unique not null`
- `name_en text not null`
- `name_hi text`
- `image_url text`
- `tint text`
- `sort_order int default 0`
- `is_active boolean default true`
- `created_at timestamptz default now()`
- `updated_at timestamptz default now()`

### `brands`

- `id uuid primary key default gen_random_uuid()`
- `name text unique not null`
- `logo_url text`
- `is_active boolean default true`
- `created_at timestamptz default now()`
- `updated_at timestamptz default now()`

### `products`

- `id uuid primary key default gen_random_uuid()`
- `sku text unique`
- `category_id uuid references categories(id)`
- `brand text`
- `name_en text not null`
- `name_hi text`
- `size text`
- `pack text`
- `image_url text`
- `mrp numeric(10,2) not null default 0`
- `buy_price numeric(10,2) not null default 0`
- `stock int not null default 0`
- `regional boolean default false`
- `high_margin boolean default false`
- `trending_areas text[]`
- `is_active boolean default true`
- `created_at timestamptz default now()`
- `updated_at timestamptz default now()`

### `product_variants`

- `id uuid primary key default gen_random_uuid()`
- `product_id uuid not null references products(id) on delete cascade`
- `size text not null`
- `pack text`
- `mrp numeric(10,2)`
- `buy_price numeric(10,2)`
- `created_at timestamptz default now()`

### `offers`

- `id uuid primary key default gen_random_uuid()`
- `title text not null`
- `subtitle text`
- `image_url text`
- `media_type text default 'image'`
- `product_id uuid references products(id)`
- `discount_percent int`
- `link_url text`
- `is_active boolean default true`
- `starts_at timestamptz`
- `ends_at timestamptz`
- `created_at timestamptz default now()`
- `updated_at timestamptz default now()`

### `addresses`

- `id uuid primary key default gen_random_uuid()`
- `user_id uuid references users(id) on delete cascade`
- `name text`
- `phone text`
- `line1 text not null`
- `area text`
- `city text`
- `state text`
- `pincode text`
- `is_default boolean default false`
- `created_at timestamptz default now()`

### `orders`

- `id uuid primary key default gen_random_uuid()`
- `user_id uuid references users(id)`
- `address_id uuid references addresses(id)`
- `status text not null default 'pending'`
- `total numeric(10,2) not null default 0`
- `items jsonb not null default '[]'`
- `notes text`
- `created_at timestamptz default now()`
- `updated_at timestamptz default now()`

### `order_items`

- `id uuid primary key default gen_random_uuid()`
- `order_id uuid references orders(id) on delete cascade`
- `product_id uuid references products(id)`
- `quantity int not null`
- `mrp numeric(10,2)`
- `buy_price numeric(10,2)`

### `payments`

- `id uuid primary key default gen_random_uuid()`
- `order_id uuid references orders(id)`
- `mode text not null`
- `status text not null default 'pending'`
- `amount numeric(10,2) not null`
- `provider_ref text`
- `created_at timestamptz default now()`

### `inventory`

- `id uuid primary key default gen_random_uuid()`
- `product_id uuid references products(id)`
- `quantity int not null default 0`
- `reserved_quantity int not null default 0`
- `updated_at timestamptz default now()`

### `cart_items`

- `id uuid primary key default gen_random_uuid()`
- `user_id uuid not null references users(id) on delete cascade`
- `product_id uuid not null references products(id)`
- `variant_key text`
- `quantity int not null check (quantity > 0)`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`
- unique `(user_id, product_id, variant_key)`

### `otp_codes`

- `id uuid primary key default gen_random_uuid()`
- `phone text not null`
- `code_hash text not null`
- `expires_at timestamptz not null`
- `attempts int not null default 0`
- `consumed_at timestamptz`
- `created_at timestamptz not null default now()`

## 4. Implemented Screens and Routes

### Flutter GoRouter Routes

- `/login` - login/signup auth screen.
- `/forgot-password` - forgot password screen.
- `/style-guide` - design system/style guide screen.
- `/` - home screen.
- `/bulk-order` - bulk order utility flow.
- `/voice-search` - voice search flow.
- `/barcode-scan` - barcode scanner flow.
- `/search` - search results.
- `/quick-buy` - quick buy screen.
- `/category` - category listing.
- `/category/:id` - category filtered listing.
- `/list/:type` - product list variants such as deals/best price.
- `/products/:id` - product detail.
- `/brands` - brands screen.
- `/brands/:name` - brand-specific screen.
- `/ai` - VyparAI screen.
- `/rewards` - rewards/offers screen.
- `/rewards/history` - points history.
- `/offers` - offers screen.
- `/cart` - cart screen.
- `/checkout` - checkout.
- `/checkout/confirmation` - order confirmation.
- `/orders` - orders list.
- `/orders/:id` - order detail.
- `/orders/:id/tracking` - order tracking.
- `/orders/:id/return` - return request flow.
- `/orders/:id/exchange` - exchange request flow.
- `/orders/:id/review` - review flow.
- `/profile` - profile/account.
- `/profile/addresses` - address list.
- `/profile/addresses/new` - add address.
- `/profile/addresses/edit` - edit address.
- `/profile/payments` - payment methods.
- `/profile/payments/new` - add payment method.
- `/profile/refer` - refer and earn.
- `/profile/help` - help and support.
- `/profile/rate` - rate us.
- `/profile/about` - about VyparHub.
- `/profile/logout` - logout confirm.
- `/location` - location picker.
- `/notifications` - notifications.
- `/wallet` - wallet.
- `/wishlist` - wishlist.
- `/profile/settings` - settings.
- `/profile/language` - language.
- `/admin` - minimal mobile admin dashboard.

### Admin Portal Sections

The static admin portal in `server/public/admin/index.html` implements:

- Login
- Dashboard
- Orders
- Products
- Categories
- Users/Admin Access
- Customers
- Marketing
- Coupons
- Banners
- Reviews
- Returns & Refunds
- Reports
- Payments
- Payouts
- Settings
- System Settings
- Logs / Users Activity Log
- Support / Tickets
- Logout

## 5. Duplicated, Dead, or Inconsistent Code

- **No ORM but ORM-style requirement pressure:** The backend uses raw `pg` only. Adding Sequelize/Prisma/Knex models would create a second data access pattern unless the whole backend is migrated.
- **Admin app source mismatch:** The project history references a React admin app, but this working tree contains a static admin PWA under `server/public/admin`, not the React source tree.
- **Product price/stock duplication:** `products` stores `sku`, `mrp`, `buy_price`, `stock`, `size`, and `pack`, while `product_variants` also exists. This is a partial variant model and needs normalization/backward-compatible migration.
- **Brand duplication:** `brands` table exists, but `products.brand` stores brand as text rather than `brand_id`.
- **Settings naming overlap:** Admin nav has both `Settings` and `System Settings`; both currently map to related app configuration concepts and should be clarified.
- **Marketing/Banners/Coupons overlap:** Marketing uses the coupons renderer; banners are represented through offers with `image_url`. This works but blurs entity boundaries.
- **Returns/refunds backed by orders:** Returns/refunds are inferred from `orders.status` and `orders.notes`; there is no dedicated return request table.
- **Admin logs are synthetic:** Existing `activityLogs` composes rows from updated products/orders/categories/users instead of persisting true before/after admin actions.
- **Wallet/rewards screens ahead of backend:** Flutter/admin screens reference wallet, points, rewards, and notifications concepts but the schema is not fully present yet.
- **OTP duality:** Backend supports password auth, backend OTP tables, and Firebase phone OTP. This is valid but should remain explicitly documented to avoid confusing login flows.
- **Admin token storage follow-up:** The static admin PWA stores admin access/refresh tokens in `localStorage` for consistency with the existing implementation. A production hardening pass should move admin sessions to httpOnly, Secure, SameSite cookies.
