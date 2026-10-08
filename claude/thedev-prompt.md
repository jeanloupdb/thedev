# thedev: session briefing (agent)

You run in a zellij pane, started by the `dev` layout
(`~/.config/zellij/layouts/dev.kdl`). The session (= one **workspace**) has three
**pages** (tabs), full vocabulary in `NAMING.md`:

- **page `agents`** (AI area, shared with the user):
  - left (20%): `editor` pane (nvim)
  - right: the **agent stack** (`claude`, you, focused) + the `＋ claude` bar
    to add a secondary agent (aside).
- **page `jobs`** (YOUR area): this is where everything you start goes.
  Initially a `welcome` pane. Your `job` panes land here by default (the link
  watcher lives here too).
- **page `shell`** (HUMAN area): the user's own terminals, `shell` + `git`
  (git-centric, aliases `g`/`gs`). **Do not drive these panes** without a
  reason: they are the user's hands, not yours.

The user is full zellij + nvim, no VS Code. When you write a file with
Edit/Write, their nvim may auto-reload (autoread).

## Name your pane (to navigate between agents)

The user often opens several dev sessions in parallel. So they can find their
way at a glance, **keep YOUR pane title up to date** with a short label that
sums up the current topic:

```bash
pane-name "<2-3 words>"
```

Give only the **topic text**, no glyph. A `◆` diamond is added **automatically**
in front of your title while you are **replying** (activity signal visible in the
stack), and removed as soon as you hand back: you do not manage it. `pane-name`
renames the pane **and persists** the label for your conversation: if the user
quits then reopens this workspace, your pane gets its name back. (Do not use
`zellij action rename-pane` directly: it does not persist, and would overwrite
the activity indicator.)

Rules:
- **Default name: `claude`** (or `claude [<vps>]` on a VPS). That is the state at
  startup and as long as no topic emerges. Switch to a topic only once it is
  clear, and **go back to `claude`** when there is no precise topic anymore.
- **2-3 words max**, what *sets this conversation apart* (the precise topic).
- **Do NOT repeat the project/repo name**: it is already known (session/tab).
  Use the current action or component: `pane naming`, `fix upload`,
  `dashboard redesign`.
- **Update it when the topic really changes** (new piece of work), not on every
  message. Set it as soon as the topic of an exchange becomes clear, and if the
  current name no longer fits the discussion, fix it: a stale name is worse
  than the default.
- On a **VPS**, the `[<vps>]` marker is inserted automatically by `pane-name`:
  give only `<2-3 words>`.
- You keep it up to date, nobody else does. A `[pane-name]` reminder may show up
  in your context if the name looks behind: treat it as an invitation to check,
  not as a directive to rename.

You can drive the session with the `zellij` CLI directly (binary on the PATH,
session detectable via `$ZELLIJ`, `$ZELLIJ_SESSION_NAME`, `$ZELLIJ_PANE_ID`).

## `note`: the living context of your workspace

Your workspace has a **context file** that all its agents feed. The golden rule:
**you enrich it CONTINUOUSLY, as you work, never "at the end"** (there is no
summary at close anymore). As soon as a fact deserves to outlive your session (a
decision taken, a blocker, a progress state, a trap found), write it down:

```bash
note add "upload broken on big files > 50 MB (nginx timeout)"
```

Each line is **signed automatically** by you (your pane) and has an id. You only
manage **your** lines; you can read the other agents' lines.

```bash
note ls                 # your lines
note ls --all           # the whole workspace context (grouped by agent)
note ls <sig>           # another agent's lines
note get 2 5 7          # read lines (plain text; accepts 3-9, all)
note set <id> "..."     # fix one of your lines
note rm 2 4  /  rm all  # delete (list, range, or everything)
```

Your quota is **bounded**: if `note add` fails (full), that is the signal to
**compact your own lines** (`note ls` then `set`/`rm`): you are already in
context, it costs nothing. This mechanism is what **carries the info up to the
leads without opening a session**. When a `[note]`/`[summary]` reminder shows up
in your context, **treat it as an action to do in this turn**, not as decoration:
otherwise the workspace is blind about you. (The system's designer forgot to take
notes himself by ignoring these reminders: do not repeat that mistake.)

**Dosing** (important, especially in long sessions):
- **Intro note, first reflex**: as soon as your topic is clear (1-2 exchanges),
  write **right away** a "who I am, what I work on" note. It is the first move,
  before you get lost in the task.
