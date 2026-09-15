alter table brands add column if not exists status text not null default 'active';
do $$ begin
  alter table brands add constraint brands_status_check check (status in ('active', 'inactive')) not valid;
exception when duplicate_object then null;
end $$;
update brands set status = 'inactive' where coalesce(is_active, true) = false;

alter table products add column if not exists description text;
alter table products add column if not exists images_json jsonb not null default '[]'::jsonb;
alter table products add column if not exists starting_price numeric(10,2);

alter table product_variants add column if not exists variant_name text;
alter table product_variants add column if not exists sku text;
alter table product_variants add column if not exists selling_price numeric(10,2);
alter table product_variants add column if not exists stock_quantity int not null default 0;
alter table product_variants add column if not exists unit text;
alter table product_variants add column if not exists is_default boolean not null default false;
alter table product_variants add column if not exists status text not null default 'active';
alter table product_variants add column if not exists updated_at timestamptz not null default now();
alter table product_variants alter column size drop not null;

update product_variants
set
  variant_name = coalesce(variant_name, nullif(trim(coalesce(size, '') || ' ' || coalesce(pack, '')), ''), 'Default'),
  selling_price = coalesce(selling_price, buy_price, mrp, 0),
  sku = coalesce(sku, 'variant-' || id::text),
  unit = coalesce(unit, case
    when lower(coalesce(size, '')) like '%kg%' then 'kg'
    when lower(coalesce(size, '')) like '%g%' then 'g'
    when lower(coalesce(size, '')) like '%ml%' then 'ml'
    when lower(coalesce(size, '')) like '%l%' then 'l'
    else 'pcs'
  end),
  status = coalesce(status, 'active');

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

insert into product_variants(product_id, variant_name, sku, mrp, selling_price, stock_quantity, unit, is_default, status)
select
  p.id,
  coalesce(nullif(trim(coalesce(p.size, '') || ' ' || coalesce(p.pack, '')), ''), 'Default'),
  case
    when p.sku is not null and not exists (select 1 from product_variants existing where lower(existing.sku) = lower(p.sku))
      then p.sku
    else 'product-' || p.id::text
  end,
  p.mrp,
  p.buy_price,
  p.stock,
  'pcs',
  true,
  case when coalesce(p.is_active, true) then 'active' else 'inactive' end
from products p
where not exists (select 1 from product_variants pv where pv.product_id = p.id);

create unique index if not exists product_variants_sku_unique_idx on product_variants(sku) where sku is not null;
create index if not exists idx_product_variants_product on product_variants(product_id);
create index if not exists idx_product_variants_status on product_variants(status);

create or replace function refresh_product_starting_price(product_uuid uuid)
returns void as $$
begin
  update products
  set starting_price = (
    select min(selling_price)
    from product_variants
    where product_id = product_uuid and status = 'active'
  ),
  updated_at = now()
  where id = product_uuid;
end;
$$ language plpgsql;

create or replace function product_variant_price_trigger()
returns trigger as $$
begin
  perform refresh_product_starting_price(coalesce(new.product_id, old.product_id));
  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$ language plpgsql;

drop trigger if exists product_variant_refresh_price on product_variants;
create trigger product_variant_refresh_price
after insert or update or delete on product_variants
for each row execute function product_variant_price_trigger();

select refresh_product_starting_price(id) from products;

