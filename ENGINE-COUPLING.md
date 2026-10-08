# Engine coupling (Claude Code)

> Read-only audit from 2026-06-21. Purpose: map where and how thedev is
> hard-coupled to Claude Code, to prepare the "engine-agnostic" abstraction
> (principle no. 1 of [`VISION.md`](VISION.md)). This is the starting state of the work,
> not a rewrite already done.

## Verdict in one sentence

Coupling is **deep but concentrated**: the orchestration skeleton (workspaces,
`job`, `delegate`, `ship`, `tsnode`…) is already neutral; **all the hard coupling comes
down to a single mechanism: the way thedev *observes* an agent** (history,
resume, task result, busy/end-of-turn signals), built end to end on
Claude Code's session files and hooks.

## A. Coupling points

| # | Point | File:line | Type | Difficulty |
|---|-------|---------------|------|------------|
| 1 | Engine launch: `claude` + flags (`--remote-control --model --append-system-prompt --resume`…) | `bin/claude-pane:120-127` | CLI invocation | medium |
| 2 | History picker: parses transcripts `~/.claude/projects/*/*.jsonl` | `bin/dev-picker:24,347-369,415-433` | session format | **hard** |
| 3 | Resume = id of the `.jsonl` file passed to `--resume` | `bin/dev-picker:426` → `bash/dev-launcher.sh:50-53` → `bin/claude-pane:58-59` | session format | **hard** |
| 4 | Task result extracted from the JSONL transcript (`jq` on `type=="assistant"`) | `bin/thedev-link:207-219` | session format | **hard** |
| 5 | `transcript_path` provided by the hooks, source of truth for the watcher | `claude/hooks/dev-claude-track.sh:43,107-112`; `bin/thedev-link:183-210` | session format + hooks | **hard** |
| 6 | 4 Claude Code hooks (`SessionStart/SessionEnd/UserPromptSubmit/Stop`) wired | `install.sh:51-71`; `claude/hooks/dev-claude-track.sh` | hooks/settings | **hard** |
| 7 | Anthropic OAuth endpoint + `.claudeAiOauth` token (5h window) | `bin/claude-window-usage:12,20-24` | endpoint | medium |
| 8 | Plan/tier read from `~/.claude.json` (`oauthAccount`) | `bin/dev-picker:238-245` | endpoint/format | low |
| 9 | Remote Control: `--remote-control <name>` automatic on VPS | `bin/claude-pane:103-106`; picker `135-137` | CLI invocation | medium |
| 10 | Hardcoded model names (alias→ids) | `bin/thedev-link:26-29` | model | low |
| 11 | Default heartbeat model = `haiku` | `bin/heartbeat-run:31,65-67` | model | low |
| 12 | Headless `claude -p` (heartbeat; `cremote` DEPRECATED) | `bin/heartbeat-run:65-67`; `bin/cremote:33` | CLI invocation | low |
| 13 | `CLAUDE_CODE_SESSION_ID` to persist a pane name | `bin/pane-name:28` | specific env | low |
| 14 | Claude Code rendering env (`CLAUDE_CODE_NO_FLICKER`…) | `bin/claude-pane:19,24,120` | CLI invocation | low |
| 15 | Machine identity = `claude/vps-context/*.md` symlinked as `~/.claude/CLAUDE.md` | `install.sh:96-102`; `bin/claude-pane:36-38` | config format | low |
| 16 | `/start` invoked in the project bootstrap brief | `bin/new-project:83` | vocabulary/feature | low |
| 17 | "claude" vocabulary (scripts, panes, registry, layout) | `bin/claude-pane`, `claude-aside`, `dev-claude-reg`, `claude-window-usage`; `zellij/layouts/dev.kdl:17,19`; `~/.cache/dev-claudes` | vocabulary | low |
| 18 | "Ground truth" discovery via `pgrep -x claude` | `bin/dev-picker:71-73,103` | CLI invocation | medium |

## B. The hardest couplings, and they are ONE problem

Points **2 → 6** are not independent: they are one cross-cutting mechanism,
*"thedev knows what an agent is doing by reading its Claude Code session files"*,
which feeds the picker, the launcher, the hook and the task watcher.

