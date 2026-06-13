# thedev

Une app de dev en terminal (sur [zellij](https://zellij.dev)) pour piloter tes machines avec **Claude Code** — sur ton abonnement, sans rien exposer.

## Ce que tu peux faire

**Travailler avec l'IA**
- Lancer **plusieurs Claude en parallèle** dans un même espace de projet
- Claude en **autonomie** (permissions en bypass) : il agit sans te demander à chaque étape
- Des **panes auto-nommés** par sujet pour t'y retrouver entre 10 Claude
- **Retrouver tes Claude** là où tu les avais laissés après avoir fermé (reprise de session)

**Piloter tes machines**
- **Déléguer une mission** à un autre ordi / un VPS : il bosse pour toi, sur ton abonnement (pas d'API facturée)
- **Choisir le modèle** d'une mission (Fable / Opus / Sonnet…)
- **Voir l'état de tout ton parc** d'un coup d'œil (sessions, missions, process vivants) sans ssh manuel
- **Piloter une session VPS depuis l'app Claude** (téléphone / web), automatiquement
- **Pousser un dossier** vers une machine en une commande

**Automatiser & exposer**
- Faire **tourner et gérer des habitudes** par l'IA sur ton VPS (automatisations programmées, alertes Telegram)
- **Exposer un site/service local en HTTPS public** via ton VPS — sans ouvrir un seul port (Tailscale)
- Lancer et gérer **tout process long** (serveur, build, agent) dans une sandbox

**Garder le contrôle**
- Ton **usage Claude** (fenêtre Max 5x) + **RAM** + **CPU** sous les yeux en permanence, discret
- Une page **Infos / dashboard** : version, parc, usage, santé système
- **Tout sur ton abonnement** : 0 crédit API, 0 port ouvert, 0 clé — ton infra, tes règles

## Installer

**Avec l'IA** — installe le [CLI Claude](https://docs.claude.com/claude-code), clone le repo, lance `claude` dedans, et donne-lui :

> Installe thedev. Lis `README.md` et `MANIFEST.md`, vérifie les dépendances
> (`./bin/thedev-manifest --check-deps`), installe celles qui manquent, lance
> `./install.sh`, puis dis-moi comment démarrer `dev`.

**À la main :**

```bash
git clone https://github.com/jeanloupdb/thedev.git ~/thedev && cd ~/thedev
./bin/thedev-manifest --check-deps    # ce qui manque
./install.sh                          # puis : source ~/.bashrc && dev
```

Serveur : `./install.sh --vps=<label>`.

## Aller plus loin

- **Toutes les commandes** : [`MANIFEST.md`](MANIFEST.md) (généré) ou `./bin/thedev-manifest`
- **Vocabulaire** (machine / espace / page / pane / crun) : [`NAMING.md`](NAMING.md)
- **Dépendances** : zellij, claude, nvim, python3, git, jq, fzf, inotify-tools
