# Project Analysis

## Source Project Identified

The uploaded source was a React/Vite/TanStack application split into:

- Customer FMCG ordering app.
- Admin dashboard.
- Supabase-backed catalog/admin implementation.

## Existing Customer Screens

- Login and OTP-style verification.
- Shop onboarding form.
- Home dashboard with search, hero delivery banner, category grid, quick tiles, promo banners, product rails, and best deals grid.
- Category listing.
- Category detail with left category rail and product grid.
- Offers grid.
- AI stock helper.
- Cart with quantity controls and delivery threshold.
- Checkout with address, payment mode, UPI, and order success states.
- Profile drawer with wallet, rewards, orders, support, refer, agent, KYC, policies, terms, and about sections.

## Existing Admin Screens

- Auth page.
- Dashboard metrics.
- Products list and product form.
- Categories.
- Brands.
- Offers.
- Orders.

## Existing Flow

Login -> OTP -> Shop Details -> Home -> Category/Product/Offer/AI/Cart -> Checkout -> Order Placed.

Admin flow:

Auth -> Dashboard -> Products/Categories/Brands/Offers/Orders.

## Architecture Migrated To

- Flutter Material 3 frontend.
- Riverpod state management.
- Go Router navigation.
- Dio-ready API client.
- Flutter Secure Storage token storage.
- Firebase Analytics, Messaging, and Crashlytics wrappers.
- Mock repository layer so the app runs without a backend.
- Node.js Express backend with PostgreSQL, JWT, RBAC, validation, and security middleware.
