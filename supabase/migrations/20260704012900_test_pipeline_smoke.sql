-- Test migration: verifies the migration pipeline end to end.
-- Creates a trivial table that records when this migration was applied.
create table if not exists public.migration_smoke_test (
  id bigint generated always as identity primary key,
  note text not null,
  applied_at timestamptz not null default now()
);

alter table public.migration_smoke_test enable row level security;

create policy "smoke test rows are readable by everyone"
on public.migration_smoke_test
for select
using (true);

insert into public.migration_smoke_test (note)
values ('pipeline smoke test');
