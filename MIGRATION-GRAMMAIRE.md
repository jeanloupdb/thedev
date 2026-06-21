# Migration vers la grammaire d'armée — plan d'attaque

Issu de l'audit automatisé (workflow `thedev-army-audit`, 10 sous-systèmes, 12 agents).
Read-only à ce stade : **rien n'est encore modifié.** Doctrine : [`VISION.md`](VISION.md) §« Diriger une armée d'agents ».

## Principe

La grammaire d'armée est le **lexique interne de thedev**, pas un nouveau nom de produit.
`thedev` reste le produit ; `Claude` reste le moteur ; on renomme le **substrat** et on ajoute
la **couche de commandement**. Le plat reste la loi *dans* une équipe ; la hiérarchie est l'axe
vertical *entre* équipes.

## Grammaire — substrat (renommages)

| Actuel | Armée | Alias rétro-compat | Note |
|---|---|---|---|
| espace (concept, `$esp`, colonnes, dict) | **équipe** | non (code interne) | ~200 occ. ; producteur+consommateur même commit |
| `crun` (binaire + sous-cmd) | **soutien** | **oui, PERMANENT** | binaire le + tapé, lu par le prompt de chaque session + réseau missions |
| `dev-picker` | **état-major** | oui | chemins absolus à éditer en plus |
| `dev-claude-reg` | **reg-soldat** | oui | 6 call-sites atomiques |
| cache `dev-claude-*` | **soldat-\*** | non (fallback lecture) | écrit par `claude.sh`, lu par 5 binaires — rename atomique |
| `claude-aside` / `aside` | **renfort** | oui | bind Alt+c + alias shell à aligner |
| `claude-pane` | **soldat-pane** | oui | garde `claude` à l'intérieur (le moteur) |
| `space-open` | **team-open** | oui | dossier d'état reste `spaces/` physique |
| `new-project` (+ skill) | **lever-equipe** | oui | — |
| `dev-quit-menu/impact` | **debrief-menu/impact** | oui | câblé Ctrl+Q dans config.kdl |
| `thedev-autos` | **garde-list** | oui | ⚠️ filtre systemd `*thedev*` à migrer par VPS |
| `heartbeat-run` | **garnison-run** | oui | dormant |
| `agents-welcome` + pane `welcome` | **garnison** (accueil) | oui | contrat `.id` à migrer des 2 côtés |
| `mission result` / `.result` | **debrief** (surface) | oui (sous-cmd) | suffixe `.result` **reste sur disque** (protocole cross-machine) |

### Gelés — NE PAS renommer (décisions dures de l'audit)

- **`thedev`** — nom du produit ; tag `@thedev` pilote l'install + filtre systemd.
- **`Claude`** — le moteur partout (proc `pgrep -x claude`, modèle, env `CLAUDE_PANE_*`, `--resume`, statusLine). « soldat » **uniquement en prose**, tri manuel, jamais de `sed` global.
- **`engine`** — déjà « le moteur » conceptuel ; hardcodé dans dev.kdl + 6 modules, zéro gain à renommer.
- **chemins physiques `~/.cache/thedev/spaces/` et `/links/`** — protocole disque accordé au bit près entre 2 machines (mission ↔ thedev-link). Surface dit « équipe », disque garde `spaces/links`.
- **binaires méta** `thedev-status/doctor/metrics/manifest/propose` — appelés par chemin absolu + SSH + install.
- **`ship` / `tsnode`** — pas d'équivalent ; tsnode crée des units systemd + nœuds Tailscale (risque réseau).
- **tabs `sandbox` / `code page` / `my space`** — matchés par égalité exacte + garde-fou anti-fermeture. **GELÉS tant que le général n'a pas tranché un mot** (→ question ouverte).
- noms de **fichiers .md** (NAMING/VISION/MANIFEST/README) — refs croisées ; on réécrit le **contenu**, pas le nom.

## Grammaire — couche commandement

