#!/usr/bin/env bash
# SessionStart: in a DDEV project, inject the core rules + facts from .ddev/config.yaml.
command -v ddev >/dev/null || exit 0
d=$PWD; while [ "$d" != "/" ] && [ ! -f "$d/.ddev/config.yaml" ]; do [ -e "$d/.git" ] && exit 0; d=$(dirname "$d"); done
c="$d/.ddev/config.yaml"; [ -f "$c" ] || exit 0
v() { sed -nE "s/^$1:[[:space:]]*['\"]?([^'\"#]*[^'\"# ])['\"]?.*/\1/p" "$c" | head -1; }
name=$(v name); type=$(v type); php=$(v php_version); node=$(v nodejs_version)
cat <<MSG
DDEV project (${name:-?}, type ${type:-?}${php:+, php $php}${node:+, node $node}; URL https://${name:-?}.ddev.site).
Tooling runs in containers, NOT on the host (host PHP/Node versions differ): prefix composer/php/node/npm/pnpm/yarn/artisan/drush/wp/phpunit/pest/phpstan/tsc/biome/eslint/vendor/bin/* with \`ddev\` (or \`ddev exec <cmd>\`). Edit files directly on the host; git/gh/search stay on the host.
After writing a file the next container command needs: \`ddev mutagen sync && ddev exec ...\`. Dev servers: assume already running. Details: ddev skill.
MSG
