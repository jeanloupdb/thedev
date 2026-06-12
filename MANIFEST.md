# thedev — manifest

> **Généré** par `thedev-manifest` depuis les tags `# @thedev` des scripts `bin/`.
> Ne pas éditer à la main. Régénérer : `thedev-manifest --write`. 20 commandes.

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
- **mission** — envoie une mission a un espace distant et attend le resultat (--model)
- **ship** — pousse un dossier local vers une machine (rsync, respecte gitignore)
- **thedev-link** — ouvre un espace aux missions entrantes (watcher inbox, modele via Model:)
- **thedev-status** — board cross-machine compact (espaces ouverts, missions en cours, cruns)

### Liens — déprécié
- **cremote** — commande claude one-shot distante (DEPRECATED: claude -p = pool credits, prefere mission)

### Exposition réseau
- **tsnode** — expose un service local 127.0.0.1 en HTTPS public (Tailscale Funnel)

### Infra
- **heartbeat-run** — heartbeat autonome (DORMANT, coupe 2026-06 pour cout)
- **thedev-manifest** — genere le manifest de thedev depuis les tags @thedev des scripts bin/

## Capacités composables

Ce que tu peux *faire* en combinant les briques (au-delà des commandes prises une à une) :

- **Exposer n'importe quel site/service en public, via un VPS** : `ship <vps> .` (pousse le code) → `mission <vps>/<espace> "lance-le bindé sur 127.0.0.1:<port> puis tsnode <nom> <port>"` → URL `https://<nom>.<tailnet>.ts.net` publique (Tailscale Funnel, sans ouvrir de port ni toucher au reste du serveur). Marche même depuis une machine sans IP publique.
- **Déléguer un vrai chantier à une autre machine** : `mission [--model <m>] <machine>/<espace> "…"` — le Claude distant peut lui-même lancer un workflow (armée d'agents), sur l'abonnement. `TIMEOUT=0` pour un chantier long.
- **Voir l'état de tout le parc d'un coup d'œil** : `thedev-status` (espaces ouverts, missions en cours, cruns vivants/morts par machine) sans ssh manuel.
- **Plusieurs Claude en parallèle dans un espace** + les **retrouver après un quit** (asides + registre de reprise).

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
