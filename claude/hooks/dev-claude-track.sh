#!/usr/bin/env bash
# Hook multi-events Claude Code → TRADUCTEUR vers l'adaptateur moteur (engine event).
# Parse le payload du hook (hook_event_name/session_id/cwd/transcript_path) et
# délègue l'ÉTAT (registre, busy, sentinelles de mission) à `engine event`. Restent
# ICI les mécanismes propres au hook Claude : le rename du pane (SessionStart) et le
# nudge pane-name (UserPromptSubmit, stdout injecté dans le contexte de Claude).
# No-op hors d'un pane zellij.

NUDGE_DIR="$HOME/.cache/dev-claude-nudge"   # 1 fichier par session (mtime = dernier nudge)

# Adaptateur moteur résolu en VOISIN (le hook est câblé en chemin absolu du repo
# dans settings.json → $0 = ce fichier ; ../../bin/engine = l'engine du repo). On
# ne dépend pas du PATH (engine peut ne pas être symliqué).
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

case "$ev" in
  SessionStart)
    # engine event tient le registre (+ sentinelle de mission) et renvoie le nom de
    # pane à afficher (vide pour une mission → pas de rename). Garde-fou : ne renomme
    # que les panes GÉRÉS (signature = CLAUDE_PANE_NAME posé par claude-pane/aside) ;
    # un `claude` tapé à la main dans le pane shell/git ne doit pas être renommé.
    name=$("$ENGINE" event session-start --session "$sid" --cwd "$cwd" --transcript "$tp" 2>/dev/null)
    if [ -n "${CLAUDE_PANE_NAME:-}" ] && [ -n "$name" ]; then
      zellij action rename-pane -p "$ZELLIJ_PANE_ID" "$name" 2>/dev/null
    fi
    ;;
  UserPromptSubmit)
    # Un tour démarre → marqueur busy (via l'adaptateur).
    "$ENGINE" event busy --session "$sid" --cwd "$cwd" 2>/dev/null

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
    # Claude a fini sa réponse → plus busy (+ sentinelle turn-ended pour une mission).
    "$ENGINE" event turn-end --session "$sid" --cwd "$cwd" --transcript "$tp" 2>/dev/null
    ;;
  SessionEnd)
    # Sur un quit (Ctrl+Q→fermer), Claude déclenche SessionEnd (reason "other") pour
    # TOUS les Claude — même reason qu'un /exit. On ne supprime pas (la relance
    # restaure la cohorte du quit) : engine event horodate la fin (markend).
    "$ENGINE" event session-end --session "$sid" --cwd "$cwd" 2>/dev/null
    ;;
esac
exit 0
