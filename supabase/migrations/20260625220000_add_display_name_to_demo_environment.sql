-- Demo migration: add an optional human-friendly name to the environment row.
-- Nullable (no default) so it applies cleanly to the existing 'current' row.
alter table public.demo_environment
  add column if not exists display_name text;
