#!/usr/bin/env bash
# install.sh — installe thedev (l'app de dev zellij : layout `dev`, helpers,
# liens cross-machine, board) sur une machine, SANS toucher au reste de ta
# config perso. Idempotent. Symlinks → backup auto (.bak.<timestamp>).
#
# Prérequis (binaires) : zellij, claude (CLI), nvim, python3, git, jq, fzf,
# inotify-tools. Vérifie-les après coup : ./bin/thedev-manifest --check-deps
#
# Usage :
#   ./install.sh                  # thedev
#   ./install.sh --vps=<label>    # + marqueur serveur (badge rouge + Remote Control)
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
  if [ -e "$dst" ] || [ -L "$dst" ]; then log "Backup : $dst → $dst.bak.$TS"; mv "$dst" "$dst.bak.$TS"; fi
  ln -s "$src" "$dst"; log "Lien : $dst"
}

log "zellij (config + thème + layout dev)…"
link "$REPO/zellij/config.kdl"       "$HOME/.config/zellij/config.kdl"
link "$REPO/zellij/themes/muted.kdl" "$HOME/.config/zellij/themes/muted.kdl"
link "$REPO/zellij/layouts/dev.kdl"  "$HOME/.config/zellij/layouts/dev.kdl"

log "helpers ~/.local/bin (dérivés du manifest — tags @thedev, jamais une liste figée)…"
for b in $("$REPO/bin/thedev-manifest" --scripts); do
  link "$REPO/bin/$b" "$HOME/.local/bin/$b"
done

# thedev-machines : TA liste de machines pour le board (user-specific, gitignorée).
# On lie le vrai fichier s'il existe ; sinon on rappelle de partir du template.
if [ -f "$REPO/thedev-machines" ]; then
  log "config thedev-machines (board cross-machine)…"
  link "$REPO/thedev-machines" "$HOME/.config/thedev-machines"
else
  warn "pas de thedev-machines → board limité au local. Pour le cross-machine :"
  warn "  cp $REPO/thedev-machines.example $REPO/thedev-machines  (puis liste tes hôtes ssh)"
fi

# Hook dev-claude-track : registre des Claude ouverts (resume + noms persistants)
# + marqueur « busy » + nudge pane-name. On ne REMPLACE pas settings.json : on
# FUSIONNE le hook dans les 4 events via jq, idempotent.
SETTINGS="$HOME/.claude/settings.json"
TRACK="$REPO/claude/hooks/dev-claude-track.sh"
if command -v jq >/dev/null 2>&1; then
  mkdir -p "$HOME/.claude"
  [ -s "$SETTINGS" ] || echo '{}' > "$SETTINGS"
  if grep -qF "dev-claude-track" "$SETTINGS"; then
    log "hook dev-claude-track déjà câblé"
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
      mv "$tmp" "$SETTINGS"; log "hook dev-claude-track ajouté à settings.json (4 events + QCM)"
    else
      rm -f "$tmp"; warn "fusion jq échouée : hook non câblé (registre/nudge désactivés)"
    fi
  fi
else
  warn "jq absent : hook dev-claude-track non câblé (registre/nudge désactivés)"
fi

# Fonctions dev/srv/aside : sourcées depuis le .bashrc réel (jamais remplacé), idempotent.
MARK="# >>> thedev >>>"
if ! grep -qF "$MARK" "$HOME/.bashrc" 2>/dev/null; then
  log "ajout du source dev-launcher dans ~/.bashrc"
  cat >> "$HOME/.bashrc" <<EOF

$MARK
export PATH="\$HOME/.local/bin:\$PATH"
[ -f "$REPO/bash/dev-launcher.sh" ] && source "$REPO/bash/dev-launcher.sh"
# <<< thedev <<<
EOF
fi

# Marqueur serveur (--vps=<label>) : badge/titre rouge + auto Remote Control.
if [ -n "$VPS_LABEL" ]; then
  mkdir -p "$HOME/.config"
  printf '%s\n' "$VPS_LABEL" > "$HOME/.config/dev-vps"
  log "marqueur VPS : ~/.config/dev-vps = $VPS_LABEL"
  # Identité native OPTIONNELLE : si TU fournis claude/vps-context/<label>.md
  # (perso, gitignoré), on le lie en ~/.claude/CLAUDE.md. Sinon on saute.
  ctx="$REPO/claude/vps-context/$VPS_LABEL.md"
  if [ -f "$ctx" ]; then
    mkdir -p "$HOME/.claude"
    [ -e "$HOME/.claude/CLAUDE.md" ] && [ ! -L "$HOME/.claude/CLAUDE.md" ] && \
      mv "$HOME/.claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md.bak.$TS"
    ln -sf "$ctx" "$HOME/.claude/CLAUDE.md"
    log "identité native : ~/.claude/CLAUDE.md → vps-context/$VPS_LABEL.md"
  fi
fi

# Signale (sans installer) les apps externes manquantes.
"$REPO/bin/thedev-manifest" --check-deps || warn "des dépendances manquent → features dégradées (cf. ✗ ci-dessus)."

log "Terminé. Lance 'dev' après : source ~/.bashrc (ou nouveau shell)."
