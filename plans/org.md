# Plan: the org layer (brick by brick)

Implementation of the [`VISION.md`](../VISION.md) section "Running many agents"
and of the [`NAMING.md`](../NAMING.md) vocabulary. We build the tree
**from the roots**, not from the top.

> **Update, July 2026.** Since the first draft:
> - the old map command was **renamed** to a tree command, now **`org-tree`** (more explicit):
>   read `org-tree` wherever this doc talks about the map *command* ("workspace card"
>   remains the concept).
> - The **report-on-quit is REMOVED**: context is no longer summarized at close time,
>   it **syncs up continuously** (brick 4 below).
> - **Bricks 4 (memory in 3 tenses) and 5 (on-demand lead + partition) are in place**: see
>   below. Syncing up is **event-driven at end of turn** (no more systemd timer).

## The model, on one page

The hierarchy is a **self-balancing n-ary tree** (a *semantic* B-tree):

- The **leaves** are real workspaces (1 project / 1 machine), peer agents.
- **A single object: the `lead`.** Can be called up at any time (a briefed session,
  **not** running 24/7), it holds the **aggregated context** of its whole subtree
  (sub-leads or workspaces). It wakes up on an event (directive to route, report to
  aggregate, question), produces, goes back to sleep. Cost ∝ activity.
- **The "top lead" is not a separate type: it is the `lead` at the root**
  (on the top machine). Leads everywhere, a single one at the very top. It exists as soon as
  there is something to direct; what "appears" on a split is a **level**,
  not the first agent.

**Recursive placement rule** (the same at every level):

```
a workspace is born, declares its card, then:
  is there a lead whose domain fits?
  ├─ YES → free slot (< n)?
  │        ├─ YES → attach to it.                     ← common case, zero cost
  │        └─ NO  → the lead overflows → the PARENT re-partitions (split WITHIN the domain).
  └─ NO →
           total workspaces ≤ n?
           ├─ YES → attach to the closest lead (or stay flat under the owner).
           └─ NO  → ask the owner for a reorg (they know the whole tree).
```

Invariants:

1. **Semantics > capacity.** If the right lead is full, we **split within its
   domain** (a sub-lead of the same domain); we never put the workspace under a
   lead that has room but does not fit. `n` is a *pressure* that triggers
   the split, not a routing wall.
2. **`n` = span of control (~7), with hysteresis.** Split at `n`, merge
   well below (~`n/2`), never at the same threshold, otherwise the tree oscillates.
3. **Growth by root split (the root always stays unique).** When the
   root overflows, we do **not** turn it into several peers; we create **a single lead
   above** that contains them: the height goes up by 1. This is the B-tree invariant
   (only the split of the *root* grows the height). Mirror for merging: a
   lead under the threshold is folded back; a root with a single real lead is **dissolved**
   (the height goes down). Without this, a tower of empty leads = a cost wall.
4. **A single re-partitioner per level**: the parent (the root lead at the top).
   No multi-session meeting: the lead redraws the map, alone, on an overflow
   event. The overload is **noticed during any session** and
   the reorg is **invoked** there (no standing monitor): opportunistic, event-driven.

The VISION safeguard remains the rule: the reorg moves a workspace under another
lead, it **never** changes a workspace's *assignment*, and the owner
bypasses the map at will.

## The fixed skeleton (decision): root lead → machine lead → domain → workspace

The B-tree above describes the *mechanics*; here is the **concrete, fixed skeleton**,
which maps it onto reality (machines + phone access):

- **The root lead**: a **real Claude session on the top machine** (the always-on
  VPS, `thedev-sommet`), the owner's entry point. Single access point (phone → top machine).
  It sees the fleet (aggregated `org-tree`) and directs downward (`directive`). **On demand**:
  opened when you want to direct, not running 24/7.
- **One lead per machine**: under the root lead, **exactly one local lead per
  machine** (jlal-pc, indice…). It is the **single entry point** of a machine:
  the root lead directs a machine *through its machine lead*, never N floating
  roots. **A machine cannot have several root leads.**
- **The domain organizes *under* the machine lead**: domain-first applies
  **inside** a machine (grouping its workspaces by project). The machine lead
  is the level the *root lead* sees; the domain is the level the
  *machine lead* sees.
