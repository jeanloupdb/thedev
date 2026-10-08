#!/usr/bin/env bash
# install.sh: installs thedev (the zellij dev app: `dev` layout, helpers,
# cross-machine links, board) on a machine, WITHOUT touching the rest of your
# personal config. Idempotent. Symlinks, with automatic backup (.bak.<timestamp>).
#
# Requirements (binaries): zellij, claude (CLI), nvim, python3, git, jq, fzf,
# inotify-tools. Check them afterwards: ./bin/thedev-manifest --check-deps
#
# Usage:
#   ./install.sh                  # thedev
#   ./install.sh --vps=<label>    # + server marker (red badge + Remote Control)
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TS=$(date +%Y%m%d-%H%M%S)
VPS_LABEL=""
for arg in "$@"; do case "$arg" in --vps=*) VPS_LABEL="${arg#--vps=}" ;; esac; done
log()  { printf '\033[1;34m[thedev]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[thedev-warn]\033[0m %s\n' "$*"; }

link() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ] && return
  if [ -e "$dst" ] || [ -L "$dst" ]; then log "Backup: $dst → $dst.bak.$TS"; mv "$dst" "$dst.bak.$TS"; fi
  ln -s "$src" "$dst"; log "Link: $dst"
}

log "zellij (config + theme + dev layout)…"
link "$REPO/zellij/config.kdl"       "$HOME/.config/zellij/config.kdl"
link "$REPO/zellij/themes/muted.kdl" "$HOME/.config/zellij/themes/muted.kdl"
link "$REPO/zellij/layouts/dev.kdl"  "$HOME/.config/zellij/layouts/dev.kdl"
link "$REPO/zellij/layouts/org.kdl"  "$HOME/.config/zellij/layouts/org.kdl"
link "$REPO/zellij/plugins"          "$HOME/.config/zellij/plugins"

# Pre-grant zjstatus permissions (the bottom bar): otherwise the permission
# prompt cannot show up in a 1-line bar, so the bar is empty on first launch,
# with no explanation.
# Note: zellij keys the cache by the BARE plugin path (no "file:" prefix).
zj_perm="${XDG_CACHE_HOME:-$HOME/.cache}/zellij/permissions.kdl"
if [ ! -f "$zj_perm" ] || ! grep -q 'zjstatus.wasm' "$zj_perm" 2>/dev/null; then
  mkdir -p "$(dirname "$zj_perm")"
  cat >> "$zj_perm" <<ZJPERM
"$HOME/.config/zellij/plugins/zjstatus.wasm" {
    ReadApplicationState
    ChangeApplicationState
    RunCommands
}
ZJPERM
  log "zjstatus permissions granted ($zj_perm)"
fi

log "helpers in ~/.local/bin (derived from the manifest, @thedev tags, never a hardcoded list)…"
for b in $("$REPO/bin/thedev-manifest" --scripts); do
  link "$REPO/bin/$b" "$HOME/.local/bin/$b"
done

# thedev-machines: YOUR list of machines for the board (user-specific, gitignored).
# Link the real file if it exists; otherwise remind the user to start from the template.
if [ -f "$REPO/thedev-machines" ]; then
  log "thedev-machines config (cross-machine board)…"
  link "$REPO/thedev-machines" "$HOME/.config/thedev-machines"
else
  warn "no thedev-machines, so the board is local only. For cross-machine:"
  warn "  cp $REPO/thedev-machines.example $REPO/thedev-machines  (then list your ssh hosts)"
fi

