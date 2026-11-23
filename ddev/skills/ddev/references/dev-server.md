# Dev servers and URLs (Next/Vite/Node)

Project URL: `https://<name>.ddev.site` (`name:` in config), not `localhost:8080`. `ddev describe` lists all URLs; `ddev launch` opens the primary.

For `type: generic` / non-PHP projects the app is a dev server, not Apache/PHP-FPM:

- Run it **inside the container**, bound to `0.0.0.0` on `container_port` from `web_extra_exposed_ports` (e.g. 3000). Reach it via the ddev URL, not `localhost:<port>`.
- **Assume it's already running** (the user usually started it); a second one fails with `EADDRINUSE`. Check and reuse (pages hot-reload):

```sh
curl -sko /dev/null -w '%{http_code}' https://<name>.ddev.site
```

- Only if down, start in background (`ddev exec` has no detach flag):

```sh
ddev exec "nohup pnpm dev > /tmp/dev.log 2>&1 &"
ddev exec tail -n 50 /tmp/dev.log
```

`502 Bad Gateway` = containers up but the dev server isn't listening on `container_port`: start it, don't `ddev restart`.
