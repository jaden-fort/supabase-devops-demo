create table if not exists public.demo_environment (
  name text primary key,
  label text not null,
  updated_at timestamptz not null default now()
);

alter table public.demo_environment enable row level security;

create policy "demo environment is readable by everyone"
on public.demo_environment
for select
using (true);

create or replace function public.demo_database_identity()
returns text
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(
    (
      select label || ': ' || current_database()
      from public.demo_environment
      where name = 'current'
      limit 1
    ),
    current_database()
  );
$$;

grant execute on function public.demo_database_identity() to anon, authenticated;
