<div align="center">

# thedev

**L'atelier de dev en terminal qui pilote toutes tes machines avec Claude — sur ton abonnement, sans rien exposer.**

![Claude Code](https://img.shields.io/badge/Claude_Code-natif-D97757?logo=anthropic&logoColor=white)
![zellij](https://img.shields.io/badge/zellij-base-2563EB)
![Tailscale](https://img.shields.io/badge/Tailscale-0_port_ouvert-242424?logo=tailscale&logoColor=white)
![Bash](https://img.shields.io/badge/Bash-la_colle-4EAA25?logo=gnubash&logoColor=white)
![Abonnement](https://img.shields.io/badge/coût-abonnement_seul-22C55E)

<!-- DÉMO : ajoute ici un GIF (vhs / asciinema → agg) du picker + du dashboard.
     C'est l'élément le plus important above the fold — il manque encore. -->

</div>

> [!IMPORTANT]
> La puissance d'un agent cloud, **chez toi** : **0 crédit API · 0 port ouvert · 0 clé**. Ton infra, tes machines, tes règles — et c'est lisible/auditable (bash + fichiers).

## ⚡ Installer (avec l'IA, en 1 minute)

Installe le [CLI Claude](https://docs.claude.com/claude-code), clone le repo, lance `claude` dedans, et colle :

> Installe thedev. Lis `README.md` et `MANIFEST.md`, vérifie les dépendances
> (`./bin/thedev-manifest --check-deps`), installe celles qui manquent, lance
> `./install.sh`, puis dis-moi comment démarrer `dev`.

<details>
<summary>… ou à la main</summary>

```bash
git clone https://github.com/jeanloupdb/thedev.git ~/thedev && cd ~/thedev
./bin/thedev-manifest --check-deps    # ce qui manque
./install.sh                          # puis : source ~/.bashrc && dev
```
Serveur : `./install.sh --vps=<label>`. Dépendances : zellij, claude, nvim, python3, git, jq, fzf, inotify-tools.
</details>

## Fonctionnalités

**thedev, c'est le OpenClaw / Ruflo / Hermes léger, sécurisé et Linux des devs** : pas un essaim d'agents API dans le cloud, mais ton terminal, tes machines, ton abonnement — auditable (bash + fichiers) et sans rien exposer.

Légende : ✅ oui · 🟡 partiel / autre approche · ❌ non

| Fonctionnalité | 🦞 OpenClaw | 🪽 Hermes | 🌀 Ruflo | 🖥️ **thedev** |
|---|:---:|:---:|:---:|:---:|
| 👁️ **Vue du parc** — tous tes Claude et leur état, organisés | 🟡 | 🟡 | 🟡 | ✅ |
| 🧩 **Claude en renfort** — autant de Claude que voulu par espace | ✅ | ✅ | ✅ | ✅ |
| 🔌 **Reprise 1 clic** — reprendre une session locale ou distante | 🟡 | ✅ | 🟡 | ✅ |
| 🏷️ **Auto-nommage** — les panes se nomment seuls au fil du sujet | ❌ | ❌ | ❌ | ✅ |
| 📁 **1 dossier = 1 session** — modèle simple, pas de boîte noire | ❌ | ❌ | ❌ | ✅ |
| 🖥️ **Multi-machines** — poste + serveurs en un seul espace | ❌ | 🟡 | ✅ | ✅ |
| 📨 **Missions** — envoyer une tâche à un Claude distant (choix du modèle) | 🟡 | ✅ | 🟡 | ✅ |
| 🚚 **Partage entre machines** — dossiers entiers, respecte `.gitignore` | ❌ | ❌ | ❌ | ✅ |
| 📲 **Pilotage à distance** — piloter ton serveur depuis l'app | ✅ | ✅ | 🟡 | ✅ |
| ▶️ **Commandes longues** — terminal dédié pour `npm start`, builds, watchers | ❌ | 🟡 | ❌ | ✅ |
| 🖧 **Tes terminaux** — voir les logs, taper une commande sans l'IA | ❌ | 🟡 | ❌ | ✅ |
| 🙈 **Page « my space »** — un terminal privé, hors de portée de Claude | ❌ | ❌ | ❌ | ✅ |
| 🔒 **Secrets hors chat** — saisir mdp / clé / sudo sans que l'IA les voie | ❌ | 🟡 | ❌ | ✅ |
| 🧹 **Fermeture propre** — voir ce qu'on coupe avant de fermer (Ctrl+Q) | ❌ | ❌ | ❌ | ✅ |
| 📊 **Ressources en direct** — RAM, disque, CPU affichés en permanence | ❌ | ❌ | 🟡 | ✅ |
| ⏳ **Fenêtre Claude 5h** — % restant avant le rate-limit, gratuit | ❌ | ❌ | ❌ | ✅ |
| 🌑 **Léger** — TUI minimaliste, thème noir | ❌ | ✅ | ❌ | ✅ |
| ⏰ **Automatisations distantes** — tâches rejouées dans le temps sur un serveur | ✅ | ✅ | ✅ | ✅ |
| 🛰️ **Headless** — tourne en arrière-plan sans interface sur un serveur | ✅ | ✅ | ✅ | ✅ |
| 🌐 **Exposition 0 port** — publier un site HTTPS via Tailscale, sans ouvrir de port | ❌ | ❌ | 🟡 | ✅ |
| 💳 **Sur ton abo** — fonctionne sur l'abonnement Claude, sans coût API | ❌¹ | ❌ | ❌¹ | ✅ |
| 💬 **Multi-messageries** — piloter depuis WhatsApp / Telegram / Discord / Signal… | ✅ | ✅ | ❌ | ❌² |
| 🧠 **Mémoire persistante** — contexte cumulé entre projets/sessions | 🟡 | ✅ | ✅ | ❌ |
| 🔧 **Self-improvement** — l'agent crée et améliore ses propres skills | 🟡 | ✅ | ✅ | ❌ |
| 🔀 **Multi-modèles** — 200+ modèles, pas que Claude | ✅ | ✅ | ✅ | ❌ |
| 📦 **Registre de skills** — installer des skills partagés par la communauté | ✅ | ✅ | ✅ | ❌ |
| 🌐 **Automation navigateur / voix** — piloter un browser, entrées vocales | ✅ | 🟡 | 🟡 | ❌ |

<sub>¹ OpenClaw et Ruflo fonctionnaient sur l'abonnement Claude (détournement de token / framework tiers) — Anthropic a bloqué cet usage le 4 avril 2026. thedev reste légitime via Claude Code interactif.</sub><br>
<sub>² thedev ne se pilote pas en textant un bot : son entrée à distance, c'est le **Remote Control de ta session Claude depuis l'app officielle** (voir Pilotage à distance). Telegram sert aux alertes/livraisons sortantes, pas de commande.</sub>

<sub>Ex. d'automatisation : « sur mon VPS, chaque matin, génère un article + son podcast audio et envoie-moi le lien sur Telegram. »</sub>

## Comment c'est organisé

```mermaid
flowchart LR
  M["machine"] --> E["espace<br/>(1 projet)"]
  E --> CP["code page<br/>éditeur + pile de Claude"]
  E --> SB["sandbox<br/>crun : process longs, agents"]
  E --> MS["my space<br/>tes shells"]
  E -. "mission" .-> V["autre machine / VPS"]
```

Une **machine** porte des **espaces** (1 projet chacun), chaque espace a des **pages** et des **panes**. Un **crun** = un process long dans la sandbox. Les espaces s'échangent des **missions**. Vocabulaire complet : [`NAMING.md`](NAMING.md).

## Aller plus loin

- **Toutes les commandes** : [`MANIFEST.md`](MANIFEST.md) (généré) ou `./bin/thedev-manifest`
- **État du parc en direct** : `thedev-status` · **usage Claude** : la barre en bas

---

<div align="center">

Fait pour coder avec Claude sans louer le cloud. ⭐ si ça te parle.

</div>
