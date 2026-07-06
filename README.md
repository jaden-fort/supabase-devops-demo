# Fort Database DevOps Demo

This repo is a small Supabase database DevOps demo. It uses GitFlow-style branches,
GitHub Actions, Supabase migrations, and a plain static web page that displays the
database it is connected to.

The page does not hard-code the database name. It calls
`public.demo_database_identity()` through Supabase RPC, and the function reads from
Postgres with `current_database()`.

## What Is In The Demo

- `main`: production branch.
- `develop`: persistent staging branch.
- `feature/*`: local work that opens PRs into `develop`.
- `release/*`: reviewed release candidates that open PRs into `main`.
- `supabase/migrations`: versioned database changes.
- `supabase/seed.sql`: local and preview sample data.
- `web/`: plain HTML, CSS, and JavaScript app.
- `.github/workflows`: CI plus staging and production deployment workflows.



## Local Setup

1. Install the Supabase CLI and Docker.
2. Start the local database:
  ```bash
   supabase db start
  ```
3. Copy the example browser config:
  ```bash
   cp web/env.example.js web/env.js
  ```
4. Replace the placeholder anon key in `web/env.js` with the local anon key from:
  ```bash
   supabase status
  ```
5. Serve the page from the repo root:
  ```bash
   python3 -m http.server 3000
  ```
6. Open `http://127.0.0.1:3000/web/`.



## Manual GitHub Setup

Do these steps yourself in GitHub. This repo intentionally does not link anything
for you.

1. Push this repository to GitHub.
2. Create the `develop` branch from `main`.
3. Add a repository secret (used by the staging and production deploy workflows
  to authenticate the Supabase CLI):
  - `SUPABASE_ACCESS_TOKEN`
4. Create a `staging` environment and add:
  - `SUPABASE_PROJECT_ID`
  - `SUPABASE_DB_PASSWORD`
  - `SUPABASE_URL`
  - `SUPABASE_ANON_KEY`
5. Create a `production` environment and add the same names with production values.
6. Protect `develop`:
  - require pull requests
  - require the CI check
  - block force pushes and deletion
7. Protect `main`:
  - require pull requests
  - require the CI check
  - require review
  - block force pushes and deletion
8. Add a required reviewer to the `production` environment so production deploys
  pause for approval.



## Manual Supabase Setup

Do these steps yourself in Supabase. This repo intentionally does not create or
link projects for you.

1. Create a production Supabase project.
2. Create a persistent `develop` branch or a separate staging project.
3. Record each project or branch ref and database password for GitHub secrets.
4. Enable the GitHub integration for the production project.
5. Connect this GitHub repository.
6. Set the working directory to `.` because `supabase/` is at the repo root.
7. Enable automatic branching for PR previews.
8. Keep automatic production deployment disabled if GitHub Actions should remain
  the deploy authority.

gtest

## Docs

- Supabase local development CLI config:
[https://supabase.com/docs/guides/local-development/cli/config](https://supabase.com/docs/guides/local-development/cli/config)
- Supabase managing environments:
[https://supabase.com/docs/guides/deployment/managing-environments](https://supabase.com/docs/guides/deployment/managing-environments)
- Supabase branching:
[https://supabase.com/docs/guides/deployment/branching](https://supabase.com/docs/guides/deployment/branching)
- Supabase JavaScript RPC:
[https://supabase.com/docs/reference/javascript/rpc](https://supabase.com/docs/reference/javascript/rpc)
- Supabase CLI GitHub Action:
[https://github.com/supabase/setup-cli](https://github.com/supabase/setup-cli)
- GitHub Actions secrets:
[https://docs.github.com/en/actions/security-for-github-actions/security-guides/using-secrets-in-github-actions](https://docs.github.com/en/actions/security-for-github-actions/security-guides/using-secrets-in-github-actions)
- GitHub environments:
[https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)
- GitHub protected branches:
[https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches)



## Demo Flow

1. Create `feature/show-db-name` from `develop`.
2. Add or change a migration, then open a PR into `develop`.
3. CI starts a fresh local Supabase database and verifies the RPC returns a value.
4. Merge to `develop`; GitHub Actions deploys migrations to staging.
5. Create `release/demo-1` from `develop` and open a PR into `main`.
6. Supabase Branching creates a preview database for the release PR (review it in
  Supabase as needed; CI does not test it).
7. Merge to `main`; approve the production environment job; production migrations
  deploy and the production web artifact points at production Supabase.



## CI Database Strategy

CI runs a single check: on PRs into `develop` or `main` it starts a throwaway
local Supabase database on the runner and verifies the RPC with `psql`. Fast,
isolated, and free. Migrations reach staging and production when commits land on
`develop` and `main` (see the deploy workflows), not from CI.

## Environment Labels

Local and preview databases use `local-preview` from `supabase/seed.sql`.

For staging and production, set a human-readable label once after deployment:

```sql
insert into public.demo_environment (name, label)
values ('current', 'develop')
on conflict (name) do update set label = excluded.label, updated_at = now();
```

Use `production` instead of `develop` for the production project.