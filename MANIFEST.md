# thedev — manifest

> **Généré** par `thedev-manifest` depuis les tags `# @thedev` des scripts `bin/`.
> Ne pas éditer à la main. Régénérer : `thedev-manifest --write`. 27 commandes.

## Modèle mental

**machine** → **espace** (1 projet × 1 machine, tous pairs) → **pages** (`code page` = nvim + stack de Claude · `sandbox` = territoire agents/cruns · `my space` = terminaux humains) → **panes**.
Un **crun** = un pane long-running lancé dans la sandbox. Les espaces s'échangent des **missions** cross-machine (interactif, sur l'abonnement). Vocabulaire complet : `NAMING.md` · liens : `plans/thedev-liens.md`.

## Commandes

### Lancement (picker)
- **dev-picker** — selecteur de machine/projet au lancement (fzf, multi-serveurs)

### Session & panes
- **agents-welcome** — pane d'accueil de la sandbox (badge VPS)
- **aside-button** — barre + pour ajouter un Claude aside a la stack
- **claude-aside** — ouvre un Claude secondaire empile (aside) sans toucher la session
- **claude-pane** — lance le Claude principal d'un pane (surcouche prompt, remote-control, auto-open liens)
- **dev-quit-impact** — résumé COMPACT de ce que « fermer cet espace » va couper (Ctrl+Q).
- **dev-quit-menu** — menu de fermeture propre de la session
- **editor-pane** — pane nvim de la code page (badge VPS)
- **git-pane** — pane git-centric (alias g/gs)
- **shell-pane** — pane shell perso de my space (badge VPS)

### Nommage
- **pane-name** — nomme et persiste le titre d'un pane Claude (prefixe VPS auto)

### Registre
- **dev-claude-reg** — registre des Claude ouverts (resume + noms de pane persistants)

### Exécution (crun)
- **crun** — lance et gere tout process long-running dans la sandbox (dedup, vivacite, crun alive)

### Liens cross-machine
- **mission** — envoie une mission a un espace distant (async par defaut, result/list/cancel)
- **ship** — pousse un dossier local vers une machine (rsync, respecte gitignore)
- **thedev-autos** — état des automatisations thedev de CETTE machine (timers systemd --user)
- **thedev-link** — ouvre un espace aux missions entrantes (watcher inbox, modele via Model:)
- **thedev-status** — board cross-machine compact (espaces ouverts, missions en cours, cruns)

### Liens — déprécié
- **cremote** — commande claude one-shot distante (DEPRECATED: claude -p = pool credits, prefere mission)

### Exposition réseau
- **tsnode** — expose un service local 127.0.0.1 en HTTPS public (Tailscale Funnel)

### Infra
- **claude-window-usage** — % d'utilisation de la fenêtre de rate-limit Max 5x (5h/7d) — GRATUIT
- **heartbeat-run** — heartbeat autonome (DORMANT, coupe 2026-06 pour cout)
- **thedev-manifest** — genere le manifest de thedev depuis les tags @thedev des scripts bin/
- **thedev-metrics** — métriques limitantes locales (RAM/disque/load) — source unique
- **thedev-propose** — proposeur de tâches par signaux (parc git + todos + autos) — zéro IA, zéro coût

### Autres
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
