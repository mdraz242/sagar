# Product Catalog Phase Audit

## Product Data Surfaces

All customer product surfaces now consume the same normalized product contract from the Node API:

| Surface | Endpoint / Source | Notes |
| --- | --- | --- |
| Home sections: Top Deals, Flash Sale, Hot Right Now, Featured, Recommended | `GET /api/home-sections` | Uses `catalogRepository.homeSections()` and `normalizeProductPayload()`. |
| Category listing / In Demand | `GET /api/products?categoryId=...` | Uses `catalogRepository.products()` and the same normalization. |
| Search results / Quick Buy suggestions | `GET /api/products?search=...` | Uses the same products endpoint and normalized variants. |
| Product detail / variant sheet | `GET /api/products/:id` plus product payload from listings | Returns `variants`, `default_variant`, top-level MRP/selling/stock derived from active variants. |
| Bulk banners / curated rails | Home section product payloads | No independent pricing fallback; cards use the same Flutter `Product` model. |
| Top Brands | `GET /api/brands` / admin brand data | Public brand filtering excludes inactive/deleted brands. |

## Normalized Product Contract

Every product payload should include:

- `mrp`, `buyPrice` / `buy_price`, `stock` derived from the first in-stock active variant.
- `variants[]` with `id`, `product_id`, `size`, `pack`, `pack_quantity`, `mrp`, `buyPrice`, `costPrice`, `stock`, and active flags.
- `default_variant` / `defaultVariant` for callers that need the displayed variant explicitly.

If no active variant exists, the app must treat the product as unavailable instead of silently displaying `Rs 0`.

## Phase Completion Notes

- Phase 1: Home/category/search/detail surfaces share the backend catalog normalization path.
- Phase 2: Shared customer `ProductCard` now uses fixed name height and aligned margin/button placement.
- Phase 3: Margin display is plain right-aligned blue `Total margin ₹...`, no bordered green pill.
- Phase 4: Admin variants support pack quantity, cost price, active status, validation, and preview; Flutter uses a two-step pack picker.
- Phase 5: Regression should check Home sections, category listing, search/Quick Buy, single-variant direct add, and multi-variant bottom sheet.
