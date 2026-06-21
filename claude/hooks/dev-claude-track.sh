#!/usr/bin/env bash
# Hook multi-events Claude Code → TRADUCTEUR vers l'adaptateur moteur (engine event)
# + animation du titre de pane (pulse ◆↔◇ pendant un tour). L'ÉTAT (registre, busy,
# sentinelles de mission) est délégué à `engine event` ; restent ICI les mécanismes
# propres au hook Claude : rename de pane, pulse ◆, et nudge pane-name (stdout injecté
# dans le contexte de Claude). No-op hors d'un pane zellij.

BUSY_DIR="$HOME/.cache/dev-claude-busy"      # 1 fichier par session active
NUDGE_DIR="$HOME/.cache/dev-claude-nudge"    # 1 fichier par session (mtime = dernier nudge)

# Adaptateur moteur résolu en VOISIN (le hook est câblé en chemin absolu du repo dans
# settings.json → $0 = ce fichier ; ../../bin/engine = l'engine du repo). Pas de
# dépendance au PATH (engine peut ne pas être symliqué).
_self="$0"; case "$_self" in */*) ;; *) _self="$(command -v -- "$_self")" ;; esac
ENGINE="$(cd "$(dirname "$(readlink -f -- "$_self")")/../../bin" 2>/dev/null && pwd)/engine"

payload=$(cat)
[ -n "${ZELLIJ_PANE_ID:-}" ] || exit 0   # pas dans un pane zellij → on ignore

ev=$(printf '%s' "$payload"  | jq -r '.hook_event_name // empty' 2>/dev/null)
sid=$(printf '%s' "$payload" | jq -r '.session_id // empty'      2>/dev/null)
cwd=$(printf '%s' "$payload" | jq -r '.cwd // empty'             2>/dev/null)
tp=$(printf '%s' "$payload"  | jq -r '.transcript_path // empty' 2>/dev/null)
[ -n "$sid" ] || exit 0
[ -n "$cwd" ] || cwd="$PWD"
cwd=$(realpath "$cwd" 2>/dev/null || printf '%s' "$cwd")

# Pane « géré » = lancé par claude-pane/claude-aside (CLAUDE_PANE_NAME posé) et pas
# une mission (pane crun « mission-… »). Seuls ces panes voient leur titre touché.
is_managed_pane() {
  [ -n "${ZELLIJ_PANE_ID:-}" ] && [ -n "${CLAUDE_PANE_NAME:-}" ] || return 1
  case "$CLAUDE_PANE_NAME" in mission-*) return 1 ;; esac
  return 0
}

# Titre « en cours » : ◆ <nom> pendant un tour, nom nu au repos. Le losange EST le
# signal d'activité. Nom propre relu dans le registre (jamais de ◆ stocké). Pose le
# 1er frame ; l'animation ◆↔◇ est ensuite tenue par pane-pulse.
pane_busy_title() {   # $1 = 1 (en cours) | 0 (au repos)
  is_managed_pane || return 0
  local nm
  nm=$(dev-claude-reg get "$sid" 2>/dev/null | cut -f4)
  [ -n "$nm" ] || nm="$CLAUDE_PANE_NAME"
  nm=${nm#◆ }
  [ "$1" = "1" ] && nm="◆ $nm"
  zellij action rename-pane -p "$ZELLIJ_PANE_ID" "$nm" 2>/dev/null
}

case "$ev" in
  SessionStart)
    # engine event tient le registre (+ sentinelle de mission) et renvoie le nom de
    # pane (vide pour une mission → pas de rename). Au démarrage on n'est pas en tour
    # → titre nu (strip d'un vieux « ◆ … »). Garde-fou : ne renomme que les panes
    # GÉRÉS (un `claude` tapé à la main dans shell/git garde son nom).
    name=$("$ENGINE" event session-start --session "$sid" --cwd "$cwd" --transcript "$tp" 2>/dev/null)
    if [ -n "${CLAUDE_PANE_NAME:-}" ] && [ -n "$name" ]; then
      zellij action rename-pane -p "$ZELLIJ_PANE_ID" "${name#◆ }" 2>/dev/null
    fi
    ;;
  UserPromptSubmit)
    # Un tour démarre → marqueur busy (état, via l'adaptateur). Pour un pane géré, on
    # enrichit le marqueur avec <pane_id>\t<session> (pane-pulse anime le bon pane) et
    # on lance le pulser ; pour un claude non géré, le marqueur vide de l'adaptateur
    # suffit (le picker n'utilise que le NOM du fichier = sid).
    "$ENGINE" event busy --session "$sid" --cwd "$cwd" 2>/dev/null
    if is_managed_pane; then
      printf '%s\t%s\n' "$ZELLIJ_PANE_ID" "${ZELLIJ_SESSION_NAME:-}" > "$BUSY_DIR/$sid" 2>/dev/null
      pane_busy_title 1                                  # 1er frame : ◆ <nom>
      setsid pane-pulse </dev/null >/dev/null 2>&1 &     # pulse ◆ du titre du pane (instance unique via flock)
      setsid tab-pulse  </dev/null >/dev/null 2>&1 &     # ● <pages busy> dans la barre zjstatus (idem)
    fi

    # --- Nudge pane-name (stdout → contexte de Claude) — mécanisme propre au hook ---
    # Uniquement pour les panes gérés, jamais pour les missions.
    [ -n "${CLAUDE_PANE_NAME:-}" ] || exit 0
    case "$CLAUDE_PANE_NAME" in mission-*) exit 0 ;; esac
    row=$(dev-claude-reg get "$sid" 2>/dev/null)
    [ -n "$row" ] || exit 0
    name=$(printf '%s' "$row" | cut -f4)
    started=$(printf '%s' "$row" | cut -f6)
    now=$(date +%s); age=$(( now - started ))
    nf="$NUDGE_DIR/$sid"
    last=0; [ -f "$nf" ] && last=$(stat -c %Y "$nf" 2>/dev/null || echo 0)
    since=$(( now - last ))
    case "$name" in
      "◆ "*)
        # Déjà nommé → re-check périodique : un nom qui a divergé du sujet est
        # pire que le défaut (il oriente vers la mauvaise conversation).
        if [ "$age" -ge 2700 ] && [ "$since" -ge 2700 ]; then
          mkdir -p "$NUDGE_DIR" 2>/dev/null && : > "$nf"
          printf '[pane-name] Ton pane s'\''appelle « %s ». Si la discussion a bifurqué vers un autre sujet, mets-le à jour : pane-name "◆ <2-3 mots>". Sinon ignore ce rappel.\n' "$name"
        fi
        ;;
      *)
        # Toujours au nom par défaut → rappel après 10 min de session, au plus
        # toutes les 20 min.
        if [ "$age" -ge 600 ] && [ "$since" -ge 1200 ]; then
          mkdir -p "$NUDGE_DIR" 2>/dev/null && : > "$nf"
          printf '[pane-name] Ce pane s'\''appelle encore « %s ». Si un sujet s'\''est dégagé dans cette conversation, nomme-le : pane-name "◆ <2-3 mots>". Sinon ignore ce rappel.\n' "$name"
        fi
        ;;
    esac
    ;;
  Stop)
    # Fin de tour → plus busy (+ sentinelle turn-ended de mission, via l'adaptateur),
    # puis titre du pane remis au nom nu.
    "$ENGINE" event turn-end --session "$sid" --cwd "$cwd" --transcript "$tp" 2>/dev/null
    pane_busy_title 0
    ;;
  SessionEnd)
    # Quit/exit → l'adaptateur horodate la fin (markend) et nettoie busy/nudge ; on
    # remet le titre nu (nettoie un ◆ figé, ex. /exit → shell keep-alive).
    "$ENGINE" event session-end --session "$sid" --cwd "$cwd" 2>/dev/null
    pane_busy_title 0
    ;;
esac
exit 0
