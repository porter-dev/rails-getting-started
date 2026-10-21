# Rails on Porter

A minimal Ruby on Rails app, ready to deploy on Porter with zero edits.

## What's inside

| Component | Version | Notes |
| --- | --- | --- |
| Ruby | 4.0.7 | Pinned in `.ruby-version` and the `Dockerfile` |
| Rails | 8.1.4 | Propshaft, importmap, Turbo and Stimulus |
| Puma | 8.x | Listens on `0.0.0.0:${PORT:-3000}` |
| SQLite | 3 | Zero-config default database, not persistent in a container |

| Endpoint | Method | Description |
| --- | --- | --- |
| `/` | GET | Home page confirming the app is running |
| `/up` | GET | Rails health check, returns 200 when the app has booted |

## Run locally

With Ruby 4.0.7 installed:

```sh
bin/setup
```

This installs gems, prepares the SQLite database and starts the dev server at http://localhost:3000. Run the tests with `bin/rails test`.

With Docker:

```sh
docker build -t rails-getting-started .
docker run -p 3000:3000 -e SECRET_KEY_BASE=$(openssl rand -hex 64) rails-getting-started
```

## Deploy on Porter

### From the dashboard

1. Fork this repo.
2. In https://dashboard.porter.run create a new app from your GitHub repo. Porter reads `porter.yaml` and builds the `Dockerfile`.
3. Add the `SECRET_KEY_BASE` environment variable (generate one with `openssl rand -hex 64`).
4. Porter opens a PR adding a GitHub Actions workflow. Merge it, and every push to `main` redeploys.

See https://docs.porter.run/applications/deploy/deploy-from-github-repo for details.

### From the CLI

1. Install the CLI: https://docs.porter.run/cli/installation
2. `porter auth login`
3. `porter apply -f porter.yaml`

Set `SECRET_KEY_BASE` on the app in the dashboard or through an environment group before the first deploy.

## Configuration

`porter.yaml` defines one `web` service:

| Field | Value | Purpose |
| --- | --- | --- |
| `build.method` | `docker` | Builds the `Dockerfile` at the repo root |
| `run` | `/rails/bin/docker-entrypoint ./bin/rails server` | Runs `bin/rails db:prepare`, then starts Puma. Porter replaces the image entrypoint with `run`, so the entrypoint is called explicitly |
| `port` | `3000` | Port Puma listens on |
| `cpuCores` / `ramMegabytes` | `0.5` / `512` | Resources per instance |
| `healthCheck.httpPath` | `/up` | Rails' built-in health check |

Full reference: https://docs.porter.run/applications/configuration-as-code/reference

| Name | Required | Description |
| --- | --- | --- |
| `SECRET_KEY_BASE` | Yes | Signs cookies and sessions. The app refuses to boot in production without it |
| `DATABASE_URL` | No | Database connection URL. When unset the app uses SQLite inside the container |
| `PORT` | No | Port Puma listens on. Defaults to `3000`, which must match `port` in `porter.yaml` |
| `RAILS_MAX_THREADS` | No | Puma threads and database pool size. Defaults to `3` |

Production expects TLS to be terminated by Porter's load balancer, so `config.assume_ssl` and `config.force_ssl` are both on. Requests get HSTS and secure cookies, and `/up` is excluded from the HTTPS redirect.

### Persistent data with Postgres

SQLite data lives inside the container and is lost on every deploy. For persistent data:

1. Create a Postgres datastore in Porter: https://docs.porter.run/addons/datastores
2. Attach its environment group to this app. If the group does not expose `DATABASE_URL`, add `DATABASE_URL=postgres://<user>:<password>@<host>:5432/<database>` built from its values.
3. Run migrations before each deploy by adding this to `porter.yaml`:

```yaml
predeploy:
  run: bin/rails db:prepare
```

The `pg` gem is already in the `Gemfile`, and Rails uses the adapter from `DATABASE_URL` automatically.

## Learn more

- https://docs.porter.run/getting-started/quickstart
- https://docs.porter.run/applications/configuration-as-code/overview
- https://docs.porter.run/applications/configure/environment-groups
- https://docs.porter.run/addons/datastores
- https://docs.porter.run/preview-environments/overview
- https://github.com/porter-dev/starters
