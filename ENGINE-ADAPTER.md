# Engine adapter: signatures

> Designed on 2026-06-21. A bash interface that decouples thedev from Claude Code,
> in response to the [`ENGINE-COUPLING.md`](ENGINE-COUPLING.md) audit and to principle
> no. 1 of [`VISION.md`](VISION.md). This is the **contract**.
>
> **Status**: implemented in `bin/engine` (dispatcher) + `lib/engine/claude.sh`
> (Claude backend). The outgoing verbs (`launch`/`resume`/`list`/`read`/`usage`/
> `running`) and the core of `engine event` are **faithful wrappers** of the
> current behavior, tested on real data.
>
> **Migrations done**: `thedev-link` (task result → `engine read
> --transcript`), `dev-picker` (workspace discovery → `engine list --all
> --json`; JSONL schema + `~/.claude/projects` removed; `engine list` in a single
> python3 process, ~90 ms), the **hooks** (`dev-claude-track.sh` becomes a thin
> translator → `engine event`; the registry/busy/task sentinels are
> kept by the adapter, while pane renaming, the ◆ pulse (`pane-pulse`) and the nudge
> stay on the hook side), and
> **launching** (`dev.kdl`, `claude-aside`, `thedev-link`, `dev-adjust-auto`
> call `engine launch`; `claude-pane` remains the backend implementation that `engine_launch`
> execs). **All 4 verbs of the contract are wired: engine decoupling is complete
> on the call-site side.** Caveat: the `dev.kdl` change cannot be verified outside a
> real zellij render (to validate on first launch after the cutover).

## Guiding idea

The abstraction boundary is not the code, it is **the schema**: stable arguments
in, output in a stable format. Whatever engine sits behind it,
`engine list` always outputs the same columns.

## Shape & selection

- A dispatcher `bin/engine` (git style: `engine <verb> …`).
- Backend selected by `THEDEV_ENGINE` (default `claude`), implemented in
  `lib/engine/<name>.sh` (sourced).
- **Two halves**: *outgoing* (thedev calls the engine) and *incoming* (the engine
  notifies thedev through events).

## Golden rule on the `ID`

The session `ID` is an **opaque string**. Only the backend interprets it
(today = basename of the `.jsonl`; tomorrow, something else). thedev **never**
assumes it is a file name: that is hard point no. 3 of the audit.

## Output / exit conventions

Machine-readable stdout (TSV by default, `--json` for the picker). Exit:
**0** ok, **2** not supported by this engine, **1** error. Stable, so the
caller can branch (e.g. hide the quota bar if `engine usage` → 2).

---

## Outgoing: the verbs

### `engine launch`: start a session (exec)
```bash
engine launch [--cwd DIR] [--model NAME] [--remote-control NAME] \
              [--system-append FILE] [--resume ID] [-- EXTRA...]
```
Builds env+argv and **execs** the engine (takes over the pane); does not return
on success. `--resume ID` ⇒ resumes instead of starting fresh.
*Today (claude)*: `bin/claude-pane` (`--remote-control --model
--append-system-prompt --resume`, env `CLAUDE_CODE_*`).

### `engine resume ID`: sugar for `launch --resume ID`
Kept as a verb because the picker has a separate "resume" path.

### `engine list`: list sessions
```bash
engine list [--cwd DIR] [--all] [--json]
```
Default: sessions of `$PWD`. `--all`: all of them (workspace discovery).
**TSV stdout**, one session per line, fixed columns:
```
ID \t MTIME_ISO \t CWD \t BUSY \t TITLE
```
`ID` opaque, `MTIME_ISO` sortable, `CWD` absolute, `BUSY` `1|0|?`, `TITLE`
(tabs/newlines removed). `--json`: same fields as JSON lines. Exit 0 even if empty.
*Today*: glob `~/.claude/projects/*/*.jsonl` + parse (`cwd`, `ai-title`, mtime).