| Terme | Sens | Statut |
|---|---|---|
| **général** | toi (l'humain), seul donneur d'intention au sommet | rôle doctrinal |
| **soldat** | une instance Claude qui bosse dans une équipe (pairs entre eux) | existe (substrat soldat-\*) |
| **équipe** | une session/espace = unité plate de soldats pairs | existe |
| **chef** | commande des équipes sur l'axe vertical (au-dessus, jamais dedans) | **à créer** |
| **ordre** | directive descendante d'un chef vers une équipe | **à créer** |
| **raid** | présence du général *dans* une équipe | **à créer** (alias sur `dev`) |
| **débrief** | remontée à la sortie d'un raid / d'une mission | **à créer** (surface) |
| **garde** | les automatisations distantes (timers systemd) | existe |
| **garnison** | le mode headless | existe (dormant) |
| **état-major** | le picker / accueil / vue de flotte | existe |

## Les 11 agents de migration, en 5 vagues

- **Vague 1 — vocabulaire, zéro risque runtime** : `A1` docs (prose), `A2` prompt runtime (`zellij-pane-prompt.md`, garde `crun` tant que l'alias n'existe pas), `A4` vocabulaire code interne (espace→équipe, dict producteur+consommateur même commit).
- **Vague 2 — le pivot** : `A6` `crun`→`soutien` + **alias permanent posé EN PREMIER** + migration cache `claude-agents`→`thedev-soutien` (double-lecture).
- **Vague 3 — cœur substrat (filets posés)** : `A7` cluster cache `soldat-*` + `reg-soldat` + contrat welcome (atomique, hors session live, double-lecture) ; `A8` binaires doctrinaux (chacun avec symlink rétro-compat) ; `A5` régénère le MANIFEST.
- **Vague 4 — câblage chemins absolus** : `A9` dev.kdl + config.kdl + settings.json + hook `soldat-track.sh` (backup + `jq empty`, tabs gelés).
- **Vague 5 — propagation & ajouts** : `A10` sync config→thedev + push + pull/re-install VPS + settings.json physique par machine + units systemd `garde` + marqueurs `.bashrc` ; `A3` réécriture fiches vps-context (après le substrat) ; `A11` primitifs `chef`/`ordre`/`raid`/`débrief`.

## Filets transverses (non négociables)

1. **Alias rétro-compat AVANT tout retrait** — on ne supprime un ancien nom qu'après un cycle complet de déploiement + nouvelle session.
2. **Jamais casser la session live** — `crun`/`engine`/`reg`/hook tournent ici et maintenant ; créer nouveaux noms + alias avant retrait ; renames de cache hors session active ou en double-lecture.
3. **Chemins absolus non couverts par alias** (dev.kdl, config.kdl, settings.json, SSH `$me __probe`, thedev-doctor) — édition physique.
4. **settings.json** — pas un symlink (mode 600, skip-worktree VPS) → édition physique par machine + `jq empty` + `.bak`.
5. **Caches partagés** — rename atomique multi-binaire + fallback lecture un cycle + migration des fichiers existants.
6. **Double dépôt** — un `git mv` côté config crée un fichier que `sync-from-config.sh` ignore → `git add` côté thedev une fois ; docs racine renommées à la main dans chaque dépôt.
7. **VPS par git uniquement** (jamais scp) — `pull --rebase --autostash` + re-install.
8. **Units systemd `garde`** — migrer la `Description *thedev*` par machine (casse silencieuse sinon).
9. **Backups** avant dev.kdl/config.kdl/settings.json ; tester `team-open` sur une session jetable d'abord.

## Décisions qui reviennent au général (avant exécution)

1. **Mots pour les 3 pages** (`sandbox`, `code page`, `my space`) — le lexique n'en fournit pas ; gelés tant que non tranchés.
2. **Forme de `chef` / `ordre`** — binaires dédiés, ou sous-commandes au-dessus de `mission` ?
3. **`lien` / `thedev-link`** — garder « lien » comme canal entre équipes, ou l'intégrer à chef/ordre ? (le binaire reste `thedev-link` en alias quoi qu'il arrive)
4. **`cremote`** (déprécié, `claude -p`) — geler tel quel ou supprimer pendant le rename ?
5. **Politique de retrait des alias** — `crun` recommandé **permanent** ; les autres, après combien de cycles ?
