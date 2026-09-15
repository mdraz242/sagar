do $$ begin
  create type order_status as enum ('placed','confirmed','packed','shipped','out_for_delivery','delivered','cancelled');
exception when duplicate_object then null; end $$;

alter table orders add column if not exists status_v2 order_status not null default 'placed';

update orders
set status_v2 = case lower(status::text)
  when 'confirmed' then 'confirmed'::order_status
  when 'packed' then 'packed'::order_status
  when 'shipped' then 'shipped'::order_status
  when 'out_for_delivery' then 'out_for_delivery'::order_status
  when 'delivered' then 'delivered'::order_status
  when 'cancelled' then 'cancelled'::order_status
  else 'placed'::order_status
end;

do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_name = 'orders' and column_name = 'status_v2'
  ) then
    alter table orders drop column if exists status;
    alter table orders rename column status_v2 to status;
  end if;
end $$;

create table if not exists order_status_history (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references orders(id) on delete cascade,
  status order_status not null,
  changed_by_admin_id uuid references admins(id) on delete set null,
  changed_at timestamptz not null default now()
);

insert into order_status_history(order_id, status, changed_at)
select o.id, o.status, coalesce(o.created_at, now())
from orders o
where not exists (select 1 from order_status_history h where h.order_id = o.id);

create table if not exists refund_requests (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references orders(id) on delete cascade,
  customer_id uuid references users(id) on delete set null,
  amount numeric(10,2) not null default 0,
  reason text,
  refund_method text not null default 'wallet' check (refund_method in ('original_payment','wallet','upi','store_credit')),
  status text not null default 'requested' check (status in ('requested','approved','rejected','pending_manual_gateway_refund','credited_to_wallet','store_credit_issued')),
  admin_notes text,
  rejection_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_order_status_history_order on order_status_history(order_id, changed_at);
create index if not exists idx_refund_requests_order on refund_requests(order_id);
create index if not exists idx_refund_requests_customer on refund_requests(customer_id, created_at desc);

alter table offers add column if not exists coupon_code text;
alter table offers add column if not exists applies_to text not null default 'all' check (applies_to in ('all','category','product'));
alter table offers add column if not exists category_id uuid references categories(id) on delete set null;
alter table offers add column if not exists max_discount numeric(10,2);
alter table offers add column if not exists min_order_amount numeric(10,2);

create table if not exists referral_settings (
  id boolean primary key default true,
  reward_amount numeric(10,2) not null default 200,
  updated_at timestamptz not null default now(),
  constraint referral_settings_singleton check (id)
);

insert into referral_settings(id, reward_amount)
values(true, 200)
on conflict(id) do nothing;

create table if not exists app_settings (
  key text primary key,
  value_json jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

insert into app_settings(key, value_json)
values('referral', jsonb_build_object('rewardAmount', 200))
on conflict(key) do nothing;

insert into role_permissions(role_id, module, action, allowed)
select r.id, m.module, a.action, true
from roles r
cross join (values ('rewards'),('merchandising'),('delivery_zones'),('notifications')) as m(module)
cross join (values ('view'),('add'),('edit'),('delete'),('export'),('import')) as a(action)
where r.name = 'Super Admin'
on conflict(role_id, module, action) do update set allowed=true, updated_at=now();

insert into role_permissions(role_id, module, action, allowed)
select r.id, m.module, a.action, true
from roles r
cross join (values ('merchandising'),('delivery_zones')) as m(module)
cross join (values ('view'),('add'),('edit'),('delete')) as a(action)
where r.name = 'Catalog Manager'
on conflict(role_id, module, action) do update set allowed=true, updated_at=now();

insert into role_permissions(role_id, module, action, allowed)
select r.id, m.module, a.action, true
from roles r
cross join (values ('rewards'),('merchandising'),('notifications')) as m(module)
cross join (values ('view'),('add'),('edit')) as a(action)
where r.name = 'Marketing'
on conflict(role_id, module, action) do update set allowed=true, updated_at=now();
