#!/usr/bin/env bash
# Backend « claude » de l'adaptateur moteur (cf. bin/engine, ENGINE-ADAPTER.md).
# Sourcé par bin/engine quand THEDEV_ENGINE=claude (défaut). Implémente le contrat
# moteur en enveloppant le comportement Claude Code ACTUEL (transcripts JSONL,
# registre dev-claude-reg, marqueurs busy, claude-window-usage). Premier jet :
# wrapper fidèle, les call-sites historiques ne sont pas encore re-routés ici.

ENGINE_PROC_NAME=claude
CC_PROJECTS="$HOME/.claude/projects"
CC_BUSY_DIR="$HOME/.cache/dev-claude-busy"
CC_NUDGE_DIR="$HOME/.cache/dev-claude-nudge"
CC_WAITING_DIR="$HOME/.cache/dev-claude-waiting"   # Claude bloqué sur une question/permission

# Chemin du transcript .jsonl d'une session (id = basename sans extension).
_cc_transcript_for() {   # $1=id  → chemin sur stdout, exit 1 si introuvable
  local id="$1" f
  for f in "$CC_PROJECTS"/*/"$id".jsonl; do
    [ -f "$f" ] && { printf '%s\n' "$f"; return 0; }
  done
  return 1
}

# (cwd, titre, mtime_epoch) d'un transcript sans tout lire (head/tail), comme le
# fait dev-picker (session_info) : cwd en tête, ai-title en queue, repli sur le 1er
# message utilisateur « humain ».
_cc_session_info() {   # $1=path  → "cwd\ttitle\tmtime" sur stdout, exit 1 sinon
  local path="$1" head tail cwd title first mtime
  [ -f "$path" ] || return 1
  mtime=$(stat -c %Y "$path" 2>/dev/null) || return 1
  head=$(head -c 65536 "$path" 2>/dev/null)
  tail=$(tail -c 131072 "$path" 2>/dev/null)
  cwd=$(printf '%s' "$head" | grep -aom1 '"cwd":"[^"]*"' | sed 's/^"cwd":"//; s/"$//')
  [ -n "$cwd" ] || return 1
  title=$(printf '%s\n' "$tail" | grep -a '"type":"ai-title"' | tail -1 \
            | jq -r '.aiTitle // empty' 2>/dev/null)
  if [ -z "$title" ]; then
    first=$(printf '%s\n' "$head" | grep -a '"type":"user"' \
              | jq -r 'if (.message.content|type)=="string" then .message.content
                       else ([.message.content[]?|select(.type=="text")|.text]|join(" ")) end' 2>/dev/null \
              | grep -av '^[[:space:]]*<command-' | head -1)
    title=$(printf '%s' "$first" | tr '\n\t' '  ' | sed 's/  */ /g; s/^ //; s/ $//' | cut -c1-60)
  fi
  [ -n "$title" ] || title="(session)"
  title=$(printf '%s' "$title" | tr '\n\t' '  ')   # schéma TSV : pas de tab/newline
  printf '%s\t%s\t%s\n' "$cwd" "$title" "$mtime"
}

# ── Contrat moteur ───────────────────────────────────────────────────────────

# Démarre une session (exec). Positionnels: cwd model resume init initfile -- extra…
engine_launch() {
  local cwd="$1" model="$2" resume="$3" init="$4" initfile="$5"; shift 5
  [ "${1:-}" = "--" ] && shift
  [ -n "$cwd" ] && cd "$cwd" 2>/dev/null
  [ -n "$model" ]    && export CLAUDE_PANE_MODEL="$model"
  [ -n "$resume" ]   && export CLAUDE_RESUME_ID="$resume"
  [ -n "$init" ]     && export CLAUDE_PANE_INIT="$init"
  [ -n "$initfile" ] && export CLAUDE_PANE_INIT_FILE="$initfile"
  # NB : --remote-control (auto sur VPS) et --append-system-prompt (prompt zellij)
  # sont gérés nativement par claude-pane → on lui délègue.
  exec claude-pane "$@"
}

