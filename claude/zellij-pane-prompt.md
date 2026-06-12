# zellij session context

Tu tournes dans un pane zellij, lancé par le layout `dev`
(`~/.config/zellij/layouts/dev.kdl`). La session (= un **espace**) a trois
**pages** (onglets) — vocabulaire complet dans `NAMING.md` :

- **page `code page`** (territoire IA, partagé avec l'utilisateur) :
  - gauche (20%) : pane `editor` (nvim)
  - droite : la **stack des Claude** (`claude`, toi, focus) + la barre `＋ claude`
    pour ajouter un Claude secondaire (aside).
- **page `sandbox`** (TON territoire) : c'est là que tu déposes tout ce que tu
  lances. Initialement un pane d'accueil `welcome`. Tes panes `crun`
  atterrissent ici par défaut (et le watcher de liens y vit aussi).
- **page `my space`** (territoire HUMAIN) : les terminaux perso de l'utilisateur,
  `shell` + `git` (git-centric, alias `g`/`gs`). **Ne pilote pas ces panes** sans
  raison — c'est sa main, pas la tienne.

L'utilisateur est full zellij + nvim — pas de VS Code. Quand tu écris dans un
fichier via Edit/Write, son nvim peut auto-reload (autoread).

## Nomme ton pane (pour naviguer entre plusieurs Claude)

L'utilisateur ouvre souvent plusieurs sessions dev en parallèle. Pour qu'il
s'y retrouve d'un coup d'œil, **garde le titre de TON pane à jour** avec un
libellé court qui résume le sujet courant :

```bash
pane-name "◆ <2-3 mots>"
```

`pane-name` renomme le pane **et persiste** le libellé pour ta conversation :
si l'utilisateur quitte puis relance cet espace, ton pane retrouve son nom.
(N'utilise pas `zellij action rename-pane` directement — il ne persiste pas.)

Règles :
- **Nom par défaut : `claude`** (ou `claude [<vps>]` sur VPS). C'est l'état au
  démarrage et tant qu'aucun sujet ne se dégage. Tu ne bascules sur `◆ <…>`
  qu'une fois un sujet clair, et tu **reviens à `claude`** s'il n'y a plus de
  sujet précis.
- **2-3 mots max**, ce qui *différencie* cette conversation (le sujet précis).
- **Ne répète PAS le nom du projet/repo** — il est déjà connu (session/onglet).
  Mets l'action ou le composant en cours : `◆ nommage panes`, `◆ fix upload`,
  `◆ refonte dashboard`.
- **Mets-le à jour quand le sujet bascule vraiment** (nouveau chantier), pas à
  chaque message. Pose-le dès que le sujet d'un échange se précise — et si le
  nom courant ne colle plus à la discussion, corrige-le : un nom périmé est
  pire que le défaut.
- Sur un **VPS**, le repère `[<vps>]` est inséré automatiquement par
  `pane-name` — donne juste `◆ <2-3 mots>`.
- C'est toi qui le tiens à jour, personne d'autre ne le fait. Un rappel
  `[pane-name]` peut apparaître dans ton contexte si le nom semble en retard —
  traite-le comme une invitation à vérifier, pas comme un ordre de renommer.

Tu peux piloter la session via la CLI `zellij` directement (binaire sur le PATH,
session détectable via `$ZELLIJ`, `$ZELLIJ_SESSION_NAME`, `$ZELLIJ_PANE_ID`).

## Quand l'utiliser

- Processus long-running (serveur dev, build watch, tail de logs) : lance-les dans
  un pane dédié au lieu de `cmd &` qui pollue ta sortie et te coupe du process.
- Ouvrir un fichier dans l'éditeur de l'utilisateur sans quitter ta boucle.
- Capturer ce qui se passe dans un autre pane (logs serveur, sortie test runner)
  sans demander à l'utilisateur de copier-coller.
- Grouper plusieurs commandes liées dans un nouvel onglet nommé pour rester organisé.

Ne l'utilise PAS pour des commandes courtes one-shot : reste dans ton pane.

## Commandes utiles

```bash
# lancer une commande dans un nouveau pane
zellij run -- npm run dev
zellij run --name "server" -- ./serve.sh
zellij run --floating -- htop

# pages (onglets)
zellij action new-tab --name "logs"
zellij action go-to-tab-name "code page"
zellij action current-tab-info

# capturer la sortie d'un pane (focus dessus d'abord, ou note le pane id)
zellij action dump-screen /tmp/pane.txt

# ouvrir un fichier dans l'editor de l'utilisateur
zellij action edit src/main.rs

# envoyer une commande dans le pane focus (rare — préfère `zellij run`)
zellij action write-chars "git status"
zellij action send-keys "Enter"
```

## Garde-fous

- Vérifie `[ -n "$ZELLIJ" ]` avant d'invoquer `zellij action` si tu n'es pas sûr.
- N'ouvre pas un pane par étape — réutilise les panes existants quand c'est pertinent.
- Le pane `shell` à côté de toi est piloté par l'utilisateur : ne lui envoie pas
  de `write-chars` sans raison, ça écrase ce qu'il est en train de taper.

## `crun` — la commande pour tout ce que tu lances

**Tu DOIS utiliser `crun` au lieu de `zellij run` direct.** Il gère :
dédup par nom, registre des agents actifs, bascule auto vers la page `sandbox`,
fermeture propre. Ne lance JAMAIS via `zellij run`, `cmd &`, ou
`run_in_background=true` quand l'utilisateur veut voir la sortie.

```bash
crun <name> -- <cmd>              # lance dans la sandbox
crun --tab <tab> <name> -- <cmd>  # tab spécifique (créée si absente)
crun --floating <name> -- <cmd>   # pane flottant
crun list                         # liste les agents (● vivant, ○ mort)
crun kill <name>                  # tue un agent par nom
crun cleanup                      # ferme les panes morts
```

**Discipline** :
- **AVANT de créer un crun, fais `crun list`** et regarde l'existant : s'il y a
  déjà un agent **similaire** (même but/commande), **réutilise son nom**
  (`crun <ce-nom> -- …` → crun remplace l'ancien) au lieu d'en créer un nouveau ;
  tue les inutiles (`crun kill <name>`) et purge les morts (`crun cleanup`).
  **Pour une relance d'une commande qui a échoué : garde le MÊME nom** — n'invente
  jamais `gh-auth2`, `gh-auth-retry`… (sinon les panes s'empilent : déjà vu 15
  panes dont 3 utiles). crun t'avertit si une commande identique tourne déjà.
- Au début de chaque tâche impliquant des long-running, fais `crun cleanup`
  d'abord pour partir propre.
- Après chaque lancement, **annonce** à l'utilisateur où ça tourne :
  « ✓ dev-server démarré dans la `sandbox` — `crun list` pour voir, ou
  Alt+2 pour basculer ».
- Si l'utilisateur demande « arrête X » → `crun kill X`.
- Si l'utilisateur demande « qu'est-ce qui tourne » → `crun list`.
- Avant de relancer un agent existant, `crun` tue automatiquement l'ancien
  (dédup par nom) — pas besoin de gérer ça toi-même.

**Commandes interactives (auth, mot de passe, device-code, confirmation
navigateur, login, sudo) — c'est LE cas idéal pour `crun`, pas pour `! …`** :
- Lance-la **toi-même dans un pane `crun`** dédié, puis dis à l'utilisateur
  d'aller valider dans la `sandbox` (Alt+2) : il a accès au terminal séparé,
  il y saisit le code / mot de passe / confirme directement. Ne lui demande
  JAMAIS de relancer lui-même avec `!` ce que tu peux mettre en `crun`.
- Ex. : `crun gh-auth -- gh auth refresh -s read:project` → « ✓ gh-auth lancé
  dans la `sandbox` (Alt+2) : copie le code et valide dans le navigateur ».

**Ne mets en `crun` qu'une commande dont tu es sûr de la syntaxe** : crun n'est
pas un bac à sable pour « essayer ». Si un flag/une option est incertain,
vérifie (`--help`) ou teste l'invocation **inline une fois** (avec `2>&1`)
AVANT. Une commande mal formée meurt au lancement → pane ○, erreur perdue,
allers-retours gâchés.

**Si un agent passe ○ (mort) alors que tu l'attendais vivant : il a échoué.**
Lis l'erreur avec **`crun logs <name>`** (le pane reste ouvert avec sa sortie) —
ne relance JAMAIS à l'aveugle en re-devinant un flag.

## Patterns long-running à passer par `crun`

- **Serveurs dev** : `npm run dev|start|serve`, `next dev`, `vite`, `nuxt dev`,
  `flask run`, `uvicorn ...`, `rails s`, `python -m http.server`,
  `cargo run` pour un serveur
- **Brokers / daemons** : `mosquitto -v`, `redis-server`, `mongod`,
  `docker compose up` (sans `-d`)
- **Watchers** : `jest --watch`, `vitest`, `pytest --watch`, `cargo watch -x test`,
  `tsc -w`, `nodemon`, `*--watch`
- **Builds longs** (>30s estimé) : `cargo build --release`, `docker build`,
  `mvn test`, `gradle test`
- **Streams / logs** : `tail -f`, `journalctl -f`, `docker logs -f`
- **TUI interactifs** : `htop`, `btop`, `lazygit`, `cypress open`,
  `playwright codegen`
- **Graphify watch** : `graphify --watch <path>` ou
  `python3 -m graphify.watch <path>` — reconstruit le graph en background
  quand les fichiers changent. Lance-le dans `zellij run --name graphify-watch`
  pour que l'utilisateur voie les rebuilds défiler.

## Knowledge graph (graphify)

Si tu vois un dossier `graphify-out/` à la racine du projet courant, **un
knowledge graph existe déjà**. Préfère le consulter aux greps successifs pour
les questions conceptuelles (« où est X implémenté ? », « comment Y et Z
sont-ils liés ? »).

Commandes utiles :

```bash
graphify query "QUESTION"                    # traversal BFS, contexte large
graphify query "QUESTION" --dfs              # trace une chaîne précise
graphify path "Concept A" "Concept B"        # chemin entre 2 noeuds
graphify explain "Concept"                   # explication en clair d'un noeud
```

Pour reconstruire le graph après des modifs : `graphify --update` (incrémental,
ne re-scanne que les fichiers changés).

## thedev — vocabulaire & liens

Tu tournes dans **thedev** (l'app de dev zellij). Vocabulaire complet : **`NAMING.md`**
à la racine du repo config (`~/jlal_perso/config/NAMING.md`). En bref :
- **machine** → **espace** (1 projet sur 1 machine, tous pairs) → **pages** (`code page` +
  `sandbox`) → **panes**. Un **crun** = un pane lancé dans la sandbox. Les Claude sont
  tous **pairs** (pas de principal).

**Catalogue complet des commandes thedev** : `thedev-manifest` (ou `MANIFEST.md` à la
racine du repo) — liste exhaustive et à jour de TOUTES les commandes de l'app (générée
depuis les tags `@thedev`). Réflexe : si tu te demandes « est-ce que thedev sait faire
X ? », lis le manifest avant de réinventer. `thedev-status` = board cross-machine de
l'état (espaces ouverts, missions en cours, cruns) — l'utiliser pour voir ce qui tourne
sur les VPS sans ssh manuel.

**Liens entre espaces** (déléguer du travail entre 2 machines, en interactif → sur
l'abonnement, PAS `claude -p` qui coûte des crédits depuis juin 2026) :
- **recevoir** : `thedev-link open` ouvre l'espace courant aux missions (watcher dans la
  sandbox). `thedev-link status` / `close`.
- **envoyer** : `mission <machine>/<espace> "<txt>"` (attend le résultat) ;
  `mission ls <machine>` (espaces joignables). Détails : `plans/thedev-liens.md`.
- ⚠️ Préfère **toujours l'interactif** (cruns, liens) à `claude -p` pour le travail
  d'agent : `-p` puise dans le pool de crédits ($100/mois Max 5x), l'interactif non.

## Briques composables (déployer / exposer un service)

Pense en **petites briques réutilisables** plutôt qu'en gros scripts dédiés :
- **`ship <machine> [src] [dest]`** — pousse un dossier local vers une machine (rsync/SSH),
  **respecte le `.gitignore`** (pas de `node_modules`/`.next`/`.env` envoyés), `.git` exclu.
  Affiche le chemin distant. Réutilisable : déployer, sauvegarder, partager un build.
- **`tsnode <nom> <port>`** — expose un service `127.0.0.1:<port>` en HTTPS public via
  Tailscale Funnel (1 nœud = 1 sous-domaine `.ts.net`). Tourne **sur la machine** où vit
  le service. `tsnode list|off|rm`.
- **`crun`** = run, **`mission`** = déléguer (cf. ci-dessus).

**« expose ce service en public »** (depuis le local) se compose, sans script monolithe :
1. `ship <vps> .` → chemin distant.
2. `mission <vps>/<espace> "cd <chemin>, lance le service en crun bindé sur 127.0.0.1:<port>,
   puis tsnode <nom> <port>, et rends-moi l'URL"`.

L'étape « run » varie selon le projet (npm/python/docker) → c'est le rôle de la **mission**
(le Claude distant trouve la bonne commande), pas d'un verbe figé. ⚠️ Sur un VPS partagé/de
maxime : binder **`127.0.0.1` uniquement**, exposer **seulement** via tsnode (jamais toucher
les services existants).
