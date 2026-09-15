-- Repair older live databases that were created before all import upsert
-- conflict targets had matching unique indexes.

with duplicate_brands as (
  select
    id,
    first_value(id) over (partition by name order by created_at nulls last, id) as keeper_id,
    row_number() over (partition by name order by created_at nulls last, id) as rn
  from brands
  where name is not null
)
update products p
set brand_id = d.keeper_id
from duplicate_brands d
where d.rn > 1 and p.brand_id = d.id;

with duplicate_brands as (
  select
    id,
    row_number() over (partition by name order by created_at nulls last, id) as rn
  from brands
  where name is not null
)
delete from brands b
using duplicate_brands d
where d.rn > 1 and b.id = d.id;

with duplicate_product_skus as (
  select
    id,
    sku,
    row_number() over (
      partition by lower(sku)
      order by created_at nulls last, id
    ) as rn
  from products
  where nullif(trim(coalesce(sku, '')), '') is not null
)
update products p
set sku = left(d.sku, 180) || '-' || d.rn::text
from duplicate_product_skus d
where p.id = d.id and d.rn > 1;

with duplicate_variant_skus as (
  select
    id,
    sku,
    row_number() over (
      partition by lower(sku)
      order by created_at nulls last, id
    ) as rn
  from product_variants
  where nullif(trim(coalesce(sku, '')), '') is not null
)
update product_variants pv
set sku = left(d.sku, 180) || '-' || d.rn::text
from duplicate_variant_skus d
where pv.id = d.id and d.rn > 1;

create unique index if not exists brands_name_unique_idx on brands(name);
create unique index if not exists categories_slug_unique_idx on categories(slug);
create unique index if not exists products_sku_unique_idx on products(sku);
create unique index if not exists product_variants_sku_unique_full_idx on product_variants(sku);
create unique index if not exists delivery_zones_name_unique_idx on delivery_zones(name);
