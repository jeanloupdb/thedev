# Adaptateur moteur — signatures

> Conception du 2026-06-21. Interface bash qui découple thedev de Claude Code,
> en réponse à l'audit [`ENGINE-COUPLING.md`](ENGINE-COUPLING.md) et au principe
> n°1 de [`VISION.md`](VISION.md). C'est le **contrat**.
>
> **Statut** : implémenté dans `bin/engine` (dispatcher) + `lib/engine/claude.sh`
> (backend Claude). Les verbes sortants (`launch`/`resume`/`list`/`read`/`usage`/
> `running`) et le core de `engine event` sont des **wrappers fidèles** du
> comportement actuel — testés sur données réelles.
>
> **Migrations faites** : `thedev-link` (résultat de mission → `engine read
> --transcript`) et `dev-picker` (découverte des espaces → `engine list --all
> --json` ; le schéma JSONL et `~/.claude/projects` ont quitté le picker).
> `engine list` est implémenté en un seul process python3 (~90 ms) pour ne pas
> ralentir l'accueil. **Pas encore fait** : les hooks (`engine event`) et
> `claude-pane` (`engine launch`).

## Idée directrice

La frontière d'abstraction n'est pas le code, c'est **le schéma** : arguments
stables en entrée, sortie au format stable. Peu importe le moteur derrière,
`engine list` sort toujours les mêmes colonnes.

## Forme & sélection

- Un dispatcher `bin/engine` (style git : `engine <verbe> …`).
- Backend choisi par `THEDEV_ENGINE` (défaut `claude`), implémenté dans
  `lib/engine/<nom>.sh` (sourcé).
- **Deux moitiés** : *sortant* (thedev appelle le moteur) et *entrant* (le moteur
  notifie thedev via des événements).

## Règle d'or sur l'`ID`