1. **Reading the transcripts `~/.claude/projects/*/*.jsonl`** (`dev-picker:24,347-369,415-433`): backbone of the picker (workspace history, title, `cwd`, resume id).
2. **`--resume <basename .jsonl>`** (`dev-picker:426`, `dev-launcher.sh:50-53`, `claude-pane:58-59`): the "resume" semantics assume id = transcript basename.
3. **Extracting the task result from the JSONL** (`thedev-link:207-219`): the deterministic reliability of tasks relies on Claude's assistant schema.
4. **4 hooks + `transcript_path`** (`install.sh:51-71`, `dev-claude-track.sh`, `thedev-link:183-210`): session registry, busy marker (fleet view), pane-name nudge, end-of-turn sentinel.

## C. Superficial couplings (`sed` work)

- **Vocabulary/naming** (#17): script names, pane `name="claude"`, `＋ claude` button, registry `~/.cache/dev-claudes`. Zero logic.
- **Model names** (#10, #11): a few isolated lines.
- **Usage/quota endpoint** (#7, #8): `claude-window-usage` is already self-contained; replacing the URL/parsing is local.
- **Rendering env** (#14), **`CLAUDE.md` as context** (#15), **`/start`** (#16): prompt/display details.
- **Headless `claude -p`** (#12): `cremote` deprecated, heartbeat turned off: dead surface.

## D. The realistic abstraction: an "engine" adapter

Doable **without a massive rewrite**, by isolating the observation layer in a
single adapter exposing **5 operations**, concentrated in **4 files**
(`claude-pane`, `dev-picker`, `thedev-link`, `dev-claude-track.sh`):

1. **launch** a session (flags + env): today `claude-pane`
2. **list** the sessions of a folder + title/id: today the picker's JSONL glob
3. **resume** by id: today `--resume`
4. **read** the last message of a session: today the `jq` in `thedev-link`
5. **signals** busy / end-of-turn: today the hooks + `transcript_path`

Plus a secondary adapter for usage/quota (#7). The rest (vocabulary,
models, env) is cosmetic.

> The bash signatures of this adapter (the 5 verbs + the incoming event contract
> + the order of work) are specified in [`ENGINE-ADAPTER.md`](ENGINE-ADAPTER.md).

**Conclusion**: thedev is not accidentally coupled to Claude everywhere: its
backbone (jobs, tasks, workspaces) is sound. But its **agent observation
layer** assumes Claude Code end to end. The work for principle no. 1 is
real, and **bounded** (≈ 5 functions, 4 files).

## Accepted leftovers (outside the adapter's scope)

The adapter decoupled the observation layer + launching. What stays
tied to Claude is **no longer scattered coupling**; by nature, it is:

- **Claude features with no generic equivalent**: automatic Remote Control on VPS
  (`claude-pane`), 5h window / quota (`claude-window-usage` + the picker reads
  `~/.claude.json` / `stats-cache.json` **without going through `engine usage`**),
  the `/start` slash command (`new-project`), the `~/.claude/CLAUDE.md` identity.
- **A picker feature outside the adapter**: rewriting the `cwd` in the
  transcripts when a folder is renamed (`dev-picker`) edits the `.jsonl`
  directly; `engine list/read` does not cover it.
- **Small hardcoded leftovers**: model IDs (`thedev-link`), `CLAUDE_CODE_SESSION_ID`
  (`pane-name`), the vocabulary (`claude-pane`, `dev-claude-reg`, `~/.cache/dev-claude-*`).
- **Structural dependency**: the **hook system** itself, which is how
  thedev receives its events. An engine without hooks would need another source
  for `engine event`.
- **The brain** (thedev system prompt + skills + memory): carried by Claude Code's
  rails (`--append-system-prompt`, skills, memory). Detached in *substance*
  (it is thedev knowledge), coupled in *transport*.

And **`resume`**: abstracted as an interface (verb + opaque id), but the
*capability* "resume a conversation" remains a **prerequisite** on the engine.
