alter table refund_requests add column if not exists request_type text not null default 'return'
  check (request_type in ('return','exchange','cancel_refund'));
alter table refund_requests add column if not exists items_json jsonb not null default '[]'::jsonb;
alter table refund_requests add column if not exists quantity_total int not null default 0;
alter table refund_requests add column if not exists customer_notes text;

create index if not exists idx_refund_requests_status on refund_requests(status, created_at desc);
