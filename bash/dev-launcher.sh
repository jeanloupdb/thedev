# dev-launcher.sh — sourced from ~/.bashrc
# Lanceur zellij.
#   dev          → sélecteur TUI 2 panneaux (sessions + dossiers) via dev-picker
#   dev <chemin> → cible/crée un dossier, session neuve (~, relatif, $DEV_ROOT/<nom>)
#   dev .        → dossier courant
# La session choisie est reprise en passant CLAUDE_RESUME_ID (lu par claude-pane).
# Recrée toujours la session zellij pour prendre en compte le layout.

export DEV_ROOT="${DEV_ROOT:-$HOME/jlal_perso}"

# Raccourci : 2e Claude en parallèle dans le tab courant (sans toucher au
# Claude en cours). À lancer depuis le pane `shell`. `aside -f` = flottant.
alias aside='claude-aside'

# srv [projet|list] — dev sur le serveur distant via SSH.
#   srv            → ouvre le sélecteur dev sur le serveur
#   srv <projet>   → dev <projet> sur le serveur
#   srv list       → sessions zellij vivantes côté serveur
# zellij tourne en tâche de fond côté serveur (client/serveur, sans GUI) : si tu
# fermes ton PC, la session + Claude continuent là-bas. Reconnecte avec `srv …`
# et dev se rattache à la session vivante (tu reprends où tu en étais).
# Hôte par défaut = alias SSH 'jlax' (surcharge : SRV_HOST=... srv …).
srv() {
  local host="${SRV_HOST:-jlax}"
  # ConnectTimeout : si le VPS est down, on échoue en ~8s (pas un long hang) et on
  # rend la main proprement → l'accueil thedev se ré-affiche (boucle de dev()).
  case "${1:-}" in
    list) ssh -o ConnectTimeout=8 "$host" 'PATH="$HOME/.local/bin:$PATH" zellij list-sessions' ;;
    *)    printf '\033[1;34m→ connexion à %s…\033[0m\n' "$host"
          ssh -o ConnectTimeout=8 -t "$host" "bash -lic 'dev ${1:-}'" \
            || { echo "✗ $host injoignable — retour à l'accueil thedev."; sleep 1; } ;;
  esac
}

# (Re)crée la session zellij `$1` dans $PWD et RESTAURE les Claude qui étaient
# ouverts. Sur une reprise ($2 = id non vide), on relit le registre
# (dev-claude-reg) du dossier : le Claude principal reprend sa conversation
# (CLAUDE_RESUME_ID) et DEV_RESTORE=1 dit à claude-pane de respawn un aside
# --resume par claude secondaire. Session NEUVE ($2 vide) : démarrage propre.
_dev_spawn() {
  local session="$1" resume="$2" real main_id="" restore=""
  if [ -n "$resume" ]; then
    restore=1
    if command -v dev-claude-reg >/dev/null 2>&1; then
      real=$(realpath "$PWD" 2>/dev/null || pwd -P)
      main_id=$(dev-claude-reg list "$real" \
                  | awk -F'\t' '$3=="main"{print $6"\t"$1}' | sort -n | tail -1 | cut -f2)
    fi
  fi
  [ -n "$main_id" ] || main_id="$resume"
  zellij delete-session --force "$session" >/dev/null 2>&1
  CLAUDE_RESUME_ID="$main_id" DEV_RESTORE="$restore" \
    zellij -n ~/.config/zellij/layouts/dev.kdl -s "$session"
}

# cd vers la cible + (re)lance zellij. $2 = id de session à reprendre (ou "").
_dev_launch() {
  local target="$1" resume="$2" session
  cd "$target" || return
  session=$(basename "$PWD")

  # Une session zellij VIVANTE porte déjà ce nom ? → on s'y rattache au lieu de
  # l'écraser (sinon `delete-session --force` tuerait le dev en cours, claude
  # inclus). Les sessions mortes (EXITED) sont nettoyées et recréées.
  if zellij list-sessions --no-formatting 2>/dev/null \
       | grep -v 'EXITED' | awk '{print $1}' | grep -qxF "$session"; then
    zellij attach "$session"
    return
  fi

  _dev_spawn "$session" "$resume"
}