- **The workspace**: the leaf (1 project / 1 machine, peer agents).

**Why machine before domain**: **control** and **access** come first. The
root lead (and the phone) need **one handle per machine**, not one handle
per scattered domain. Accepted cost: a domain spread over 2 machines appears
under 2 machine leads; the cross-machine unity of a project gives way to the unity of
control.

The recursive rule (split/merge, `n` thresholds, hysteresis) applies **within the
subtree of a machine lead**: too many domains on a machine → its lead splits
into domain sub-leads; the machine empties out → they merge. The machine lead
itself remains as long as the machine has workspaces.

---

## Where the top lives: control plane on the VPS

The top must be **reachable at all times**: a personal machine sleeps,
shuts down, has no stable IP, and a smartphone has no shell, no git, no `claude`.
Hence: **an always-on VPS holds the root.**

The distinction that saves cost, **control plane vs compute**:

- **The VPS = control plane** (lightweight, **no AI running**). It holds three
  things: the **canonical state** (tree, cards, synced-up reports), the
  **reachable meeting point** (where the smartphone and the machines talk), the **directive
  queue** (what the owner decided, waiting to be consumed). Cost:
  a few €/month, **zero** subscription burn.
- **The machines = compute.** Agents work where the code and the
  tools are. The machine is an **attribute of the leaf** (where it runs), **not** an
  org level: each machine syncs up its cards+reports to the top and
  consumes the directives waiting for it.
- **The root lead materializes on demand** (on an event: directive to route,
  reorg), reads the state on the VPS, produces, goes back to sleep. The VPS does not sleep;
  the *agent* does.

**The first level is the MACHINE (fixed decision, see § The fixed skeleton).**
The root lead sees **one lead per machine**; `command-fleet/<machine>/` is both
the **transport** partition (rsync `--delete` without collision) **and** the
subtree of that machine lead. Placing a workspace = adding a leaf under **its
domain, under its machine's lead**; the top assembles the tree
`root lead → machine lead → domain → workspace` from the union of what was synced up. A
domain spread over 2 machines appears under 2 machine leads: the accepted cost of
control unity.

The three limits, stated openly:

1. **State divergence.** The **cards** travel in git (versioned, in-repo);
   the VPS only holds the **mirror + inbox + reports** (disposable,
   rebuildable). A single source per data type.
2. **Directive to an offline machine.** No synchronous RPC: the directive is **dropped
   in the VPS queue**, consumed when the machine wakes up. Queue, not direct
   call: it works even smartphone → laptop that is off.
3. **Door security.** The smartphone talks to the VPS **through Tailscale** (private
   mesh), *not* through public Funnel. Zero surface exposed to the open internet.

Mirror of the VISION safeguard ("the owner is never locked in"): **the
branch is never locked in by the top either**. It runs alone if the top
sleeps and resyncs without losing anything. Both ends of the tree are
autonomous.

> Today (checked): starting a `thedev` just registers the agent in a
> **flat** registry (`~/.cache/soldats`), nothing syncs up. The only existing upward
> gesture, `thedev-link open`, is **auto-triggered only on a VPS**
> (`agent-pane`). On the laptop, the workspace is silent twice over. The target above
> = extend to the laptop the gesture that only the VPS does today, pointed at the VPS.

### Cross-machine sync up *(in progress)*

Concrete realization of the top, reusing the existing transport (**SSH**,
through the `~/.ssh/config` aliases + the `~/.config/thedev-machines` registry).

- **Declared top**: `~/.config/thedev-sommet` (fleet-wide constant, versioned
  + symlinked like `thedev-machines`) = the ssh alias of the top. **Set to `jlax`.**
  Empty/missing → cross-machine off, everything stays local (clean degradation).
- **`sync-up`** (machine → top): `rsync -az --delete` of the local
  `~/.cache/thedev/command/` to `top:command-fleet/<machine>/command/`.
  **One subfolder per machine** → `--delete` limited to its own subtree, zero
  collision (keys are already `<machine>__<workspace>`). Best effort: if the top
  sleeps, no-op, the next sync up catches up (natural queue). The machine that
  *is* the top (`dev-vps == thedev-sommet`) does not push to itself.
- **`org-tree` reads the fleet**: local `command/` **+** all the
  `command-fleet/*/command/`, deduplicated by key → the **complete tree, all machines**,
  grouped by domain. Same renderer, richer data. Title aware of the role
  (top vs local view).

