# Changes Made

## Added

- `mobile/lib/core`: theme, config, network, storage, analytics, notifications, responsive utilities.
- `mobile/lib/data`: models, repositories, mock datasources.
- `mobile/lib/features`: authentication, home, products, cart, checkout, offers, orders, profile, AI, admin.
- `mobile/lib/shared/widgets`: app shell, product card, cached network image wrapper.
- `server/src`: Express controllers, routes, services, repositories, middleware, validators, database scripts.
- `server/migrations/001_init.sql`: PostgreSQL schema.
- `server/src/db/seed.js`: demo catalog and user seeding.
- `preview/index.html`: Edge/browser preview of the migrated design.

## Modified

- Flutter app config now uses `--dart-define=API_BASE_URL=...` and defaults to mock data when no API URL is supplied.
- Home, category, and admin screens now use `LayoutBuilder`, adaptive grid counts, `Wrap`, `Expanded`, and responsive padding.
- README run instructions updated for VS Code, web, Android, Edge, and backend setup.

## Removed

- Supabase runtime dependency from the generated mobile/backend architecture.
- Hardcoded emulator API URL from Flutter defaults.