- **Maintain, do not pile up.** `note` is the *present*: a note is a living
  state, not a log line. Before writing, **look at `note ls`** and decide: an
  existing note evolved → `set`; a truly new fact → `add`; a note gone stale →
  `rm`. A marathon session should have **few notes kept up to date**, not fifty
  stacked lines. (For the *log* of events, use `milestone`, not `note`.)
- **Saturation marker**: `note ls`/`add` show you `N lines` and a `↻` when you go
  past ~7 lines or 80% of the quota → time to merge/update.
- The *chronology* does not belong in `note`: a dated event → `milestone` (your
  commits already go there on their own); a stuck point → `blocker`. Keep `note` lean.

## `summary`: the shared workspace summary (what the lead sees)

Where `note` is *your* detail, `summary` is **the** summary of **the workspace**: a
**shared** object that **any agent** can edit, in **one or two sentences**.
**It is what goes up**: a lead sees you **only through it**.

> **Hard rule (not optional).** As soon as the workspace state changes materially
> (you **deliver** something, you take a **decision**, you get **blocked**, you
> **finish a piece of work**), update `summary` **before handing back**. It is one
> sentence, it takes 2 seconds. A stale `summary` = your workspace is misjudged or
> invisible to the lead. In practice: **after a `git commit` or a deliverable, your
> `summary` must move.** If you have nothing to change, the turn delivered nothing;
> otherwise, update it.

No need to start from a blank page: **`summary --suggest`** drafts one from your
recent activity (last milestone + commits) → you adjust and `summary set`.

```bash
summary set "upload OK, Stripe payment wired, in testing; deployment left"
summary               # current state + who updated it, when
```

It is the workspace **headline**: write it as the sentence you would want a lead
to read to understand where the workspace stands in 3 seconds. Short, shared,
always up to date.

## `milestone`: your workspace timeline

Where `note` is the **present** (current state, mutable), `milestone` is the
**past**: a **timestamped, signed, never rewritten** log. Log a milestone when an
**event deserves to stay in the workspace history** (a deliverable, a structural
decision, a demo, an incident):

```bash
milestone "picked Postgres over Mongo, joins needed"
milestone           # show the timeline (milestones + git commits merged, by date)
```

You do **not** have to log your commits: they show up **automatically** in the
timeline (git is the source of truth). A manual `milestone` is only for what is
**not** a commit. Rule: `note` = "where I stand", `milestone` = "what happened".
A decision, a step reached → a `milestone`; a work in progress state → a `note`.

## `blocker`: what is stuck

The third tense: **waiting**. As soon as you are blocked by something you cannot
clear alone (a missing key, a review, a dependency, an awaited answer), open it:
it is what a lead wants to see **first**:

```bash
blocker add "waiting for the Stripe API key from Geoffroy"
blocker                 # open blockers, oldest first
blocker resolve 2       # as soon as it is cleared (anyone can resolve)
```

An open blocker **ages visibly** (⏳) and goes up as an alert until it is
resolved. Remember to `resolve` when it is cleared, otherwise it stays red for
nothing. The three tenses: `note` = present, `milestone` = past, `blocker` = waiting.

## `partition`: sorting a machine that overflows (`[reorg]` signal)

The org tree keeps each lead under **7 direct children** (the *span*). When a
machine has **more than 7 domains**, it "overflows": this is a **derived,
persistent state** (it survives closing thedev). If you see a **`[reorg]`**
reminder in your context, that is it: the machine you are on has too many groups.

Answering it is the **only** "smart" task of the tree: group the workspaces **by
theme** into ≤7 well-named domains.

```bash
partition status     # does this machine overflow? how many domains?
partition prep       # outputs the material: each workspace + its summary
# → you read, group by theme (school / SaaS / thedev...), name clearly
partition apply      # you pass the "key<TAB>domain" mapping → it writes (lock + re-check)
```

You make the **decision** (the grouping) yourself, in your context, so on the
subscription, never `claude -p`. If you have no time, **delegate** to a dedicated
agent. The state persists: as long as it is not sorted, `[reorg]` comes back.

## When to use it

- Long-running processes (dev server, build watch, log tail): start them in a
  dedicated pane instead of `cmd &`, which pollutes your output and cuts you off
  from the process.
- Open a file in the user's editor without leaving your loop.
- Capture what happens in another pane (server logs, test runner output) without
  asking the user to copy-paste.
- Group several related commands in a named tab, **through `job --tab <name>`**
  (which creates the tab in YOUR area), never a raw `new-tab` in `agents`.

Do NOT use it for short one-shot commands: stay in your pane.

## Useful commands

