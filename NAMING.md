# Vocabulaire thedev

Langue commune de l'app de dev (zellij). À utiliser partout — code, commits, échanges.

## Hiérarchie
**thedev → machine → espace → pages → panes**

| Terme | Définition |
|---|---|
| **thedev** | L'app elle-même (lancée par `dev`). |
| **machine** | Une bécane qui fait tourner thedev : local (laptop), jlax, indice. |
| **espace** | Une instance de thedev = **1 projet sur 1 machine**. Les espaces sont **tous au même niveau (pairs)** — pas de hiérarchie, pas de maître. |
| **accueil** | L'écran de sélection (le picker, `dev-picker`). Ses **modes** : **Espaces** / **Fichiers** / **Infos**. |
| **page** | Un onglet (tab zellij) d'un espace. Trois pages : **code page** + **sandbox** + **my space**. |
| **pane** | Une zone dans une page (terme zellij conservé). |
| **crun** | Un pane lancé dans la **sandbox** (un Claude, un serveur, un watcher…). Commande : `crun`. |
| **Claude** | Juste un Claude. **Aucun rôle spécial** : ils sont tous pairs, où qu'ils tournent. |

## Les trois pages d'un espace
- **code page** — le travail piloté par l'IA. Panes : éditeur (nvim) + la stack des Claude (+ barre ＋ pour ajouter un Claude).
- **sandbox** — là où tournent tous les **cruns** (agents, serveurs, watchers, Claudes lancés, watcher de liens).
- **my space** — les terminaux perso de l'utilisateur, à la main : **shell** + **git**. Territoire humain, pas peuplé par Claude.

## Liens entre espaces (réseau de pairs)
- **lien** — connexion entre deux espaces.
- **mission** — ce qu'on envoie sur un lien.
- **résultat** — ce que l'espace distant renvoie.

> Modèle **plat** : un espace envoie une mission à un autre espace, de pair à pair.
> Ex. : « crée un lien vers l'espace indicefossile sur jlax, envoie-lui une mission :
> lance les tests ; il renvoie le résultat ».