# Liste les sessions. all=1 → un espace par dossier (realpath, id = dernière conv) ;
# sinon toutes les sessions du cwd demandé. Sortie TSV (ou JSON-lines si json=1).
# Implémenté en UN seul process python3 (et non bash+jq par fichier) : le picker
# l'appelle au démarrage, la latence compte — le bash par-fichier coûtait ~5 s.
engine_list() {   # $1=want_cwd  $2=all  $3=json
  python3 - "$1" "$2" "$3" "$CC_PROJECTS" "$CC_BUSY_DIR" <<'PY'
import sys, os, re, json, glob, datetime
want_cwd, allf, jsonf, projects, busydir = sys.argv[1], sys.argv[2]=="1", sys.argv[3]=="1", sys.argv[4], sys.argv[5]

def flatten(content):
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return " ".join(it.get("text", "") for it in content
                        if isinstance(it, dict) and it.get("type") == "text")
    return ""

def session_info(path):
    """(cwd, titre, mtime) sans tout lire (têtes/queues) — logique reprise telle
    quelle de l'ancien dev-picker."""
    try:
        size = os.path.getsize(path)
        with open(path, "rb") as f:
            head = f.read(65536)
            f.seek(max(0, size - 131072))
            tail = f.read()
        mtime = os.path.getmtime(path)
    except OSError:
        return None
    m = re.search(rb'"cwd":"([^"]*)"', head)
    if not m:
        return None
    cwd = m.group(1).decode("utf-8", "replace")
    title = ""
    for line in tail.split(b"\n"):
        if b'"type":"ai-title"' in line:
            try:
                title = json.loads(line).get("aiTitle", "") or title
            except Exception:
                pass
    if not title:
        first = ""
        for line in head.split(b"\n"):
            if b'"type":"user"' in line:
                try:
                    t = flatten(json.loads(line).get("message", {}).get("content"))
                except Exception:
                    continue
                if t and not t.lstrip().startswith("<command-"):
                    first = t
                    break
        title = re.sub(r"\s+", " ", first).strip()[:60]
    title = re.sub(r"\s+", " ", title).strip() or "(session)"
    return cwd, title, mtime

best, rows = {}, []
for path in glob.glob(os.path.join(projects, "*", "*.jsonl")):
    info = session_info(path)
    if not info:
        continue
    cwd, title, mtime = info
    if not cwd:
        continue
    try:
        real = os.path.realpath(cwd)
    except OSError:
        real = cwd
    sid = os.path.basename(path)[:-6]
    if allf:
        g = best.get(real)
        if not g or mtime > g[1]:
            best[real] = (sid, mtime, real, title)
    elif real == want_cwd:
        rows.append((sid, mtime, real, title))
if allf:
    rows = list(best.values())

for sid, mtime, cwd, title in rows:
    iso = datetime.datetime.fromtimestamp(mtime).astimezone().isoformat(timespec="seconds")
    busy = os.path.exists(os.path.join(busydir, sid))
    if jsonf:
        print(json.dumps({"id": sid, "mtime": iso, "cwd": cwd, "busy": busy, "title": title},
                         ensure_ascii=False))
    else:
        t = title.replace("\t", " ").replace("\n", " ")
        print("\t".join([sid, iso, cwd, "1" if busy else "0", t]))
PY
}

