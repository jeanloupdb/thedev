#!/usr/bin/env bash
# Hook multi-events Claude Code → TRADUCTEUR vers l'adaptateur moteur (engine event)
# + animation du titre de pane (pulse ◆↔◇ pendant un tour). L'ÉTAT (registre, busy,
# sentinelles de mission) est délégué à `engine event` ; restent ICI les mécanismes
# propres au hook Claude : rename de pane, pulse ◆, et nudge pane-name (stdout injecté
# dans le contexte du soldat). No-op hors d'un pane zellij.

BUSY_DIR="$HOME/.cache/soldat-busy"        # 1 fichier par session active
NUDGE_DIR="$HOME/.cache/soldat-nudge"      # 1 fichier par session (mtime = dernier nudge pane-name)
NOTE_NUDGE_DIR="$HOME/.cache/soldat-note-nudge" # idem, pour le rappel « note add » (contexte d'équipe)
JALON_NUDGE_DIR="$HOME/.cache/soldat-jalon-nudge" # idem, pour le rappel « jalon » (timeline) — rare
PART_NUDGE_DIR="$HOME/.cache/soldat-partition-nudge" # idem, pour le rappel « reorg » (machine déborde)
HEAD_MARK_DIR="$HOME/.cache/soldat-head"   # dernier HEAD git vu par session (détecte un commit → nudge resume)
WAITING_DIR="$HOME/.cache/soldat-waiting"  # Soldat bloqué sur un QCM (contenu = pane_id\tsession)
PANES_DIR="$HOME/.cache/soldat-panes"      # sid → pane_id\tsession, PERSISTANT tant que le soldat vit
                                           # (busy/waiting ne portent l'info que pendant leur état ;
                                           #  la colonne de gauche doit pouvoir sauter sur un soldat AU REPOS)

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
    # Où vit ce soldat : sid → pane_id. C'est ce qui permet de lui SAUTER dessus
    # depuis la colonne de gauche (focus-pane-id), même quand il est au repos.
    mkdir -p "$PANES_DIR" 2>/dev/null
    printf '%s\t%s\n' "$ZELLIJ_PANE_ID" "${ZELLIJ_SESSION_NAME:-}" > "$PANES_DIR/$sid" 2>/dev/null
    # Carte d'equipe (brique 1 commandement) : (re)construit le miroir runtime depuis
    # .thedev/equipe.md + les derives. Principal d'une VRAIE equipe seulement
    # (is_managed_pane exclut les missions ; -z CLAUDE_PANE_ONCE exclut les asides).
    # Best-effort, jamais bloquant.
    if is_managed_pane && [ -z "${CLAUDE_PANE_ONCE:-}" ]; then
      equipe card --cwd "$cwd" >/dev/null 2>&1 || true
      # Balayage : matérialise les cartes MANQUANTES des équipes locales récentes (même
      # source que la liste ÉQUIPES de l'accueil) → aucune équipe ne reste « sans chef »
      # faute de carte. La carte remonte ensuite au sommet (Stop → remonter). Détaché,
      # best-effort, borné : jamais bloquant pour le SessionStart.
      setsid timeout 8 equipe sweep </dev/null >/dev/null 2>&1 &
      # pane-id + sid + transcript du soldat PRINCIPAL, persistés par session → le
      # débrief riche (debrief-menu, option « r ») sait quel pane cibler et quel
      # transcript lire au moment du close. Clé = nom de session assaini.
      if [ -n "${ZELLIJ_SESSION_NAME:-}" ]; then
        md="$HOME/.cache/soldat-main"; mkdir -p "$md" 2>/dev/null \
          && printf '%s\t%s\t%s\n' "$ZELLIJ_PANE_ID" "$sid" "$tp" \
             > "$md/$(printf '%s' "$ZELLIJ_SESSION_NAME" | tr -c 'A-Za-z0-9._-' '_')" 2>/dev/null || true
      fi
      # Respiration (brique 3 commandement) : une équipe qui NAÎT peut faire déborder le
      # chef-machine (> N équipes) → matérialiser l'étage des sous-chefs de domaine. La
      # surcharge est « remarquée pendant une session quelconque » (doctrine, event-driven,
      # pas de moniteur debout). `reorg` = écrivain unique du régime ; borné, jamais bloquant.
      timeout 5 reorg >/dev/null 2>&1 || true
      # GC du contexte d'équipe (`note`) : purge les notes des soldats VRAIMENT quittés
      # (fermeture délibérée hors rafale du quit), piloté par la cohorte reg-soldat.
      # Tourne à la RÉOUVERTURE (équipe vivante) — jamais sur SessionEnd. Une équipe
      # close ne déclenche rien → contexte préservé. Best-effort, borné.
      timeout 5 note gc --cwd "$cwd" >/dev/null 2>&1 || true
    fi
    ;;
  UserPromptSubmit)
    # Un tour démarre → « calcule » (busy + animations). Pour un soldat non géré,
    # engine event busy pose juste le marqueur vide (l'etat-major n'utilise que le sid).
    _mark_busy

    # --- Nudge « note » (stdout → contexte du soldat) : rend le soldat conscient qu'il
    # enrichit le contexte de l'équipe EN CONTINU (`note add`), pas à la fermeture.
    # Établi dès le 1er tour (awareness), puis rafraîchi au plus toutes les 45 min.
    # Panes gérés, jamais les missions.
    if [ -n "${CLAUDE_PANE_NAME:-}" ]; then
      case "$CLAUDE_PANE_NAME" in
        mission-*) ;;
        *)
          # État à 3 temps via le contenu du marqueur : absent = tour 1 (amorce, pas de
          # nudge) ; vide = tour ≥2 → note d'INTRO ; horodaté → ENTRETIEN toutes les 45 min.
          nnf="$NOTE_NUDGE_DIR/$sid"; nnow=$(date +%s)
          mkdir -p "$NOTE_NUDGE_DIR" 2>/dev/null
          if [ ! -e "$nnf" ]; then
            : > "$nnf"                                   # tour 1 : on amorce, on ne dit rien
          elif [ ! -s "$nnf" ]; then
            printf '%s' "$nnow" > "$nnf"                 # tour 2 : note d'intro
            printf '[note] Ton sujet est clair : pose ta **note d'\''intro** — `note add "<qui tu es · sur quoi tu bosses>"`. Puis enrichis le contexte de l'\''équipe au fil de l'\''eau (pas à la fin).\n'
          else
            nlast=$(cat "$nnf" 2>/dev/null || echo 0)
            if [ $(( nnow - nlast )) -ge 2700 ]; then
              printf '%s' "$nnow" > "$nnf"
              printf '[note] Entretiens tes notes plutôt que d'\''empiler : regarde `note ls`, `set`/`rm` l'\''obsolète, `add` seulement le vraiment neuf. Le déroulé va dans `jalon`, pas ici.\n'
            fi
          fi
          # Rappel « jalon » (timeline), beaucoup plus rare : les commits git nourrissent
          # déjà la timeline, un jalon manuel ne vaut que pour un cap/décision hors commit.
          jnf="$JALON_NUDGE_DIR/$sid"
          jlast=0; [ -f "$jnf" ] && jlast=$(stat -c %Y "$jnf" 2>/dev/null || echo 0)
          if [ $(( nnow - jlast )) -ge 5400 ]; then
            mkdir -p "$JALON_NUDGE_DIR" 2>/dev/null && : > "$jnf"
            printf '[jalon] Un cap franchi ou une décision structurante depuis tout à l'\''heure ? Pose-le dans la timeline : `jalon "<événement>"` (tes commits y remontent déjà tout seuls).\n'
          fi
          # Rappel « reorg » : la machine DÉBORDE (état dérivé, PERSISTANT — survit à la
          # fermeture/relance de thedev). Fire dès le 1er tour d'une session relancée, puis
          # au plus toutes les 30 min. `partition status` = lecture locale, gaté par le
          # marqueur (jamais à chaque tour).
          pnf="$PART_NUDGE_DIR/$sid"
          plast=0; [ -f "$pnf" ] && plast=$(stat -c %Y "$pnf" 2>/dev/null || echo 0)
          if [ $(( nnow - plast )) -ge 1800 ]; then
            mkdir -p "$PART_NUDGE_DIR" 2>/dev/null && : > "$pnf"
            pst=$(partition status 2>/dev/null)
            if printf '%s' "$pst" | grep -q 'déborde'; then
              phead=$(printf '%s' "$pst" | head -1 | sed 's/^ *//')
              printf '[reorg] %s → déborde le span. Range par thème : `partition prep`, regroupe en ≤7 domaines clairs, `partition apply` (ou délègue à un soldat dédié). L'\''état persiste tant que ce n'\''est pas rangé.\n' "$phead"
            fi
          fi
          # Rappel « resume » sur COMMIT — déclencheur NATUREL : tu viens de livrer, c'est
          # exactement quand le résumé d'équipe doit bouger. Fort et ciblé (fire seulement
          # si un commit est apparu depuis ton dernier tour ET que le resume n'a pas bougé
          # récemment → pas de bruit si tu l'as déjà fait).
          newhead=$(git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
          if [ -n "$newhead" ]; then
            hmk="$HEAD_MARK_DIR/$sid"; oldhead=""; [ -f "$hmk" ] && oldhead=$(cat "$hmk" 2>/dev/null)
            if [ -n "$oldhead" ] && [ "$newhead" != "$oldhead" ]; then
              nk="$( { head -n1 "$HOME/.config/dev-vps" 2>/dev/null || hostname -s; } | tr -c 'A-Za-z0-9._-' '_')__$(printf '%s' "${ZELLIJ_SESSION_NAME:-}" | tr -c 'A-Za-z0-9._-' '_')"
              rf="$HOME/.cache/thedev/command/resume/$nk.md"; rmt=0; [ -f "$rf" ] && rmt=$(stat -c %Y "$rf" 2>/dev/null || echo 0)
              if [ $(( nnow - rmt )) -ge 300 ]; then
                printf '[resume] Tu as commité (%s) depuis ton dernier tour, mais le `resume` de l'\''équipe n'\''a pas bougé. Mets-le à jour EN UNE PHRASE maintenant — `resume --suggest` te propose un brouillon. Un chef ne te voit qu'\''à travers lui.\n' "$newhead"
              fi
            fi
            mkdir -p "$HEAD_MARK_DIR" 2>/dev/null; printf '%s' "$newhead" > "$hmk"
          fi ;;
      esac
    fi

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
    # Remontée quasi-live vers le sommet (multi-machine) : à la fin d'un tour, pousse le
    # cache mémoire → DÉBOUNCÉE (≥45s), en ARRIÈRE-PLAN détaché, bornée (ConnectTimeout
    # dans remonter). rsync delta-only, zéro Claude/crédit. No-op si pas de sommet / on
    # EST le sommet (remonter s'auto-annule) ; verrou non-bloquant côté remonter.
    if is_managed_pane; then
      rmk="$HOME/.cache/thedev/last-remonter"
      rlast=0; [ -f "$rmk" ] && rlast=$(stat -c %Y "$rmk" 2>/dev/null || echo 0)
      if [ $(( $(date +%s) - rlast )) -ge 45 ]; then
        mkdir -p "$HOME/.cache/thedev" 2>/dev/null && : > "$rmk"
        setsid remonter </dev/null >/dev/null 2>&1 &
      fi
    fi
    ;;
  SessionEnd)
    # Quit/exit → l'adaptateur horodate la fin (markend) et nettoie busy/nudge ; on
    # remet le titre nu (nettoie un ◆ figé, ex. /exit → shell keep-alive).
    "$ENGINE" event session-end --session "$sid" --cwd "$cwd" 2>/dev/null
    # Plus de débrief-au-quit : le contexte d'équipe ne se résume PLUS à la fermeture.
    # Il est alimenté EN CONTINU par les soldats (`note add`), et ces notes persistent
    # (fichiers cache) après le close. Rien à flusher ici — l'info est déjà remontée.
    # Cosmétique (titre nu) : peut hanger sans conséquence (session qui ferme), et le
    # `timeout` de pane_busy_title borne l'attente.
    pane_busy_title 0
    # Flush final vers le sommet : pousse les derniers écrits (best-effort, détaché ;
    # verrou non-bloquant → saute si un remonter tourne déjà).
    if is_managed_pane; then setsid remonter </dev/null >/dev/null 2>&1 & fi
    ;;
  PreToolUse)
    # Rafraîchit aussi le marqueur busy (activité en cours).
    [ -f "$BUSY_DIR/$sid" ] && touch "$BUSY_DIR/$sid" 2>/dev/null
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
    # Rafraîchit le marqueur busy à CHAQUE outil → un tour ACTIF reste « frais » et n'est
    # pas purgé par le filet anti-orphelin de pane-pulse. Un tour INTERROMPU (Stop non tiré)
    # cesse d'être rafraîchi → le marqueur vieillit → pane-pulse le purge → le ◆ s'éteint.
    [ -f "$BUSY_DIR/$sid" ] && touch "$BUSY_DIR/$sid" 2>/dev/null
    # Tu as répondu au QCM → le soldat reprend : retour en « calcule ».
    case "$(printf '%s' "$payload" | jq -r '.tool_name // empty' 2>/dev/null)" in
      AskUserQuestion) _mark_busy ;;
    esac
    ;;
esac
exit 0
