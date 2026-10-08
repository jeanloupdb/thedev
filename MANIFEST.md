# thedev: manifest

> **Generated** by `thedev-manifest` from the `# @thedev` tags of the `bin/` scripts.
> Do not edit by hand. Regenerate: `thedev-manifest --write`. 50 commands.

## Mental model

**machine** → **workspace** (1 project × 1 machine, all peers) → **pages** (`agents` = the sidebar + the agent stack, `jobs` = automations/jobs area, `shell` = human terminals) → **panes**.
A **job** = a long-running pane started in jobs. Workspaces exchange cross-machine **tasks** (`delegate`, interactive, on the subscription). The **owner** sits at the root, **leads** above workspaces (`org-tree`). Full vocabulary: `NAMING.md`, links: `plans/thedev-liens.md`.

## Commands

### Launch (home)
- **home** — machine/project picker at startup (fzf, multi-server)

### Session & panes
- **agent-pane** — launches the main agent of a pane (prompt overlay, remote-control, link auto-open)
- **aside-button** — + bar to add an aside agent to the stack
- **editor-pane** — nvim pane of the code page (VPS badge)
- **git-pane** — git-centric pane (aliases g/gs)
- **jobs-pane** — welcome pane of the jobs page (VPS badge)
- **quit-impact** — what closing this workspace will stop (Ctrl+Q), one fact per line
- **quit-menu** — menu to cleanly close the session
- **shell-pane** — personal shell pane of my space (VPS badge)
- **sidebar** — sidebar: left column of the agents page, the file tree and a quit button
- **spawn** — opens an extra stacked agent (aside) without touching the session
- **workspace-new** — creates a new project by handing the bootstrap to a remote agent (auto VPS)
- **workspace-open** — opens a workspace (local or remote) DETACHED with an already briefed agent (injected prompt)

### Org (leads, summaries, directives)
- **blocker** — workspace blockers: open points that get opened and closed
- **briefing** — pushes the briefing (the org tree) to Telegram via tg
- **directive** — directive: TOP-DOWN instruction from the owner to a workspace
- **directives** — directives: the directives RECEIVED from the owner (target machine side)
- **lead** — lead: opens an interactive Claude briefed as THIS lead (on demand)
- **milestone** — workspace timeline: manual milestones plus git commits (auto)
- **note** — workspace context: a note = one line signed by an agent
- **org-driver** — right pane of the org view (launches the briefed lead Claude)
- **org-nav** — left navigator of the org view (tree → opens the lead on the right)
- **org-tree** — org tree: the tree of workspaces, grouped by domain
- **partition** — partition: sorts a machine's workspaces into themed domains
- **reorg** — reorg: the breathing, splitting/merging levels (brick 3)
- **summary** — workspace summary: THE shared headline that syncs up to the lead
- **sync-up** — syncs local cards and reports up to the top (VPS)
- **workspace** — workspace card + report on quit (brick 1 of the org plan)

### Naming
- **claude-goto-waiting** — jumps to the agent pane waiting for you (blocking question), bound to Alt+W
- **pane-name** — names and saves the title of an agent pane (automatic VPS prefix)
- **pane-pulse** — animates (pulse ◆↔◇) the title of agent panes while they answer
- **wait-bar** — red alert "action waiting for you, Alt+W" in the zjstatus bar

### Registry
- **agent-register** — registry of open agents (resume + persistent pane names)

### Run (job)
- **job** — launches and manages any long-running process in the jobs page (dedup, liveness, job alive)

### Cross-machine links
- **automation-list** — state of the thedev automations on THIS machine (systemd --user timers)
- **delegate** — sends a task to a remote workspace (async by default, result/list/cancel)
- **ship** — pushes a local folder to a machine (rsync, honours gitignore)
- **thedev-link** — opens a workspace to incoming tasks (inbox watcher, model via Model:)
- **thedev-status** — compact cross-machine board (open workspaces, running tasks, jobs)

### Links (deprecated)
- **cremote** — one-shot remote claude command (DEPRECATED: claude -p = credit pool, prefer delegate)

### Network exposure
- **tsnode** — exposes a local 127.0.0.1 service as public HTTPS (Tailscale Funnel)

### Infra
- **claude-window-usage** — usage % of the Max 5x rate-limit window (5h/7d), FREE
- **headless-run** — autonomous heartbeat (DORMANT, cut in 2026-06 for cost)
- **thedev-doctor** — install diagnostic: deps, symlinked scripts, engine, hooks, launch
- **thedev-manifest** — generates the thedev manifest from the @thedev tags of the bin/ scripts
- **thedev-metrics** — local limiting metrics (RAM/disk/load/heat), single source

### Other
- **engine** (moteur) — engine-agnostic facade: launches/lists/reads/watches an agent (see ENGINE-ADAPTER.md)
- **thedev-landing** (ui) — animated boot screen of a claude pane (nature island and birds)
- **feed** (veille) — triggers a feed (cron-as-task): drops a local task in the inbox
- **tg** (veille) — sends text/photo to Telegram (Bot API, curl): delivery of feeds & alerts

## External dependencies

| Command | Package | Scope | |
|---|---|---|---|
| `zellij` | zellij | core | required |
| `claude` | claude CLI | core | required |
| `nvim` | neovim | core | required |
| `python3` | python3 | core | required |
| `git` | git | core | required |
| `jq` | jq | core | required |
| `fzf` | fzf (>=0.50) | core | required |
| `inotifywait` | inotify-tools | core | required |
| `ssh` | openssh-client | liens | required |
| `rsync` | rsync | liens | required |
| `tailscale` | tailscale | expose | optional |

## Installation

- **Global** (full personal config): `./install.sh [--with-deps] [--gnome] [--vps=<label>]`
- **thedev only** (without touching the personal .bashrc/.claude): `./install-dev.sh [--vps=<label>]`
  (the list of installed scripts is derived from this manifest: `thedev-manifest --scripts`).
- **Check dependencies**: `thedev-manifest --check-deps`