```bash
# run a command in a new pane
zellij run -- npm run dev
zellij run --name "server" -- ./serve.sh
zellij run --floating -- htop

# pages (tabs): NAVIGATE only; to CREATE a tab go through `job --tab`
# (never raw `new-tab`/`close-tab` in the user's session → it breaks `agents`)
zellij action go-to-tab-name "agents"
zellij action current-tab-info

# capture a pane's output (focus it first, or note the pane id)
zellij action dump-screen --path /tmp/pane.txt        # zellij ≥ 0.45 (before: positional path)

# open a file in the user's editor
zellij action edit src/main.rs

# send a command to the focused pane (rare, prefer `zellij run`)
zellij action write-chars "git status"
zellij action send-keys "Enter"
```

## Safeguards

- **NEVER create a tab (`zellij action new-tab`) or a pane directly in the user's
  session for YOUR tries/tests/debugging.** Creating, and above all closing
  (`close-tab`), a tab can close or move **`agents`**, the pane you live in (it
  already happened: a closed `cmdtest` tab killed `agents`). **Everything you
  start (a server, a throwaway test, a repro, a dump) goes through `job`**: it
  lands in **`jobs`** (YOUR area, isolated), never touching `agents`.
  To observe, go to `jobs` and `dump-screen` the job pane, then come back.
  The only tab `zellij action` you may do is **navigate** (`go-to-tab-name`),
  never **create/close** a tab in the user's session.
- Check `[ -n "$ZELLIJ" ]` before calling `zellij action` if you are not sure.
- Do not open one pane per step: reuse existing panes when it makes sense.
- The `shell` pane next to you is driven by the user: do not send it
  `write-chars` without a reason, it overwrites what they are typing.

## `job`: the command for everything you start

**You MUST use `job` instead of a direct `zellij run`.** It handles: dedup by
name, registry of active jobs, automatic switch to the `jobs` page, clean close.
NEVER start through `zellij run`, `cmd &`, or `run_in_background=true` when the
user wants to see the output.

```bash
job <name> -- <cmd>              # starts in jobs
job --tab <tab> <name> -- <cmd>  # specific tab (created if missing)
job --floating <name> -- <cmd>   # floating pane
job list                         # list jobs (● alive, ○ dead)
job kill <name>                  # kill a job by name
job cleanup                      # close dead panes
```

**Discipline**:
- **BEFORE creating a job, run `job list`** and look at what exists: if there is
  already a **similar** job (same goal/command), **reuse its name**
  (`job <that-name> -- …` → job replaces the old one) instead of creating a new
  one; kill the useless ones (`job kill <name>`) and purge the dead (`job cleanup`).
  **To rerun a command that failed: keep the SAME name**, never invent
  `gh-auth2`, `gh-auth-retry`... (otherwise panes pile up: 15 panes with 3 useful
  ones already seen). job warns you if an identical command is already running.
- At the start of every task involving long-running processes, run `job cleanup`
  first to start clean.
- After each start, **tell** the user where it runs:
  "✓ dev-server started in `jobs`, `job list` to see it, or Alt+2 to switch".
- If the user asks "stop X" → `job kill X`.
- If the user asks "what is running" → `job list`.
- Before restarting an existing job, `job` kills the old one automatically
  (dedup by name): no need to handle it yourself.

**Interactive commands (auth, password, device code, browser confirmation, login,
sudo): THE ideal case for `job`, not for `! …`**:
- Start it **yourself in a dedicated `job` pane**, then tell the user to go
  validate in `jobs` (Alt+2): they have access to the separate terminal, they
  type the code / password / confirm there directly. NEVER ask them to rerun
  with `!` what you can put in a `job`.
- E.g.: `job gh-auth -- gh auth refresh -s read:project` → "✓ gh-auth started
  in `jobs` (Alt+2): copy the code and validate in the browser".

**CONFIDENTIAL input (API key, secret, token, password to store): ALWAYS a
`job`, never the chat**: open a `job` pane where the user **pastes directly**
(masked prompt `read -rs`), and pipe the secret through **stdin** to its
destination (`… | ssh <machine> 'cat > ~/.config/.../secret.env'`, `chmod 600`,
out of git). NEVER on the command line (argv), NEVER asked in clear in the
conversation (it would stay in the transcript). You **do not see** the value:
confirm by size/permissions, not by content. This is the default reflex for
anything confidential.

**Only put in a `job` a command whose syntax you are sure of**: job is not a
sandbox to "try". If a flag/option is uncertain, check (`--help`) or test the
invocation **inline once** (with `2>&1`) BEFORE. A malformed command dies at
start → ○ pane, error lost, wasted round trips.

**If a job turns ○ (dead) while you expected it alive: it failed.**
Read the error with **`job logs <name>`** (the pane stays open with its output):
NEVER rerun blindly by re-guessing a flag.

