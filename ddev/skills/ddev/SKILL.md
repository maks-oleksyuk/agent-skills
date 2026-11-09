---
name: ddev
description: >-
  Use before running any dev command — composer, php, node/npm/yarn/pnpm, artisan, drush, wp, vendor/bin/*, tests, linters, type checks, builds (phpunit, pest, phpstan, vitest, tsc, biome, eslint) or a database client — in a project where BOTH `.ddev/config.yaml` exists AND the `ddev` binary is installed. Both are required: a `.ddev/` directory alone isn't enough, since the project may run on plain Docker or the host without DDEV — then run commands normally. With DDEV the app runs in Docker containers, so PHP, Composer, Node, the database and CLI tools live in the containers, not the host; running them directly gives "command not found", the wrong PHP/Node version, or an unreachable database. Also use when a container command can't see a file you just wrote, or a dev server isn't reachable at its ddev URL. Trigger on any such failure in a DDEV project — even if the user never says "DDEV".
---

# Working inside DDEV

DDEV runs the project's PHP, Composer, Node, database and CLI tools (artisan, drush, wp, …) **inside Docker containers**, not on the host. Core rule: **execute tooling through `ddev`, but edit files directly.** The project folder is shared with the container (at `/var/www/html`), so editing on the host is enough. Wrapping edits in `ddev exec` adds friction with zero benefit. Running tooling on the host is the usual cause of "command not found", a wrong PHP/Node version, or "could not connect to database".

What stays on the host: git, gh, reading and searching files, editors. These don't need the container.

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
ddev describe   # URLs, services, db credentials, ports, perf mode — best status view
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
| `npx tsc` / `vitest` / … | `ddev exec npx tsc ...`         |
| any other binary        | `ddev exec <command>`            |
| an interactive shell    | `ddev ssh`                       |

`ddev exec` runs in the **web** container at the project root, so relative paths like `vendor/bin/pest` resolve as expected. For a subfolder (a package in a monorepo), use `ddev exec --dir /var/www/html/packages/x <command>`. Note that **`-d` is `--dir`**, not "detached".

Some commands come from **add-ons**, not core — e.g. `ddev pnpm` (ddev-pnpm), `ddev task` (ddev-taskfile). List them with `ddev add-on list --installed`. If `ddev pnpm` errors "unknown command", the add-on isn't installed — use `ddev exec pnpm` instead.

If a `Taskfile.yml` exists (ddev-taskfile add-on), **prefer `ddev task <name>`** over raw `ddev exec ...` — those are the project's defined entrypoints. `ddev task --list` shows them.

## Pitfalls

**File sync lag (Mutagen).** On macOS, DDEV usually syncs files with Mutagen; `ddev describe` then shows "Perf mode: mutagen". The sync is asynchronous, so a file you just created or changed on the host may not exist in the container yet. The command then fails with "Cannot find module", "No such file" or stale results. The same lag applies the other way, for build output and lockfiles written in the container. When the next command needs a file you just wrote, sync first:

```sh
ddev mutagen sync && ddev exec npx vitest run path/to/new.test.ts
```

**Only the project is in the container.** Files outside the project folder (`/tmp`, a scratch dir, another repo) don't exist inside it. Either copy them into the project (a gitignored folder) and delete them afterwards, or run on the host if the command doesn't need container tools.

**Quoting.** `ddev exec` runs the command through `bash -c` inside the container and re-quotes only the arguments that contain spaces. An argument with shell characters but no spaces, such as `node -e "import('x').then(f)"`, breaks with "syntax error near unexpected token `('". Pass the whole command as one string with your own quoting, or put the code in a file:

```sh
ddev exec "node -e \"import('x').then(m => console.log(m))\""
```

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
- **Assume it's already running.** The user usually starts it in their own terminal, and a second one fails with `EADDRINUSE` / "port already in use". Check first and reuse it. Pages hot-reload, so curl the existing server to verify a change:

```sh
curl -sko /dev/null -w '%{http_code}' https://<name>.ddev.site   # up? reuse it
```

- **Only if it's down, start it in the background** so the session stays free. `ddev exec` has no detach flag, so use `nohup` inside the container and keep the log there:

```sh
ddev exec "nohup pnpm dev > /tmp/dev.log 2>&1 &"
ddev exec tail -n 50 /tmp/dev.log     # check it started
```

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
