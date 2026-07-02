# Plan — la couche commandement (brique par brique)

Implémentation de la doctrine [`VISION.md`](../VISION.md) §« Diriger une armée
d'agents » et du vocabulaire [`NAMING.md`](../NAMING.md). On construit l'arbre
**par les racines**, pas par la cime.

## Le modèle, en une page

La hiérarchie est un **arbre n-aire auto-équilibré** (un B-tree *sémantique*) :

- Les **feuilles** sont de vraies équipes (1 projet / 1 machine), soldats pairs.
- **Un seul objet : le `chef`.** Convocable à tout moment (une session briefée,
  **pas** debout 24/7), il tient le **contexte agrégé** de tout son sous-arbre
  (sous-chefs ou équipes). Il se réveille sur événement (ordre à router, débrief à
  agréger, question), produit, se rendort. Coût ∝ activité.
- **Le « général en chef » n'est pas un type à part — c'est le `chef` à la racine**
  (sur le sommet). Des chefs partout, un seul tout en haut. Il existe dès qu'il y a
  quelque chose à commander ; ce qui « apparaît » à une scission, c'est un **étage**,
  pas le premier agent.

**Règle récursive de placement** (uniforme à chaque étage) :

```
une équipe naît, déclare sa carte, puis :
  chef dont le domaine colle ?
  ├─ OUI → place libre (< n) ?
  │        ├─ OUI → se brancher dessus.              ← cas courant, coût nul
  │        └─ NON → le chef déborde → le PARENT re-partitionne (scission DANS le domaine).
  └─ NON →
           total équipes ≤ n ?
           ├─ OUI → se brancher sur le chef le + proche (ou rester à plat sous le général).
           └─ NON → demander une réorg au général (il connaît l'arbre entier).
```

Invariants :

1. **Sémantique > capacité.** Si le bon chef est plein, on **scinde dans son
   domaine** (sous-chef du même domaine) — on ne fourre jamais l'équipe chez un
   chef qui a de la place mais ne colle pas. `n` est une *pression* qui déclenche
   la scission, pas un mur d'aiguillage.
2. **`n` = span de contrôle (~7), avec hystérésis.** Scinder à `n`, fusionner
   bien en dessous (~`n/2`) — jamais au même seuil, sinon l'arbre oscille.
3. **Croissance par split de racine (la racine reste toujours unique).** Quand la
   racine déborde, on ne la met **pas** en plusieurs pairs — on crée **un seul chef
   au-dessus** qui les contient : la hauteur monte de 1. C'est l'invariant B-tree
   (seul le split de la *racine* fait grandir la hauteur). Miroir en fusion : un
   chef sous le seuil est replié ; une racine à un seul vrai chef est **dissoute**
   (la hauteur baisse). Sans ça, tour de chefs vides = mur de coût.
4. **Un seul re-partitionneur par étage** : le parent (le chef-racine au sommet).
   Pas de réunion multi-sessions — le chef redessine la carte, seul, sur événement
   de débordement. La surcharge est **remarquée pendant une session quelconque** et
   la réorg **invoquée** là (pas de moniteur debout) : opportuniste, event-driven.

Le garde-fou de VISION reste la loi : la réorg déplace une équipe sous un autre
chef, elle ne change **jamais** la *mission* d'une équipe, et le général
court-circuite la carte à volonté.

## L'ossature figée (décision) — général → chef-machine → domaine → équipe

Le B-tree ci-dessus décrit la *mécanique* ; voici l'**ossature concrète, figée**,
qui la plaque sur le réel (machines + accès téléphone) :

- **Le général** — une **vraie session Claude sur le sommet** (le VPS toujours
  allumé, `thedev-sommet`). Point d'accès unique (téléphone → sommet). Il voit la
  flotte (`carte` agrégée) et commande vers le bas (`ordre`). **Convocable** :
  ouvert quand tu veux commander, pas debout 24/7.
- **Un chef par machine** — sous le général, **exactement un chef local par
  machine** (jlal-pc, indice…). C'est le **point d'entrée unique** d'une machine :
  le général commande une machine *à travers son chef-machine*, jamais N racines
  qui flottent. **Une machine ne peut pas avoir plusieurs chefs-racines.**
- **Le domaine organise *sous* le chef-machine** — domaine-d'abord s'applique
  **à l'intérieur** d'une machine (grouper ses équipes par projet). Le chef-machine
  est le niveau que voit le *général* ; le domaine, le niveau que voit le
  *chef-machine*.
