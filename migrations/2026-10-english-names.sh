#!/usr/bin/env bash
# Migration oct. 2026 : nomenclature thedev en anglais (fin du vocabulaire militaire).
# Idempotent : se rejoue sans risque. À lancer UNE fois par machine après le pull.
#
#   soldat → agent · soutien → job · équipe → workspace · état-major → home
#   pages « le front / le camp / la tente » → agents / jobs / shell
#   + commandes renommées (cf. NAMING.md)
#
# Ce qu'il fait :
#   1. renomme les fichiers d'état dans ~/.cache (sans écraser un fichier neuf) ;
#   2. retire de ~/.local/bin les liens cassés qui pointaient vers les anciens scripts
#      (les nouveaux sont posés par install) ;
#   3. repointe les hooks Claude (settings.json) vers agent-track.sh ;
#   4. remplace le timer thedev-remonter par thedev-sync-up.
# Les sessions zellij déjà ouvertes gardent leurs anciens noms d'onglets : les fermer
# et les rouvrir (Ctrl+Q → fermer, puis dev) pour passer aux pages agents/jobs/shell.
set -u
log() { printf '\033[1;34m[migration]\033[0m %s\n' "$*"; }

C="${XDG_CACHE_HOME:-$HOME/.cache}"
# Renomme $1 en $2. Si $2 existe déjà (un hook a recommencé à écrire sous le nouveau nom),
# on FUSIONNE un dossier sans rien écraser ; un fichier déjà présent l'emporte (le neuf).
mvc() {
  [ -e "$1" ] || [ -L "$1" ] || return 0
  if [ ! -e "$2" ]; then
    mv "$1" "$2" && log "state: ${1#$HOME/} → ${2#$HOME/}"
  elif [ -d "$1" ] && [ -d "$2" ]; then
    cp -an "$1/." "$2/" 2>/dev/null && rm -rf "$1" && log "state: merged ${1#$HOME/} into ${2#$HOME/}"
  else
    rm -rf "$1" && log "state: dropped ${1#$HOME/} (${2#$HOME/} is newer)"
  fi
}
mvc "$C/soldats"                "$C/agents"
mvc "$C/soldats.lock"           "$C/agents.lock"
mvc "$C/thedev-soutien"         "$C/thedev-jobs"
mvc "$C/thedev-soutien-pids"    "$C/thedev-jobs-pids"
for old in busy head main nudge panes pulse waiting goto note-nudge partition-nudge; do
  mvc "$C/soldat-$old" "$C/agent-$old"
done
mvc "$C/soldat-jalon-nudge"     "$C/agent-milestone-nudge"
for f in "$C"/garnison-*.id; do
  [ -e "$f" ] || continue
  mvc "$f" "$C/jobs-welcome-${f##*/garnison-}"
done
# Mémoire de l'org : la machine elle-même, et sur le sommet les arbres remontés par
# les autres machines (command-fleet/<machine>/…).
mvc "$C/thedev/commandement" "$C/thedev/org"
for base in "$C/thedev/command" "$C"/thedev/command-fleet/*; do
  [ -d "$base" ] || continue
  mvc "$base/equipes" "$base/workspaces"
  mvc "$base/blocage" "$base/blocker"
done
# Carte de workspace dans chaque projet : <projet>/.thedev/equipe.md → workspace.md
while IFS= read -r f; do
  mvc "$f" "${f%/equipe.md}/workspace.md"
done < <(find "$HOME" -maxdepth 7 -path '*/.thedev/equipe.md' -not -path '*/node_modules/*' 2>/dev/null)

n=0
for l in "$HOME/.local/bin"/*; do
  [ -L "$l" ] && [ ! -e "$l" ] || continue
  case "$(readlink "$l")" in
    */config/bin/*|*/thedev/bin/*) rm -f "$l"; n=$((n + 1)) ;;
  esac
done
[ "$n" -gt 0 ] && log "removed $n stale command link(s) from ~/.local/bin"

S="$HOME/.claude/settings.json"
if [ -f "$S" ] && grep -q "soldat-track.sh" "$S"; then
  cp "$S" "$S.bak-nomenclature" && sed -i 's#soldat-track\.sh#agent-track.sh#g' "$S" \
    && log "Claude hooks now point to agent-track.sh"
fi

# Timer de remontée : on le REMPLACE (pas seulement le retirer) — sinon une machine où
# il tournait perdrait la remontée vers le sommet si son installeur ne le pose pas.
REPO="$(cd "$(dirname "$(readlink -f -- "$0")")/.." && pwd)"
if command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
  if systemctl --user list-unit-files thedev-remonter.timer --no-legend 2>/dev/null | grep -q .; then
    was_on=0
    systemctl --user is-enabled thedev-remonter.timer >/dev/null 2>&1 && was_on=1
    systemctl --user disable --now thedev-remonter.timer >/dev/null 2>&1
    rm -f "$HOME/.config/systemd/user/thedev-remonter.timer" "$HOME/.config/systemd/user/thedev-remonter.service"
    for u in thedev-sync-up.service thedev-sync-up.timer; do
      [ -f "$REPO/systemd/user/$u" ] && ln -sfn "$REPO/systemd/user/$u" "$HOME/.config/systemd/user/$u"
    done
    systemctl --user daemon-reload
    if [ "$was_on" = 1 ] && [ -f "$REPO/systemd/user/thedev-sync-up.timer" ]; then
      systemctl --user enable --now thedev-sync-up.timer >/dev/null 2>&1 \
        && log "timer thedev-remonter replaced by thedev-sync-up"
    else
      log "removed the old thedev-remonter timer"
    fi
  fi
fi
rm -f "$HOME/.config/zellij/layouts/commandement.kdl" 2>/dev/null

log "done. Run the installer again to set up the new names, then reopen your sessions."
