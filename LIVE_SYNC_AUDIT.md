# VyparHub Live Sync Audit

Last updated: 8 July 2026

This audit tracks whether admin-managed entities are filtered from customer-facing APIs after delete/deactivate, and whether customer app sessions receive a live event to refresh without restart.

| Entity | Delete/deactivate removed from public API | Live-sync event fires | Fixed in this phase |
| --- | --- | --- | --- |
| Products | Yes. Public catalog filters inactive/deleted products. | Yes: `product.created`, `product.updated`, `product.deleted`, `catalog.updated`. | Already present, verified by code audit. |
| Product Variants | Yes. Deleted variants no longer join to public product rows. | Yes: variant delete emits `product.updated` with `variantDeleted`. | Already present, verified by code audit. |
| Brands | Yes. Deleted brands are soft-deactivated and related products are hidden from public catalog. | Yes: `brand.deleted`, `catalog.updated`. | Fixed before/within this phase. |
| Categories | Yes. Deleted categories are soft-deactivated and related products are hidden from public catalog. | Yes: `category.deleted`, `category.updated`, `catalog.updated`. | Fixed in this phase. |
| Coupons / Offers | Yes. Deleted offers are removed from the offers table. | Yes: `coupon.deleted` or `banner.deleted`, plus `catalog.updated`. | Fixed in this phase. |
| Banners | Yes. Banner-backed offers are removed from the offers table. | Yes: `banner.deleted`, `catalog.updated`. | Fixed in this phase. |
| Home Sections | Yes. Deleted sections and removed items no longer appear in `home-sections`. | Yes: `home_section.updated`, `home_section.deleted`. | Already present, verified by code audit. |
| Delivery Zones | Yes. Public delivery context now matches only configured zone pincodes. | Yes: `delivery_zone.updated`, `catalog.updated`. | Fixed in Phase 2. |
| Notifications | Not a customer catalog entity. Notification writes create push/log entries. | Yes: `notification.created` for admin/customer flows where applicable. | Not needed. |
| Reviews | Customer-facing review listing is not currently exposed as a live public catalog dependency. | Admin review approval is currently admin-side. | Follow-up: add public product review endpoint if reviews become visible on product detail. |
| Returns / Refunds | Yes. Refund status is read from order/refund APIs. | Yes: `refund.status_changed`, `wallet.transaction_created`. | Already present, verified by code audit. |
| Admin Users / Roles | Admin-only entity. | Admin-only refresh required after RBAC changes. | Not customer-facing. |

## Live Verification Status

Code paths were audited locally. Full live verification still requires two active sessions against the deployed Render/Supabase backend: an admin browser session and a real customer device. The checklist for that manual run is recorded in `WORKFLOW_QA_REPORT.md`.
