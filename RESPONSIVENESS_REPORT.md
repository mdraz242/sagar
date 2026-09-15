# Responsiveness Report

## Mobile

- Starts at 320px width.
- Single-column page flow.
- Bottom navigation preserved.
- Product grids use two columns.
- Category detail uses compact left rail plus two-column product grid.

## Tablet

- Wider shell up to 820px.
- Category grid expands to six columns.
- Product grids expand to three columns.
- Padding increases from mobile spacing.

## Desktop and Web

- Shell expands up to 1180px.
- Product grids use four columns.
- Category grids support up to eight columns.
- Admin dashboard stats expand from two to four columns.

## Techniques Used

- `LayoutBuilder`
- `MediaQuery`
- `Expanded`
- `Wrap`
- Adaptive `GridView.count`
- Responsive helper utilities in `core/utils/responsive.dart`

## Notes

The visual language remains aligned with the original uploaded mobile-first design: orange/blue VyparHub palette, sticky header, delivery strip, fixed bottom navigation, rounded cards, product margin cards, promo banners, and category rails.
