# Couplage au moteur (Claude Code)

> Audit read-only du 2026-06-21. Objet : cartographier où et comment thedev est
> couplé en dur à Claude Code, pour préparer l'abstraction « moteur-agnostique »
> (principe n°1 de [`VISION.md`](VISION.md)). C'est l'état des lieux du chantier,
> pas une réécriture déjà faite.

## Verdict en une phrase

Couplage **profond mais concentré** : le squelette d'orchestration (espaces,
`crun`, `mission`, `ship`, `tsnode`…) est déjà neutre ; **tout le couplage dur se
réduit à un seul mécanisme — la façon dont thedev *observe* un agent** (historique,
reprise, résultat de mission, signaux busy/fin-de-tour), bâtie de bout en bout sur
les fichiers de session et les hooks de Claude Code.

## A. Points de couplage

| # | Point | Fichier:ligne | Type | Difficulté |
|---|-------|---------------|------|------------|
| 1 | Lancement du moteur : `claude` + flags (`--remote-control --model --append-system-prompt --resume`…) | `bin/claude-pane:120-127` | invocation CLI | moyenne |
| 2 | Sélecteur d'historique : parse des transcripts `~/.claude/projects/*/*.jsonl` | `bin/dev-picker:24,347-369,415-433` | format session | **forte** |
| 3 | Resume = id du fichier `.jsonl` passé à `--resume` | `bin/dev-picker:426` → `bash/dev-launcher.sh:50-53` → `bin/claude-pane:58-59` | format session | **forte** |
| 4 | Résultat de mission extrait du transcript JSONL (`jq` sur `type=="assistant"`) | `bin/thedev-link:207-219` | format session | **forte** |
| 5 | `transcript_path` fourni par les hooks, source de vérité du watcher | `claude/hooks/dev-claude-track.sh:43,107-112` ; `bin/thedev-link:183-210` | format session + hooks | **forte** |
| 6 | 4 hooks Claude Code (`SessionStart/SessionEnd/UserPromptSubmit/Stop`) câblés | `install.sh:51-71` ; `claude/hooks/dev-claude-track.sh` | hooks/settings | **forte** |
| 7 | Endpoint OAuth Anthropic + token `.claudeAiOauth` (fenêtre 5h) | `bin/claude-window-usage:12,20-24` | endpoint | moyenne |
| 8 | Plan/tier lu dans `~/.claude.json` (`oauthAccount`) | `bin/dev-picker:238-245` | endpoint/format | faible |
| 9 | Remote Control : `--remote-control <nom>` auto sur VPS | `bin/claude-pane:103-106` ; picker `135-137` | invocation CLI | moyenne |
| 10 | Noms de modèles en dur (alias→ids) | `bin/thedev-link:26-29` | modèle | faible |
| 11 | Modèle par défaut heartbeat = `haiku` | `bin/heartbeat-run:31,65-67` | modèle | faible |
| 12 | `claude -p` headless (heartbeat ; `cremote` DEPRECATED) | `bin/heartbeat-run:65-67` ; `bin/cremote:33` | invocation CLI | faible |
| 13 | `CLAUDE_CODE_SESSION_ID` pour persister un nom de pane | `bin/pane-name:28` | env spécifique | faible |
| 14 | Env de rendu Claude Code (`CLAUDE_CODE_NO_FLICKER`…) | `bin/claude-pane:19,24,120` | invocation CLI | faible |
| 15 | Identité machine = `claude/vps-context/*.md` symlinké en `~/.claude/CLAUDE.md` | `install.sh:96-102` ; `bin/claude-pane:36-38` | format config | faible |
| 16 | `/start` invoqué dans le brief de bootstrap projet | `bin/new-project:83` | vocabulaire/feature | faible |
| 17 | Vocabulaire « claude » (scripts, panes, registre, layout) | `bin/claude-pane`, `claude-aside`, `dev-claude-reg`, `claude-window-usage` ; `zellij/layouts/dev.kdl:17,19` ; `~/.cache/dev-claudes` | vocabulaire | faible |
| 18 | Découverte « vérité terrain » par `pgrep -x claude` | `bin/dev-picker:71-73,103` | invocation CLI | moyenne |

## B. Les couplages les plus durs — et c'est UN seul problème

Les points **2 → 6** ne sont pas indépendants : c'est un mécanisme transversal —
*« thedev sait ce que fait un agent en lisant ses fichiers de session Claude Code »* —
qui irrigue le picker, le launcher, le hook et le watcher de mission.

