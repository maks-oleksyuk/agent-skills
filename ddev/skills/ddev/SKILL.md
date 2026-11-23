---
name: ddev
description: >-
  Use before running any dev command (composer, php, node/npm/yarn/pnpm, artisan, drush, wp, vendor/bin/*, tests, linters, type checks, builds, DB clients) in a project where BOTH `.ddev/config.yaml` exists AND the `ddev` binary is installed. Tooling lives in DDEV's Docker containers, not on the host. Also use when a container command can't see a freshly written file or a dev server isn't reachable at its ddev URL.
---

# Working inside DDEV

Execute tooling through `ddev`, but **edit files directly on the host** (the project is shared with the container at `/var/www/html`; never wrap edits in `ddev exec`). git, gh, file reading and search stay on the host.

## Confirm DDEV applies

```sh
test -f .ddev/config.yaml && command -v ddev >/dev/null && echo "use ddev"
```

Otherwise run commands normally. `.ddev/config.yaml` holds `type`, `php_version`, `nodejs_version`, `docroot` — read it instead of querying the host. If commands fail, `ddev describe` (status, URLs, credentials) and `ddev start` (idempotent).

## Route commands

| Instead of | Run |
| --- | --- |
| `composer`, `php`, `npm`/`yarn`/`pnpm`/`node`, `drush`, `wp` | `ddev <same>` |
| `php artisan ...` | `ddev artisan ...` |
| `vendor/bin/pest`, `npx tsc`, any other binary | `ddev exec <command>` |
| interactive shell | `ddev ssh` |

- Subfolder: `ddev exec --dir /var/www/html/packages/x <cmd>` (`-d` is `--dir`, not detach).
- `ddev pnpm` / `ddev task` come from add-ons; "unknown command" → use `ddev exec pnpm`. If `Taskfile.yml` exists, prefer `ddev task <name>` (`ddev task --list`).

## Pitfalls

- **Mutagen lag (macOS):** a file just written on the host may not be in the container yet ("No such file", "Cannot find module"). Run `ddev mutagen sync && ddev exec <cmd>`.
- **Only the project folder is mounted:** `/tmp` and other repos are invisible in the container.
- **Quoting:** `ddev exec` re-quotes only args containing spaces; pass complex commands as one string: `ddev exec "node -e \"...\""`, or put code in a file.

## More (read only when needed)

- Database access/import/export → `references/database.md`
- Next/Vite/Node dev servers, project URL, 502s → `references/dev-server.md`
- Lifecycle (stop, poweroff, logs, xdebug) → `ddev --help`
- Laravel (`type: laravel`) → `references/laravel.md`
