alter table orders add column if not exists idempotency_key text;

create unique index if not exists orders_user_id_idempotency_key_idx
  on orders(user_id, idempotency_key)
  where idempotency_key is not null and idempotency_key <> '';
