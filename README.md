# Task-Assignment

A small Rails (7.x) application for simple task assignment and management with a minimal admin/manager/employee dashboard. The app includes:

- A dashboard for Admin / Manager / Employee views.
- Task creation, update, delete, and mark-complete actions.
- An "undo" flow for reversible actions (mark complete) backed by an audit table (`TaskStatusChange`).
- Integration with OpenAI via `AiWorkflowService` to produce progress summaries and suggestions (uses `OPENAI_API_KEY`).
- TailwindCSS for styling, built using the Tailwind CLI and served via Propshaft.
- Turbo (Hotwire) enabled partial updates for smooth UX.

This README documents local setup, important files, and deployment instructions (GitHub + Render).

## Quick project map

- `app/controllers/dashboard_controller.rb` — main dashboard and admin/manager/employee flows.
- `app/services/ai_workflow_service.rb` — builds prompts and calls OpenAI to generate summaries & suggestions.
- `app/models/task.rb`, `app/models/user.rb` — core models.
- `app/models/task_status_change.rb` — stores status transitions so actions can be undone.
- `app/views/dashboard/*` — dashboard views and partials (now use `_task_row.html.erb` for rows).
- `app/assets/stylesheets/application.tailwind.css` — Tailwind entry file.
- `package.json` — contains `build:css` script used to compile Tailwind into `app/assets/builds/application.css`.
- `db/migrate/*` — migrations (including `CreateTaskStatusChanges` added for undo support).

## Prerequisites

- Ruby 3.x (use project's `.ruby-version` if present).
- Bundler (gem install bundler)
- Node.js + npm (for Tailwind CLI)
- PostgreSQL (or your DB configured in `config/database.yml`)
- An OpenAI API key (if you want AI summaries): set `OPENAI_API_KEY` in your environment.

## Local setup

1. Install Ruby gems

```bash
bundle install
```

2. Install Node packages (for Tailwind CLI)

```bash
npm ci
```

3. Build Tailwind CSS (this writes `app/assets/builds/application.css`)

```bash
npm run build:css
```

You may prefer a watch mode during development (not included in this repo by default) — add a `watch:css` script if you want live rebuilds.

4. Prepare the database

```bash
bundle exec rails db:create
bundle exec rails db:migrate
bundle exec rails db:seed # optional if seeds exist
```

5. Start the Rails server

```bash
bin/rails server
# or
bin/rails s
```

Open http://localhost:3000

## Environment variables

Set these in your shell or in your hosting platform (Render):

- `DATABASE_URL` or use `config/database.yml` settings
- `RAILS_ENV` (production on server)
- `RAILS_MASTER_KEY` (if using encrypted credentials)
- `SECRET_KEY_BASE` (Rails secret)
- `OPENAI_API_KEY` (for AI integration)

## How the "undo" works

When a task is marked completed from the Dashboard, the app creates a `TaskStatusChange` record with `from_status` and `to_status`. The undo action finds the most recent `TaskStatusChange` that set the task to `completed` and restores the `from_status`. The undo is also recorded as an opposite status change.

This design keeps a lightweight audit trail and makes undo deterministic (reverts to the immediate last state).

## Assets & Tailwind

Source: `app/assets/stylesheets/application.tailwind.css`
Build output (committed or generated): `app/assets/builds/application.css`

If styles appear broken, make sure `app/assets/builds/application.css` exists. Rebuild with:

```bash
npm run build:css
```

## Tests

There are no automated tests included yet. Recommended next steps:

- Add controller specs for dashboard and tasks (mark/undo/delete flows).
- Add system tests for Turbo interactions.

## Deploying to Render (recommended steps)

1. Push your repo to GitHub (or ensure it's up to date). Example:

```bash
git add .
git commit -m "Add README and deployment instructions"
git push origin main
```

2. On Render.com:

- Create a new Web Service and connect your GitHub repository.
- Set the branch to deploy (e.g. `main`).

3. Environment / Build settings

- Environment: `Docker` or `Native` (choose `Native` for Rails apps unless you have a Dockerfile)
- Build Command (example):

```bash
npm ci
npm run build:css
bundle install --jobs 4 --retry 3
bundle exec rails db:migrate
```

- Start Command (example):

```bash
bundle exec puma -C config/puma.rb
```

4. Environment variables (set in Render dashboard):

- `DATABASE_URL` (Render provides a managed DB or supply your own connection)
- `RAILS_ENV=production`
- `RAILS_MASTER_KEY` (copy from local `config/master.key` or credentials)
- `SECRET_KEY_BASE` (generate or use Rails credentials)
- `OPENAI_API_KEY` (if you want AI summaries)

5. Deploy and verify logs. After the initial deploy, run migrations (if not part of build) and check logs.

Notes:
- Render can also run a `pre-deploy` or `post-deploy` script if you prefer to run migrations automatically.
- If you use a Procfile, make sure Render uses it or supply the Start Command above.

## GitHub & CI

- If you want automated deploys, enable Auto-Deploy from GitHub on Render when you add the repo.
- For CI, add GitHub Actions with a workflow that runs `bundle exec rspec` or other checks before pushing to Render.

## Next recommended improvements

- Add tests (controller + system) for mark-complete / undo flows.
- Add UI for viewing `TaskStatusChange` history per task.
- Limit undo window (e.g., allow undo only within 10 minutes) if desired.
- Add watch script for Tailwind during development (e.g. `npm run watch:css`).

---

If you'd like, I can now:

- Commit and push this README to `origin/main` (I can run the git commands for you).
- Walk through connecting the repo to Render or prepare a `render.yaml` file to codify the deploy.
- Add a GitHub Action that runs `npm run build:css` and `bundle exec rails db:migrate` on push.

Which of these would you like me to do next?
