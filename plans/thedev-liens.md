# Plan: thedev links (network of peer workspaces, without `-p`)

> Vocabulary: see `NAMING.md`. Goal: delegate work between workspaces **on different
> machines**, **interactively** (subscription) rather than with `claude -p` (credit
> pool, since June 15/22, 2026).

## Principle
A **workspace** (on a **machine**) opens a **link** to another workspace and sends it
a **task**; the remote workspace runs it in its **sandbox** (interactive
jobs → subscription) and sends back a **result**. **Flat** model (peers).
A link is **always cross-machine** (**SSH** transport).

## Layout (per machine, `~/.cache/thedev/`)
```
links/<workspace>              ← REGISTRY: 1 file = 1 workspace open to tasks
spaces/<workspace>/
  inbox/<id>.mission           ← received tasks
  outbox/<id>.result           ← results to return (atomic write: .tmp then mv)
  work/<id>/                    ← task in progress (claim)
  done/<id>/                    ← archive (task + result + log)
```

## Format (email style)
`inbox/<id>.mission`: headers `From:` / `Created:` / `Timeout:` + blank line + body.
`outbox/<id>.result`: headers `Status:` (ok|error|timeout) / `Finished:` + body.
The appearance of `<id>.result` = "task finished" signal.

## Lifecycle
1. sender: `ssh` drops `inbox/<id>.mission` on the target machine.
2. **watcher** (a bash job of the target workspace) sees the file → claim → `work/`.
3. starts a **task job**: `claude "<task + 'write the result to outbox/<id>.result'>"`
   **interactively** (subscription); can fan out into other jobs.
4. the task job writes the result (last act) → the watcher sees it → kills the pane, archives.
5. sender: polls `outbox/<id>.result` over ssh → reads → hands it back to its Claude.

> Interactive exec: the task job is started with the task as its **initial prompt**
> (`claude "<…>"`, not `-p`). Fallback if the positional prompt does not run
> by itself: local zellij `write-chars` injection into the task job's pane.

## Commands
- `thedev-link open|close|status`: opens/closes the current workspace to tasks
  (starts/stops its watcher + registry (un)registration). **Auto `open` on VPS**, manual locally.
- `delegate <machine>/<workspace> "<txt>"`: sends, waits, returns the result.
- `delegate ls <machine>`: lists reachable workspaces (reads the registry over ssh).

## v1 defaults (approved)
- **Concurrency**: sequential (one task at a time per workspace, queued).
- **Timeout**: 10 min by default, overridden by the `Timeout:` header.
- **Sender**: runs in a **job** (non-blocking, pings you when it returns).

## Integration
- sandbox: the watcher is a job (visible in `job list`).
- home (Infos mode): "Links: open/closed" + tasks in progress (v2: `delegate ls`).
- `dev` launcher: `thedev-link open` when a workspace starts on a VPS.

## Security
- Only SSH delivers tasks → only the key holder (you) can send. Zero
  open network surface.
- task job runs as `jlal`, in your sandbox → scoped. On jlax it reads the native
  `~/.claude/CLAUDE.md` → does not touch maxime.
- ⚠️ task = instructions run autonomously (`--dangerously-skip-permissions`).
  Safeguard = delivery goes through YOUR SSH (same trust as a manual login).

## Workspace identity
workspace = `$ZELLIJ_SESSION_NAME` (the name of the thedev session). Address: `<machine>/<workspace>`.
