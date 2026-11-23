#!/usr/bin/env bash
# Blocks host-run dev tooling in a DDEV project and tells Claude to prefix with `ddev`.
# Fail-open: any doubt (no jq, no ddev, no .ddev/config.yaml) -> allow.
command -v jq >/dev/null && command -v ddev >/dev/null || exit 0
input=$(cat)
cmd=$(jq -r '.tool_input.command // empty' <<<"$input")
dir=$(jq -r '.cwd // empty' <<<"$input")
[ -n "$cmd" ] && [ -n "$dir" ] || exit 0

# project must have .ddev/config.yaml at or above cwd
# nearest .ddev wins; a nested git clone (.git without its own .ddev) is a separate project -> allow
d=$dir; while [ "$d" != "/" ] && [ ! -f "$d/.ddev/config.yaml" ]; do [ -e "$d/.git" ] && exit 0; d=$(dirname "$d"); done
[ -f "$d/.ddev/config.yaml" ] || exit 0

# drop quoted strings (so `ddev exec "cd x && php y"` isn't flagged), split into segments
segs=$(printf '%s' "$cmd" | sed -E "s/\"[^\"]*\"//g; s/'[^']*'//g" | sed -E 's/(&&|\|\||[;|])/\n/g')
bad=$(printf '%s\n' "$segs" | sed -E 's/^[[:space:]]*(cd [^ ]+[[:space:]]*)?([A-Za-z_][A-Za-z0-9_]*=[^ ]* )*//' |
  grep -E '^(\./)?(php|composer|node|npm|npx|pnpm|yarn|artisan|drush|wp|phpunit|pest|phpstan|pint|vitest|tsc|biome|eslint)( |$)|^(\./)?(vendor/bin|node_modules/\.bin)/' | head -1)
[ -n "$bad" ] || exit 0

echo "DDEV project: '${bad%% *}' must run inside the containers, not on the host (different PHP/Node version, no DB access). Re-run it as 'ddev <cmd>' (ddev composer/php/npm/pnpm/artisan/drush/wp) or 'ddev exec <cmd>'. See the ddev skill." >&2
exit 2