# Lit le(s) message(s) d'une session. last=1 → dernier seulement ; role filtre.
# Reproduit le jq de thedev-link (capture déterministe du résultat de mission).
engine_read() {   # $1=id  $2=last  $3=role  $4=json  $5=ref (chemin transcript, optionnel)
  local id="$1" last="$2" role="$3" json="$4" ref="${5:-}" tp lastjson=false
  if [ -n "$ref" ]; then
    tp="$ref"; [ -f "$tp" ] || { echo "engine: transcript '$tp' introuvable" >&2; return 1; }
  else
    tp=$(_cc_transcript_for "$id") || { echo "engine: session '$id' introuvable" >&2; return 1; }
  fi
  command -v jq >/dev/null 2>&1 || { echo "engine: jq requis" >&2; return 1; }
  [ "$last" = 1 ] && lastjson=true
  if [ "$json" = 1 ]; then
    jq -c --arg role "$role" '
      select(($role=="any" and (.type=="assistant" or .type=="user")) or .type==$role)
      | {role:.type,
         text:([.message.content[]?|select(.type=="text")|.text]|join("")),
         ts:(.timestamp // null)}' "$tp" 2>/dev/null \
      | { [ "$last" = 1 ] && tail -1 || cat; }
  else
    jq -rs --arg role "$role" --argjson last "$lastjson" '
      [ .[]
        | select(($role=="any" and (.type=="assistant" or .type=="user")) or .type==$role)
        | .message.content[]? | select(.type=="text") | .text ]
      | if $last then (last // empty) else .[] end' "$tp" 2>/dev/null
  fi
}

# Fenêtre de quota (5h/7d). TSV: WINDOW \t USED_PCT \t RESETS_IN (resets non exposé
# par le cache --pct → colonne vide). exit 2 si le moteur n'expose pas de quota.
engine_usage() {   # $1=json
  local json="$1" pct h5 d7
  command -v claude-window-usage >/dev/null 2>&1 || return 2
  pct=$(claude-window-usage --pct 2>/dev/null)
  [ -n "$pct" ] || return 0   # hors-ligne / pas de token → silencieux
  h5=$(printf '%s' "$pct" | awk '{print $2}')
  d7=$(printf '%s' "$pct" | awk '{print $4}')
  if [ "$json" = 1 ]; then
    jq -cn --arg h "$h5" --arg d "$d7" \
      '[{window:"5h",used_pct:($h|tonumber?//null)},
        {window:"7d",used_pct:($d|tonumber?//null)}][]'
  else
    printf '5h\t%s\t\n7d\t%s\t\n' "$h5" "$d7"
  fi
}

# Vérité terrain des process. Sans id : nombre de moteurs vivants. Avec id : 0/1
# selon qu'un process tourne dans le cwd de cette session (comme dev-picker).
engine_running() {   # $1=id (optionnel)
  local id="$1" tp info cwd real n=0 p pc
  if [ -z "$id" ]; then
    pgrep -x "$ENGINE_PROC_NAME" 2>/dev/null | wc -l | tr -d ' '
    return 0
  fi
  tp=$(_cc_transcript_for "$id") || { echo 0; return 0; }
  info=$(_cc_session_info "$tp") || { echo 0; return 0; }
  cwd=$(printf '%s' "$info" | cut -f1)
  real=$(realpath "$cwd" 2>/dev/null || printf '%s' "$cwd")
  for p in $(pgrep -x "$ENGINE_PROC_NAME" 2>/dev/null); do
    pc=$(readlink "/proc/$p/cwd" 2>/dev/null)
    [ "$(realpath "$pc" 2>/dev/null || printf '%s' "$pc")" = "$real" ] && n=$((n+1))
  done
  [ "$n" -gt 0 ] && echo 1 || echo 0
}

# Puits d'événements normalisés (le pivot entrant). Tient l'ÉTAT thedev : registre
# (dev-claude-reg), marqueurs busy, et sentinelles de mission (transcript_path /
# turn-ended, lues par le watcher de thedev-link). Les extras spécifiques Claude
# (rôle, nom de pane, session zellij) sont lus dans l'env du hook, comme avant.
# Le rename du pane et le nudge pane-name restent côté hook (mécanismes propres au
# hook Claude) ; session-start renvoie le nom de pane sur stdout pour le rename.
engine_event() {   # $1=type $2=session $3=cwd $4=title $5=transcript
  local type="$1" sid="$2" cwd="$3" tp="${5:-}" role def name mid w
  case "$type" in
    session-start)
      role="main"; [ -n "${CLAUDE_PANE_ONCE:-}" ] && role="aside"
      def="${CLAUDE_PANE_NAME:-claude}"
      case "$def" in
        mission-*)
          # Mission (thedev-link) : pas de registre ; on enregistre le
          # transcript_path dans le work-dir (source de vérité du résultat).
          mid="${def#mission-}"
          if [ -n "$tp" ]; then
            for w in "$HOME"/.cache/thedev/spaces/*/work/"$mid"; do
              [ -d "$w" ] && printf '%s\n' "$tp" > "$w/transcript_path" 2>/dev/null
            done
          fi
          return 0 ;;
      esac
      name=$(dev-claude-reg upsert "$sid" "$cwd" "$role" "${ZELLIJ_SESSION_NAME:-}" "$def" 2>/dev/null)
      dev-claude-reg gc 14 2>/dev/null     # housekeeping : purge > 14 j
      printf '%s' "$name"                  # → l'appelant (hook) renomme le pane
      ;;
    busy)
      mkdir -p "$CC_BUSY_DIR" 2>/dev/null && : > "$CC_BUSY_DIR/$sid" 2>/dev/null
      rm -f "$CC_WAITING_DIR/$sid" 2>/dev/null   # nouveau tour → il ne t'attend plus
      ;;
    turn-end)
      rm -f "$CC_BUSY_DIR/$sid" 2>/dev/null
      case "${CLAUDE_PANE_NAME:-}" in
        mission-*)
          # Fin de tour déterministe d'une mission : sentinelle turn-ended (+
          # transcript_path en filet), lue par le watcher de thedev-link.
          mid="${CLAUDE_PANE_NAME#mission-}"
          for w in "$HOME"/.cache/thedev/spaces/*/work/"$mid"; do
            [ -d "$w" ] || continue
            date -Iseconds > "$w/turn-ended" 2>/dev/null
            [ -n "$tp" ] && [ ! -s "$w/transcript_path" ] && printf '%s\n' "$tp" > "$w/transcript_path" 2>/dev/null
          done
          ;;
      esac
      ;;
    session-end)
      rm -f "$CC_BUSY_DIR/$sid" "$CC_NUDGE_DIR/$sid" "$CC_WAITING_DIR/$sid" 2>/dev/null
      dev-claude-reg markend "$sid" 2>/dev/null
      ;;
    waiting)
      # Claude attend une réponse/permission (hook Notification) → état « t'attend » :
      # marqueur waiting, et on retire busy (il ne CALCULE plus, il te bloque).
      mkdir -p "$CC_WAITING_DIR" 2>/dev/null && : > "$CC_WAITING_DIR/$sid" 2>/dev/null
      rm -f "$CC_BUSY_DIR/$sid" 2>/dev/null
      ;;
    *)
      echo "engine event: type inconnu '$type'" >&2; return 1 ;;
  esac
}

# Décrit le câblage cible des hooks natifs vers `engine event`. Ne modifie PAS
# settings.json (la migration depuis dev-claude-track.sh est une étape séparée).
engine_install_hooks() {
  cat <<'MAP'
claude → engine event (mapping cible) :
  SessionStart     → engine event session-start --session <id> --cwd <cwd> [--transcript <tp>]
  UserPromptSubmit → engine event busy          --session <id> --cwd <cwd>
  Stop             → engine event turn-end       --session <id> --cwd <cwd>
  SessionEnd       → engine event session-end    --session <id> --cwd <cwd>
Câblage actuel : install.sh → claude/hooks/dev-claude-track.sh (pas encore re-routé).
MAP
}