# agent-track hook: registry of open Claude sessions (resume + persistent names)
# + "busy" marker + pane-name nudge. We do NOT REPLACE settings.json: we
# MERGE the hook into the 4 events with jq, idempotent.
# An old soldat-track entry counts as wired: the migration below renames it.
SETTINGS="$HOME/.claude/settings.json"
TRACK="$REPO/claude/hooks/agent-track.sh"
if command -v jq >/dev/null 2>&1; then
  mkdir -p "$HOME/.claude"
  [ -s "$SETTINGS" ] || echo '{}' > "$SETTINGS"
  if grep -qE "agent-track|soldat-track" "$SETTINGS"; then
    log "agent-track hook already wired"
  else
    tmp=$(mktemp)
    if jq --arg h "$TRACK" '
          .hooks = (.hooks // {})
          | .hooks.SessionStart     = ((.hooks.SessionStart     // []) + [{hooks:[{type:"command",command:$h}]}])
          | .hooks.SessionEnd       = ((.hooks.SessionEnd       // []) + [{hooks:[{type:"command",command:$h}]}])
          | .hooks.UserPromptSubmit = ((.hooks.UserPromptSubmit // []) + [{hooks:[{type:"command",command:$h}]}])
          | .hooks.Stop             = ((.hooks.Stop             // []) + [{hooks:[{type:"command",command:$h}]}])
          | .hooks.PreToolUse       = ((.hooks.PreToolUse       // []) + [{matcher:"AskUserQuestion",hooks:[{type:"command",command:$h}]}])
          | .hooks.PostToolUse      = ((.hooks.PostToolUse      // []) + [{matcher:"AskUserQuestion",hooks:[{type:"command",command:$h}]}])
        ' "$SETTINGS" > "$tmp" && jq -e . "$tmp" >/dev/null 2>&1; then
      mv "$tmp" "$SETTINGS"; log "agent-track hook added to settings.json (4 events + multiple choice)"
    else
      rm -f "$tmp"; warn "jq merge failed: hook not wired (registry/nudge disabled)"
    fi
  fi
else
  warn "jq missing: agent-track hook not wired (registry/nudge disabled)"
fi

# dev/srv/aside functions: sourced from the real .bashrc (never replaced), idempotent.
MARK="# >>> thedev >>>"
if ! grep -qF "$MARK" "$HOME/.bashrc" 2>/dev/null; then
  log "adding the dev-launcher source line to ~/.bashrc"
  cat >> "$HOME/.bashrc" <<EOF

$MARK
export PATH="\$HOME/.local/bin:\$PATH"
[ -f "$REPO/bash/dev-launcher.sh" ] && source "$REPO/bash/dev-launcher.sh"
# <<< thedev <<<
EOF
fi

# Server marker (--vps=<label>): red badge/title + automatic Remote Control.
if [ -n "$VPS_LABEL" ]; then
  mkdir -p "$HOME/.config"
  printf '%s\n' "$VPS_LABEL" > "$HOME/.config/dev-vps"
  log "VPS marker: ~/.config/dev-vps = $VPS_LABEL"
  # OPTIONAL native identity: if YOU provide claude/vps-context/<label>.md
  # (personal, gitignored), it is linked as ~/.claude/CLAUDE.md. Otherwise skipped.
  ctx="$REPO/claude/vps-context/$VPS_LABEL.md"
  if [ -f "$ctx" ]; then
    mkdir -p "$HOME/.claude"
    [ -e "$HOME/.claude/CLAUDE.md" ] && [ ! -L "$HOME/.claude/CLAUDE.md" ] && \
      mv "$HOME/.claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md.bak.$TS"
    ln -sf "$ctx" "$HOME/.claude/CLAUDE.md"
    log "native identity: ~/.claude/CLAUDE.md → vps-context/$VPS_LABEL.md"
  fi
fi

# Report (without installing) missing external apps.
"$REPO/bin/thedev-manifest" --check-deps || warn "some dependencies are missing, so some features are degraded (see ✗ above)."

# One-time migration to the English names (old links, hooks, state), if shipped.
[ -x "$REPO/migrations/2026-10-english-names.sh" ] && "$REPO/migrations/2026-10-english-names.sh"

log "Done. Run 'dev' after: source ~/.bashrc (or open a new shell)."
