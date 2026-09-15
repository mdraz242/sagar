# VyparHub Current Auth And Data Plan

VyparHub now uses:

- Flutter mobile app for the customer experience.
- Node/Express API on Render for business logic.
- Supabase Postgres as the production database.
- MSG91 for customer OTP delivery.
- Firebase only for Cloud Messaging, Analytics, Crashlytics, and app initialization.

Customer phone login no longer uses Firebase phone authentication. OTP requests and verification go through the backend MSG91 flow:

```text
Flutter app -> Node API OTP endpoints -> MSG91 -> Node API JWT session -> Supabase Postgres
```

Render must provide:

```text
DATABASE_URL=<Supabase pooler connection string>
PGSSLMODE=require
OTP_PROVIDER=msg91
MSG91_AUTH_KEY=<auth key>
MSG91_TEMPLATE_ID=<template id>
MSG91_SENDER_ID=VYPRHB
OTP_CODE_TTL_MINUTES=10
```

Keep `FIREBASE_SERVICE_ACCOUNT_JSON` only if server-side push notifications are enabled.
