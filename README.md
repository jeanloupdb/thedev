<div align="center">

# thedev

### Pars à la conquête du monde avec une armée d'agents.

![Claude Code](https://img.shields.io/badge/Claude_Code-natif-D97757?logo=anthropic&logoColor=white)
![zellij](https://img.shields.io/badge/zellij-base-2563EB)
![Tailscale](https://img.shields.io/badge/Tailscale-0_port_ouvert-242424?logo=tailscale&logoColor=white)
![Bash](https://img.shields.io/badge/Bash-la_colle-4EAA25?logo=gnubash&logoColor=white)
![Abonnement](https://img.shields.io/badge/coût-abonnement_seul-22C55E)

<!-- DÉMO — génère le GIF puis décommente la ligne dessous :  vhs demo.tape  →  demo.gif -->
<!-- ![thedev — l'accueil : ton parc de Claude en un coup d'œil](demo.gif) -->

</div>

> **Sais-tu diriger des hommes ?** 3 ou 4, peut-être. Mais en 2030, avec l'IA, ce sera 100 ou 1000 : une armée obéissante et flexible, qui te connaît autant que tu la connais. **C'est thedev.**

Une armée trop libre ne sait plus où elle va, et ses soldats désertent jusqu'à ce que plus personne n'écoute les ordres. Une armée trop cadrée, elle, étouffe la moindre initiative sous la procédure, les validations, la paperasse. Tout l'art du chef tient dans cet équilibre — **faire confiance à ses soldats sans jamais lâcher la chaîne de commandement.**

**C'est ce chef que thedev te donne l'occasion de devenir.** Qu'ils soient 3 ou 300, tu connais chacun de tes soldats et tu sais où te placer dans la chaîne de commandement. Armée à coût fixe et réplicable plutôt que mercenaires payés au coup, la tienne tient sur ton **abonnement**, pas à l'API.

## 🚀 Installer

**Il n'y a pas d'inscription à thedev.** Pas de compte, pas de serveur à nous, pas
d'abonnement en plus : c'est un outil qui vit sur ta machine. Le seul compte dont tu as
besoin est celui de **Claude**. thedev pilote [Claude Code](https://claude.com/claude-code),
donc il te faut un abonnement Claude et la CLI connectée. Tout le reste est libre et gratuit.

thedev tourne sous **Linux**. Sur **Windows**, WSL fait tourner un vrai Linux à l'intérieur
de Windows : rien à partitionner, réversible en une commande.

<details>
<summary><b>Je suis sur Windows</b> : installer Linux d'abord (2 minutes)</summary>

<br>

Ouvre le **Terminal Windows en administrateur** (clic droit sur le menu Démarrer →
« Terminal (admin) » ou « PowerShell (admin) » selon ta version), puis :

```powershell
wsl --install
```

Redémarre quand Windows te le demande, ouvre **Ubuntu** depuis le menu Démarrer, et
reprends ci-dessous : tu es maintenant dans un Linux.
[Guide officiel Microsoft](https://learn.microsoft.com/windows/wsl/install)

</details>

### 1. Les outils

thedev est de la colle : il s'appuie sur des outils existants et n'en installe aucun
à ta place. Cette étape est donc obligatoire, y compris sur un WSL neuf.

```bash
sudo apt update && sudo apt install -y git python3 jq fzf inotify-tools neovim
mkdir -p ~/.local/bin && export PATH="$HOME/.local/bin:$PATH"

# zellij (le multiplexeur sur lequel thedev est bâti), absent des dépôts Ubuntu
curl -L https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz \
  | tar xz -C ~/.local/bin

# Claude Code
curl -fsSL https://claude.ai/install.sh | bash
claude   # connecte-toi à ton compte Claude, puis quitte avec /exit
```

### 2. thedev

```bash
git clone https://github.com/jeanloupdb/thedev
cd thedev && ./install.sh
source ~/.bashrc
```

### 3. Ouvrir un projet

```bash
dev
```

C'est la seule commande à retenir. Elle ouvre l'accueil : choisis **nouvelle équipe**,
pointe un dossier, et ton premier Claude démarre dedans.

> Quelque chose cloche ? **`thedev-doctor`** vérifie l'installation ligne par ligne et
> dit quoi relancer. Il ne répare rien tout seul, il diagnostique.

<details>
<summary>Ce que l'installation touche, et comment faire marche arrière</summary>

<br>

`install.sh` ne pose ni démon ni service. Il crée des liens symboliques (tout fichier
existant est sauvegardé en `.bak.<date>`) :

- les 50 commandes de thedev dans `~/.local/bin/`
- la config zellij : `~/.config/zellij/{config.kdl, themes/, layouts/, plugins/}`
- un bloc délimité dans `~/.bashrc` (c'est lui qui fournit la commande `dev`)
- le hook `soldat-track` fusionné dans `~/.claude/settings.json`

Pour tout retirer :

```bash
cd ~/thedev && ./bin/thedev-manifest --scripts | xargs -I{} rm -f ~/.local/bin/{}
rm -f ~/.config/zellij/config.kdl ~/.config/zellij/themes/muted.kdl \
      ~/.config/zellij/layouts/dev.kdl ~/.config/zellij/layouts/commandement.kdl \
      ~/.config/zellij/plugins
sed -i '/# >>> thedev >>>/,/# <<< thedev <<</d' ~/.bashrc
rm -rf ~/thedev
```

Les liens zellij pointent *dans* le dossier cloné : retire-les avant de supprimer
`~/thedev`, sinon zellij se retrouve avec une config qui ne mène nulle part. Si tu avais
déjà une config zellij, `install.sh` l'avait mise de côté en `.bak.<date>` — c'est là
qu'elle t'attend.

</details>

## 🎖️ L'arsenal

**Le socle**
- 🖥️ **App TUI, en arrière-plan** — tout vit dans le terminal (zellij) ; ça tourne détaché : tu fermes, tu te rebranches, c'est toujours là
- 📁 **Une session par dossier** — 1 projet = 1 équipe, modèle simple
- 🤖 **Claude Code natif** — le moteur tourne en interactif, sur ton abonnement
- 🐚 **Bash + fichiers** — la colle de l'outil : lisible, modifiable, auditable, pas de boîte noire
- 🛡️ **Tailscale** — réseau privé entre tes machines, 0 port ouvert
- 🐧 **Linux + nvim** — ou Windows via WSL ; TUI minimaliste, pensé pour ton poste de dev

**Commander ton armée**
- 👁️ **Vue du parc** — tous tes Claude et leur état d'un coup d'œil
- 🧩 **Claude en renfort** — autant d'agents que tu veux par espace
- 🏷️ **Auto-nommage** — les panes se nomment seuls au fil du sujet
- 🔌 **Reprise 1 clic** — reprends une session locale ou distante

**Tes machines, partout**
- 🌍 **Multi-machines** — poste + serveurs sous un même commandement
- 📨 **Missions** — envoie une tâche à un Claude distant (au modèle de ton choix)
- 🚚 **Partage entre machines** — des dossiers entiers, en respectant `.gitignore`
- 📲 **Pilotage à distance** — pilote ton serveur depuis l'app
- 🛰️ **Headless** — tourne en arrière-plan sur un serveur, sans interface
- ⏰ **Automatisations distantes** — des tâches rejouées dans le temps

**Tu gardes la main**
- ▶️ **Commandes longues** — terminal dédié pour `npm start`, builds, watchers
- 🖧 **Tes terminaux** — vois les logs, tape une commande sans l'IA
- 🙈 **Page « my space »** — un terminal privé, hors de portée de Claude
- 🧹 **Fermeture propre** — vois ce que tu coupes avant de fermer (Ctrl+Q)
- 📊 **Ressources en direct** — RAM, disque, CPU en permanence

**Sûr et souverain**
- 💳 **Sur ton abo** — sur l'abonnement Claude, zéro coût API
- 🔒 **Secrets hors chat** — mdp / clé / sudo sans que l'IA les voie
- 🌐 **Exposition 0 port** — publie un site HTTPS via Tailscale, sans ouvrir de port
- ⏳ **Fenêtre Claude 5h** — le % restant avant le rate-limit, en direct

<sub>Ex. d'automatisation : « sur mon VPS, chaque matin, génère un article + son podcast audio et envoie-moi le lien sur Telegram. »</sub>

## Aller plus loin

- **Pourquoi thedev existe (le cap durable)** : [`VISION.md`](VISION.md)
- **Toutes les commandes** : [`MANIFEST.md`](MANIFEST.md) (généré) ou `./bin/thedev-manifest`
- **État du parc en direct** : `thedev-status` · **usage Claude** : la barre en bas

---

<div align="center">

Fait pour coder avec Claude sans louer le cloud. ⭐ si ça te parle.

</div>
