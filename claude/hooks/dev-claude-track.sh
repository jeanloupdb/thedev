#!/usr/bin/env bash
# Hook multi-events : tient le registre des Claude ouverts par espace de dev
# (dev-claude-reg, SessionStart/End) ET un marqueur « busy » par session
# (UserPromptSubmit → en train de répondre ; Stop → fini). Le picker lit ces
# marqueurs pour montrer quels Claude distants tournent en ce moment.
# No-op hors d'un pane zellij.
#
# stdout : SessionStart/UserPromptSubmit injectent stdout dans le contexte.
# On n'y écrit RIEN, sauf le nudge pane-name (UserPromptSubmit), qui est
# volontairement injecté pour rappeler à Claude de (re)nommer son pane —
# la règle soft du prompt ne suffit pas (constat : les renames s'étiolent
# à mesure que le prompt injecté grossit).

BUSY_DIR="$HOME/.cache/dev-claude-busy"     # 1 fichier par session active (mtime = dernier tour)
NUDGE_DIR="$HOME/.cache/dev-claude-nudge"   # 1 fichier par session (mtime = dernier nudge)

payload=$(cat)
[ -n "${ZELLIJ_PANE_ID:-}" ] || exit 0   # pas dans un pane zellij → on ignore

ev=$(printf '%s' "$payload"  | jq -r '.hook_event_name // empty' 2>/dev/null)
sid=$(printf '%s' "$payload" | jq -r '.session_id // empty'      2>/dev/null)
cwd=$(printf '%s' "$payload" | jq -r '.cwd // empty'             2>/dev/null)
[ -n "$sid" ] || exit 0
[ -n "$cwd" ] || cwd="$PWD"
cwd=$(realpath "$cwd" 2>/dev/null || printf '%s' "$cwd")

case "$ev" in
  SessionStart)
    role="main"; [ -n "${CLAUDE_PANE_ONCE:-}" ] && role="aside"
    # Nom par défaut = nom posé au lancement par claude-pane/claude-aside
    # (ex. « claude 2 » pour un aside, « claude [indice] » sur VPS) → la 1re
    # inscription NE clobbe PAS ce nom. Sur une reprise, upsert préserve le
    # nom persistant déjà stocké (« ◆ <sujet> »), qu'on ré-applique au pane.
    def="${CLAUDE_PANE_NAME:-claude}"
    # Les Claude de mission (thedev-link) sont éphémères et leur pane est géré
    # par crun (« mission-<id> ») : pas de registre, pas de rename.
    case "$def" in mission-*) exit 0 ;; esac
    name=$(dev-claude-reg upsert "$sid" "$cwd" "$role" "${ZELLIJ_SESSION_NAME:-}" "$def" 2>/dev/null)
    # Garde-fou : ne renomme que les panes GÉRÉS (lancés par claude-pane/aside,
    # signature = CLAUDE_PANE_NAME posé). Un `claude` tapé à la main dans le
    # pane shell/git ne doit pas voir son pane renommé en « claude ».
    if [ -n "${CLAUDE_PANE_NAME:-}" ] && [ -n "$name" ]; then
      zellij action rename-pane -p "$ZELLIJ_PANE_ID" "$name" 2>/dev/null
    fi
    dev-claude-reg gc 14 2>/dev/null   # housekeeping : purge les lignes > 14 j
    ;;
  UserPromptSubmit)
    # Un tour démarre → Claude se met à répondre : marqueur « busy » (mtime=maintenant).
    mkdir -p "$BUSY_DIR" 2>/dev/null && : > "$BUSY_DIR/$sid" 2>/dev/null

    # --- Nudge pane-name (stdout → contexte de Claude) ---
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
    # Claude a fini sa réponse → plus busy.
    rm -f "$BUSY_DIR/$sid" 2>/dev/null
    ;;
  SessionEnd)
    # Sur un quit (Ctrl+Q→fermer), Claude intercepte le signal et déclenche
    # SessionEnd (reason "other") pour TOUS les Claude — même reason qu'un /exit
    # volontaire. On ne SUPPRIME donc pas (ça effacerait tout avant la relance) :
    # on HORODATE la fin. La relance restaure la « cohorte du quit » (voir
    # dev-claude-reg restore).
    rm -f "$BUSY_DIR/$sid" "$NUDGE_DIR/$sid" 2>/dev/null   # plus en cours
    dev-claude-reg markend "$sid" 2>/dev/null
    ;;
esac
exit 0
