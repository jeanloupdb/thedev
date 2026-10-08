# Vision

## What it is

thedev turns an **intention** into a **finished result**, produced by agents, **on your own machines**, and keeps you in control of the whole thing.

A session is a bounded context (a school assignment, a side project, a production backend) where an agent downloads, organizes, runs, deploys, and hands you a deliverable. You decide, you check, you own. You do not *type* the work: you **direct** it and you **answer** for it.

## The core (fixed)

This is the invariant. It does not move: it is the reference point for every decision.

> An intention → a session where an agent does the work end to end, on the right machine → a finished result that you own, **with you in control, on your infrastructure, at a controlled cost**.

And its lasting center of gravity: **not** "the agent executes" (the labs will make that commonplace and free, and we *consume* it) but **you keep control, trust and cost** over what it produces.

In one line: **thedev is the tool for the part that does not get automated**: deciding what to do, checking that it is right, owning the result, answering for it.

## The surface (replaceable)

Everything else is 2026 packaging, swappable without touching the core:

- the terminal / zellij / the TUI
- Claude Code as the engine
- the word "dev"
- the current interface (picker, Remote Control, tasks…)

If a better engine comes out, thedev adopts it. If the interface becomes voice-based or ambient, the core still holds. Never confuse the packaging with the substance.

## The bet

The stronger the models get, the more agents run in parallel, and the more the bottleneck shifts:

- from **"can the agent do it"** (solved by the labs, better and better)
- to **"can I supervise, trust, pay for and coordinate N agents on my machines"**: never solved by the labs, because it goes against their interest (they sell the brain, not your control tower), and it **grows** with autonomy.

thedev bets on the second. So **every jump in model capability is a tailwind, not a threat.**

## Running many agents (the organization model)

The bet above raises the question (*supervise, trust, coordinate N agents*) without answering it. Here is the answer, and it is the opposite of what the labs do.

**Top-down decomposition vs bottom-up aggregation.** A typical agent, facing a task that is too big, **creates workers below itself**: short-lived, they do a piece, return a result, and end. The tree grows from the *task* and extends *downward*. thedev does the opposite: when you have too many **real workspaces** to direct, you create **leads above** them. The leaves are real agents working continuously on real projects; the nodes above do not *do* the work, they **distribute attention** and **relay information**: directives going down, status going up. We do not create subordinates, we create **leads**.

**Flat is not overturned: it is the rule *inside* a workspace.** A session is a **workspace**: a group of **peer** agents working together, with no internal lead. This is permanent and unchanged. The hierarchy **never** goes down inside a workspace; it organizes workspaces **relative to each other**. A **lead** sits above workspaces, never inside one, and two sibling workspaces stay peers (they do not direct each other; they report to a lead, one level up). The org model **adds a vertical axis** to the horizontal flat structure; it does not replace it.

**A hierarchy that grows and shrinks.** The vertical axis is not fixed: it grows and folds back with the load, symmetrically on three axes.

| Growing | Shrinking |
|---|---|
| **Split**: span too wide → promote a sub-lead | **Merge**: span too thin → fold back, give the turns back |
| **Step in**: you take over a workspace, the chain is informed and stands aside | **Step out**: you report upward, the lead takes over again |
| **Directives** ↓: the lead's intent goes down | **Status** ↑: state goes up, aggregated and summarized |

**The owner is never locked in by their own organization.** Two absolute privileges:
- *Free bypass*: you take over any workspace without asking anyone. Your presence is a **fact**, not a request: the chain is **informed** (a presence flag goes up) and **stands aside** (the responsible lead suspends its directives on that workspace); it does not **authorize** you.
- *Clean exit*: you leave by **flushing a report upward** (what you changed, the state, the directives in progress); the flag drops, the lead takes over with the context. Never a silent exit: even an abrupt close flushes a minimal report.

**The limits, stated openly.** This model has a cost, and we say so:
- **Subscription ceiling**: each lead is a real session that burns turns on your subscription. The organization cannot grow without bound; its permanent cost must stay ∝ the load. That is *why* merging is vital, not optional. "Infinitely" is an asymptote; 2 or 3 levels is reality.
- **Upward latency**: information goes up at each node's *turn*; depth × cadence = freshness of the view at the top.
- **Hysteresis**: split at N, merge well below M, otherwise the tree oscillates.
- **Compression**: each level summarizes; the report **links the artifacts** (transcript, files) so you can dig back in without loss. A native advantage of the bash + files foundation.

**The safeguard.** This self-organization is *not* the autonomy we reject (see Non-goals): it never decides *what to produce*, it only manages *the scope of your attention*. You are always the root, the intention always comes from you, you can always bypass. The hierarchy **serves** your control, it does not **replace** it. The day it decides in your place, that is a bug, not a feature.

## Design principles

1. **Engine-agnostic** *(direction, not current state)*. thedev orchestrates an engine; it IS NOT the engine. Reduce hard dependencies on the internals of a specific CLI, so that changing engines does not force a rewrite. Current coupling and abstraction plan: [`ENGINE-COUPLING.md`](ENGINE-COUPLING.md).
2. **Primitives that last.** Bet on ops/sysadmin building blocks that will be worth as much in five years as today: the **workspace** (unit of work), the **fleet view**, the **task** (dispatch between machines), the **job** (long-running process), **isolated secrets**, **cost/quota awareness**.
3. **Consume the brain, do not rebuild it.** Native memory, planning, autonomy, multimodal: when the labs ship them, thedev *exposes* them, it does not reimplement them.
4. **Human in control.** Anything irreversible, costly or sensitive stays under human decision. Secrets out of the chat. A close that first shows what it will cut.
5. **On your infrastructure, on your subscription, auditable.** Your machines, your subscription (no API), zero open ports, readable bash + files. No black box, no rented cloud.
6. **Lightweight.** Minimal TUI, low footprint, to run many agents without saturating.

## Non-goals

thedev does **not** try to:

- be a smarter agent → that is the labs' territory, we consume it;
- be autonomous / self-improve on its own → the point is that *you* stay in control;
- be universally multi-model → a deliberate choice, centered on your subscription;
- be a consumer assistant across messaging apps → control goes through the official app, not through a bot shell (smaller attack surface);
- become a product to sell → thedev is a **production engine**, not a commodity. Its value is what *you* build with it, which accumulates.

## How it evolves

The core does not move. The surface does, on purpose. Filter question for every addition:

- does it strengthen "you keep control / trust / cost"? → **core**, we invest.
- does it rebuild what the labs will ship? → **we wait**, we will consume it.
- does it hard-couple us to a specific engine? → **to abstract**.