- **L'équipe** — la feuille (1 projet / 1 machine, soldats pairs).

**Pourquoi machine avant domaine** : le **contrôle** et l'**accès** priment. Le
général (et le téléphone) ont besoin d'**un handle par machine**, pas d'un handle
par domaine éparpillé. Prix assumé : un domaine réparti sur 2 machines apparaît
sous 2 chefs-machine — l'unité cross-machine d'un projet cède le pas à l'unité de
contrôle.

La règle récursive (scission/fusion, seuils `n`, hystérésis) s'applique **dans le
sous-arbre d'un chef-machine** : trop de domaines sur une machine → son chef scinde
en sous-chefs de domaine ; la machine se vide → ils fusionnent. Le chef-machine,
lui, subsiste tant que la machine a des équipes.

---

## Où vit le sommet — plan de contrôle sur le VPS

Le sommet doit être **joignable en permanence** : une machine perso dort,
s'éteint, n'a pas d'IP stable, et un smartphone n'a ni shell ni git ni `claude`.
D'où : **un VPS toujours allumé tient la racine.**

Distinction qui sauve le coût — **plan de contrôle vs calcul** :

- **Le VPS = plan de contrôle** (léger, **sans IA debout**). Il détient trois
  choses : l'**état canonique** (arbre, cartes, débriefs remontés), le
  **rendez-vous joignable** (où smartphone et machines se parlent), la **file
  d'ordres** (ce que le général a décidé, en attente de consommation). Coût :
  quelques €/mois, **zéro** brûlage d'abo.
- **Les machines = le calcul.** Les soldats bossent là où sont le code et les
  outils. La machine est un **attribut de la feuille** (où elle tourne), **pas** un
  étage de commandement : chaque machine remonte ses cartes+débriefs au sommet et
  consomme les ordres qui l'attendent.
- **Le général se matérialise à la demande** (sur événement : ordre à router,
  réorg), lit l'état sur le VPS, produit, se rendort. Le VPS ne dort pas ;
  l'*agent*, si.

**Le premier étage est la MACHINE (décision figée — cf. § L'ossature figée).**
Le général voit **un chef par machine** ; le `command-fleet/<machine>/` est à la
fois la partition de **transport** (rsync `--delete` sans collision) **et** le
sous-arbre de ce chef-machine. Poser une équipe = ajouter une feuille sous **son
domaine, sous le chef de sa machine** ; le sommet assemble l'arbre
`général → chef-machine → domaine → équipe` depuis l'union des remontées. Un
domaine réparti sur 2 machines apparaît sous 2 chefs-machine — prix assumé de
l'unité de contrôle.

Les trois murs, assumés :

1. **Divergence d'état.** Les **cartes** voyagent en git (versionnées, in-repo) ;
   le VPS ne détient que le **miroir + inbox + débriefs** (jetable,
   reconstructible). Une seule source par type de donnée.
2. **Ordre à une machine offline.** Pas de RPC synchrone : l'ordre est **déposé
   dans la file du VPS**, consommé au réveil de la machine. File, pas appel
   direct — marche même smartphone → PC éteint.
3. **Sécurité de la porte.** Le smartphone parle au VPS **via Tailscale** (mesh
   privé), *pas* via Funnel public. Zéro surface exposée à l'internet ouvert.

Miroir du garde-fou de VISION (« le général n'est jamais prisonnier ») : **la
branche n'est jamais prisonnière du général**. Elle tourne seule si le sommet
dort et se resynchronise sans rien perdre. Les deux bouts de l'arbre sont
autonomes.

> Aujourd'hui (vérifié) : lancer un `thedev` inscrit juste le soldat dans un
> registre **plat** (`~/.cache/soldats`), rien ne remonte. Le seul geste vers le
> haut existant — `thedev-link open` — n'est **auto-déclenché que sur un VPS**
> (`soldat-pane`). Sur le PC, l'équipe est doublement muette. La cible ci-dessus
> = généraliser au PC le geste que seul le VPS fait déjà, pointé vers le VPS.

### La remontée cross-machine *(en cours)*

Réalisation concrète du sommet, en réutilisant le transport existant (**SSH**,
via les alias `~/.ssh/config` + le registre `~/.config/thedev-machines`).

- **Sommet déclaré** : `~/.config/thedev-sommet` (constante de flotte, versionnée
  + symliquée comme `thedev-machines`) = l'alias ssh du sommet. **Vaut `jlax`.**
  Vide/absent → cross-machine off, tout reste local (dégradation propre).
- **`remonter`** (machine → sommet) : `rsync -az --delete` du
  `~/.cache/thedev/command/` local vers `sommet:command-fleet/<machine>/command/`.
  **Un sous-dossier par machine** → `--delete` borné à son propre sous-arbre, zéro
  collision (les clés sont déjà `<machine>__<equipe>`). Best-effort : si le sommet
  dort, no-op, la prochaine remontée rattrape (file naturelle). La machine qui
  *est* le sommet (`dev-vps == thedev-sommet`) ne se pousse pas.
- **`carte` lit la flotte** : local `command/` **+** tous les
  `command-fleet/*/command/`, dédup par clé → l'**arbre complet, toutes machines**,
  groupé par domaine. Même renderer, données plus riches. Titre conscient du rôle
  (sommet vs vue locale).

**Déclencheur auto — posé.** Timer systemd `--user` (`thedev-remonter.timer` +
`.service`, versionnés + activés par `install.sh`) : `remonter` toutes les ~15 min
**tant que la session est ouverte** (`Linger=no` → tourne quand tu bosses, quand
les cartes/débriefs bougent — coût ∝ activité). `remonter` s'auto-neutralise sur
le sommet, donc les units sont uniformes sur toute la flotte.

DEHORS (suite) : le sens **descendant** enrichi (le sommet route un ordre vers une
feuille distante) reste `mission` tel quel ; et une remontée **événementielle**
(push juste après un débrief) en complément du timer, si la fraîcheur 15 min ne
suffit pas.

---

## Les surfaces — la carte + le pilotage

**Un arbre, plusieurs rendus.** L'arbre canonique vit **une seule fois** (plan de
contrôle, VPS). Toute vue n'est qu'une **peau** par-dessus. Ne jamais forker le
modèle : une seule vérité, des renderers interchangeables.

**Dans thedev** : la carte vit **dans l'accueil** (aperçu : ta branche + l'état
du lien au sommet), et une **commande `carte`** la déplie en grand (flottant) à
la demande. **Pas de nouvel onglet permanent.**

