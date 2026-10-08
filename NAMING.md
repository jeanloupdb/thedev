# thedev glossary

The shared vocabulary of thedev. Use it everywhere: code, commits, docs, conversations.

## Structure

**Runtime:** thedev → machine → **workspace** → pages → panes
**Org:** owner → lead → workspace → agent

| Term | Meaning | Command |
|---|---|---|
| **thedev** | The app itself, started with `dev`. | `dev` |
| **machine** | A computer running thedev: your laptop, a server. | |
| **workspace** | One project on one machine: a zellij session holding a group of peer agents. | `workspace` |
| **agent** | One Claude Code instance working in a workspace. Agents in a workspace are peers. | |
| **home** | The start screen: workspaces, folders, infos, automations. | `home` |
| **page** | A tab of a workspace. Every workspace has three: **agents**, **jobs**, **shell**. | |
| **pane** | An area inside a page (zellij term). | |
| **job** | A long-running process (dev server, watcher, build) started in the **jobs** page. | `job` |
| **spawn** | Add one more agent to the current workspace. | `spawn` |
| **automation** | A scheduled task that drops work into a workspace (systemd timer). | `automation-list` |
| **headless** | A workspace running with no client attached (server, closed laptop). | `headless-run` |

## The three pages of a workspace

- **agents**: where the AI works. The sidebar on the left, the stack of agents on the right, and the `+` bar to spawn one more.
- **jobs**: every long-running process started with `job` lands here, isolated from the agents page.
- **shell**: your own terminals (`shell` and `git`). Agents do not drive these panes.

## Workspace memory

Each workspace keeps a shared, living context that every agent feeds as it works.

| Term | Meaning | Command |
|---|---|---|
| **note** | Present state: short lines describing where things stand. Kept up to date, not stacked. | `note` |
| **summary** | The one or two sentences a lead reads to understand the workspace at a glance. | `summary` |
| **milestone** | Past: a dated, signed event (a delivery, a decision). Commits are added automatically. | `milestone` |
| **blocker** | Waiting: what is stuck and on what. Shown first to leads until resolved. | `blocker` |

## Between workspaces

| Term | Meaning | Command |
|---|---|---|
| **link** | A workspace opened to incoming tasks from other machines. | `thedev-link` |
| **task** | Work delegated to an agent in a workspace on another machine (peer to peer). | `delegate` |
| **report** | What comes back from a task, or from a workspace when it closes. | |

## The org

Inside a workspace, agents are peers. The hierarchy runs **between** workspaces.

| Term | Meaning | Command |
|---|---|---|
| **owner** | You, the root of everything. You can bypass any level. | |
| **lead** | Sits above one or more workspaces, never inside one. Reads their summaries, sends directives. | `lead` |
| **directive** | A top-down instruction from a lead to a workspace. | `directive`, `directives` |
| **org tree** | The tree of leads, domains and workspaces, with their state. | `org-tree`, `org-nav` |
| **partition** | Grouping a machine's workspaces into a few themed domains, so no lead has too many. | `partition` |
| **sync up** | Sending this machine's workspace cards and reports up to the top machine. | `sync-up` |

> Flat and vertical coexist. Two sibling workspaces stay peers (neither commands the
> other); they both report to a lead, which belongs to another level.

## Renamed in October 2026

The previous vocabulary was military. If you meet an old name in an old note or
transcript, here is its new one:

| Old | New |
|---|---|
| équipe | workspace |
| soldat | agent |
| général | owner |
| chef | lead |
| état-major (`etat-major`) | home (`home`) |
| le front / le camp / la tente | agents / jobs / shell |
| soutien (`soutien`, `crun`) | job (`job`) |
| renfort (`renfort`) | spawn (`spawn`) |
| garde | automation |
| garnison | headless, or the welcome pane of the jobs page |
| mission (`mission`) | task (`delegate`) |
| ordre (`ordre`, `ordres`) | directive (`directive`, `directives`) |
| débrief | report |
| jalon / blocage / résumé (`jalon`, `blocage`, `resume`) | milestone / blocker / summary |
| commandement, arbre (`arbre`, `carte`) | org, org tree (`org-tree`) |
| remonter | sync up (`sync-up`) |

Migration for an existing install: `migrations/2026-10-english-names.sh`, run by
`install.sh`.