**Auto trigger: in place.** systemd `--user` timer (`thedev-remonter.timer` +
`.service`, versioned + enabled by `install.sh`): `sync-up` every ~15 min
**while the session is open** (`Linger=no` → runs while you work, while
cards/reports change; cost ∝ activity). `sync-up` neutralizes itself on
the top, so the units are the same across the whole fleet.

OUT (next): the enriched **downward** direction (the top routes a directive to a
remote leaf) stays `delegate` as is; and an **event-driven** sync up
(push right after a report) in addition to the timer, if 15 min freshness is
not enough.

---

## The surfaces: the map + control

**One tree, several renderings.** The canonical tree lives **only once** (control
plane, VPS). Every view is just a **skin** on top. Never fork the
model: a single truth, interchangeable renderers.

**In thedev**: the map lives **in home** (preview: your branch + the state
of the link to the top), and an **`org-tree` command** expands it full size (floating) on
demand. **No new permanent tab.**

**Home header: three states**:

- *branch, top reachable* → `● reachable`, entry "open the owner's
  board" (briefing + directive queues).
- *branch, top unreachable* → `○ unreachable`, **reassuring promise** (not
  an error): "X reports + Y directives queued, sent as soon as the top
  answers". Local home stays fully usable.
- *on the VPS* → "you are **at the top**" + counters (linked machines, workspaces,
  pending directives).

