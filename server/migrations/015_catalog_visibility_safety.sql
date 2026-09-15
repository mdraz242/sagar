update products
set is_active = true
where is_active is null;

update categories
set is_active = true
where is_active is null;

update brands
set is_active = true
where is_active is null;

update brands
set status = case when coalesce(is_active, true) then 'active' else 'inactive' end
where status is null;

update product_variants
set
  is_active = coalesce(is_active, coalesce(status, 'active') = 'active'),
  status = coalesce(status, 'active'),
  pack_quantity = greatest(1, coalesce(pack_quantity, 1)),
  stock_quantity = greatest(0, coalesce(stock_quantity, 0)),
  selling_price = coalesce(selling_price, buy_price, mrp, 0),
  cost_price = coalesce(cost_price, selling_price, buy_price, mrp, 0)
where is_active is null
   or status is null
   or pack_quantity is null
   or pack_quantity < 1
   or stock_quantity is null
   or stock_quantity < 0
   or selling_price is null
   or cost_price is null;

alter table products alter column is_active set default true;
alter table categories alter column is_active set default true;
alter table brands alter column is_active set default true;
alter table product_variants alter column is_active set default true;