L'`ID` de session est une **chaîne opaque**. Seul le backend l'interprète
(aujourd'hui = basename du `.jsonl` ; demain, autre chose). thedev ne suppose
**jamais** que c'est un nom de fichier — c'est le point dur n°3 de l'audit.

## Conventions de sortie / exit

stdout machine-readable (TSV par défaut, `--json` pour le picker). Exit :
**0** ok · **2** non supporté par ce moteur · **1** erreur. Stable, pour que
l'appelant branche (ex. masquer la barre quota si `engine usage` → 2).

---

## Sortant — les verbes

### `engine launch` — démarrer une session (exec)
```bash
engine launch [--cwd DIR] [--model NAME] [--remote-control NAME] \
              [--system-append FILE] [--resume ID] [-- EXTRA...]
```
Construit env+argv et **exec** le moteur (prend le pane) ; ne rend pas la main si
ok. `--resume ID` ⇒ reprend au lieu de démarrer neuf.
*Aujourd'hui (claude)* : `bin/claude-pane` (`--remote-control --model
--append-system-prompt --resume`, env `CLAUDE_CODE_*`).

### `engine resume ID` — sucre = `launch --resume ID`
Gardé comme verbe car le picker a un chemin « reprendre » distinct.

### `engine list` — lister les sessions
```bash
engine list [--cwd DIR] [--all] [--json]
```
Défaut : sessions de `$PWD`. `--all` : toutes (découverte des espaces).
**stdout TSV**, une session/ligne, colonnes fixes :
```
ID \t MTIME_ISO \t CWD \t BUSY \t TITLE
```
`ID` opaque · `MTIME_ISO` triable · `CWD` absolu · `BUSY` `1|0|?` · `TITLE`
(tabs/newlines retirés). `--json` : mêmes champs en JSON-lines. Exit 0 même si vide.
*Aujourd'hui* : glob `~/.claude/projects/*/*.jsonl` + parse (`cwd`, `ai-title`, mtime).

### `engine read` — lire le(s) message(s)
```bash
engine read ID|--transcript REF [--last] [--role assistant|user|any] [--json]
```
Lit par **id** (résolu par le backend) ou par **référence de transcript** directe
(`--transcript`, pour un appelant qui a déjà la réf via un event).
`--last` (défaut) = dernier message ; `--role assistant` (défaut) = filtre.
`--last --role assistant` ⇒ **le texte assistant final = résultat de mission**.
stdout = texte brut ; `--json` = `{role,text,ts}` en JSON-lines.
*Aujourd'hui* : le `jq` de `thedev-link:207-219`.

### `engine usage` — fenêtre de quota (optionnel)
```bash
engine usage [--json]
# stdout TSV: WINDOW \t USED_PCT \t RESETS_IN   (ex: 5h \t 73 \t 2h14m)
```
Exit **2** si le moteur n'a pas de notion de quota.
*Aujourd'hui* : OAuth `api.anthropic.com/api/oauth/usage`.

### `engine running` — vérité terrain des process
```bash
engine running            # nombre de process moteur vivants
engine running --id ID    # 0/1 : cette session tourne-t-elle ?
```
*Aujourd'hui* : `pgrep -x claude` (`dev-picker:71-73`).

---

## Entrant — le contrat d'événements

Le seul vrai changement architectural : thedev consomme des **événements**, pas
des hooks Claude. Puits stable, appelé par le mécanisme natif du moteur :
```bash
engine event TYPE --session ID --cwd DIR [--title T] [--transcript REF]
#   TYPE ∈ session-start | busy | turn-end | session-end
```
Écrit dans le registre thedev (agnostique), consommé par picker / missions /
pane-name.
- *Pour Claude* : les 4 hooks (`SessionStart/Stop/UserPromptSubmit/SessionEnd`)
  appellent `engine event …` — remplace le `dev-claude-track.sh` qui parle Claude.
- *Pour un moteur sans hooks* : le backend produit ces events par polling/wrapper.
  **thedev s'en fiche, il lit des events.**

---

## Le contrat backend (`lib/engine/<x>.sh` doit définir)

```bash
engine_launch          # exec le moteur
engine_list            # émet le TSV de sessions
engine_read            # émet texte/JSON d'une session
engine_usage           # émet le quota, ou `return 2`
engine_running         # compte/teste les process
engine_install_hooks   # câble l'eventing natif → `engine event`   (appelé par install.sh)
# + métadonnées : ENGINE_PROC_NAME, ...
```

## Migration d'un site d'appel (avant / après)

```bash
# Résultat de mission — thedev-link (FAIT)
# AVANT (couplé au schéma JSONL de Claude) :
jq -r 'select(.type=="assistant")|.message.content[]|select(.type=="text")|.text' "$transcript" | tail -1
# APRÈS :
engine read --transcript "$transcript" --last --role assistant
```
```bash
# Découverte des espaces — dev-picker
# AVANT : glob ~/.claude/projects/*/*.jsonl + parse
# APRÈS : engine list --all --json
```

## Ce qui reste hors moteur (ne pas y toucher)

Registre, rendu du picker, `crun`, `mission` (transport `.mission`/`.result`),
`ship`, `tsnode`, `thedev-status` : déjà agnostiques. **L'adaptateur n'absorbe QUE
le lancement + la couche d'observation.** Les ~14 autres points de l'audit sont du
`sed` (vocabulaire, modèles, env).

## Deux points de conception à garder en tête

- **`launch` qui `exec`** ne *retourne* pas : tout ce qui doit se passer « après
  démarrage » passe par les **events**, pas par un code de retour. Cohérent avec le
  modèle pane de zellij.
- **`engine event` est le pivot** : c'est lui qui transforme « thedev lit les
  fichiers de Claude » en « thedev écoute des événements normalisés ». Si on ne fait
  qu'**une** chose de tout ce chantier, c'est ça — `list`/`read` peuvent rester en
  lecture directe un temps.

## Ordre d'attaque suggéré

1. `engine event` + `engine_install_hooks` (le pivot entrant) — isole le suivi d'état.
2. `engine read` — débranche la capture de résultat de mission du schéma JSONL.
3. `engine list` — débranche la découverte des espaces du picker.
4. `engine launch`/`resume` — encapsule `claude-pane`.
5. `usage` / `running` / vocabulaire — le facile, en dernier.
