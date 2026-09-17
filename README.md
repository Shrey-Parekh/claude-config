# claude-config

Portable Claude Code configuration, synced between my desktop and laptop (both Windows).

## What's in here

```
claude-config/
├── README.md
├── .gitignore
├── .claude/
│   ├── CLAUDE.md        # global instructions for all projects
│   ├── RTK.md            # rtk (token proxy) usage reference
│   ├── settings.json      # hooks, enabled plugins/marketplaces, theme, model settings
│   └── skills/
│       └── graphify/      # custom skill: codebase -> knowledge graph
└── scripts/
    ├── sync-to-repo.ps1   # ~/.claude -> this repo
    └── sync-from-repo.ps1 # this repo -> ~/.claude
```

Only directories that actually exist in my Claude Code setup are here. There's no `commands/`,
`agents/`, or `hooks/` folder yet because I don't have any custom slash commands, subagents, or
standalone hook scripts — `scripts/sync-to-repo.ps1` will start picking those up automatically
the moment they exist under `~/.claude/`.

## What is intentionally NOT synced

Everything below stays local to each machine and is excluded via `.gitignore`:

**Secrets** (never committed, ever):
- `.credentials.json` — OAuth access/refresh tokens, client secret for claude.ai and connected MCP servers.

**Machine-specific / local state:**
- `plugins/` — installed-plugin cache. Reproduced automatically from `settings.json`'s
  `enabledPlugins` + `extraKnownMarketplaces` the next time Claude Code starts.
- `cache/`, `sessions/`, `session-data/`, `session-env/`, `shell-snapshots/`, `telemetry/`,
  `metrics/`, `ide/`, `file-history/`, `backups/`, `state/`, `projects/` — runtime/session state.
- `*.log`, `history.jsonl` — local logs and command history.
- `.caveman-*`, `.ponytail-*`, `.last-*` — per-machine mode/state flags for installed skills.

**Known caveat:** `settings.json`'s `hooks.PreToolUse` entries call
`C:/Users/Shrey/.local/bin/graphify.EXE` by absolute path. This only works as-is on a machine
where graphify is installed at that exact path under this same username. If a new machine's
graphify install lives elsewhere, edit that path in `.claude/settings.json` after syncing.

## Setup on a new Windows PC

```powershell
cd ~
git clone https://github.com/Shrey-Parekh/claude-config.git
cd claude-config
.\scripts\sync-from-repo.ps1
```

This copies `CLAUDE.md`, `RTK.md`, `settings.json`, and everything under `skills/` into
`~/.claude/`, backing up anything it would overwrite into `~/.claude/backups/sync-from-repo-<timestamp>/`.
It never deletes existing files in `~/.claude/`.

After syncing:
1. Sign in to Claude Code / restore API keys and MCP OAuth connections manually on this machine
   (they are never stored in this repo).
2. Confirm the plugins listed in `settings.json` install correctly (Claude Code will fetch them
   from the marketplaces on first use).
3. If graphify (or any other hook-backed tool) is installed at a different path on this machine,
   fix the path in `~/.claude/settings.json`.

## Updating the central config (after changing your setup on either PC)

```powershell
cd ~/claude-config
git pull
.\scripts\sync-to-repo.ps1
git status
git diff
git add .
git commit -m "Update Claude Code configuration"
git push
```

`sync-to-repo.ps1` only copies known-portable files (`CLAUDE.md`, `RTK.md`, `settings.json`,
`skills/`, and `commands/`/`agents/`/`hooks/` if present) — it never touches `.credentials.json`
or other local state. It backs up whatever it's about to overwrite in the repo under
`scripts/.backups/<timestamp>/`.

**Before every push:** run `git status` and `git diff` and actually look at what's staged.
If you ever see anything that looks like a key, token, or credential in the diff, stop and
don't push — pull it out of the working tree first.

## Pulling changes onto the other PC

```powershell
cd ~/claude-config
git pull
.\scripts\sync-from-repo.ps1
```

## Secrets and API keys

None live in this repo. Each machine authenticates independently:
- Claude Code login / OAuth happens per-machine (`~/.claude/.credentials.json`, gitignored).
- Any API keys for MCP servers or plugins are entered/configured directly on each machine, not
  stored here.
