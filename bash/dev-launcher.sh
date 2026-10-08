# dev-launcher.sh — sourced from ~/.bashrc
# Lanceur zellij.
#   dev          → sélecteur TUI 2 panneaux (sessions + dossiers) via home
#   dev <chemin> → cible/crée un dossier, session neuve (~, relatif, $DEV_ROOT/<nom>)
#   dev .        → dossier courant
# La session choisie est reprise en passant CLAUDE_RESUME_ID (lu par agent-pane).
# Recrée toujours la session zellij pour prendre en compte le layout.

export DEV_ROOT="${DEV_ROOT:-$HOME/jlal_perso}"

# Raccourci : 2e Claude en parallèle dans le tab courant (sans toucher au
# Claude en cours). À lancer depuis le pane `shell`. `aside -f` = flottant.
alias aside='spawn'

# srv [projet|list] — dev sur le serveur distant via SSH.
#   srv            → ouvre le sélecteur dev sur le serveur
#   srv <projet>   → dev <projet> sur le serveur
#   srv list       → sessions zellij vivantes côté serveur
# zellij tourne en tâche de fond côté serveur (client/serveur, sans GUI) : si tu
# fermes ton PC, la session + Claude continuent là-bas. Reconnecte avec `srv …`
# et dev se rattache à la session vivante (tu reprends où tu en étais).
# Hôte par défaut = la 1re machine de ~/.config/thedev-machines (surcharge :
# SRV_HOST=... srv …). Pas de fichier = pas de serveur : on le dit au lieu de
# tenter un alias ssh qui n'existe que chez son auteur.
srv() {
  local host="${SRV_HOST:-$(sed 's/#.*//' "$HOME/.config/thedev-machines" 2>/dev/null \
                            | grep -m1 '[^[:space:]]' | tr -d '[:space:]')}"
  [ -n "$host" ] || {
    echo "srv: no machine: list your ssh aliases in ~/.config/thedev-machines"
    echo "     (1 per line), or run: SRV_HOST=<alias> srv"
    return 1
  }
  # ConnectTimeout : si le VPS est down, on échoue en ~8s (pas un long hang) et on
  # rend la main proprement → l'home thedev se ré-affiche (boucle de dev()).
  case "${1:-}" in
    list) ssh -o ConnectTimeout=8 "$host" 'PATH="$HOME/.local/bin:$PATH" zellij list-sessions' ;;
    *)    printf '\033[1;34m→ connecting to %s…\033[0m\n' "$host"
          # Presse-papiers du PC remonté sur les serveurs : clip-serve (serveur local +
          # tunnels ssh -R supervisés vers chaque machine, jeton poussé par stdin). Les
          # shims wl-paste/wl-copy du serveur s'en servent → coller une image dans
          # Claude et copier à la souris marchent à distance.
          clip-serve --ensure >/dev/null 2>&1
          # 255 est le SEUL code par lequel ssh signale un échec de connexion ;
          # tout autre code non nul vient de la commande distante (session fermée,
          # erreur de zellij…). Les confondre faisait annoncer « injoignable » une
          # machine parfaitement joignable.
          ssh -o ConnectTimeout=8 -t "$host" "bash -lic 'dev ${1:-}'"
          local rc=$?
          if [ "$rc" -eq 255 ]; then
            echo "✗ $host unreachable (SSH connection failed), back to thedev home."; sleep 2
          elif [ "$rc" -ne 0 ]; then
            echo "✗ $host reached, but the remote session ended with an error (code $rc)."; sleep 2
          fi ;;
  esac
}