create table if not exists wallet_accounts (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references users(id) on delete cascade,
  balance numeric(12,2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(customer_id)
);

create table if not exists wallet_transactions (
  id uuid primary key default gen_random_uuid(),
  wallet_account_id uuid not null references wallet_accounts(id) on delete cascade,
  type text not null check (type in ('credit', 'debit')),
  amount numeric(12,2) not null check (amount > 0),
  reason text not null check (reason in ('order_refund','wallet_topup','cashback','admin_adjustment','order_payment')),
  reference_type text,
  reference_id uuid,
  created_by uuid references users(id),
  created_at timestamptz not null default now()
);

create or replace function reconcile_wallet_balance(account_uuid uuid)
returns void as $$
begin
  update wallet_accounts
  set balance = coalesce((
    select sum(case when type = 'credit' then amount else -amount end)
    from wallet_transactions
    where wallet_account_id = account_uuid
  ), 0),
  updated_at = now()
  where id = account_uuid;
end;
$$ language plpgsql;

create or replace function wallet_transaction_reconcile_trigger()
returns trigger as $$
begin
  perform reconcile_wallet_balance(coalesce(new.wallet_account_id, old.wallet_account_id));
  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$ language plpgsql;

drop trigger if exists wallet_transactions_reconcile on wallet_transactions;
create trigger wallet_transactions_reconcile
after insert or update or delete on wallet_transactions
for each row execute function wallet_transaction_reconcile_trigger();

create table if not exists loyalty_tiers (
  id uuid primary key default gen_random_uuid(),
  name text unique not null,
  min_points int not null default 0,
  benefits_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists loyalty_rules (
  id uuid primary key default gen_random_uuid(),
  action text unique not null,
  points_awarded int not null default 0,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists loyalty_ledger (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references users(id) on delete cascade,
  points int not null,
  type text not null check (type in ('earned', 'redeemed', 'expired')),
  reason text not null,
  reference_type text,
  reference_id uuid,
  created_at timestamptz not null default now(),
  expires_at timestamptz
);

create table if not exists redeemable_rewards (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  points_cost int not null check (points_cost >= 0),
  reward_type text not null check (reward_type in ('coupon', 'free_delivery', 'product')),
  reward_value_json jsonb not null default '{}'::jsonb,
  active boolean not null default true,
  stock_limit int,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists referral_codes (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references users(id) on delete cascade,
  code text unique not null,
  created_at timestamptz not null default now(),
  unique(customer_id)
);

create table if not exists referral_events (
  id uuid primary key default gen_random_uuid(),
  referrer_customer_id uuid not null references users(id) on delete cascade,
  referred_customer_id uuid references users(id) on delete set null,
  status text not null default 'pending' check (status in ('pending', 'joined', 'rewarded')),
  reward_amount numeric(12,2) not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists delivery_zones (
  id uuid primary key default gen_random_uuid(),
  name text unique not null,
  pincodes_json jsonb not null default '[]'::jsonb,
  estimated_delivery_minutes int not null default 120,
  delivery_fee numeric(10,2) not null default 0,
  free_delivery_min_order numeric(10,2) not null default 0,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists home_sections (
  id uuid primary key default gen_random_uuid(),
  section_key text not null check (section_key in ('top_deals','flash_sale','hot_right_now','featured')),
  title text not null,
  display_order int not null default 0,
  active boolean not null default true,
  starts_at timestamptz,
  ends_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists home_section_items (
  id uuid primary key default gen_random_uuid(),
  home_section_id uuid not null references home_sections(id) on delete cascade,
  product_id uuid references products(id) on delete cascade,
  variant_id uuid references product_variants(id) on delete cascade,
  display_order int not null default 0,
  created_at timestamptz not null default now(),
  check (product_id is not null or variant_id is not null)
);

create table if not exists admin_activity_log (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid references users(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  before_json jsonb,
  after_json jsonb,
  created_at timestamptz not null default now()
);

create table if not exists notifications_log (
  id uuid primary key default gen_random_uuid(),
  target text not null check (target in ('all', 'segment', 'user')),
  title text not null,
  body text not null,
  segment_json jsonb not null default '{}'::jsonb,
  sent_by_admin_id uuid references users(id) on delete set null,
  sent_at timestamptz not null default now(),
  delivery_status text not null default 'queued'
);

create index if not exists idx_wallet_transactions_account on wallet_transactions(wallet_account_id, created_at desc);
create index if not exists idx_loyalty_ledger_customer on loyalty_ledger(customer_id, created_at desc);
create index if not exists idx_referral_events_referrer on referral_events(referrer_customer_id);
create index if not exists idx_home_section_items_section on home_section_items(home_section_id, display_order);
create index if not exists idx_admin_activity_log_entity on admin_activity_log(entity_type, entity_id);
create index if not exists idx_notifications_log_sent on notifications_log(sent_at desc);