### `engine read`: read the message(s)
```bash
engine read ID|--transcript REF [--last] [--role assistant|user|any] [--json]
```
Reads by **id** (resolved by the backend) or by direct **transcript reference**
(`--transcript`, for a caller that already has the ref from an event).
`--last` (default) = last message; `--role assistant` (default) = filter.
`--last --role assistant` ⇒ **the final assistant text = the task result**.
stdout = raw text; `--json` = `{role,text,ts}` as JSON lines.
*Today*: the `jq` in `thedev-link:207-219`.

### `engine usage`: quota window (optional)
```bash
engine usage [--json]
# stdout TSV: WINDOW \t USED_PCT \t RESETS_IN   (ex: 5h \t 73 \t 2h14m)
```
Exit **2** if the engine has no notion of quota.
*Today*: OAuth `api.anthropic.com/api/oauth/usage`.

### `engine running`: ground truth on processes
```bash
engine running            # number of live engine processes
engine running --id ID    # 0/1: is this session running?
```
*Today*: `pgrep -x claude` (`dev-picker:71-73`).

---

## Incoming: the event contract

The only real architectural change: thedev consumes **events**, not
Claude hooks. A stable sink, called by the engine's native mechanism:
```bash
engine event TYPE --session ID --cwd DIR [--title T] [--transcript REF]
#   TYPE ∈ session-start | busy | turn-end | session-end
```
Writes to the thedev registry (engine-agnostic), consumed by the picker / tasks /
pane-name.
- *For Claude*: the 4 hooks (`SessionStart/Stop/UserPromptSubmit/SessionEnd`)
  call `engine event …`, replacing the Claude-specific `dev-claude-track.sh`.
- *For an engine without hooks*: the backend produces these events by polling/wrapping.
  **thedev does not care, it reads events.**

---

## The backend contract (`lib/engine/<x>.sh` must define)

```bash
engine_launch          # execs the engine
engine_list            # emits the sessions TSV
engine_read            # emits text/JSON for a session
engine_usage           # emits the quota, or `return 2`
engine_running         # counts/tests processes
engine_install_hooks   # wires native eventing → `engine event`   (called by install.sh)
# + metadata: ENGINE_PROC_NAME, ...
```

## Migrating a call site (before / after)

```bash
# Task result: thedev-link (DONE)
# BEFORE (coupled to Claude's JSONL schema):
jq -r 'select(.type=="assistant")|.message.content[]|select(.type=="text")|.text' "$transcript" | tail -1
# AFTER:
engine read --transcript "$transcript" --last --role assistant
```
```bash
# Workspace discovery: dev-picker
# BEFORE: glob ~/.claude/projects/*/*.jsonl + parse
# AFTER: engine list --all --json
```

## What stays outside the engine (do not touch)

Registry, picker rendering, `job`, `delegate` (`.mission`/`.result` transport),
`ship`, `tsnode`, `thedev-status`: already engine-agnostic. **The adapter absorbs ONLY
launching + the observation layer.** The ~14 other points of the audit are
`sed` work (vocabulary, models, env).

## Two design points to keep in mind

- **`launch` that `exec`s** does not *return*: everything that must happen "after
  startup" goes through **events**, not through a return code. Consistent with the
  zellij pane model.
- **`engine event` is the pivot**: it is what turns "thedev reads Claude's
  files" into "thedev listens to normalized events". If we do only **one** thing
  out of this whole effort, it is this one; `list`/`read` can stay as direct
  reads for a while.

## Suggested order of work

1. `engine event` + `engine_install_hooks` (the incoming pivot): isolates state tracking.
2. `engine read`: unplugs task result capture from the JSONL schema.
3. `engine list`: unplugs the picker's workspace discovery.
4. `engine launch`/`resume`: wraps `claude-pane`.
5. `usage` / `running` / vocabulary: the easy part, last.

## Checking

`engine selftest` exercises the whole contract (list/read/usage/running/event) on
real data + a throwaway round-trip. **Run it after an engine update**: if
Claude Code changes its transcript format, `list` returns 0 workspaces
or malformed TSV → the test goes `FAIL` and points to the only file to fix
(`lib/engine/claude.sh`).
