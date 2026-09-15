-- Snapshot the delivery address on each order at checkout time, instead of only
-- keeping a live foreign key to addresses. This makes invoices immutable: if the
-- customer later edits or deletes the saved address, past invoices are unaffected.
alter table orders add column if not exists delivery_address jsonb;

-- Best-effort backfill for existing orders: copy whatever the linked address
-- currently contains. Orders whose address was already edited/deleted since being
-- placed will reflect that edited/missing state here -- the original at-checkout
-- value was never captured for pre-migration orders, so this is the closest
-- available proxy, not a perfect historical record.
update orders o
set delivery_address = (
  select jsonb_build_object(
    'name', a.name,
    'phone', a.phone,
    'line1', a.line1,
    'area', a.area,
    'city', a.city,
    'state', a.state,
    'pincode', a.pincode
  )
  from addresses a
  where a.id = o.address_id
)
where o.delivery_address is null
  and o.address_id is not null;