**En-tête d'accueil — trois états** :

- *branche, sommet joignable* → `● joignable`, entrée « ouvrir le tableau du
  général » (briefing + files d'ordres).
- *branche, sommet injoignable* → `○ injoignable`, **promesse rassurante** (pas
  une erreur) : « X débriefs + Y ordres en file, transmis dès que le sommet
  répond ». L'accueil local reste pleinement utilisable.
- *sur le VPS* → « tu es **au sommet** » + compteurs (machines reliées, équipes,
  ordres en attente).

**« Parler à un nœud » — 3 saveurs** (l'annuaire de l'arbre) :

- **feuille (équipe)** → un **ordre** / un fil ; consommé si up, mis en file si
  elle dort.
- **chef** → interroge le **rôle** : il répond depuis le **digest agrégé** de sa
  branche, **sans réveiller chaque feuille** (un seul réveil = une synthèse).
- **général** → le transverse (réorg, priorités du mois).

**Le contrat (à figer tôt, il porte toutes les peaux)** — le VPS n'expose que
**deux verbes** ; tout le reste est cosmétique :

1. `donne-moi l'arbre` → l'état de la hiérarchie (nœuds, statuts, digests).
2. `parle à ce nœud` → dépose un ordre / ouvre un fil vers une feuille, un chef
   ou le général.

**Staging des peaux** (même contrat, moteur unique — chaque étape *rhabille*, ne
réécrit rien) :

1. **Telegram** — *en cours, assemblé sur l'existant* (pas de nouveau moteur) :
   - **PUSH (donne-moi l'arbre)** — ✅ posé : `briefing` = `carte` → `tg` (Bot
     API, curl, réutilise `TELEGRAM_BOT_TOKEN`/`CHAT_ID` du canal existant).
     Envoyé pour de vrai. Sur le **sommet**, `carte` voit toute la flotte →
     briefing complet ; schedulable (cron/timer) pour le briefing du matin.
   - **PULL (parle à un nœud)** — le **bot officiel tourne déjà** et bridge DM →
     agent Claude (qui a `carte`/`mission` sous la main). Reste à polir les
     *verbes* (syntaxe courte « carte », « ordre <cible>: … ») → prochaine étape.
2. **Site Tailscale** — même contrat, rendu web privé (carte visuelle).
3. **App native** (but final) — même contrat ; n'apporte en propre que les
   notifications push natives (déjà couvertes par Telegram en attendant).

Le tableau du général est **actif**, pas seulement consultable : le but est de
*commander* l'armée depuis le téléphone, pas de la regarder.

*À trancher plus tard :* le rattachement au boot est-il **systématique** (chaque
`thedev` déclare son existence au sommet) ou **paresseux** (l'équipe reste muette
jusqu'à ce qu'un ordre/mission la concerne) ? Lean actuel : **déclaration
immédiate, placement paresseux** (se déclarer tant que l'arbre est plat, ne
chercher son chef qu'une fois des chefs nés).

---

## Brique 1 — la carte d'équipe + le débrief-au-quit *(le socle)* — ✅ POSÉE

Tout le reste opère là-dessus. Durable quoi qu'il arrive ensuite : c'est de
l'ops bash+fichiers, moteur-agnostique, à coût permanent **nul** (event-driven).

> **État : posée (tranche minimale).** Script `equipe` (`config/bin/equipe`,
> symliqué) : `equipe card` (lit `.thedev/equipe.md` ou dérive → miroir
> `~/.cache/thedev/command/equipes/<clé>.md`) et `equipe debrief` (flush dérivé
> zéro-IA → `debriefs/<clé>/<ts>.md`). Câblé dans le hook `soldat-track.sh` :
> SessionStart → carte, SessionEnd → débrief, gardé au **soldat principal d'une
> vraie équipe** (missions + asides exclus), best-effort non bloquant. Reste
> DEHORS de la tranche : le débrief **riche** via `debrief-menu` (le corps rédigé
> par le soldat à la sortie propre). Source de vérité = config ; non publié sur
> thedev (public) ; non commité.

### 1a. La carte d'équipe

**Principe : une équipe ne déclare que le *non-dérivable*.** Nom, machine, cwd,
branche, sujet courant, activité, nombre de soldats sont **déjà** dans
`~/.cache/soldats` (TSV) + git → jamais redéclarés. Restent à déclarer :
**domaine, résumé, statut, tags**.

**Source de vérité : `.thedev/equipe.md` à la racine du projet** — versionné,
voyage avec le dossier, éditable à la main ou par un soldat. **Optionnel** : si
absent, thedev dérive une carte minimale (nom + cwd + machine + branche) ; la
déclaration ne fait qu'**enrichir**. Zéro friction, mieux avec un peu.

Format — frontmatter YAML (champs machine-lisibles) + corps libre (contexte que
le chef et le briefing lisent) :

```markdown
---
domaine: indicefossile        # la clé de cluster — s'aligne sur `contexte`
                              # (proposals.json / état-major). C'est sur ce
                              # champ que le chef décide s'il contient l'équipe.
statut: actif                 # actif | pause | fini
tags: [carbone, fastapi, ciqual]
---

Backend distant qui calcule l'indice carbone d'un repas depuis la base CIQUAL.
Le produit a 3 surfaces (mobile, web, backend) ; cette équipe = le backend.
```

**Identité de l'équipe** (la clé du nœud, jamais déclarée — dérivée) :
`<machine>/<equipe>` où `machine` = `~/.config/dev-vps` ou `hostname -s`, et
`equipe` = `$ZELLIJ_SESSION_NAME` ou `basename "$(pwd -P)"`. Même résolution que
`thedev-link` / `soldat-track` — on ne réinvente pas.

**Miroir runtime** (ce que les chefs / le général interrogent) :
`~/.cache/thedev/command/equipes/<machine>__<equipe>.md`. Reconstruit depuis la
carte + le registre soldats à l'ouverture d'une équipe (même pattern que le hook
`soldat-track.sh` qui peuple `~/.cache/soldats`). La déclaration est durable
(in-repo) ; le miroir est jetable (in-cache).

Champ d'attachement : `chef: <machine>/<chef>` (ou vide = à plat sous le
général). **Présent dès la brique 1 mais non géré** — il sera écrit par la règle
récursive (brique 3). On pose le champ, on ne le remplit pas encore.

### 1b. Le débrief-au-quit

VISION L57 : *« même une fermeture brutale flushe un débrief minimal »*. À la
sortie d'une équipe, on flushe un artefact d'état que le chef lira en remontant.

**Emplacement :** `~/.cache/thedev/command/debriefs/<machine>__<equipe>/<ts>.md`.
Le plus récent = l'état courant vu d'en haut.

```markdown
---
equipe: local/indicefossile
quand: 2026-06-30T21:15:00+02:00
raison: detach            # detach | quit | crash
session: <sid>
---

## État
<une ligne : où ça en est, ce qui bloque>

## Changé
<git diff --stat résumé, ou les fichiers touchés>

## Ordres en cours
<si un ordre était actif — sinon « aucun »>

## Artefacts
- transcript : <chemin .jsonl>
- fichiers   : <liste>
```

Deux niveaux, selon la sortie :

- **Minimal (toujours, même crash)** — purement dérivé, zéro IA : id + timestamp
  + `raison` + dernier sujet (registre soldats) + `git status --short` + chemin
  du transcript. Écrit par le hook **SessionEnd** (`soldat-track.sh`, déjà câblé
  sur cet event).
- **Riche (sortie propre)** — le soldat rédige le corps (État / Changé / Ordres)
  avant de partir. Branché sur le flux gracieux existant **`debrief-menu`**
  (Ctrl+Q → détacher/fermer) : la branche « détacher » ou « fermer » déclenche
  la rédaction avant de couper.

**Compression (mur de VISION) :** le débrief *lie* les artefacts (transcript,
fichiers) au lieu de les recopier — re-creuser sans perte, avantage natif du
socle fichiers.

### Périmètre brique 1 — ce qui est DEDANS / DEHORS

DEDANS : le format `.thedev/equipe.md`, la dérivation de secours, le miroir
cache, le format de débrief, le câblage minimal (SessionEnd) + riche
(debrief-menu). Namespace neuf : `~/.cache/thedev/command/` (les `spaces/` et
`links/` existants ne bougent pas).

DEHORS (briques suivantes) : la règle récursive de placement (brique 3), le chef
comme rôle convocable + `ordre` qui descend (brique 2/3), la réorg par le
général. Voir map ci-dessous.

---

## Brique 2 — le digest + le routage *(en cours)*

Les **deux verbes du contrat** (cf. §Les surfaces) rendus réels sur le namespace
`~/.cache/thedev/command/` que la brique 1 alimente. Toujours event-driven,
**aucun chef debout**.

1. **`donne-moi l'arbre` → la commande `carte`.** Agrège toutes les cartes
   (`equipes/*.md`) et rend l'**arbre groupé par `domaine`**. L'**état** d'une
   équipe suit la **présence, pas le débrief** : si un soldat `claude` tourne dans
   son cwd (vérité-terrain du registre `~/.cache/soldats`, comme l'état-major), on
   affiche son **sujet + busy en direct** (`◆` répond · `●` au repos) — *sans rien
   fermer* ; sinon on retombe sur le **dernier débrief** (`○`, la mémoire d'une
   équipe fermée). Le débrief n'est donc **pas** la source d'état des équipes
   vivantes, seulement la pierre tombale des fermées.
   Tant que l'arbre est plat (pas de vrais chefs), **le `domaine` EST le
   proto-chef** : le regroupement par domaine préfigure l'étage des chefs sans le
   payer. Un seul renderer nourrit les trois usages : l'aperçu d'accueil, la
   commande `carte` dépliée, et — plus tard — les peaux téléphone.
2. **`parle à un nœud` (feuille) → `mission`.** Router un ordre vers une équipe
   existe **déjà** : `mission <machine>/<equipe> "<ordre>"` (transport
   `~/.cache/thedev/spaces/`, interactif = abonnement). Rien à rebâtir ; on
   *documente* que c'est la saveur « feuille » du verbe.

### Périmètre brique 2 — DEDANS / DEHORS

DEDANS (tranche minimale) : la commande **`carte`** (lecteur/agrégateur/renderer,
read-only, sans câblage → risque nul), groupée par domaine, avec statut + dernière
ligne d'état + ancienneté relative. Le routage feuille via `mission` (existant).

DEHORS : l'agrégation **cross-machine** (remonter les cartes des autres machines
vers le VPS — un problème de *transport/sync*, pas de rendu ; `carte` montrera
l'arbre complet automatiquement quand la donnée arrivera). Le **chef comme agent
convocable** qui digère *sa* branche et répond sans réveiller ses feuilles (saveur
« chef » du verbe) — n'a de sens qu'avec de la profondeur d'arbre → brique 3.

## Suite

- **Brique 3 — la respiration.** La règle récursive (placement, scission/fusion,
  seuils `n` + hystérésis), le re-partitionnement par le général, la naissance/
  dissolution d'étages, le chef-agent convocable. Ne paie son coût qu'à l'échelle
  (~8+ équipes).