# Force la fermeture d'une session vivante puis la relance (choix "fermer &
# relancer" du picker sur une session ● en cours). $2 = id à reprendre.
_dev_recreate() {
  local target="$1" resume="$2" session
  cd "$target" || return
  session=$(basename "$PWD")
  _dev_spawn "$session" "$resume"
}

# Résout un chemin/nom utilisateur, le crée au besoin, lance une session NEUVE.
_dev_open_path() {
  local target="$1" ans
  if   [ "$target" = "." ];        then target="$PWD"
  elif [ -d "$DEV_ROOT/$target" ]; then target="$DEV_ROOT/$target"
  else target="${target/#\~/$HOME}"
  fi
  command -v realpath >/dev/null && target=$(realpath -m -- "$target")
  if [ ! -d "$target" ]; then
    printf "dossier '%s' inexistant — le créer ? [Y/n] " "$target"
    read -r ans; case "$ans" in [nN]*) return 1 ;; esac
    mkdir -p "$target" || { echo "dev: échec de création de '$target'" >&2; return 1; }
  fi
  _dev_launch "$target" ""
}

# Met à jour la config dev depuis le git d'origine (déclenché par le bouton
# « mettre à jour dev » du picker, qui n'apparaît que si on est en retard).
# git pull --ff-only puis install-dev.sh (symlinks des nouveaux scripts + hooks).
_dev_update() {
  local repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  if [ ! -d "$repo/.git" ]; then
    echo "dev: $repo n'est pas un clone git — maj impossible ici." >&2
    read -r -p "Entrée pour continuer…" _; return 1
  fi
  echo "→ mise à jour de la config dev (git -C $repo pull)…"
  if git -C "$repo" pull --ff-only; then
    { [ -f "$repo/install.sh" ] && bash "$repo/install.sh" >/dev/null; } && echo "  symlinks/hooks resynchronisés."
    echo "✓ config à jour."
  else
    echo "✗ git pull a échoué (voir ci-dessus)."
  fi
  read -r -p "Entrée pour revenir au sélecteur…" _
}

dev() {
  # Argument explicite : on cible/crée un dossier, session neuve.
  [ -n "$1" ] && { _dev_open_path "$1"; return; }

  local picker="$HOME/.local/bin/dev-picker" outf out cwd id start
  if ! command -v python3 >/dev/null || [ ! -x "$picker" ]; then
    _dev_launch "$PWD" ""; return   # repli : session neuve dans le dossier courant
  fi

  start="$PWD"
  # Boucle : après un detach (Ctrl+Q) ou la fin d'une session, zellij rend la
  # main → on ré-affiche le sélecteur (on peut rejoindre la session ● restée
  # vivante, ou en choisir une autre). Esc dans le sélecteur sort vers le shell.
  while :; do
    cd "$start" 2>/dev/null
    outf=$(mktemp)
    # stdout NON capturé → le TUI garde le terminal ; la décision est écrite dans outf.
    "$picker" "$(pwd -P)" "$outf"
    out=$(cat "$outf" 2>/dev/null); rm -f "$outf"
    [ -z "$out" ] && break          # annulé (Esc) → retour au shell

    cwd=$(printf '%s' "$out" | cut -f2)
    id=$(printf '%s' "$out" | cut -f3)
    case "$out" in
      NEW*)      _dev_launch "$cwd" "" ;;
      RESUME*)   _dev_launch "$cwd" "$id" ;;
      RECREATE*) _dev_recreate "$cwd" "$id" ;;   # fermer & relancer (session ● en cours)
      SERVER*)   SRV_HOST="$cwd" srv "$id" ;;    # dev distant : $cwd=hôte ; $id=cwd distant (vide → picker serveur ; sinon attache la session)
      UPDATE*)   _dev_update ;;                  # met à jour la config dev (git pull) puis ré-affiche le picker
    esac
  done
}

# `thedev` — alias du nom de l'app vers la commande de lancement `dev`.
thedev() { dev "$@"; }

# scratch project bootstrap: `scratch [name]` → tmp dir + git init + zellij
scratch() {
  local name="${1:-scratch-$(date +%Y%m%d-%H%M%S)}"
  local dir="$HOME/scratch/$name"
  mkdir -p "$dir" && cd "$dir" && git init -q
  echo "scratch: $dir"
  command -v zellij >/dev/null && dev "$dir" || true
}
