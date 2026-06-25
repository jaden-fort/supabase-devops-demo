insert into public.demo_environment (name, label)
values ('current', 'local-preview')
on conflict (name) do update
set
  label = excluded.label,
  updated_at = now();
