-- Test migration: exercises the migration pipeline end to end.
-- Idempotent DDL + a public read policy so it applies cleanly on a fresh or existing DB.
create table if not exists public.test_migration_log (
  id bigint generated always as identity primary key,
  note text not null,
  applied_at timestamptz not null default now()
);

alter table public.test_migration_log enable row level security;

create policy "test migration rows are readable by everyone"
on public.test_migration_log
for select
using (true);

insert into public.test_migration_log (note)
values ('test migration applied');
