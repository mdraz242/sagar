do $$
declare
  constraint_name text;
begin
  for constraint_name in
    select con.conname
    from pg_constraint con
    join pg_class rel on rel.oid = con.conrelid
    where rel.relname = 'home_sections'
      and con.contype = 'c'
      and pg_get_constraintdef(con.oid) like '%section_key%'
  loop
    execute format('alter table home_sections drop constraint if exists %I', constraint_name);
  end loop;
end $$;

alter table home_sections
  add constraint home_sections_section_key_check
  check (section_key in (
    'top_deals',
    'flash_sale',
    'hot_right_now',
    'featured',
    'recommended',
    'recommended_for_shop'
  ));

insert into home_sections(section_key, title, display_order, active)
values ('recommended_for_shop', 'Recommended for Your Shop', 50, true)
on conflict do nothing;
