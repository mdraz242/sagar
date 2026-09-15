# Phase 6 Dual-Actor Real-Time Validation Report

Date: 2026-07-07

This report tracks the required real simultaneous validation between the live admin panel and a real customer device/emulator. Code support for Phase 5 was updated in this pass, but the checks below require a live admin session and a real Flutter app session against the deployed Render/Supabase backend at the same time. They were not simulated with mock data.

## Checklist

| # | Scenario | Result | Notes |
|---|---|---|---|
| 1 | Admin adds a Flash Sale product with a 5-minute window; user Home updates live and section expires on time. | Pending real-device validation | Requires live admin panel and customer app open simultaneously. |
| 2 | User places a real order; admin Orders list receives it live with bell notification. | Pending real-device validation | Backend emits `order.created`; must be confirmed on deployed admin UI. |
| 3 | Admin moves order Confirmed -> Packed -> Shipped -> Out for Delivery -> Delivered; user receives push and tracking updates after each step. | Pending real-device validation | Requires physical device FCM delivery and admin status changes. |
| 4 | User cancels an early order; admin Orders list updates and prepaid order creates a refund request. | Pending real-device validation | Customer cancel API now accepts a reason and creates `cancel_refund` request for prepaid orders. |
| 5 | User submits partial return on delivered order; admin approves; user sees request status and wallet update when applicable. | Pending real-device validation | Return/exchange UI now submits selected items, quantities, reason, method, and notes. |
| 6 | Admin edits visible product price/stock; user category screen updates live. | Pending real-device validation | Requires live socket event verification with customer app foregrounded. |
| 7 | Admin adds a new product to the currently open category; user sees it live. | Pending real-device validation | Requires deployed admin and customer app connected to the same backend. |

## Implementation Notes From This Pass

- Customer cancel order is now allowed while status is `placed`, `confirmed`, or `packed`.
- Cancel order requires a user-selected reason.
- Prepaid cancelled orders create a `refund_requests` record with `request_type = cancel_refund`.
- Delivered orders can open Return and Exchange flows within the return window.
- Return/Exchange requests now include selected order items, quantities, reason, refund/exchange method, and optional customer notes.
- Order details now surfaces the latest return/exchange/refund request status for the customer.

## Required Manual Validation

Run these checks after deploying the backend migrations and installing a fresh APK:

1. Open the live admin panel in a desktop browser.
2. Open the customer app on a real device using the same deployed API.
3. Place one COD order and one prepaid test order.
4. Exercise cancel, return, exchange, order status changes, and product live updates.
5. Replace each `Pending real-device validation` row above with `Pass` or `Fail` and the observed behavior.
