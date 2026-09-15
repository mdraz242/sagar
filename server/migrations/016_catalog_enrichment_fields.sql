-- 014_catalog_enrichment_fields.sql
-- Adds the catalog enrichment fields needed by the redesigned admin
-- Add Product / Add Category / Add Brand forms.
--
-- Every change here is purely additive (IF NOT EXISTS / ADD COLUMN with a
-- safe default) so it is safe to run against a live database with existing
-- rows. Nothing is dropped, renamed, or backfilled destructively.
--
-- NOTE: rename this file if "014" already exists in your migrations folder
-- so it doesn't collide with another migration.

-- ---------------------------------------------------------------------------
-- products: SEO / compliance / descriptive fields shown in the "Additional
-- Details" step of the Add Product wizard.
-- ---------------------------------------------------------------------------
alter table products
  add column if not exists hsn_code text,
  add column if not exists meta_title text,
  add column if not exists meta_description text,
  add column if not exists ingredients text,
  add column if not exists storage_instructions text,
  add column if not exists shelf_life text,
  add column if not exists country_of_origin text default 'India',
  add column if not exists highlights jsonb not null default '[]'::jsonb;

-- ---------------------------------------------------------------------------
-- product_variants: pricing / inventory fields shown in the "Pricing &
-- Inventory" and "Variants" steps of the Add Product wizard.
-- ---------------------------------------------------------------------------
alter table product_variants
  add column if not exists tax_percent numeric(5,2) not null default 0,
  add column if not exists discount_percent numeric(5,2) not null default 0,
  add column if not exists low_stock_alert integer not null default 0,
  add column if not exists barcode text;

-- ---------------------------------------------------------------------------
-- categories: description field shown in the Add Category modal.
-- ---------------------------------------------------------------------------
alter table categories
  add column if not exists description text;

-- ---------------------------------------------------------------------------
-- brands: slug + description fields shown in the Add Brand modal.
-- ---------------------------------------------------------------------------
alter table brands
  add column if not exists slug text,
  add column if not exists description text;

-- Backfill slugs for any existing brands so the unique index below doesn't
-- fail on nulls or collisions. Safe/no-op if brands table is empty or every
-- row already has a slug.
update brands
  set slug = lower(regexp_replace(regexp_replace(trim(name), '[^a-zA-Z0-9]+', '-', 'g'), '(^-+|-+$)', '', 'g'))
  where slug is null or slug = '';

-- De-duplicate any slugs that collided during backfill (keeps the first
-- created row's slug as-is, appends the row's short id to the rest).
update brands b
  set slug = b.slug || '-' || substr(b.id::text, 1, 8)
  where exists (
    select 1 from brands b2
    where b2.slug = b.slug and b2.id <> b.id and b2.created_at < b.created_at
  );

create unique index if not exists brands_slug_key on brands (slug);