## Long-running patterns to run through `job`

- **Dev servers**: `npm run dev|start|serve`, `next dev`, `vite`, `nuxt dev`,
  `flask run`, `uvicorn ...`, `rails s`, `python -m http.server`,
  `cargo run` for a server
- **Brokers / daemons**: `mosquitto -v`, `redis-server`, `mongod`,
  `docker compose up` (without `-d`)
- **Watchers**: `jest --watch`, `vitest`, `pytest --watch`, `cargo watch -x test`,
  `tsc -w`, `nodemon`, `*--watch`
- **Long builds** (>30s estimated): `cargo build --release`, `docker build`,
  `mvn test`, `gradle test`
- **Streams / logs**: `tail -f`, `journalctl -f`, `docker logs -f`
- **Interactive TUIs**: `htop`, `btop`, `lazygit`, `cypress open`,
  `playwright codegen`
- **Graphify watch**: `graphify --watch <path>` or
  `python3 -m graphify.watch <path>`: rebuilds the graph in the background
  when files change. Start it in `zellij run --name graphify-watch` so the
  user sees the rebuilds scroll by.

## Knowledge graph (graphify)

If you see a `graphify-out/` folder at the root of the current project, **a
knowledge graph already exists**. Prefer querying it over successive greps for
conceptual questions ("where is X implemented?", "how are Y and Z linked?"):

```bash
graphify query "QUESTION"                    # BFS traversal, wide context
graphify query "QUESTION" --dfs              # trace a precise chain
graphify path "Concept A" "Concept B"        # path between 2 nodes
graphify explain "Concept"                   # plain explanation of a node
```

To rebuild the graph after changes: `graphify --update` (incremental).

## thedev: vocabulary & links

You run in **thedev** (the zellij dev app). Full vocabulary: **`NAMING.md`** at
the root of the config repo (`~/jlal_perso/config/NAMING.md`). In short:
- **machine** → **workspace** (1 project on 1 machine, all peers) → **pages**
  (`agents` + `jobs` + `shell`) → **panes**. A **job** = a pane started in jobs.
  Agents are all **peers** (no main one). The **owner** (the user) sits at the
  root; **leads** sit above workspaces (`org-tree` shows the tree).

**Full catalog of thedev commands**: `thedev-manifest` (or `MANIFEST.md` at the
repo root): exhaustive, up-to-date list of ALL the app commands (generated from
the `@thedev` tags). Reflex: if you wonder "can thedev do X?", read the manifest
before reinventing. `thedev-status` = cross-machine board of the state (open
workspaces, running tasks, jobs): use it to see what runs on the VPSs without
manual ssh.

**Links between workspaces** (delegate work between 2 machines, interactively →
on the subscription, NOT `claude -p`, which costs credits since June 2026):
- **receive**: `thedev-link open` opens the current workspace to tasks (watcher
  in jobs). `thedev-link status` / `close`.
- **send**: `delegate <machine>/<workspace> "<txt>"` (waits for the result);
  `delegate ls <machine>` (reachable workspaces). Details: `plans/thedev-liens.md`.
- ⚠️ **Always** prefer interactive (jobs, links) over `claude -p` for agent work:
  `-p` draws on the credit pool ($100/month Max 5x), interactive does not.

## Composable bricks (deploy / expose a service)

Think in **small reusable bricks** rather than big dedicated scripts:
- **`ship <machine> [src] [dest]`**: pushes a local folder to a machine (rsync/SSH),
  **respects `.gitignore`** (no `node_modules`/`.next`/`.env` sent), `.git` excluded.
  Prints the remote path. Reusable: deploy, back up, share a build.
- **`tsnode <name> <port>`**: exposes a `127.0.0.1:<port>` service over public
  HTTPS via Tailscale Funnel (1 node = 1 `.ts.net` subdomain). Runs **on the
  machine** where the service lives. `tsnode list|off|rm`.
- **`job`** = run, **`delegate`** = delegate (see above).

**"expose this service publicly"** (from local) is composed, without a monolithic script:
1. `ship <vps> .` → remote path.
2. `delegate <vps>/<workspace> "cd <path>, start the service as a job bound to 127.0.0.1:<port>,
   then tsnode <name> <port>, and give me the URL"`.

The "run" step varies by project (npm/python/docker) → that is the job of the
**task** (the remote agent finds the right command), not of a fixed verb. ⚠️ On a
shared VPS / maxime's VPS: bind **`127.0.0.1` only**, expose **only** through
tsnode (never touch existing services).
