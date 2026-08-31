# thedev — manifest

> **Généré** par `thedev-manifest` depuis les tags `# @thedev` des scripts `bin/`.
> Ne pas éditer à la main. Régénérer : `thedev-manifest --write`. 53 commandes.

## Modèle mental

**machine** → **equipe** (1 projet × 1 machine, tous pairs) → **pages** (`le front` = la sidebar + la stack des soldats · `le camp` = territoire la garde/soutiens · `la tente` = terminaux humains) → **panes**.
Un **soutien** = un pane long-running lancé dans le camp. Les equipes s'échangent des **missions** cross-machine (interactif, sur l'abonnement). Vocabulaire complet : `NAMING.md` · liens : `plans/thedev-liens.md`.

## Commandes

### Lancement (etat-major)
- **etat-major** — selecteur de machine/projet au lancement (fzf, multi-serveurs)

### Session & panes
- **aside-button** — barre + pour ajouter un soldat aside a la stack
- **debrief-impact** — ce que « fermer cette equipe » va COUPER (Ctrl+Q) — un fait par ligne.
- **debrief-menu** — menu de fermeture propre de la session
- **editor-pane** — pane nvim de la code page (badge VPS)
- **garnison** — pane de garnison de la sandbox (badge VPS)
- **git-pane** — pane git-centric (alias g/gs)
- **lever-equipe** — crée un nouveau projet en déléguant le bootstrap à un soldat distant (VPS auto)
- **renfort** — ouvre un soldat secondaire empile (aside) sans toucher la session
- **shell-pane** — pane shell perso de my space (badge VPS)
- **sidebar** — sidebar — colonne gauche du front : menu cliquable (accueil, files, soldats, sessions…)
- **soldat-pane** — lance le soldat principal d'un pane (surcouche prompt, remote-control, auto-open liens)
- **team-open** — ouvre un equipe (local ou distant) DÉTACHÉ avec un soldat déjà briefé (prompt injecté)

### Nommage
- **claude-goto-waiting** — saute au pane soldat qui « t'attend » (QCM bloquant) — bind Alt+W
- **pane-name** — nomme et persiste le titre d'un pane soldat (prefixe VPS auto)
- **pane-pulse** — anime (pulse ◆↔◇) le titre des panes soldat en cours de réponse
- **wait-bar** — alerte rouge « action t'attend · Alt+W » dans la barre zjstatus

### Registre
- **reg-soldat** — registre des soldats ouverts (resume + noms de pane persistants)

### Exécution (soutien)
- **soutien** — lance et gere tout process long-running dans la sandbox (dedup, vivacite, soutien alive)

### Liens cross-machine
- **garde-list** — état de la garde thedev de CETTE machine (timers systemd --user)
- **mission** — envoie une mission a une equipe distante (async par defaut, result/list/cancel)
- **ship** — pousse un dossier local vers une machine (rsync, respecte gitignore)
- **thedev-link** — ouvre une equipe aux missions entrantes (watcher inbox, modele via Model:)
- **thedev-status** — board cross-machine compact (equipes ouvertes, missions en cours, soutiens)

### Liens — déprécié
- **cremote** — commande claude one-shot distante (DEPRECATED: claude -p = pool credits, prefere mission)

### Exposition réseau
- **tsnode** — expose un service local 127.0.0.1 en HTTPS public (Tailscale Funnel)

### Infra
- **claude-window-usage** — % d'utilisation de la fenêtre de rate-limit Max 5x (5h/7d) — GRATUIT
- **garnison-run** — heartbeat autonome (DORMANT, coupe 2026-06 pour cout)
- **pose** — règle la machine selon l'endroit où le PC est posé (lit / bureau)
- **thedev-doctor** — diagnostic d'installation : deps, scripts symlinkés, engine, hooks, lancement
- **thedev-manifest** — genere le manifest de thedev depuis les tags @thedev des scripts bin/
- **thedev-metrics** — métriques limitantes locales (RAM/disque/load/chaleur) — source unique

### Autres
- **arbre** (commandement) — arbre de commandement : l'arbre des equipes, groupe par domaine
- **blocage** (commandement) — blocages d'equipe : points ouverts qui s'ouvrent et se ferment
- **briefing** (commandement) — pousse le briefing (l'arbre carte) sur Telegram via tg
- **chef** (commandement) — chef — ouvre un Claude interactif briefé comme CE chef (convocable)
- **commandement-driver** (commandement) — pane de droite du cockpit commandement (lance le Claude chef briefé)
- **commandement-nav** (commandement) — navigateur de gauche du cockpit commandement (arbre → ouvre le chef à droite)
- **equipe** (commandement) — carte d'equipe + debrief-au-quit (brique 1 du plan commandement)
- **jalon** (commandement) — timeline d'equipe : jalons manuels ⊕ commits git (auto)
- **note** (commandement) — contexte d'equipe : une note = une ligne signee par un soldat
- **ordre** (commandement) — ordre — commande VERTICALE du général vers une équipe
- **ordres** (commandement) — ordres — les ordres REÇUS du général (côté machine cible)
- **partition** (commandement) — partition : range les équipes d'une machine en domaines par thème
- **remonter** (commandement) — remonte les cartes+debriefs locaux vers le sommet (VPS)
- **reorg** (commandement) — reorg — la respiration : scission/fusion d'etages (brique 3)
- **resume** (commandement) — resume d'equipe : LE headline partage qui remonte au chef
- **engine** (moteur) — façade moteur-agnostique : lance/liste/lit/observe un agent (voir ENGINE-ADAPTER.md)
- **thedev-landing** (ui) — landing animée du boot d'un pane claude — île nature + oiseaux
- **feed** (veille) — déclenche un feed (cron-as-mission) : dépose une mission locale dans l'inbox
- **inbox** (veille) — lit/cherche plusieurs boîtes IMAP (lecture seule, multi-comptes) — pour Claude & veilles
- **tg** (veille) — envoie texte/photo sur Telegram (Bot API, curl) — livraison des feeds & alertes
- **veille-tts** (veille) — synthèse vocale réaliste d'un texte via Gemini TTS (clé AI Studio)

## Dépendances externes

| Commande | Paquet | Portée | |
|---|---|---|---|
| `zellij` | zellij | core | requis |
| `claude` | claude CLI | core | requis |
| `nvim` | neovim | core | requis |
| `python3` | python3 | core | requis |
| `git` | git | core | requis |
| `jq` | jq | core | requis |
| `fzf` | fzf (>=0.50) | core | requis |
| `inotifywait` | inotify-tools | core | requis |
| `ssh` | openssh-client | liens | requis |
| `rsync` | rsync | liens | requis |
| `tailscale` | tailscale | expose | optionnel |

## Installation

- **Globale** (config perso complète) : `./install.sh [--with-deps] [--gnome] [--vps=<label>]`
- **thedev seul** (sans toucher .bashrc/.claude perso) : `./install-dev.sh [--vps=<label>]`
  — la liste des scripts installés est dérivée de ce manifest (`thedev-manifest --scripts`).
- **Vérifier les dépendances** : `thedev-manifest --check-deps`
