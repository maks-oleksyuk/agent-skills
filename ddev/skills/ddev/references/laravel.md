# Laravel inside DDEV

DDEV detects Laravel (`type: laravel` in `.ddev/config.yaml`) and ships an
`artisan` shortcut. Run every Laravel CLI command through `ddev`.

## artisan

```sh
ddev artisan migrate                  # run migrations against the container db
ddev artisan migrate:fresh --seed     # rebuild schema + seed (destructive)
ddev artisan db:seed
ddev artisan tinker                   # REPL; for automation use --execute="..."
ddev artisan queue:work               # long-running; blocks until stopped
ddev artisan cache:clear
ddev artisan key:generate
```

## Composer & Node

```sh
ddev composer install
ddev composer require <vendor/package>
ddev npm install
ddev npm run dev      # vite dev server; use ddev describe for its URL/port
ddev npm run build
```

## Tests

```sh
ddev artisan test                 # the framework test runner
ddev exec vendor/bin/pest         # Pest directly
ddev exec vendor/bin/phpunit
```

## Database & .env

The app's `.env` uses the **in-container** values — `DB_HOST=db`, `DB_DATABASE=db`, `DB_USERNAME=db`, `DB_PASSWORD=db` — not host values. After changing `.env` or `config/*`, clear the cache so Laravel picks it up:

```sh
ddev artisan config:clear
```

For a raw client from the host, see the Database section of the main skill.
