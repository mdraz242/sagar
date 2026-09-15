# VyparHub REST API

Base URL: `http://localhost:8081/api`

All responses use:

```json
{ "success": true, "data": {} }
```

Errors use:

```json
{ "success": false, "error": { "message": "Error message", "details": {} } }
```

Protected routes require:

```http
Authorization: Bearer <accessToken>
```

## Auth

### Register with password

`POST /auth/register`

```json
{
  "name": "Ramesh Sharma",
  "shopName": "Sharma Kirana Store",
  "phone": "9876543210",
  "password": "Demo@123",
  "address": "Main Market, Sector 12",
  "area": "Delhi",
  "pincode": "110001"
}
```

### Login with password

`POST /auth/login`

```json
{ "phone": "9876543210", "password": "Demo@123" }
```

### Send OTP

`POST /auth/otp/send`

Rate limited to 3 requests per phone per 10 minutes.

```json
{ "phone": "7777777777" }
```

`POST /auth/otp/resend` accepts the same body and issues a fresh OTP. The older `POST /auth/otp/request` route is kept only as a backward-compatible alias to this same MSG91-backed handler.

Local development uses `OTP_PROVIDER=mock` and returns `devCode`. Production should set `OTP_PROVIDER=msg91` and configure `MSG91_AUTH_KEY`, `MSG91_TEMPLATE_ID`, `MSG91_SENDER_ID`, and `OTP_CODE_TTL_MINUTES=10`.

### Verify OTP

`POST /auth/otp/verify`

```json
{
  "phone": "7777777777",
  "code": "123456",
  "name": "Demo Retailer",
  "shopName": "Demo Store",
  "address": "Test Market",
  "area": "Delhi",
  "pincode": "110001"
}
```

### Logout

`POST /auth/logout`

### Refresh token

`POST /auth/refresh`

```json
{ "refreshToken": "<refresh-token>" }
```

Returns a fresh `accessToken`, `refreshToken`, and `user`.

## Products

### List products

`GET /products?page=1&limit=20&categoryId=snacks&search=chips&brand=Haldiram`

Filters:

- `page`, `limit`
- `categoryId`: category UUID or slug
- `search`: English/Hindi product name search
- `brand`

### Product details

`GET /products/:id`

`:id` can be a product UUID or SKU.

## Categories

`GET /categories`

Optional:

- `isActive=true`
- `isActive=false`
- `isActive=all`

## Offers

`GET /offers`

## Cart

### Get cart

`GET /cart`

### Add item

`POST /cart/add`

```json
{ "productId": "<product-uuid>", "variantKey": "Pack_10", "quantity": 2 }
```

`variantKey` is optional. The API also accepts a legacy `cartKey` in the form `<productId>__<variantKey>`.

### Remove item

`POST /cart/remove`

```json
{ "productId": "<product-uuid>", "variantKey": "Pack_10", "quantity": 1 }
```

If the remaining quantity reaches zero, the row is deleted.

## Addresses

### List addresses

`GET /addresses`

### Create address

`POST /addresses`

```json
{
  "name": "Ramesh Sharma",
  "phone": "9876543210",
  "line1": "Shop 12, Main Market",
  "area": "Sector 12",
  "city": "Delhi",
  "state": "Delhi",
  "pincode": "110001",
  "isDefault": true
}
```

### Update address

`PUT /addresses/:id`

### Set default address

`PATCH /addresses/:id/default`

### Delete address

`DELETE /addresses/:id`

## Orders

### Create order

`POST /orders`

```json
{
  "addressId": "<address-uuid>",
  "paymentMode": "cod",
  "notes": "Deliver before noon",
  "items": [
    { "productId": "<product-uuid>", "quantity": 2, "variantKey": "Pack_10" }
  ]
}
```

The server calculates prices from the product catalog and writes normalized `order_items`; client-supplied prices are ignored.
When `paymentMode` is `cod`, the server also writes a pending `payments` row with mode `cod`.

### List orders

`GET /orders?page=1&limit=20&status=pending`

Customers only see their own orders. Admin and super admin users see all orders.

### Order details

`GET /orders/:id`

## Payments

### Create Razorpay order

`POST /payments/create-order`

Protected. Body:

```json
{ "orderId": "<internal-order-uuid>" }
```

Returns the public Razorpay `keyId`, `razorpayOrderId`, amount in paise, currency, and the internal order id. The client must use these values to open Razorpay Checkout.

### Razorpay webhook

`POST /payments/webhook`

Public endpoint configured in Razorpay Dashboard. The server verifies `x-razorpay-signature` using `RAZORPAY_WEBHOOK_SECRET`; only signature-verified `payment.captured` events mark an internal order as `confirmed` and insert a paid `payments` row.

## Users

- `GET /profile`
- `PUT /profile`

`PUT /profile` also accepts `fcmToken` to store the device token for push notifications.

## Admin

Admin routes require role `admin` or `super_admin`.

- `GET /admin/dashboard`
- `GET /admin/orders`
- `GET /admin/products`
- `POST /admin/products`
- `PUT /admin/products/:id`
- `DELETE /admin/products/:id`
- `GET /admin/categories`
- `POST /admin/categories`
- `PUT /admin/categories/:id`
- `DELETE /admin/categories/:id`
- `GET /admin/brands`
- `POST /admin/brands`
- `PUT /admin/brands/:id`
- `DELETE /admin/brands/:id`
- `GET /admin/offers`
- `POST /admin/offers`
- `PUT /admin/offers/:id`
- `DELETE /admin/offers/:id`
- `PATCH /admin/orders/:id/status`
- `POST /admin/uploads`

`POST /admin/uploads` accepts multipart form data with field `file` and returns:

```json
{ "path": "/uploads/<filename>", "url": "/uploads/<filename>" }
```

Uploads are stored on local disk under `server/uploads` and served from `/uploads/*`. This is simple for local/investor demos; production should move this to S3 or Cloudflare R2.

`PATCH /admin/orders/:id/status` body:

```json
{ "status": "shipped" }
```

Status updates trigger the Phase 5 notification service when Firebase Admin credentials are configured.