**"Talk to a node": 3 flavors** (the tree's directory):

- **leaf (workspace)** → a **directive** / a thread; consumed if up, queued if
  it sleeps.
- **lead** → queries the **role**: it answers from the **aggregated digest** of its
  branch, **without waking each leaf** (a single wake-up = one synthesis).
- **owner** → the cross-cutting stuff (reorg, priorities of the month).

**The contract (to fix early, it carries every skin)**: the VPS exposes only
**two verbs**; everything else is cosmetic:

1. `give me the tree` → the state of the hierarchy (nodes, statuses, digests).
2. `talk to this node` → drops a directive / opens a thread to a leaf, a lead
   or the owner.

**Staging of the skins** (same contract, single engine: each step *re-skins*, rewrites
nothing):

1. **Telegram**: *in progress, assembled from what exists* (no new engine):
   - **PUSH (give me the tree)**: ✅ in place: `briefing` = `org-tree` → `tg` (Bot
     API, curl, reuses `TELEGRAM_BOT_TOKEN`/`CHAT_ID` from the existing channel).
     Actually sent. On the **top**, `org-tree` sees the whole fleet →
     complete briefing; schedulable (cron/timer) for the morning briefing.
   - **PULL (talk to a node)**: the **official bot already runs** and bridges DM →
     a Claude agent (which has `org-tree`/`delegate` at hand). The *verbs* still
     need polishing (short syntax "org-tree", "directive <target>: …") → next step.
2. **Tailscale site**: same contract, private web rendering (visual map).
3. **Native app** (end goal): same contract; its only own contribution is native push
   notifications (already covered by Telegram in the meantime).

The owner's board is **active**, not just read-only: the goal is to
*direct* the agents from the phone, not to watch them.

*To decide later:* is attaching at boot **systematic** (each
`thedev` declares its existence to the top) or **lazy** (the workspace stays silent
until a directive/task concerns it)? Current lean: **immediate declaration,
lazy placement** (declare yourself while the tree is flat, only look for
your lead once leads exist).

---

## Brick 1: the workspace card + the report-on-quit *(the foundation)*: ✅ IN PLACE

Everything else operates on it. Durable whatever happens next: it is
bash+files ops, engine-agnostic, with **zero** permanent cost (event-driven).

> **State: in place (minimal slice).** Script `workspace` (`config/bin/workspace`,
> symlinked): `workspace card` (reads `.thedev/equipe.md` or derives → mirror
> `~/.cache/thedev/command/equipes/<key>.md`) and `workspace debrief` (derived flush,
> zero AI → `debriefs/<key>/<ts>.md`). Wired into the `agent-track.sh` hook:
> SessionStart → card, SessionEnd → report, restricted to the **main agent of a
> real workspace** (tasks + asides excluded), best effort, non-blocking. Still
> OUT of the slice: the **rich** report via `quit-menu` (body written
> by the agent on a clean exit). Source of truth = config; not published on
> thedev (public); not committed.

### 1a. The workspace card

**Principle: a workspace only declares what is *not derivable*.** Name, machine, cwd,
branch, current topic, activity, number of agents are **already** in
`~/.cache/soldats` (TSV) + git → never declared again. What remains to declare:
**domain, summary, status, tags**.

**Source of truth: `.thedev/equipe.md` at the project root**: versioned,
travels with the folder, editable by hand or by an agent. **Optional**: if
absent, thedev derives a minimal card (name + cwd + machine + branch); the
declaration only **enriches** it. Zero friction, better with a little.

Format: YAML frontmatter (machine-readable fields) + free body (context that
the lead and the briefing read):

```markdown
---
domaine: indicefossile        # the cluster key, aligned with `contexte`
                              # (proposals.json / home). The lead decides
                              # from this field whether it contains the workspace.
statut: actif                 # actif | pause | fini
tags: [carbone, fastapi, ciqual]
---

Remote backend that computes the carbon index of a meal from the CIQUAL database.
The product has 3 surfaces (mobile, web, backend); this workspace = the backend.
```

(Field names and values such as `domaine`, `statut`, `actif` are parsed: keep them as is.)

**Workspace identity** (the node key, never declared, derived):
`<machine>/<workspace>` where `machine` = `~/.config/dev-vps` or `hostname -s`, and
`workspace` = `$ZELLIJ_SESSION_NAME` or `basename "$(pwd -P)"`. Same resolution as
`thedev-link` / `agent-track`: we do not reinvent it.

**Runtime mirror** (what the leads / the owner query):
`~/.cache/thedev/command/equipes/<machine>__<workspace>.md`. Rebuilt from the
card + the agent registry when a workspace opens (same pattern as the
`agent-track.sh` hook that fills `~/.cache/soldats`). The declaration is durable
(in-repo); the mirror is disposable (in-cache).

Attachment field: `chef: <machine>/<lead>` (or empty = flat under the
owner). **Present from brick 1 but not managed**: it will be written by the
recursive rule (brick 3). We add the field, we do not fill it yet.

### 1b. The report-on-quit

VISION: *"even an abrupt close flushes a minimal report"*. When a
workspace exits, we flush a state artifact that the lead will read when syncing up.

**Location:** `~/.cache/thedev/command/debriefs/<machine>__<workspace>/<ts>.md`.
The most recent = the current state seen from above.

```markdown
---
equipe: local/indicefossile
quand: 2026-06-30T21:15:00+02:00
raison: detach            # detach | quit | crash
session: <sid>
---

## État
<one line: where it stands, what is blocking>

## Changé
<git diff --stat summary, or the files touched>

## Ordres en cours
<if a directive was active, otherwise "none">

## Artefacts
- transcript : <.jsonl path>
- fichiers   : <list>
```

(The frontmatter keys and section headings are the on-disk format: kept as is.)

Two levels, depending on the exit:

- **Minimal (always, even on crash)**: purely derived, zero AI: id + timestamp
  + `raison` + last topic (agent registry) + `git status --short` + transcript
  path. Written by the **SessionEnd** hook (`agent-track.sh`, already wired
  on that event).
- **Rich (clean exit)**: the agent writes the body (state / changed / directives)
  before leaving. Plugged into the existing graceful flow **`quit-menu`**
  (Ctrl+Q → detach/close): the "detach" or "close" branch triggers
  the writing before cutting.

**Compression (VISION limit):** the report *links* the artifacts (transcript,
files) instead of copying them: dig back in without loss, a native advantage of the
files foundation.

### Brick 1 scope: what is IN / OUT

IN: the `.thedev/equipe.md` format, the fallback derivation, the cache
mirror, the report format, the minimal wiring (SessionEnd) + rich
(quit-menu). New namespace: `~/.cache/thedev/command/` (the existing `spaces/` and
`links/` do not move).

OUT (next bricks): the recursive placement rule (brick 3), the lead
as an on-demand role + `directive` going down (brick 2/3), the reorg by the
owner. See the map below.

---

## Brick 2: the digest + routing *(in progress)*

The **two verbs of the contract** (see §The surfaces) made real on the
`~/.cache/thedev/command/` namespace that brick 1 feeds. Always event-driven,
**no lead running**.

1. **`give me the tree` → the `org-tree` command.** Aggregates all the cards
   (`equipes/*.md`) and renders the **tree grouped by `domaine`**. The **state** of a
   workspace follows **presence, not the report**: if a `claude` agent runs in
   its cwd (ground truth from the `~/.cache/soldats` registry, like home), we
   show its **topic + live busy** (`◆` answering, `●` idle), *without closing
   anything*; otherwise we fall back to the **last report** (`○`, the memory of a
   closed workspace). The report is therefore **not** the state source for live
   workspaces, only the tombstone of closed ones.
   As long as the tree is flat (no real leads), **the `domaine` IS the
   proto-lead**: grouping by domain foreshadows the lead level without
   paying for it. A single renderer feeds the three uses: the home preview, the
   expanded `org-tree` command, and later the phone skins.
2. **`talk to a node` (leaf) → `delegate`.** Routing a directive to a workspace
   **already** exists: `delegate <machine>/<workspace> "<directive>"` (transport
   `~/.cache/thedev/spaces/`, interactive = subscription). Nothing to rebuild; we
   *document* that it is the "leaf" flavor of the verb.

### Brick 2 scope: IN / OUT

IN (minimal slice): the **`org-tree`** command (reader/aggregator/renderer,
read-only, no wiring → zero risk), grouped by domain, with status + last
state line + relative age. Leaf routing through `delegate` (existing).

OUT: **cross-machine** aggregation (syncing up the other machines' cards
to the VPS, a *transport/sync* problem, not a rendering one; `org-tree` will show
the complete tree automatically when the data arrives). The **lead as an on-demand
agent** that digests *its* branch and answers without waking its leaves ("lead"
flavor of the verb): only makes sense with tree depth → brick 3.

## Brick 3: growing and shrinking *(structural: done)*

The **birth/dissolution of levels** with hysteresis, made real. Verb: the
**`reorg`** command.

- **`reorg`** decides, per machine, whether the machine lead's subtree **materializes
  the level of domain sub-leads** (`split`) or stays flat (`flat`), and
  persists it in `~/.cache/thedev/command/etages/<machine>`. **Single writer** of
  this state; `org-tree` (and the org page) only **read** it and render
  the tree accordingly; `org-tree` stays read-only.
- **Hysteresis** (invariant 2): split at `L > N` (`N=7`, `THEDEV_SPAN`), merge
  at `L ≤ N/2` (`3`, `THEDEV_SPAN_LOW`); the band `3 < L ≤ 7` is **sticky** (we
  keep the current regime): the tree does not oscillate on every open/close.
- **Event-driven** (invariant 4): `reorg` is invoked from the session hook
  (`SessionStart`, best effort, bounded): the overload is "noticed during any
  session", **no standing monitor**.
- **Rendering**: when `split`, a domain that **groups ≥2 workspaces** becomes a real
  **sub-lead `⬡`** (org node, selectable in the org
  page); **singletons** stay direct leaves under the lead
  (no level for 1 workspace). When flat, a domain with ≥2 is just a cosmetic **`◆` label**.
  A **`⚠ reorg`** marker on the lead if, after grouping, it still has
  `> N` direct children.

**Two accepted limits (what stays OUT):**

1. **Latent merge.** `L` counts the **workspace cards** (`equipes/*.md`), which
   persist after closing (a closed workspace stays a `○` node). Merging will therefore
   only trigger when a workspace is **removed** (card deleted):
   the `workspace forget` verb is missing. Today the tree only moves
   in the **split** direction.
2. **Semantic partition.** When the lead overflows with **singletons** (undeclared
   domains), mechanical grouping does not reduce the span → `⚠ reorg`. Distributing
   *semantically* (inventing coarser domains) is the **owner's** work
   (the root lead's): it needs the **on-demand lead agent** (a Claude session that
   digests the branch and redraws the map), still OUT. For a *visible* split
   right now: declare shared `domaine:` values in
   `.thedev/equipe.md` (≥2 workspaces with the same domain → sub-lead `⬡`).

## Brick 4: hierarchical memory, the 3 tenses *(in place)*

Replaces the report-on-quit. Principle: **facts sync up on their own (mechanical,
0 tokens); intelligence is only paid for at read time (AI, lazy)**. Each node has a
**bounded** context; bounded load × span ≤ 7 = bounded lead context.

Four commands, each a distinct **tense**, all signed + dated:

- **`note`**: *the present* (current state, mutable). **1 file per agent**
  (`command/notes/<workspace>/<sid>.md`) → zero contention, auto-signed from the pane.
  `add`/`ls [--all|<sig>]`/`get`/`set`/`rm` (batch + ranges). Quota per agent + sizing
  advice (`↻` beyond ~7 lines). **`note gc`** purges agents that have *really*
  quit (`agent-register` cohort, never on `SessionEnd`, never the closed workspace).
- **`summary`**: *the SHARED headline of the workspace*, what the lead sees. A common
  object, any agent edits it (atomic write, last one wins + optimistic
  guard). **Recursive**: each node has a `summary` (workspace → co-written by its
  agents; lead → written by the lead session). A lead **concatenates the bounded
  `summary`s** of its children = its context, bounded.
- **`milestone`**: *the past* (append-only, timestamped, never rewritten). **Full thread
  rebuildable**: merges manual milestones ⊕ git commits ⊕ `blocker` events
  ⊕ `summary` changes, sorted by date. Syncing up is trivial = sort by epoch.
- **`blocker`**: *waiting* (append-only log, `open`/`done`). Open ones first, the
  oldest on top (red). Anyone can resolve.

**The reflex is MANDATORY, not an invitation** (lesson: a soft reminder does not change
behavior; the designer himself ignored it). Briefing (`thedev-prompt.md`) as a
hard rule: *after a commit / a delivery, the `summary` must change*. A `[summary]` nudge
**triggered on commit** (HEAD changed + summary not touched). `summary --suggest` prefills
a draft (less friction).

**Sync up (event-driven, free).** `sync-up` = `rsync -az --delete` of **all of**
`~/.cache/thedev/command/` → the top stores **the complete memory tree** (not just the
facades: tiny, text). Triggered at **end of turn** (`Stop` hook, debounced 45 s) +
flush on close. **Store everything, load bounded, drill into the always-reachable mirror**
→ the root lead on jlax answers at a glance *and* in detail, whether the machine is off or not.

## Brick 5: the on-demand lead + semantic partition *(in place)*

- **`lead [<machine>|<machine>/<domain>]`**: calls up an **interactive** Claude
  (subscription, never `-p`) briefed with the aggregated context of the scope (via `org-tree`,
  which reads local + mirror). Reconciled with the historical shell function: **no arg =
  the root lead** (persistent, on the top, briefed with `org-tree` → sees everything through the mirror);
  **with an arg = LOCAL brief** for that machine/domain. Can be opened from the org
  page (`↵` on a node → `CHEF` decision, `dev()` launches in the current pane).
- **`partition`**: the **only intelligent step** of the tree (resolves `⚠ reorg`).
  `status`/`prep`/`apply`. The **decision** (grouping N workspaces by theme, ≤ span
  well-named domains) is made by the Claude that runs `apply` (subscription); the
  binary provides the material + safe writing (**per-node lock + re-check of the
  snapshot**). Result = `grouping/<key>` override, read by `org-tree`, non-intrusive.
  **Persistent** derived state: the `[reorg]` nudge comes back every session as long as the
  machine overflows (self-clearing state, no queue).

**Org page** (`org-nav`): left = **pure org** (owner → leads →
sub-leads, never the leaves); right = **direct children** of the node (sub-leads or
sessions); 1st line `‹ Back`; blockers in **red**; soft selection. From a
leaf, `org-tree` queries the top → the **complete fleet visible from anywhere**.

## Next

- **`workspace forget`**: remove a workspace (delete its card) so that level **merging**
  can happen (today the tree only moves in the split direction).
- **Automating a lead** (deferred, event-driven when it is done): periodic reading
  of the aggregated context → Telegram report / restarting sessions. The foundation (synced-up memory
  + on-demand lead) is ready; only a trigger is missing, **never** `claude -p`.
- **Fine-grained remote drill-down**: from a local lead, `note ls --all` of a workspace *on
  another machine* is only complete through the top (the mirror has the detail): open the
  lead *on* the top to dig further.
