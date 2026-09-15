# VyparHub MobileApp

Generated migration of the uploaded React/Vite FMCG ordering app into Flutter + Node.js + PostgreSQL.

## Migrated Features

Customer app: OTP-style login, shop onboarding, sticky brand/delivery bar, bottom navigation, home banners, trending categories, product cards, offers, cart, checkout address/payment/UPI flow, AI stock helper, profile drawer items, orders shell.

Admin/backend: JWT authentication, refresh-token signing helpers, RBAC roles (`customer`, `admin`, `super_admin`), dashboard metrics, products, categories, brands, offers, orders, addresses, payments, inventory, seed data, migrations, and API documentation.

## Order Status, Sales, and Refund Rules

Orders move forward through `placed -> confirmed -> packed -> shipped -> out_for_delivery -> delivered`. `cancelled` is terminal and is allowed before delivery. Refund workflows can move delivered orders into `partially_refunded` or `refunded`; those statuses are terminal for delivery operations and are managed only by refund actions.

Dashboard sales are derived from database state, not counters. Gross sales include orders that reached delivery (`delivered`, `partially_refunded`, `refunded`). Pending revenue includes `placed` through `out_for_delivery`. Cancelled orders are reported separately and never count as sales. Refunds are recorded in an auditable refund ledger or approved return request, then shown as `Refunded Amount`; net sales are `Gross Sales - Refunded Amount`.

Admin refunds require the `returns.edit` permission, a reason, destination, amount, and idempotency key. The backend blocks refund amounts above the remaining refundable balance and blocks refunds on already fully-refunded orders. Wallet/store-credit refunds are processed immediately; original payment/UPI refunds are marked pending for gateway/manual processing.

Supabase dependency has been removed.

## Backend

```bash
cd server
copy .env.example .env
npm install
npm run migrate
npm run seed
npm run dev
```

Default backend API for development: `https://<your-backend-host>/api`

Demo accounts:
- Customer: `9876543210` / `Demo@123`
- Super Admin: `9999999999` / `Admin@123`

## Flutter

Flutter is required on the build machine.

```bash
cd mobile
flutter pub get
flutter analyze
flutter run -d chrome
flutter run -d edge
flutter run
```

The local demo catalog is bundled with original product/category imagery so the investor demo opens even before the backend is running. To connect to a backend, pass the API URL explicitly:

```bash
flutter run -d edge --dart-define=API_BASE_URL=https://your-api.example.com/api
flutter run --dart-define=API_BASE_URL=https://your-api.example.com/api
```

## Signed APK

```bash
cd mobile
keytool -genkeypair -v -keystore android/app/release.keystore -alias vyparhub -keyalg RSA -keysize 2048 -validity 10000
set ANDROID_KEYSTORE_PATH=release.keystore
set ANDROID_KEYSTORE_PASSWORD=your-password
set ANDROID_KEY_ALIAS=vyparhub
set ANDROID_KEY_PASSWORD=your-password
flutter build apk --release --dart-define=API_BASE_URL=https://your-api.example.com/api
```

## VS Code Commands

```bash
cd mobile
flutter clean
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
flutter run -d edge
flutter run
```

## Reports

- See `PROJECT_ANALYSIS.md`
- See `CHANGES_MADE.md`
- See `RESPONSIVENESS_REPORT.md`

## Firebase

See `server/FIREBASE.md`. Add `mobile/android/app/google-services.json` and enable FCM, Analytics, and Crashlytics in Firebase.

## Structure

- `mobile/lib/core`: config, network, theme, secure storage, utils
- `mobile/lib/features`: auth, products, cart, checkout, orders, offers, profile, home, ai, admin
- `mobile/lib/shared/widgets`: reusable app shell and product card
- `server/src`: controllers, routes, services, middleware, repositories, validators, db
- `server/migrations`, `server/sql`: PostgreSQL schema and SQL assets