# lead — convoque le LEAD-RACINE (l'owner) sur le sommet (thedev-sommet).
# L'owner = un `lead` (objet unique) à la racine, sur le VPS toujours allumé. Session
# briefée : il voit la flotte (`org-tree`) et dirige vers le bas (`directive`). Convocable
# (ouvre quand tu diriges, ferme après). Depuis le téléphone : via le sommet.
lead() {
  # Un lead de MACHINE ou de DOMAINE (arg donné) = brief LOCAL via le script bin/lead
  # (résumés agrégés de ce périmètre, lus depuis le miroir). `command` contourne CETTE
  # fonction. Sans arg = l'OWNER (racine), qui vit sur le SOMMET (persistant, joignable
  # depuis le tél) — c'est le « niveau org le plus haut sur le serveur ».
  [ -n "$1" ] && { command lead "$@"; return; }
  local sommet me d bf
  sommet="$(grep -vE '^\s*#|^\s*$' "$HOME/.config/thedev-sommet" 2>/dev/null | head -n1 | tr -d '[:space:]')"
  me="$( { cat "$HOME/.config/dev-vps" 2>/dev/null || hostname -s; } )"
  [ -n "$sommet" ] || { echo "lead: no top machine declared (~/.config/thedev-sommet)."; return 1; }
  if [ "$me" = "$sommet" ] || [ "$(hostname -s)" = "$sommet" ]; then
    # on EST le sommet → ouvrir/rejoindre l'owner (lead-racine), briefé
    d="$HOME/thedev-general"; mkdir -p "$d"
    bf=$(mktemp)
    cat > "$bf" <<'BRIEF'
You are the ROOT LEAD of thedev, acting for the owner, on the top machine. Your role:
see all the machines and DIRECT, not code yourself.
- `org-tree` → the full tree (machine leads → domains → workspaces) + their state. It reads
  the MIRROR: it ALSO shows offline machines (including laptops behind NAT) through their
  last sync-ups. Do not rely on `thedev-status` to know "who exists".
- `note ls --all` / `milestone` / `blocker` (in a workspace folder) → drill into the detail.
- `directive <machine>/<workspace> "<intent>"` → directs a workspace (queue, consumed on wake-up).
  `directive list` → the queue. `delegate <machine>/<workspace> "<txt>"` → synchronous delegation if reachable.
Read `org-tree`, take the user's intent, dispatch the directives, report back.
You spread attention; you do not do the agents' work.
BRIEF
    CLAUDE_PANE_INIT_FILE="$bf" _dev_launch "$d" ""
  else
    printf '\033[1;34m→ root lead on %s…\033[0m\n' "$sommet"
    ssh -o ConnectTimeout=8 -t "$sommet" "bash -lic 'lead'" \
      || { echo "✗ $sommet unreachable."; sleep 1; }
  fi
}

# (Re)crée la session zellij `$1` dans $PWD et RESTAURE les Claude qui étaient
# ouverts. Sur une reprise ($2 = id non vide), on relit le registre
# (agent-register) du dossier : le Claude principal reprend sa conversation
# (CLAUDE_RESUME_ID) et DEV_RESTORE=1 dit à agent-pane de respawn un aside
# --resume par claude secondaire. Session NEUVE ($2 vide) : démarrage propre.
_dev_spawn() {
  local session="$1" resume="$2" real main_id="" restore=""
  if [ -n "$resume" ]; then
    restore=1
    if command -v agent-register >/dev/null 2>&1; then
      real=$(realpath "$PWD" 2>/dev/null || pwd -P)
      main_id=$(agent-register list "$real" \
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
    # zellij 0.45 relit le layout de RÉSURRECTION même pour s'attacher à une session
    # VIVANTE, et il lui arrive de l'écrire invalide (pane `expanded` hors pile) :
    # l'attache échoue alors, code 2, sur une session qui tourne très bien. Ce
    # fichier ne sert qu'à ressusciter une session morte et le serveur le réécrit
    # dans la seconde : le retirer avant d'attacher une session vivante ne perd rien.
    rm -f "${XDG_CACHE_HOME:-$HOME/.cache}"/zellij/contract_version_*/session_info/"$session"/session-layout.kdl
    zellij attach "$session"
    return
  fi

  _dev_spawn "$session" "$resume"
}

# Ouvre le COCKPIT org : une session zellij dédiée `org`
# (layout à 2 panes — org-tree à gauche, Claude lead à droite). Session vivante →
# on s'y rattache (le cockpit reprend où il en était) ; sinon on la crée.
_dev_cockpit() {
  local session="org"
  if zellij list-sessions --no-formatting 2>/dev/null \
       | grep -v 'EXITED' | awk '{print $1}' | grep -qxF "$session"; then
    zellij attach "$session"
    return
  fi
  zellij -n ~/.config/zellij/layouts/org.kdl -s "$session"
}

# Force la fermeture d'une session vivante puis la relance (choix "fermer &
# relancer" de l'home sur une session ● en cours). $2 = id à reprendre.
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
    printf "folder '%s' does not exist, create it? [Y/n] " "$target"
    read -r ans; case "$ans" in [nN]*) return 1 ;; esac
    mkdir -p "$target" || { echo "dev: failed to create '$target'" >&2; return 1; }
  fi
  _dev_launch "$target" ""
}

