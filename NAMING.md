# Vocabulaire thedev — la grammaire d'armée

Langue commune de thedev. À utiliser partout — code, commits, échanges, docs.
Doctrine complète : [`VISION.md`](VISION.md) §« Diriger une armée d'agents ».

## Le principe

- **Le plat est la loi *dans* une équipe** : les soldats d'une même équipe sont **pairs**, ils bossent ensemble sans chef interne.
- **La hiérarchie est l'axe vertical *entre* équipes** : un **chef** est au-dessus d'une ou plusieurs équipes, **jamais dedans**.
- **Toi = le général**, la racine de tout. Tu peux court-circuiter n'importe quel niveau ; la chaîne s'informe, elle ne t'autorise pas.

## Hiérarchie

**Substrat :** thedev → machine → **équipe** → pages → panes
**Commandement :** général → chef → équipe → soldat

| Terme | Définition | (ancien nom) |
|---|---|---|
| **thedev** | L'app elle-même (lancée par `dev`). Nom du produit — ne change pas. | — |
| **machine** | Une bécane qui fait tourner thedev : local, jlax, indice. | — |
| **équipe** | Une instance de thedev = **1 projet sur 1 machine**. Un groupe de **soldats pairs**. | espace |
| **soldat** | Une instance d'agent (Claude) qui bosse dans une équipe. Tous **pairs** au sein de l'équipe. *(« Claude » reste le nom du moteur ; « soldat » = l'instance qui bosse.)* | un Claude |
| **chef** | Commande des équipes sur l'axe vertical — au-dessus, **jamais dedans**. | *(nouveau)* |
| **état-major** | L'écran d'accueil (le picker). Là où le général voit toutes les équipes avant d'entrer. Modes : **Équipes** / **Fichiers** / **Infos**. | accueil / dev-picker |
| **page** | Un onglet (tab zellij) d'une équipe. Trois pages : **le front** + **le camp** + **la tente**. | page |
| **pane** | Une zone dans une page (terme zellij conservé). | — |
| **soutien** | Un process long lancé dans **le camp** (un serveur, un watcher, un agent…). Commande : `soutien` (alias `crun` **permanent**). | crun |

## La couche commandement

| Terme | Sens |
|---|---|
| **général** | Toi. Seul donneur d'intention au sommet. |
| **soldat** | Une instance qui bosse dans une équipe (pairs entre eux). |
| **équipe** | Une session = unité plate de soldats pairs. |
| **chef** | Commande des équipes (axe vertical). Commande : `chef`. |
| **ordre** | Directive descendante d'un chef vers une équipe. Commande : `ordre`. |
| **raid** | La présence du général *dans* une équipe (alias de `dev`). |
| **débrief** | La remontée à la sortie d'un raid ou d'une mission. |
| **garde** | Les automatisations distantes (timers) — les rondes qui se répètent. |
| **garnison** | Le mode headless — un soldat qui tient la position sans interface. |
| **état-major** | L'accueil / la vue de flotte. |

## Les trois pages d'une équipe

- **le front** — le travail piloté par l'IA. Panes : éditeur (nvim) + les soldats (+ barre ＋ pour appeler un **renfort**). *(ancien : code page)*
- **le camp** — là où tournent tous les **soutiens** (serveurs, watchers, agents lancés, watcher de liens). *(ancien : sandbox)*
- **la tente** — les terminaux perso du général, à la main : **shell** + **git**. Territoire humain, hors de portée des soldats. *(ancien : my space)*

## Entre équipes (réseau + commandement)

- **lien** — connexion entre deux équipes.
- **mission** — un objectif confié à une équipe distante (délégation **horizontale**, de pair à pair).
- **débrief** — ce que l'équipe distante renvoie (la remontée). *(ancien : résultat)*
- **ordre** — directive **descendante** d'un chef (axe **vertical**), distincte de la mission.

> **Le plat et le vertical coexistent.** Deux équipes sœurs restent **pairs** (elles ne se commandent pas l'une l'autre) ; elles reportent à un **chef**, d'un autre rang. La grammaire d'armée **ajoute** l'axe vertical au modèle plat horizontal — elle ne le remplace pas.
