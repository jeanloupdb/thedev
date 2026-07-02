# thedev — manifest

> **Généré** par `thedev-manifest` depuis les tags `# @thedev` des scripts `bin/`.
> Ne pas éditer à la main. Régénérer : `thedev-manifest --write`. 38 commandes.

## Modèle mental

**machine** → **equipe** (1 projet × 1 machine, tous pairs) → **pages** (`le front` = nvim + stack de Claude · `le camp` = territoire agents/soutiens · `la tente` = terminaux humains) → **panes**.
Un **soutien** = un pane long-running lancé dans le camp. Les equipes s'échangent des **missions** cross-machine (interactif, sur l'abonnement). Vocabulaire complet : `NAMING.md` · liens : `plans/thedev-liens.md`.

## Commandes

### Lancement (etat-major)
- **etat-major** — selecteur de machine/projet au lancement (fzf, multi-serveurs)

### Session & panes
- **aside-button** — barre + pour ajouter un soldat aside a la stack
- **debrief-impact** — résumé COMPACT de ce que « fermer cette equipe » va couper (Ctrl+Q).
- **debrief-menu** — menu de fermeture propre de la session
- **editor-pane** — pane nvim de la code page (badge VPS)
- **garnison** — pane de garnison de la sandbox (badge VPS)
- **git-pane** — pane git-centric (alias g/gs)
- **lever-equipe** — crée un nouveau projet en déléguant le bootstrap à un soldat distant (VPS auto)
- **renfort** — ouvre un soldat secondaire empile (aside) sans toucher la session
- **shell-pane** — pane shell perso de my space (badge VPS)
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
- **thedev-doctor** — diagnostic d'installation : deps, scripts symlinkés, engine, hooks, lancement
- **thedev-manifest** — genere le manifest de thedev depuis les tags @thedev des scripts bin/
- **thedev-metrics** — métriques limitantes locales (RAM/disque/load) — source unique
- **thedev-propose** — proposeur de tâches par signaux (parc git + todos + la garde) — zéro IA, zéro coût

### Autres
- **briefing** (commandement) — pousse le briefing (l'arbre carte) sur Telegram via tg
- **carte** (commandement) — carte d'etat-major : l'arbre des equipes, groupe par domaine
- **equipe** (commandement) — carte d'equipe + debrief-au-quit (brique 1 du plan commandement)
- **remonter** (commandement) — remonte les cartes+debriefs locaux vers le sommet (VPS)
- **engine** (moteur) — façade moteur-agnostique : lance/liste/lit/observe un agent (voir ENGINE-ADAPTER.md)
- **feed** (veille) — déclenche un feed (cron-as-mission) : dépose une mission locale dans l'inbox
- **tg** (veille) — envoie texte/photo sur Telegram (Bot API, curl) — livraison des feeds & alertes

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
