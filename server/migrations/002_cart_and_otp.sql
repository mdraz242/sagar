create table if not exists cart_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  product_id uuid not null references products(id),
  variant_key text,
  quantity int not null check (quantity > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, product_id, variant_key)
);

create unique index if not exists cart_items_user_product_null_variant_idx
  on cart_items(user_id, product_id)
  where variant_key is null;

create index if not exists idx_cart_items_user on cart_items(user_id);

create table if not exists otp_codes (
  id uuid primary key default gen_random_uuid(),
  phone text not null,
  code_hash text not null,
  expires_at timestamptz not null,
  attempts int not null default 0,
  consumed_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists idx_otp_codes_phone_created on otp_codes(phone, created_at desc);
create index if not exists idx_otp_codes_expires on otp_codes(expires_at);
