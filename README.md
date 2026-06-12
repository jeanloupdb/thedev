# thedev

Une app de développement dans le terminal, bâtie sur [zellij](https://zellij.dev), pensée pour **travailler main dans la main avec Claude** (Claude Code). Tu lances `dev`, tu choisis un projet, et tu obtiens un espace structuré : un éditeur, une pile de Claude, une sandbox pour les process longs — plus de quoi **déléguer du travail entre machines** (missions cross-machine) et **voir d'un coup d'œil ce qui tourne** où.

## Modèle mental

**machine** → **espace** (1 projet × 1 machine) → **pages** (`code page` = éditeur + Claude · `sandbox` = agents/process longs · `my space` = tes terminaux) → **panes**.
Un **crun** = un process long-running dans la sandbox. Les espaces s'échangent des **missions**. Vocabulaire complet : [`NAMING.md`](NAMING.md).

👉 **Catalogue complet des commandes** : [`MANIFEST.md`](MANIFEST.md) (généré, toujours à jour) ou `./bin/thedev-manifest`.

## Installer avec l'IA (le plus simple)

1. Installe le CLI Claude : <https://docs.claude.com/claude-code>
2. Clone ce repo, entre dedans, lance `claude`, et donne-lui ce prompt :

   > Installe thedev sur cette machine. Lis le `README.md` et `MANIFEST.md`,
   > vérifie les dépendances avec `./bin/thedev-manifest --check-deps`, installe
   > celles qui manquent (mon OS : précise-le), lance `./install.sh`, puis
   > dis-moi comment démarrer `dev`.

Claude lit le repo, comble les dépendances et fait l'install. Tu n'as qu'à valider.

## Installer à la main

```bash
git clone https://github.com/jeanloupdb/thedev.git ~/thedev && cd ~/thedev
./bin/thedev-manifest --check-deps     # voir ce qui manque
./install.sh                           # symlinks + hook + source dans .bashrc
source ~/.bashrc                        # puis : dev
```

Sur un serveur : `./install.sh --vps=<label>` (badge rouge + Remote Control).

## Dépendances

`zellij`, `claude` (CLI), `nvim`, `python3`, `git`, `jq`, `fzf` (≥0.50), `inotify-tools`.
Optionnel : `tailscale` (exposition de service), `ssh`/`rsync` (liens cross-machine).
`./bin/thedev-manifest --check-deps` te dit lesquelles manquent.

## Config qui te concerne

- **`thedev-machines`** — tes hôtes ssh pour le board cross-machine. Pars de `thedev-machines.example` (le vrai est gitignoré).
- **`claude/vps-context/<label>.md`** — identité d'une machine, optionnelle (gitignorée). Liée à `~/.claude/CLAUDE.md` par `install.sh --vps=<label>` si présente.

## Licence

Usage personnel partagé tel quel, sans garantie.
