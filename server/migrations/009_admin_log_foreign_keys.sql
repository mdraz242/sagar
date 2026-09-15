do $$
declare
  constraint_name text;
begin
  for constraint_name in
    select con.conname
    from pg_constraint con
    join pg_class rel on rel.oid = con.conrelid
    join pg_namespace nsp on nsp.oid = rel.relnamespace
    where nsp.nspname = 'public'
      and rel.relname = 'admin_activity_log'
      and con.contype = 'f'
      and pg_get_constraintdef(con.oid) ilike '%foreign key (admin_id)%'
  loop
    execute format('alter table admin_activity_log drop constraint %I', constraint_name);
  end loop;
end $$;

update admin_activity_log log
set admin_id = null
where admin_id is not null
  and not exists (select 1 from admins a where a.id = log.admin_id);

alter table admin_activity_log
  add constraint admin_activity_log_admin_id_fkey
  foreign key (admin_id) references admins(id) on delete set null;

do $$
declare
  constraint_name text;
begin
  for constraint_name in
    select con.conname
    from pg_constraint con
    join pg_class rel on rel.oid = con.conrelid
    join pg_namespace nsp on nsp.oid = rel.relnamespace
    where nsp.nspname = 'public'
      and rel.relname = 'notifications_log'
      and con.contype = 'f'
      and pg_get_constraintdef(con.oid) ilike '%foreign key (sent_by_admin_id)%'
  loop
    execute format('alter table notifications_log drop constraint %I', constraint_name);
  end loop;
end $$;

update notifications_log log
set sent_by_admin_id = null
where sent_by_admin_id is not null
  and not exists (select 1 from admins a where a.id = log.sent_by_admin_id);

alter table notifications_log
  add constraint notifications_log_sent_by_admin_id_fkey
  foreign key (sent_by_admin_id) references admins(id) on delete set null;
