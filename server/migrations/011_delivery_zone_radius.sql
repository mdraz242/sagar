alter table delivery_zones
  add column if not exists zone_type text not null default 'pincode',
  add column if not exists center_lat numeric(10,7),
  add column if not exists center_lng numeric(10,7),
  add column if not exists radius_km numeric(10,2);

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'delivery_zones_zone_type_check'
  ) then
    alter table delivery_zones
      add constraint delivery_zones_zone_type_check
      check (zone_type in ('pincode', 'radius'));
  end if;
end $$;

create unique index if not exists delivery_zones_name_unique_idx
  on delivery_zones(name);

insert into delivery_zones(
  name,
  zone_type,
  center_lat,
  center_lng,
  radius_km,
  pincodes_json,
  estimated_delivery_minutes,
  delivery_fee,
  free_delivery_min_order,
  active
)
values (
  'Siwan 200km Radius',
  'radius',
  26.2196,
  84.3567,
  200,
  '[]'::jsonb,
  120,
  20,
  999,
  true
)
on conflict(name) do update set
  zone_type = excluded.zone_type,
  center_lat = excluded.center_lat,
  center_lng = excluded.center_lng,
  radius_km = excluded.radius_km,
  estimated_delivery_minutes = excluded.estimated_delivery_minutes,
  delivery_fee = excluded.delivery_fee,
  free_delivery_min_order = excluded.free_delivery_min_order,
  active = excluded.active,
  updated_at = now();
