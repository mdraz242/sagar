alter type order_status add value if not exists 'partially_refunded';
alter type order_status add value if not exists 'refunded';

create table if not exists refunds (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references orders(id) on delete cascade,
  refund_request_id uuid references refund_requests(id) on delete set null,
  amount numeric(12,2) not null check (amount > 0),
  reason text not null,
  destination text not null check (destination in ('original_payment','wallet','upi','store_credit')),
  items_json jsonb not null default '[]'::jsonb,
  initiated_by uuid references admins(id) on delete set null,
  status text not null default 'pending' check (status in ('pending','processed','failed')),
  idempotency_key text not null,
  metadata_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  processed_at timestamptz,
  unique(initiated_by, idempotency_key)
);

create index if not exists idx_refunds_order on refunds(order_id, created_at desc);
create index if not exists idx_refunds_status on refunds(status, created_at desc);

insert into app_settings(key, value_json)
values (
  'refunds',
  jsonb_build_object(
    'enabledDestinations',
    jsonb_build_array('wallet', 'store_credit', 'original_payment', 'upi'),
    'defaultDestination',
    'wallet'
  )
)
on conflict(key) do nothing;
