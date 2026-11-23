# Database in DDEV

- **Inside containers** (app config, `ddev exec`, `ddev ssh`): host `db`; user, password, database all `db`.
- **From the host:** no fixed `localhost:3306`. Use wrappers:

```sh
ddev mysql                       # ddev psql for postgres
ddev import-db --file=dump.sql.gz
ddev export-db --file=dump.sql.gz
ddev describe                    # engine, host-mapped port, credentials
```
