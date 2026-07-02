#!/usr/bin/env bash
# Hook multi-events Claude Code → TRADUCTEUR vers l'adaptateur moteur (engine event)
# + animation du titre de pane (pulse ◆↔◇ pendant un tour). L'ÉTAT (registre, busy,
# sentinelles de mission) est délégué à `engine event` ; restent ICI les mécanismes
# propres au hook Claude : rename de pane, pulse ◆, et nudge pane-name (stdout injecté
# dans le contexte du soldat). No-op hors d'un pane zellij.

BUSY_DIR="$HOME/.cache/soldat-busy"        # 1 fichier par session active
NUDGE_DIR="$HOME/.cache/soldat-nudge"      # 1 fichier par session (mtime = dernier nudge)
WAITING_DIR="$HOME/.cache/soldat-waiting"  # Soldat bloqué sur un QCM (contenu = pane_id\tsession)

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

# Pane « géré » = lancé par soldat-pane/renfort (CLAUDE_PANE_NAME posé) et pas
# une mission (pane soutien « mission-… »). Seuls ces panes voient leur titre touché.
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
  nm=$(reg-soldat get "$sid" 2>/dev/null | cut -f4)
  [ -n "$nm" ] || nm="$CLAUDE_PANE_NAME"
  nm=${nm#◆ }
  [ "$1" = "1" ] && nm="◆ $nm"
  # timeout : sur une session en fermeture, le serveur zellij meurt → `zellij action`
  # peut hanger indéfiniment (attente d'un serveur mort). On borne à 2s pour ne jamais
  # bloquer le hook (le rename est cosmétique).
  timeout 2 zellij action rename-pane -p "$ZELLIJ_PANE_ID" "$nm" 2>/dev/null
}

# Marque le tour « en cours » (calcule) : busy + marqueur enrichi pour pane-pulse
# + animations. Au début d'un tour (UserPromptSubmit) ET à la reprise après un
# QCM bloquant (PostToolUse AskUserQuestion).
_mark_busy() {
  "$ENGINE" event busy --session "$sid" --cwd "$cwd" 2>/dev/null
  if is_managed_pane; then
    printf '%s\t%s\n' "$ZELLIJ_PANE_ID" "${ZELLIJ_SESSION_NAME:-}" > "$BUSY_DIR/$sid" 2>/dev/null
    pane_busy_title 1                                  # 1er frame : ◆ <nom>
    setsid pane-pulse </dev/null >/dev/null 2>&1 &     # pulse ◆ du titre du pane (instance unique via flock)
  fi
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
    # Carte d'equipe (brique 1 commandement) : (re)construit le miroir runtime depuis
    # .thedev/equipe.md + les derives. Principal d'une VRAIE equipe seulement
    # (is_managed_pane exclut les missions ; -z CLAUDE_PANE_ONCE exclut les asides).
    # Best-effort, jamais bloquant.
    if is_managed_pane && [ -z "${CLAUDE_PANE_ONCE:-}" ]; then
      equipe card --cwd "$cwd" >/dev/null 2>&1 || true
      # pane-id + sid + transcript du soldat PRINCIPAL, persistés par session → le
      # débrief riche (debrief-menu, option « r ») sait quel pane cibler et quel
      # transcript lire au moment du close. Clé = nom de session assaini.
      if [ -n "${ZELLIJ_SESSION_NAME:-}" ]; then
        md="$HOME/.cache/soldat-main"; mkdir -p "$md" 2>/dev/null \
          && printf '%s\t%s\t%s\n' "$ZELLIJ_PANE_ID" "$sid" "$tp" \
             > "$md/$(printf '%s' "$ZELLIJ_SESSION_NAME" | tr -c 'A-Za-z0-9._-' '_')" 2>/dev/null || true
      fi
    fi
    ;;
  UserPromptSubmit)
    # Un tour démarre → « calcule » (busy + animations). Pour un soldat non géré,
    # engine event busy pose juste le marqueur vide (l'etat-major n'utilise que le sid).
    _mark_busy

    # --- Nudge pane-name (stdout → contexte du soldat) — mécanisme propre au hook ---
    # Uniquement pour les panes gérés, jamais pour les missions.
    [ -n "${CLAUDE_PANE_NAME:-}" ] || exit 0
    case "$CLAUDE_PANE_NAME" in mission-*) exit 0 ;; esac
    row=$(reg-soldat get "$sid" 2>/dev/null)
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
    # Debrief-au-quit minimal (brique 1 commandement) : flush derive zero-IA de
    # l'etat de l'equipe pour la remontee hierarchique. Principal d'une vraie equipe
    # uniquement. FLUSHÉ EN PREMIER, avant tout appel zellij : sur une fermeture
    # d'équipe (delete-session) le serveur zellij de la session meurt → un
    # `zellij action` peut hanger et empêcher le débrief. La donnée durable d'abord,
    # le cosmétique après. (Un vrai crash ne lance aucun hook → pas de debrief.)
    if is_managed_pane && [ -z "${CLAUDE_PANE_ONCE:-}" ]; then
      reason=$(printf '%s' "$payload" | jq -r '.reason // empty' 2>/dev/null)
      equipe debrief --reason "${reason:-quit}" --session "$sid" --cwd "$cwd" --transcript "$tp" >/dev/null 2>&1 || true
    fi
    # Cosmétique (titre nu) en DERNIER : peut hanger sans conséquence (session qui
    # ferme), et le `timeout` de pane_busy_title borne l'attente.
    pane_busy_title 0
    ;;
  PreToolUse)
    # Le soldat va poser un QCM bloquant (AskUserQuestion) → il TE bloque, état « t'attend »
    # (≠ « calcule »). Le matcher du hook restreint déjà à cet outil ; on revérifie
    # tool_name par sécurité.
    case "$(printf '%s' "$payload" | jq -r '.tool_name // empty' 2>/dev/null)" in
      AskUserQuestion)
        "$ENGINE" event waiting --session "$sid" --cwd "$cwd" 2>/dev/null
        pane_busy_title 0
        if is_managed_pane; then
          # enrichit le marqueur waiting avec pane_id\tsession (pour Alt+W et l'alerte
          # de barre) puis lance l'alerte rouge « action t'attend · Alt+W ».
          printf '%s\t%s\n' "$ZELLIJ_PANE_ID" "${ZELLIJ_SESSION_NAME:-}" > "$WAITING_DIR/$sid" 2>/dev/null
          setsid wait-bar </dev/null >/dev/null 2>&1 &
        fi ;;
    esac
    ;;
  PostToolUse)
    # Tu as répondu au QCM → le soldat reprend : retour en « calcule ».
    case "$(printf '%s' "$payload" | jq -r '.tool_name // empty' 2>/dev/null)" in
      AskUserQuestion) _mark_busy ;;
    esac
    ;;
esac
exit 0
