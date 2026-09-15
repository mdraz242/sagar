# Deployment Notes

Phase 3 chose a hybrid deployment path: Node/Express on Render, PostgreSQL on Supabase, Firebase for OTP/push/analytics/crash services, and a React admin PWA served by the Node service.

For reference, these remain valid Node API + PostgreSQL hosting paths:

| Option | Tradeoff |
| --- | --- |
| Render Web Service + Render PostgreSQL | Easiest managed setup and simple GitHub deploys; free/low-cost tiers can sleep and database storage is limited. |
| Railway Node service + Railway PostgreSQL | Fastest developer experience with one-click Postgres provisioning; usage-based pricing needs monitoring for investor demos. |
| Fly.io API + managed PostgreSQL provider | Strong regional control and good Docker support; more operational setup than Render/Railway, especially for database backups. |

Recommended long-run path for this project: keep the Node API on Render or another always-on Node host, and keep PostgreSQL on Supabase using the transaction pooler connection string.

Current implementation choice: Render Web Service + Supabase Postgres. The API is a plain Node service, migrations are npm-script driven, and Socket.io works on the same Render web service as long as the app starts through `server/src/server.js`.

## Render Web Service Settings

Use these settings when creating/updating the Render service from GitHub:

- Root Directory: `server`
- Runtime: Node
- Build Command: `npm ci && npm run migrate && npm run seed:admin-data`
- Start Command: `npm start`
- Health Check Path: `/health`

If you do not want migrations to run during every deploy, set the Build Command to `npm ci` and run `npm run migrate && npm run seed:admin-data` manually from a machine that has the production `DATABASE_URL`.

Required production environment variables are documented in `server/.env.example`.

## Smoke Test

After Render deploy is live:

```powershell
cd D:\DriveE\MobileApp\server
$env:SMOKE_API_BASE_URL="https://vyparhub.onrender.com/api"
$env:SMOKE_SOCKET_ORIGIN="https://vyparhub.onrender.com"
npm run smoke-test
```
