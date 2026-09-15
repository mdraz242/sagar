create table if not exists roles (
  id uuid primary key default gen_random_uuid(),
  name text unique not null,
  description text,
  status text not null default 'active' check (status in ('active', 'inactive')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists role_permissions (
  id uuid primary key default gen_random_uuid(),
  role_id uuid not null references roles(id) on delete cascade,
  module text not null,
  action text not null check (action in ('view', 'add', 'edit', 'delete', 'export', 'import')),
  allowed boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(role_id, module, action)
);

create table if not exists admins (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  email text unique not null,
  password_hash text not null,
  role_id uuid references roles(id),
  status text not null default 'active' check (status in ('active', 'inactive')),
  refresh_token_hash text,
  last_login_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table categories add column if not exists parent_id uuid references categories(id) on delete set null;
create index if not exists idx_categories_parent on categories(parent_id);

alter table products add column if not exists brand_id uuid references brands(id) on delete set null;

update products p
set brand_id = b.id
from brands b
where p.brand_id is null and lower(p.brand) = lower(b.name);

insert into roles(name, description, status)
values
  ('Super Admin', 'Full access to all VyparHub admin modules', 'active'),
  ('Catalog Manager', 'Catalog, products, brands and category management', 'active'),
  ('Marketing', 'Offers, banners and customer campaign access', 'active'),
  ('Support', 'Orders, customers, returns and support tickets', 'active')
on conflict(name) do update set description=excluded.description, status=excluded.status, updated_at=now();

insert into role_permissions(role_id, module, action, allowed)
select r.id, m.module, a.action, true
from roles r
cross join (values
  ('dashboard'),('orders'),('products'),('brands'),('categories'),('customers'),('marketing'),
  ('coupons'),('banners'),('reviews'),('returns'),('reports'),('payments'),('payouts'),
  ('settings'),('system'),('logs'),('support'),('users')
) as m(module)
cross join (values ('view'),('add'),('edit'),('delete'),('export'),('import')) as a(action)
where r.name = 'Super Admin'
on conflict(role_id, module, action) do update set allowed=true, updated_at=now();

insert into role_permissions(role_id, module, action, allowed)
select r.id, m.module, a.action, true
from roles r
cross join (values ('dashboard'),('products'),('brands'),('categories'),('reports')) as m(module)
cross join (values ('view'),('add'),('edit'),('delete'),('export'),('import')) as a(action)
where r.name = 'Catalog Manager'
on conflict(role_id, module, action) do update set allowed=true, updated_at=now();

insert into role_permissions(role_id, module, action, allowed)
select r.id, m.module, a.action, true
from roles r
cross join (values ('dashboard'),('marketing'),('coupons'),('banners'),('customers'),('reports')) as m(module)
cross join (values ('view'),('add'),('edit'),('delete'),('export')) as a(action)
where r.name = 'Marketing'
on conflict(role_id, module, action) do update set allowed=true, updated_at=now();

insert into role_permissions(role_id, module, action, allowed)
select r.id, m.module, a.action, true
from roles r
cross join (values ('dashboard'),('orders'),('customers'),('returns'),('support'),('reviews')) as m(module)
cross join (values ('view'),('edit'),('export')) as a(action)
where r.name = 'Support'
on conflict(role_id, module, action) do update set allowed=true, updated_at=now();

insert into admins(name, email, password_hash, role_id, status)
select 'Admin', 'admin@vyparhub.com', crypt('Admin@123', gen_salt('bf')), r.id, 'active'
from roles r
where r.name = 'Super Admin'
on conflict(email) do update set role_id=excluded.role_id, status='active', updated_at=now();

create index if not exists idx_admins_email on admins(email);
create index if not exists idx_role_permissions_role on role_permissions(role_id);
create index if not exists idx_product_variants_sku on product_variants(sku);
