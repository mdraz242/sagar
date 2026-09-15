# Local Server Setup

These steps were verified on Windows with Docker Desktop on June 27, 2026, then re-run from a clean Docker PostgreSQL volume on June 29, 2026.

## Prerequisites

- Node.js available on `PATH`
- Docker Desktop running
- Port `55433` available for PostgreSQL
- Port `8081` available for the API

The project uses `55433` instead of host port `5432` because this machine already had a native PostgreSQL process on `5432`. The API uses `8081` because `8080` was already occupied by `httpd`.

## Setup

From `D:\DriveE\MobileApp\server`:

```powershell
Copy-Item .env.example .env
```

Use local-only placeholder secrets in `.env`:

```env
NODE_ENV=development
PORT=8081
DATABASE_URL=postgres://postgres:postgres@127.0.0.1:55433/vyparhub
JWT_ACCESS_SECRET=local-dev-access-secret-not-for-production
JWT_REFRESH_SECRET=local-dev-refresh-secret-not-for-production
JWT_ACCESS_EXPIRES=15m
JWT_REFRESH_EXPIRES=30d
CORS_ORIGIN=*
FCM_SERVER_KEY=local-dev-fcm-placeholder
OTP_PROVIDER=mock
OTP_CODE_TTL_MINUTES=5
OTP_DEV_CODE=1234
MSG91_AUTH_KEY=local-dev-msg91-placeholder
MSG91_TEMPLATE_ID=local-dev-msg91-template-placeholder
MSG91_SENDER_ID=VYPARH
PUBLIC_API_BASE_URL=http://localhost:8081
```

Start PostgreSQL:

```powershell
docker compose up -d postgres
```

Install dependencies:

```powershell
npm install
```

Run migrations and seed data:

```powershell
npm run migrate
npm run seed
```

Start the API:

```powershell
npm run dev
```

Verify health:

```powershell
Invoke-RestMethod http://localhost:8081/health
```

Expected response:

```json
{"success":true,"data":{"status":"ok"}}
```

## Verified Seed Users

The seed script was verified to insert:

| Phone | Password | Role | Shop |
| --- | --- | --- | --- |
| `9876543210` | `Demo@123` | `customer` | `Sharma Kirana Store` |
| `9999999999` | `Admin@123` | `super_admin` | `VyparHub HQ` |

Verification query used:

```powershell
docker exec vyparhub-postgres psql -U postgres -d vyparhub -c "select phone, role, shop_name from users where phone in ('9876543210','9999999999') order by phone;"
```

Verified output:

```text
   phone    |    role     |      shop_name
------------+-------------+---------------------
 9876543210 | customer    | Sharma Kirana Store
 9999999999 | super_admin | VyparHub HQ
```

## Verified OTP, Cart, Address, And Order Walkthrough

This PowerShell walkthrough was executed against the local API on June 27, 2026 and re-verified on June 29, 2026:

```powershell
$base = 'http://localhost:8081/api'
$phone = '7777777777'

$otpRequest = Invoke-RestMethod -Method Post -Uri "$base/auth/otp/send" -ContentType 'application/json' -Body (@{ phone = $phone } | ConvertTo-Json)

$otpVerify = Invoke-RestMethod -Method Post -Uri "$base/auth/otp/verify" -ContentType 'application/json' -Body (@{
  phone = $phone
  code = $otpRequest.data.devCode
  name = 'Demo Retailer'
  shopName = 'Demo Store'
  address = 'Test Market'
  area = 'Delhi'
  pincode = '110001'
} | ConvertTo-Json)

$token = $otpVerify.data.accessToken
$headers = @{ Authorization = "Bearer $token" }

$products = Invoke-RestMethod -Method Get -Uri "$base/products?page=1&limit=1"
$productId = $products.data.items[0].id

$cartAdd = Invoke-RestMethod -Method Post -Uri "$base/cart/add" -Headers $headers -ContentType 'application/json' -Body (@{
  productId = $productId
  quantity = 2
} | ConvertTo-Json)

$address = Invoke-RestMethod -Method Post -Uri "$base/addresses" -Headers $headers -ContentType 'application/json' -Body (@{
  name = 'Demo Retailer'
  phone = $phone
  line1 = 'Shop 12, Main Market'
  area = 'Sector 12'
  city = 'Delhi'
  state = 'Delhi'
  pincode = '110001'
  isDefault = $true
} | ConvertTo-Json)

$order = Invoke-RestMethod -Method Post -Uri "$base/orders" -Headers $headers -ContentType 'application/json' -Body (@{
  addressId = $address.data.id
  notes = 'Deliver before noon'
  items = @(@{ productId = $productId; quantity = 2 })
} | ConvertTo-Json -Depth 5)

Invoke-RestMethod -Method Get -Uri "$base/orders/$($order.data.id)" -Headers $headers
```

Verified summary:

```json
{
  "otpProvider": "mock",
  "otpDevCode": "1234",
  "cartCountAfterAdd": 1,
  "cartQuantityAfterAdd": 2,
  "orderTotal": "1536.00",
  "orderItems": 1,
  "persistedOrderItemRows": 1,
  "persistedOrderQuantity": 2
}
```

## OTP Provider

Production OTP provider selected: MSG91.

Reason: VyparHub is India-focused, and MSG91 is a practical fit for Indian transactional SMS flows, OTP templates, and sender IDs. Local development stays on `OTP_PROVIDER=mock` so developers can run the full login flow without paid SMS credentials.
