<div align="center">

# thedev

### Run many Claude Code agents in parallel, on every machine you own.

![Claude Code](https://img.shields.io/badge/Claude_Code-native-D97757?logo=anthropic&logoColor=white)
![zellij](https://img.shields.io/badge/zellij-based-2563EB)
![Tailscale](https://img.shields.io/badge/Tailscale-0_open_ports-242424?logo=tailscale&logoColor=white)
![Bash](https://img.shields.io/badge/Bash-the_glue-4EAA25?logo=gnubash&logoColor=white)
![Subscription](https://img.shields.io/badge/cost-subscription_only-22C55E)

<!-- DEMO: render the GIF, then uncomment the line below:  vhs demo.tape  →  demo.gif -->
<!-- ![thedev home: every agent you run, at a glance](demo.gif) -->

</div>

thedev is a multi-agent dev environment for Claude Code. One project on one machine is a
**workspace**: a terminal session where several agents work side by side, your long-running
processes run in their own page, and your own shells stay out of the agents' reach.

Workspaces live on your laptop and on your servers alike. Close the laptop and the server
keeps working; send a task from one machine to an agent on another; schedule an agent to
work while you sleep. Everything runs on your **Claude subscription**, not on API credits.

## 🚀 Install

**There is no sign-up for thedev.** No account, no server of ours, no extra subscription:
it is a tool that lives on your machine. The only account you need is **Claude**: thedev
drives [Claude Code](https://claude.com/claude-code), so you need a Claude subscription and
the CLI logged in. Everything else is free and open.

thedev runs on **Linux**. On **Windows**, WSL runs a real Linux inside Windows: nothing to
partition, and it can be removed with one command.

<details>
<summary><b>I am on Windows</b>: install Linux first (2 minutes)</summary>

<br>

Open **Windows Terminal as administrator** (right-click the Start menu, then
"Terminal (Admin)" or "PowerShell (Admin)" depending on your version), then:

```powershell
wsl --install
```

Restart when Windows asks, open **Ubuntu** from the Start menu, and continue below: you
are now in Linux. [Official Microsoft guide](https://learn.microsoft.com/windows/wsl/install)

</details>

### 1. The tools

thedev is glue: it builds on existing tools and installs none of them for you. This step
is required, including on a fresh WSL.

```bash
sudo apt update && sudo apt install -y git python3 jq fzf inotify-tools neovim
mkdir -p ~/.local/bin && export PATH="$HOME/.local/bin:$PATH"

# zellij (the terminal multiplexer thedev is built on), not in the Ubuntu repositories
curl -L https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz \
  | tar xz -C ~/.local/bin

# Claude Code
curl -fsSL https://claude.ai/install.sh | bash
claude   # log in to your Claude account, then leave with /exit
```

### 2. thedev

```bash
git clone https://github.com/jeanloupdb/thedev
cd thedev && ./install.sh
source ~/.bashrc
```

### 3. Open a project

```bash
dev
```

That is the only command to remember. It opens **home**: pick **new workspace**, point it
at a folder, and your first agent starts there.

> Something wrong? **`thedev-doctor`** checks the install line by line and tells you what
> to rerun. It repairs nothing by itself, it only diagnoses.

<details>
<summary>What the install touches, and how to undo it</summary>

<br>

`install.sh` creates symbolic links (any existing file is backed up as `.bak.<date>`):

- thedev's commands in `~/.local/bin/`
- the zellij config: `~/.config/zellij/{config.kdl, themes/, layouts/, plugins/}`
- a delimited block in `~/.bashrc` (it provides the `dev` command)
- the `agent-track` hook, merged into `~/.claude/settings.json`

To remove everything:

```bash
cd ~/thedev && ./bin/thedev-manifest --scripts | xargs -I{} rm -f ~/.local/bin/{}
rm -f ~/.config/zellij/config.kdl ~/.config/zellij/themes/muted.kdl \
      ~/.config/zellij/layouts/dev.kdl ~/.config/zellij/layouts/org.kdl \
      ~/.config/zellij/plugins
sed -i '/# >>> thedev >>>/,/# <<< thedev <<</d' ~/.bashrc
rm -rf ~/thedev
```

The zellij links point *into* the cloned folder: remove them before deleting `~/thedev`,
or zellij is left with a config that leads nowhere. If you already had a zellij config,
`install.sh` set it aside as `.bak.<date>`: that is where it is waiting.

</details>

## What you get

**The basics**
- 🖥️ **A terminal app that keeps running**: everything lives in zellij and runs detached. Close it, come back, it is still there.
- 📁 **One session per folder**: one project is one workspace.
- 🤖 **Native Claude Code**: agents run interactively, on your subscription.
- 🐚 **Bash and plain files**: readable, editable, auditable, no black box.
- 🛡️ **Tailscale**: a private network between your machines, no open port.
- 🐧 **Linux and nvim**, or Windows through WSL.

**Many agents at once**
- 👁️ **Home**: every agent you run, and its state, at a glance.
- 🧩 **Spawn agents**: as many as you want per workspace.
- 🏷️ **Self-naming panes**: each agent names its pane after its current topic.
- 🔌 **One-click resume**: reopen a local or remote session where you left it.

**Your machines, everywhere**
- 🌍 **Multi-machine**: laptop and servers in one view.
- 📨 **Tasks**: send work to an agent on another machine, and get the result back.
- 🚚 **Folder transfer**: push whole folders between machines, respecting `.gitignore`.
- 📲 **Remote control**: drive your server from the app.
- 🛰️ **Headless**: workspaces keep running on a server with nothing attached.
- ⏰ **Automations**: scheduled work, replayed over time.

**You stay in control**
- ▶️ **Jobs page**: long-running commands (`npm start`, builds, watchers) in their own page.
- 🖧 **Shell page**: your own terminals, out of the agents' reach.
- 🧹 **Clean exit**: see what you stop before closing (Ctrl+Q).
- 📊 **Live diagnostics**: RAM, disk, CPU, heat, network, Bluetooth devices, Claude usage.

**Safe and self-hosted**
- 💳 **Subscription only**: on your Claude plan, no API cost.
- 🔒 **Secrets out of the chat**: passwords, keys and sudo without the agent seeing them.
- 🌐 **Publish with no open port**: serve a site over HTTPS through Tailscale.
- ⏳ **Claude usage limits**: the 5-hour and weekly windows, live.

<sub>Automation example: "on my server, every morning, write an article and its audio podcast, then send me the link on Telegram."</sub>

## Learn more

- **Vocabulary**: [`NAMING.md`](NAMING.md)
- **Why thedev exists**: [`VISION.md`](VISION.md)
- **Every command**: [`MANIFEST.md`](MANIFEST.md) (generated), or `./bin/thedev-manifest`
- **Live state of all machines**: `thedev-status`

---

<div align="center">

Built to code with Claude without renting the cloud. ⭐ if it speaks to you.

</div>
