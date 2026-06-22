# agent-skills

A marketplace of [Claude Code](https://docs.claude.com/en/docs/claude-code)
skills by [Maks Oleksyuk](https://github.com/maks-oleksyuk). Each skill is its
own plugin, so you install only the ones you want.

## Skills

| Plugin | What it does |
| ------ | ------------ |
| [`ddev`](./ddev) | Teaches Claude that the project runs inside [DDEV](https://ddev.com), so commands (composer, php, npm, artisan, drush, wp) run in the containers instead of failing on the host. |

_More to come._

## Install

Add this repository as a marketplace, then install a plugin from it:

```
/plugin marketplace add maks-oleksyuk/agent-skills
/plugin install ddev@oleksyuk-agent-skills
```

Restart Claude Code (or reload plugins) after installing.

## Repository layout

```
agent-skills/
├── .claude-plugin/
│   └── marketplace.json     # catalog: lists every plugin in this repo
└── ddev/                    # one plugin = one installable unit
    ├── .claude-plugin/
    │   └── plugin.json
    └── skills/
        └── ddev/
            ├── SKILL.md
            └── references/  # loaded on demand
```

### Adding a new skill

1. Create a plugin folder at the repo root (e.g. `terraform/`).
2. Add `terraform/.claude-plugin/plugin.json`.
3. Add the skill at `terraform/skills/terraform/SKILL.md`.
4. Register it in `.claude-plugin/marketplace.json` under `plugins`.

## License

MIT