1. **Lecture des transcripts `~/.claude/projects/*/*.jsonl`** (`dev-picker:24,347-369,415-433`) : colonne vertébrale du picker (historique des espaces, titre, `cwd`, id de reprise).
2. **`--resume <basename .jsonl>`** (`dev-picker:426`, `dev-launcher.sh:50-53`, `claude-pane:58-59`) : la sémantique « reprendre » suppose id = basename du transcript.
3. **Extraction du résultat de mission depuis le JSONL** (`thedev-link:207-219`) : la fiabilité déterministe des missions repose sur le schéma assistant de Claude.
4. **4 hooks + `transcript_path`** (`install.sh:51-71`, `dev-claude-track.sh`, `thedev-link:183-210`) : registre des sessions, marqueur busy (vue de flotte), nudge pane-name, sentinelle fin-de-tour.

## C. Couplages superficiels (du `sed`)

- **Vocabulaire/nommage** (#17) : noms de scripts, pane `name="claude"`, bouton `＋ claude`, registre `~/.cache/dev-claudes`. Zéro logique.
- **Noms de modèles** (#10, #11) : quelques lignes isolées.
- **Endpoint usage/quota** (#7, #8) : `claude-window-usage` déjà autonome ; remplacer l'URL/parsing est local.
- **Env de rendu** (#14), **`CLAUDE.md` comme contexte** (#15), **`/start`** (#16) : détails de prompt/affichage.
- **`claude -p` headless** (#12) : `cremote` deprecated, heartbeat coupé — surface morte.

## D. L'abstraction réaliste : un adaptateur « moteur »

Faisable **sans réécriture massive**, en isolant la couche d'observation dans un
adaptateur unique exposant **5 opérations**, concentré dans **4 fichiers**
(`claude-pane`, `dev-picker`, `thedev-link`, `dev-claude-track.sh`) :

1. **lancer** une session (flags + env) — aujourd'hui `claude-pane`
2. **lister** les sessions d'un dossier + titre/id — aujourd'hui le glob JSONL du picker
3. **reprendre** par id — aujourd'hui `--resume`
4. **lire** le dernier message d'une session — aujourd'hui le `jq` de `thedev-link`
5. **signaux** busy / fin-de-tour — aujourd'hui les hooks + `transcript_path`

Plus un adaptateur secondaire pour l'usage/quota (#7). Le reste (vocabulaire,
modèles, env) est cosmétique.

> Les signatures bash de cet adaptateur (les 5 verbes + le contrat d'événements
> entrant + l'ordre d'attaque) sont spécifiées dans [`ENGINE-ADAPTER.md`](ENGINE-ADAPTER.md).

**Conclusion** : thedev n'est pas accidentellement couplé à Claude partout — son
ossature (crun, missions, espaces) est saine. Mais sa **couche d'observation de
l'agent** suppose Claude Code de bout en bout. Le chantier du principe n°1 est
réel, **borné** (≈ 5 fonctions, 4 fichiers).

## Résidus assumés (hors périmètre de l'adaptateur)

L'adaptateur a découplé la couche d'observation + le lancement. Ce qui reste
collé à Claude n'est **plus du couplage éparpillé** — c'est, par ordre de nature :

- **Features Claude sans équivalent générique** : Remote Control auto VPS
  (`claude-pane`), fenêtre 5h / quota (`claude-window-usage` + le picker lit
  `~/.claude.json` / `stats-cache.json` **sans passer par `engine usage`**),
  slash-command `/start` (`new-project`), identité `~/.claude/CLAUDE.md`.
- **Une feature picker hors adaptateur** : la réécriture du `cwd` dans les
  transcripts au renommage d'un dossier (`dev-picker`) édite le `.jsonl`
  directement — `engine list/read` ne la couvre pas.
- **Petits résidus en dur** : IDs de modèles (`thedev-link`), `CLAUDE_CODE_SESSION_ID`
  (`pane-name`), le vocabulaire (`claude-pane`, `dev-claude-reg`, `~/.cache/dev-claude-*`).
- **Dépendance structurelle** : le **système de hooks** lui-même — c'est par lui
  que thedev reçoit ses events. Un moteur sans hooks demanderait une autre source
  d'`engine event`.
- **Le cerveau** (system-prompt thedev + skills + mémoire) : porté par les rails
  Claude Code (`--append-system-prompt`, skills, mémoire) — détaché dans le *fond*
  (c'est du savoir thedev), couplé dans le *transport*.

Et **`resume`** : abstrait en tant qu'interface (verbe + id opaque), mais la
*capacité* « reprendre une conversation » reste un **prérequis** sur le moteur.
