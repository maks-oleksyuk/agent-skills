---
name: ddev
description: >-
  Use before running any dev command — composer, php, node/npm/yarn/pnpm, artisan, drush, wp, vendor/bin/*, or a database client — in a project where BOTH `.ddev/config.yaml` exists AND the `ddev` binary is installed. Both are required: a `.ddev/` directory alone isn't enough, since the project may run on plain Docker or the host without DDEV — then run commands normally. With DDEV the app runs in Docker containers, so PHP, Composer, Node, the database and CLI tools live in the containers, not the host; running them directly gives "command not found", the wrong PHP/Node version, or an unreachable database. Trigger on any such failure in a DDEV project — even if the user never says "DDEV".
---

# Working inside DDEV

DDEV runs the project's PHP, Composer, Node, database and CLI tools (artisan, drush, wp, …) **inside Docker containers**, not on the host. Core rule: **execute tooling through `ddev`, but edit files directly.** Files are bind-mounted, so the same bytes exist on host and in the container — wrapping edits in `ddev exec` adds friction with zero benefit. Running tooling on the host is the usual cause of "command not found", a wrong PHP/Node version, or "could not connect to database".

## Confirm DDEV applies

Both must hold, else run commands normally (a repo may ship `.ddev/`
while this machine has no `ddev`):

```sh
test -f .ddev/config.yaml && command -v ddev >/dev/null && echo "use ddev"
```

`.ddev/config.yaml` also holds `type`, `docroot`, `php_version`, `database`, `nodejs_version` — read it directly when you need those facts instead of querying the host.

## Make sure it's running

A stopped project fails every command, so check status before assuming the command is wrong:

```sh
ddev describe   # URLs, services, db credentials, ports — best status view
ddev start      # boot containers; idempotent, safe if already up
```

After changing `.ddev/` config, `ddev restart` applies it.

## Route commands through ddev

Use the shortcut when one exists; fall back to `ddev exec` for anything else.

| Instead of (host)       | Run                              |
| ----------------------- | -------------------------------- |
| `composer ...`          | `ddev composer ...`              |
| `php ...`               | `ddev php ...`                   |
| `npm` / `yarn` / `pnpm` / `node` | `ddev npm ...` etc.     |
| `php artisan ...`       | `ddev artisan ...`               |
| `drush ...` / `wp ...`  | `ddev drush ...` / `ddev wp ...` |
| `vendor/bin/phpunit`    | `ddev exec vendor/bin/phpunit`   |
| any other binary        | `ddev exec <command>`            |
| an interactive shell    | `ddev ssh`                       |

`ddev exec` runs in the **web** container at the project working dir, so relative paths like `vendor/bin/pest` resolve as expected.

Some commands come from **add-ons**, not core — e.g. `ddev pnpm` (ddev-pnpm), `ddev task` (ddev-taskfile). List them with `ddev add-on list --installed`. If `ddev pnpm` errors "unknown command", the add-on isn't installed — use `ddev exec pnpm` instead.

If a `Taskfile.yml` exists (ddev-taskfile add-on), **prefer `ddev task <name>`** over raw `ddev exec ...` — those are the project's defined entrypoints. `ddev task --list` shows them.

## Database

The database is a container, so connection details depend on where the client runs:

- **Inside containers** (app config, `ddev exec`, `ddev ssh`): host is `db`; user, password and database name are all `db`. The app is already wired to this.
- **From the host**: no fixed `localhost:3306`. Use the wrappers:

```sh
ddev mysql                       # MySQL/MariaDB client  (ddev psql for postgres)
ddev import-db --file=dump.sql.gz
ddev export-db --file=dump.sql.gz
ddev describe                    # engine, host-mapped port, credentials
```

## Project URL

Derived from `name:` in config, typically `https://<name>.ddev.site` — not `localhost:8080`. `ddev describe` lists every URL; `ddev launch` opens the primary.

## Long-running dev servers (Next/Vite/Node)

For `type: generic` / non-PHP projects the app is a dev server (`next dev`, `vite`, `node`), not Apache/PHP-FPM. Rules:

- **Run it inside the container**, bound to `0.0.0.0` on the `container_port` from `web_extra_exposed_ports` in config (e.g. `3000`). Host bind won't work — the tool (pnpm/node) lives in the container.
- **Reach it via `https://<name>.ddev.site`**, not `localhost:<port>`. The ddev router maps the exposed `container_port` to 80/443.
- **Background it** with `ddev exec -d <cmd>` when you must keep the session free.

```sh
ddev exec -d pnpm dev            # start detached inside the container
curl -sk https://<name>.ddev.site/...   # hit it through the router
```

**Assume the dev server is already running** — the user usually starts it in their own terminal. Starting a second one fails with `EADDRINUSE` / "port already in use". So **check first, don't blindly start**:

```sh
curl -sko /dev/null -w '%{http_code}' https://<name>.ddev.site   # up? reuse it
```

Only start a server if that check shows it's down. To verify a change, curl the existing server (routes/pages hot-reload) instead of launching a new one.

With `type: generic` there's no Apache/PHP-FPM — the router serves only what the dev server exposes. So `502 Bad Gateway` at the ddev URL means the containers are up but the dev server isn't listening on `container_port`: start the dev server, don't `ddev restart`.


## Lifecycle

```bash
ddev start | stop | restart      # control containers
ddev poweroff                    # stop ALL ddev projects
ddev logs                        # web logs (ddev logs -s db for database)
ddev ssh                         # shell in the web container
ddev xdebug on|off               # toggle step debugging
```

## Framework-specific workflows

The rules above are framework-agnostic. When `type` in `.ddev/config.yaml` matches, read the matching reference for idiomatic commands (cache, migrations, tests, CLI):

- **Laravel** → `references/laravel.md`

## The one mistake to avoid

Don't wrap file edits in `ddev exec` — edit host files directly; only *execution* goes through `ddev`.
