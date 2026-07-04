# Implementation Gaps

A grounded snapshot of where this demo actually is versus what the README and the
chat history describe. Written by reading the repo state (branches, workflows,
migrations, git log) — not from the docs, which are partly aspirational.

Status legend: 🔴 broken / blocking · 🟠 missing / unimplemented · 🟡 minor

---

## 🔴 1. The documented GitFlow doesn't exist

The README is built entirely around `main` + `develop` + `feature/*` + `release/*`.
The repo actually has only two branches:

- `main`, `test` (currently checked out: `test`)
- **No `develop` branch exists** (local or remote).

Consequences:

- `ci.yml` triggers on PRs into `develop` or `main`, but `develop` is never a
  target, so the "feature → develop" half of the flow can never fire.
- README "Manual GitHub Setup" step 2 ("Create the `develop` branch") was never done.
- Git history is three throwaway commits (`init`, `test`, `test migration`). No
  feature → develop → main journey has ever actually happened.

**To close:** create `develop` from `main` and push it, or rewrite the docs to the
two-branch reality you actually want.

---

## 🔴 2. Staging deploy is blocked by migration history drift

The staging Supabase project has a migration recorded in
`supabase_migrations.schema_migrations` that does not exist locally:

- Local migrations: `20260625210500`, `20260625220000`
- Remote also has: **`20260625232105`** (newer than both, never in git on any branch)

`supabase db push` does a history-consistency check and refuses to run when the
remote knows a version the repo doesn't — so **Deploy Staging currently fails.**

Root cause: a migration was applied to the staging project out-of-band (dashboard
SQL, or a push from another repo/branch) and never committed. This was diagnosed
in chat but the fix was never run (that session was aborted).

**To close (pick one), run against the staging project:**

- If that change matters: `supabase db pull` → commit the generated migration → push.
- If it's junk: `supabase migration repair --status reverted 20260625232105`
  (note: this only edits the bookkeeping table; it does **not** undo any SQL the
  migration ran).

---

## 🟠 3. The original ask in this session is not in the code

This session's request was: *local DB on `develop` PRs, Supabase preview DB on
`main` PRs.* That was implemented here (a 3-job `ci.yml`: `web-files`,
`local-database-smoke`, `preview-database-smoke`, plus README "CI Database
Strategy" and a repo-level `SUPABASE_PROJECT_ID` secret).

**A parallel chat then reverted all of it.** Current on-disk state:

- `ci.yml` has a single job, `local-database-smoke`, that runs the **same local
  smoke test for both `develop` and `main` PRs**.
- There is no `preview-database-smoke` job, no `supabase branches get` lookup, no
  HTTP RPC check against a preview DB.
- README documents the single-check behavior (preview strategy text removed).

So the preview-vs-local split does not exist in the committed repo. If you still
want it, it needs to be re-applied (and would also need a real `develop` branch
per gap #1).

---

## 🟠 4. Supabase preview branches are enabled but unused

Branching was turned on in the Supabase dashboard, but **nothing in the repo
consumes it**:

- CI doesn't test the preview DB (reverted, see #3).
- No PR comment posts the preview DB name (this was planned, partially built, then
  removed).
- No web deploy points at a preview branch.

The actual hard problem identified in chat — *how the dynamic per-PR preview URL +
anon key reach a running web page* — was never solved. Previews may be getting
created on every PR and are simply invisible.

**To close:** decide what "show the preview" means (CI comment of the RPC result is
the lightest option) and wire exactly one consumer of the preview branch.

---

## 🟠 5. The web app is never hosted

Both `deploy-staging.yml` and `deploy-production.yml` build `web/env.js` and
**upload `web/` as a GitHub Actions artifact** (a downloadable zip). There is no
Vercel / Netlify / Pages step, so there is no live URL for any environment.

A long exploration of Vercel (persistent main/develop + ephemeral PR previews) was
discussed and planned, but the user pivoted away from it. Net result: to see the
page you still run it locally and paste in the right config.

**To close:** either accept "local viewing only" and say so in the README, or add a
real hosting step.

---

## 🟠 6. The "see the migration take effect" payoff isn't wired through

The point of the demo is to *visibly* prove a migration propagated.

- A `display_name` column was added (`20260625220000`) as a sample migration, but
  nothing reads it: `demo_database_identity()` still returns only
  `label || current_database()`, and the web page never shows `display_name`.
- Environment labels in `public.demo_environment` must be set **manually via SQL**
  after each deploy (README "Environment Labels"). Nothing automates it, so a fresh
  staging/production DB shows the raw database name until someone runs the insert.

**To close:** if `display_name` is meant to be the visible proof, surface it in the
RPC and the page; otherwise drop the column. Consider seeding the env label as part
of deploy instead of a manual step.

---

## 🟠 7. Manual GitHub / Supabase setup is unverified

The pipeline depends on manual configuration that can't be checked from the repo
and is the usual cause of red deploys:

- Repo secret `SUPABASE_ACCESS_TOKEN`.
- `staging` and `production` GitHub environments, each with `SUPABASE_PROJECT_ID`,
  `SUPABASE_DB_PASSWORD`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`.
- Branch protection + a required reviewer on `production`.

Staging clearly exists (gap #2 came from it). Production setup status is unknown.
If any of these are missing, the matching deploy workflow fails at link/push.

---

## 🟡 8. Minor: deprecated config section

`supabase/config.toml` uses `[inbucket]`, which the CLI now flags as deprecated in
favor of `[local_smtp]`. Harmless (local email testing only), but it prints a WARN
on every CLI run.

---

## Suggested order if you come back to this

1. Fix the staging drift (#2) so deploys are green again.
2. Create `develop` and reconcile docs to reality (#1).
3. Decide the CI story: keep the single local smoke test, or re-apply the
   local/preview split (#3).
4. Pick one way to make a change *visible* (#6) and one consumer of previews (#4),
   or explicitly cut both from the demo's scope.