# Met à jour la config dev depuis le git d'origine (déclenché par le bouton
# « mettre à jour dev » de l'home, qui n'apparaît que si on est en retard).
# git pull --rebase --autostash puis install-dev.sh (symlinks des nouveaux scripts + hooks).
_dev_update() {
  local repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  if [ ! -d "$repo/.git" ]; then
    echo "dev: $repo is not a git clone, cannot update here." >&2
    read -r -p "Enter to continue…" _; return 1
  fi
  echo "→ updating the dev config…"
  # --rebase --autostash et non --ff-only : plusieurs sessions Claude commitent dans
  # ce dépôt, un commit local pas encore poussé est le cas NORMAL, pas une erreur.
  # On rejoue les commits locaux par-dessus le distant, travail en cours mis de côté
  # puis restauré. Seul un vrai conflit (même lignes des deux côtés) arrête tout, et
  # on annule alors le rebase pour rendre le dépôt tel qu'il était.
  if git -C "$repo" -c advice.diverging=false pull --rebase --autostash -q; then
    [ -f "$repo/install-dev.sh" ] && bash "$repo/install-dev.sh" >/dev/null && echo "  symlinks/hooks resynced."
    echo "✓ config up to date."
  else
    git -C "$repo" rebase --abort >/dev/null 2>&1
    echo "✗ update failed: a file was changed here AND on GitHub in the"
    echo "  same places. Nothing was changed. Ask an agent to reconcile."
  fi
  read -r -p "Enter to go back to the picker…" _
}

# Coupe tout mode de signalement souris resté allumé dans le terminal (zellij 0.45
# n'éteint pas toujours ?1003 au détachement) : sinon les mouvements arrivent en
# texte dans le picker et les shells.
_dev_mouse_off() { printf '\033[?1003l\033[?1002l\033[?1000l\033[?1006l' 2>/dev/null; }

dev() {
  _dev_mouse_off
  # Sur le PC : presse-papiers servi aux machines distantes dès l'ouverture de thedev
  # (serveur + tunnels supervisés), pas seulement au premier `srv`. No-op sur un VPS.
  [ -f "$HOME/.config/dev-vps" ] || { command -v clip-serve >/dev/null 2>&1 && clip-serve --ensure >/dev/null 2>&1; }
  # Argument explicite : on cible/crée un dossier, session neuve.
  [ -n "$1" ] && { _dev_open_path "$1"; return; }

  local etajm="$HOME/.local/bin/home" outf out cwd id start
  if ! command -v python3 >/dev/null || [ ! -x "$etajm" ]; then
    _dev_launch "$PWD" ""; return   # repli : session neuve dans le dossier courant
  fi

  start="$PWD"
  # Boucle : après un detach (Ctrl+Q) ou la fin d'une session, zellij rend la
  # main → on ré-affiche le sélecteur (on peut rejoindre la session ● restée
  # vivante, ou en choisir une autre). Esc dans le sélecteur sort vers le shell.
  local relf="$HOME/.cache/thedev/relais" rel relkill
  while :; do
    cd "$start" 2>/dev/null
    _dev_mouse_off   # retour de zellij : le terminal peut avoir gardé ?1003
    # RELAIS : la colonne de gauche de la page agents (`sidebar`) ne peut pas s'attacher à
    # une autre workspace depuis l'intérieur (elle mourrait avec la session). Elle
    # écrit son choix ici puis détache ; c'est NOUS, de retour dans la boucle,
    # qui l'appliquons — sans repasser par le sélecteur.
    #   <ACTION>\t<cwd>\t<id>\t<session_à_tuer>
    if [ -f "$relf" ]; then
      rel=$(head -n1 "$relf" 2>/dev/null); rm -f "$relf"
      relkill=$(printf '%s' "$rel" | cut -f4)
      [ -n "$relkill" ] && zellij delete-session --force "$relkill" >/dev/null 2>&1
      cwd=$(printf '%s' "$rel" | cut -f2)
      id=$(printf '%s' "$rel" | cut -f3)
      if [ -d "$cwd" ]; then
        case "$rel" in
          RESUME*) _dev_launch "$cwd" "$id" ;;
          NEW*)    _dev_launch "$cwd" "" ;;
        esac
        continue
      fi
    fi
    outf=$(mktemp)
    # stdout NON capturé → le TUI garde le terminal ; la décision est écrite dans outf.
    "$etajm" "$(pwd -P)" "$outf"
    out=$(cat "$outf" 2>/dev/null); rm -f "$outf"
    [ -z "$out" ] && break          # annulé (Esc) → retour au shell

    cwd=$(printf '%s' "$out" | cut -f2)
    id=$(printf '%s' "$out" | cut -f3)
    case "$out" in
      NEW*)      _dev_launch "$cwd" "" ;;
      RESUME*)   _dev_launch "$cwd" "$id" ;;
      RECREATE*) _dev_recreate "$cwd" "$id" ;;   # fermer & relancer (session ● en cours)
      SERVER*)   SRV_HOST="$cwd" srv "$id" ;;    # dev distant : $cwd=hôte ; $id=cwd distant (vide → home serveur ; sinon attache la session)
      ADJUST*)   _dev_adjust_auto "$cwd" "$(printf '%s' "$out" | cut -f3)" "$(printf '%s' "$out" | cut -f4)" ;;  # $cwd=machine, f3=cwd workspace, f4=nom auto
      UPDATE*)   _dev_update ;;                  # met à jour la config dev (git pull) puis ré-affiche l'home
      COCKPIT*)  _dev_cockpit ;;                 # cockpit org : session dédiée (org-tree gauche · lead droite)
      CHEF*)     lead "$cwd" ;;                   # discuter avec un lead : Claude briefé dans CE pane ($cwd = machine[/domaine], vide = owner)
    esac
  done
}

