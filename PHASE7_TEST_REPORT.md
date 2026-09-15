# Phase 7 Test Report

Date: June 29, 2026

## Automated Tests

Backend:

- Added `server/test/api.integration.test.js`.
- Covers OTP request/verify, cart add/remove/get, address CRUD ownership, order creation with normalized `order_items`, and Razorpay webhook signature rejection/acceptance.
- Added `npm test` script using Node's built-in test runner and `supertest`.

Mobile:

- Added `mobile/test/phase7_flow_test.dart`.
- Covers login OTP flow, variant cart provider state, and checkout address/payment/order-placed transitions.

## Bugs Found and Fixed Locally

- Fixed Firebase Admin ESM import bug in `server/src/services/notificationService.js`; valid payment webhook status updates no longer fail while attempting notification setup.
- Fixed narrow-phone header overflow in `mobile/lib/shared/widgets/app_shell.dart`.
- Fixed narrow-phone trending category title overflow in `mobile/lib/features/home/presentation/home_screen.dart`.

## Security Hardening

- Added dedicated password-login rate limiter.
- Kept OTP request limiter in place.
- Changed CORS from wildcard to explicit allowlist behavior while still allowing mobile clients with no browser `Origin` header.
- Audited ownership checks for cart, addresses, orders, and payments. Customer routes are scoped by `req.user.sub`; admin-wide routes are behind `authorize('admin', 'super_admin')`.

## Performance Pass

- Confirmed product JPG assets are under 100 KB; largest product asset observed was about 90.4 KB.
- Confirmed API/network images flow through `CatalogImage` and `AppNetworkImage`, which uses `cached_network_image`.
- Removed unused large bundled PNG assets that were pulled into the APK by the broad asset rule.
- Converted potentially large product/order screens to lazy `GridView.builder`/`ListView.builder` patterns.

## Real Device Testing

Pending. User will connect a real Android device next.

Required device test matrix:

- One low/mid-range Android phone near API 23-26 if available.
- Current user's Android phone if API 23-26 device is not available.

Flows to verify on device:

- Login/OTP.
- Browse home, categories, product detail.
- Add normal product and variant product to cart.
- Checkout COD.
- Checkout Razorpay after credentials are configured.
- View order detail/status updates.
- Admin changes order status, mobile reflects it.

## Remaining External Requirements

- Razorpay credentials are still not configured, so live payment cannot be fully device-tested yet.
- Production deployment is not configured, so deployed CORS/secrets cannot be confirmed yet.
- Privacy policy page is written but not hosted yet.
