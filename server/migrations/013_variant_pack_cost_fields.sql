alter table product_variants add column if not exists pack_quantity int not null default 1;
alter table product_variants add column if not exists cost_price numeric(10,2);
alter table product_variants add column if not exists is_active boolean not null default true;

update product_variants
set
  pack_quantity = greatest(1, coalesce(pack_quantity, 1)),
  is_active = coalesce(is_active, coalesce(status, 'active') = 'active'),
  cost_price = coalesce(cost_price, selling_price, buy_price, mrp, 0)
where pack_quantity is null
   or pack_quantity < 1
   or is_active is null
   or cost_price is null;

create index if not exists idx_product_variants_active on product_variants(is_active);

create or replace function refresh_product_starting_price(product_uuid uuid)
returns void as $$
begin
  update products
  set starting_price = (
    select min(selling_price)
    from product_variants
    where product_id = product_uuid
      and status = 'active'
      and coalesce(is_active, true) = true
  ),
  updated_at = now()
  where id = product_uuid;
end;
$$ language plpgsql;

select refresh_product_starting_price(id) from products;