# Ajuster une automation : ouvre le thedev CONCERNÉ par l'auto (son workspace, machine +
# cwd) et y ajoute un NOUVEAU pane claude « aside » déjà briefé sur la tâche (contexte
# pré-écrit). Le prompt du feed est versionné/partagé (git) → on l'édite et on sync.
#   $1=machine ('local' ou hôte ssh)  $2=cwd de le workspace  $3=nom de l'auto
# Workspace OUVERTE (session zellij vivante) → on injecte l'aside dans la session existante par
# son nom, puis on s'y attache. Workspace FERMÉE → on ouvre le thedev, agent principal briefé.
_dev_adjust_auto() {
  local machine="$1" cwd="$2" name="$3" sess task f
  [ -n "$cwd" ] || { echo "✗ workspace cwd unknown (closed workspace with no history)"; sleep 1.5; return; }
  sess=$(basename "$cwd")
  task="You are a TUNING agent opened in the workspace \"$sess\" (machine $machine). Goal: improve the thedev automation \"$name\" (timer $name.timer). Its task prompt is in ~/jlal_perso/config/feeds/$name.prompt (versioned, shared through git): read it, propose and apply improvements (clarity, robustness, anti-flood, steps). Keep it SYNCHRONOUS: never a detached Workflow/agent inside a task. When you are done: commit and push from ~/jlal_perso/config (the timer will reread the prompt on its next run). You can test with \"systemctl --user start $name.service\". Do not touch the rest of the workspace."
  f="$HOME/.cache/thedev/adjust-$name.txt"      # contexte passé par FICHIER (zéro quoting)

  if [ "$machine" = local ]; then
    if zellij list-sessions --no-formatting 2>/dev/null | grep -v EXITED | awk '{print $1}' | grep -qxF "$sess"; then
      mkdir -p "$HOME/.cache/thedev"; printf '%s\n' "$task" > "$f"
      zellij --session "$sess" action new-pane --floating --close-on-exit --cwd "$cwd" --name "adjust $name" \
        -- bash -lc "CLAUDE_PANE_INIT_FILE=$f CLAUDE_PANE_ONCE=1 exec engine launch"
      zellij attach "$sess"
    else
      CLAUDE_PANE_INIT="$task" _dev_launch "$cwd" ""     # workspace fermée → on l'ouvre, agent principal briefé
    fi
  else
    # Distant : dépose le contexte (base64, zéro quoting) puis injecte l'aside si la session
    # tourne ; dans tous les cas on s'attache ensuite au thedev concerné via srv.
    local b64; b64=$(printf '%s\n' "$task" | base64 -w0 2>/dev/null || printf '%s\n' "$task" | base64)
    ssh -o ConnectTimeout=8 "$machine" "mkdir -p ~/.cache/thedev; printf %s '$b64' | base64 -d > '$f'
      if zellij list-sessions --no-formatting 2>/dev/null | grep -v EXITED | awk '{print \$1}' | grep -qxF '$sess'; then
        PATH=\"\$HOME/.local/bin:\$PATH\" zellij --session '$sess' action new-pane --floating --close-on-exit --cwd '$cwd' --name 'adjust $name' -- bash -lc 'CLAUDE_PANE_INIT_FILE=$f CLAUDE_PANE_ONCE=1 exec engine launch'
      fi" 2>/dev/null
    SRV_HOST="$machine" srv "$cwd"
  fi
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
