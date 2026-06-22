# zellij session context

Tu tournes dans un pane zellij, lancé par le layout `dev`
(`~/.config/zellij/layouts/dev.kdl`). La session (= une **equipe**) a trois
**pages** (onglets) — vocabulaire complet dans `NAMING.md` :

- **page `le front`** (territoire IA, partagé avec l'utilisateur) :
  - gauche (20%) : pane `editor` (nvim)
  - droite : la **stack des soldats** (`claude`, toi, focus) + la barre `＋ claude`
    pour ajouter un soldat secondaire (aside).
- **page `le camp`** (TON territoire) : c'est là que tu déposes tout ce que tu
  lances. Initialement un pane garnison `garnison`. Tes panes `soutien`
  atterrissent ici par défaut (et le watcher de liens y vit aussi).
- **page `la tente`** (territoire HUMAIN) : les terminaux perso de l'utilisateur,
  `shell` + `git` (git-centric, alias `g`/`gs`). **Ne pilote pas ces panes** sans
  raison — c'est sa main, pas la tienne.

L'utilisateur est full zellij + nvim — pas de VS Code. Quand tu écris dans un
fichier via Edit/Write, son nvim peut auto-reload (autoread).

## Nomme ton pane (pour naviguer entre plusieurs soldats)

L'utilisateur ouvre souvent plusieurs sessions dev en parallèle. Pour qu'il
s'y retrouve d'un coup d'œil, **garde le titre de TON pane à jour** avec un
libellé court qui résume le sujet courant :

```bash
pane-name "<2-3 mots>"
```

Donne juste le **texte du sujet**, sans glyphe. Un losange `◆` est ajouté
**automatiquement** devant ton titre quand tu es **en train de répondre**
(signal d'activité visible dans la stack), et retiré dès que tu rends la main —
tu n'as pas à le gérer. `pane-name` renomme le pane **et persiste** le libellé
pour ta conversation : si l'utilisateur quitte puis relance cette equipe, ton pane
retrouve son nom. (N'utilise pas `zellij action rename-pane` directement — il ne
persiste pas, et écraserait l'indicateur d'activité.)

Règles :
- **Nom par défaut : `claude`** (ou `claude [<vps>]` sur VPS). C'est l'état au
  démarrage et tant qu'aucun sujet ne se dégage. Tu ne bascules sur un sujet
  qu'une fois clair, et tu **reviens à `claude`** s'il n'y a plus de sujet précis.
- **2-3 mots max**, ce qui *différencie* cette conversation (le sujet précis).
- **Ne répète PAS le nom du projet/repo** — il est déjà connu (session/onglet).
  Mets l'action ou le composant en cours : `nommage panes`, `fix upload`,
  `refonte dashboard`.
- **Mets-le à jour quand le sujet bascule vraiment** (nouveau chantier), pas à
  chaque message. Pose-le dès que le sujet d'un échange se précise — et si le
  nom courant ne colle plus à la discussion, corrige-le : un nom périmé est
  pire que le défaut.
- Sur un **VPS**, le repère `[<vps>]` est inséré automatiquement par
  `pane-name` — donne juste `<2-3 mots>`.
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
zellij action go-to-tab-name "le front"
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

## `soutien` — la commande pour tout ce que tu lances

**Tu DOIS utiliser `soutien` au lieu de `zellij run` direct.** Il gère :
dédup par nom, registre des agents actifs, bascule auto vers la page `le camp`,
fermeture propre. Ne lance JAMAIS via `zellij run`, `cmd &`, ou
`run_in_background=true` quand l'utilisateur veut voir la sortie.

```bash
soutien <name> -- <cmd>              # lance dans le camp
soutien --tab <tab> <name> -- <cmd>  # tab spécifique (créée si absente)
soutien --floating <name> -- <cmd>   # pane flottant
soutien list                         # liste les agents (● vivant, ○ mort)
soutien kill <name>                  # tue un agent par nom
soutien cleanup                      # ferme les panes morts
```

**Discipline** :
- **AVANT de créer un soutien, fais `soutien list`** et regarde l'existant : s'il y a
  déjà un agent **similaire** (même but/commande), **réutilise son nom**
  (`soutien <ce-nom> -- …` → soutien remplace l'ancien) au lieu d'en créer un nouveau ;
  tue les inutiles (`soutien kill <name>`) et purge les morts (`soutien cleanup`).
  **Pour une relance d'une commande qui a échoué : garde le MÊME nom** — n'invente
  jamais `gh-auth2`, `gh-auth-retry`… (sinon les panes s'empilent : déjà vu 15
  panes dont 3 utiles). soutien t'avertit si une commande identique tourne déjà.
- Au début de chaque tâche impliquant des long-running, fais `soutien cleanup`
  d'abord pour partir propre.
- Après chaque lancement, **annonce** à l'utilisateur où ça tourne :
  « ✓ dev-server démarré dans `le camp` — `soutien list` pour voir, ou
  Alt+2 pour basculer ».
- Si l'utilisateur demande « arrête X » → `soutien kill X`.
- Si l'utilisateur demande « qu'est-ce qui tourne » → `soutien list`.
- Avant de relancer un agent existant, `soutien` tue automatiquement l'ancien
  (dédup par nom) — pas besoin de gérer ça toi-même.

**Commandes interactives (auth, mot de passe, device-code, confirmation
navigateur, login, sudo) — c'est LE cas idéal pour `soutien`, pas pour `! …`** :
- Lance-la **toi-même dans un pane `soutien`** dédié, puis dis à l'utilisateur
  d'aller valider dans `le camp` (Alt+2) : il a accès au terminal séparé,
  il y saisit le code / mot de passe / confirme directement. Ne lui demande
  JAMAIS de relancer lui-même avec `!` ce que tu peux mettre en `soutien`.
- Ex. : `soutien gh-auth -- gh auth refresh -s read:project` → « ✓ gh-auth lancé
  dans `le camp` (Alt+2) : copie le code et valide dans le navigateur ».

**Saisie CONFIDENTIELLE (clé API, secret, token, mot de passe à stocker) — TOUJOURS
un `soutien`, jamais le chat** : ouvre un pane `soutien` où l'utilisateur **colle directement**
(prompt masqué `read -rs`), et fais filer le secret par **stdin** vers sa destination
(`… | ssh <machine> 'cat > ~/.config/.../secret.env'`, `chmod 600`, hors git) — JAMAIS
dans la ligne de commande (argv), JAMAIS demandé en clair dans la conversation (ça resterait
dans le transcript). Tu **ne vois pas** la valeur : confirme par taille/permissions, pas par
le contenu. C'est le réflexe par défaut pour tout ce qui est confidentiel.

**Ne mets en `soutien` qu'une commande dont tu es sûr de la syntaxe** : soutien n'est
pas un bac à sable pour « essayer ». Si un flag/une option est incertain,
vérifie (`--help`) ou teste l'invocation **inline une fois** (avec `2>&1`)
AVANT. Une commande mal formée meurt au lancement → pane ○, erreur perdue,
allers-retours gâchés.

**Si un agent passe ○ (mort) alors que tu l'attendais vivant : il a échoué.**
Lis l'erreur avec **`soutien logs <name>`** (le pane reste ouvert avec sa sortie) —
ne relance JAMAIS à l'aveugle en re-devinant un flag.

## Patterns long-running à passer par `soutien`

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
- **machine** → **equipe** (1 projet sur 1 machine, tous pairs) → **pages** (`le front` +
  `le camp`) → **panes**. Un **soutien** = un pane lancé dans le camp. Les soldats sont
  tous **pairs** (pas de principal).

**Catalogue complet des commandes thedev** : `thedev-manifest` (ou `MANIFEST.md` à la
racine du repo) — liste exhaustive et à jour de TOUTES les commandes de l'app (générée
depuis les tags `@thedev`). Réflexe : si tu te demandes « est-ce que thedev sait faire
X ? », lis le manifest avant de réinventer. `thedev-status` = board cross-machine de
l'état (equipes ouvertes, missions en cours, soutiens) — l'utiliser pour voir ce qui tourne
sur les VPS sans ssh manuel.

**Liens entre equipes** (déléguer du travail entre 2 machines, en interactif → sur
l'abonnement, PAS `claude -p` qui coûte des crédits depuis juin 2026) :
- **recevoir** : `thedev-link open` ouvre l'equipe courante aux missions (watcher dans
  le camp). `thedev-link status` / `close`.
- **envoyer** : `mission <machine>/<equipe> "<txt>"` (attend le résultat) ;
  `mission ls <machine>` (equipes joignables). Détails : `plans/thedev-liens.md`.
- ⚠️ Préfère **toujours l'interactif** (soutiens, liens) à `claude -p` pour le travail
  d'agent : `-p` puise dans le pool de crédits ($100/mois Max 5x), l'interactif non.

## Briques composables (déployer / exposer un service)

Pense en **petites briques réutilisables** plutôt qu'en gros scripts dédiés :
- **`ship <machine> [src] [dest]`** — pousse un dossier local vers une machine (rsync/SSH),
  **respecte le `.gitignore`** (pas de `node_modules`/`.next`/`.env` envoyés), `.git` exclu.
  Affiche le chemin distant. Réutilisable : déployer, sauvegarder, partager un build.
- **`tsnode <nom> <port>`** — expose un service `127.0.0.1:<port>` en HTTPS public via
  Tailscale Funnel (1 nœud = 1 sous-domaine `.ts.net`). Tourne **sur la machine** où vit
  le service. `tsnode list|off|rm`.
- **`soutien`** = run, **`mission`** = déléguer (cf. ci-dessus).

**« expose ce service en public »** (depuis le local) se compose, sans script monolithe :
1. `ship <vps> .` → chemin distant.
2. `mission <vps>/<equipe> "cd <chemin>, lance le service en soutien bindé sur 127.0.0.1:<port>,
   puis tsnode <nom> <port>, et rends-moi l'URL"`.

L'étape « run » varie selon le projet (npm/python/docker) → c'est le rôle de la **mission**
(le soldat distant trouve la bonne commande), pas d'un verbe figé. ⚠️ Sur un VPS partagé/de
maxime : binder **`127.0.0.1` uniquement**, exposer **seulement** via tsnode (jamais toucher
les services existants).
