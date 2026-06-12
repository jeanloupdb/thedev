# Plan — thedev liens (réseau d'espaces pairs, sans `-p`)

> Vocabulaire : voir `NAMING.md`. But : déléguer du travail entre espaces **sur des
> machines différentes**, en **interactif** (abonnement) plutôt que `claude -p` (pool
> de crédits, depuis le 15/22 juin 2026).

## Principe
Un **espace** (sur une **machine**) ouvre un **lien** vers un autre espace et lui
envoie une **mission** ; l'espace distant l'exécute dans sa **sandbox** (cruns
interactifs → abonnement) et renvoie un **résultat**. Modèle **plat** (pairs).
Un lien est **toujours cross-machine** (transport **SSH**).

## Arborescence (par machine, `~/.cache/thedev/`)
```
links/<espace>                 ← REGISTRE : 1 fichier = 1 espace ouvert aux missions
spaces/<espace>/
  inbox/<id>.mission           ← missions reçues
  outbox/<id>.result           ← résultats à rendre (écrit atomique : .tmp puis mv)
  work/<id>/                    ← mission en cours (claim)
  done/<id>/                    ← archive (mission + résultat + log)
```

## Format (style email)
`inbox/<id>.mission` : en-têtes `From:` / `Created:` / `Timeout:` + ligne vide + corps.
`outbox/<id>.result` : en-têtes `Status:` (ok|error|timeout) / `Finished:` + corps.
L'apparition de `<id>.result` = signal « mission finie ».

## Cycle de vie
1. émetteur : `ssh` dépose `inbox/<id>.mission` sur la machine cible.
2. **watcher** (crun bash de l'espace cible) voit le fichier → claim → `work/`.
3. lance un **crun-mission** : `claude "<mission + 'écris le résultat dans outbox/<id>.result'>"`
   en **interactif** (abonnement) ; peut fanout en d'autres cruns.
4. le crun-mission écrit le résultat (dernier acte) → le watcher le voit → tue le pane, archive.
5. émetteur : poll `outbox/<id>.result` via ssh → lit → rend à son Claude.

> Exec interactif : crun-mission démarré avec la mission en **prompt initial**
> (`claude "<…>"`, pas `-p`). Fallback si le prompt positionnel ne s'auto-exécute
> pas : injection zellij `write-chars` en local dans le pane du crun-mission.

## Commandes
- `thedev-link open|close|status` — ouvre/ferme l'espace courant aux missions
  (lance/arrête son watcher + (dé)inscription registre). **Auto `open` sur VPS**, manuel en local.
- `mission <machine>/<espace> "<txt>"` — envoie, attend, rend le résultat.
- `mission ls <machine>` — liste les espaces joignables (lit le registre via ssh).

## Défauts v1 (validés)
- **Concurrence** : séquentiel (une mission à la fois par espace, file d'attente).
- **Timeout** : 10 min par défaut, surchargé par l'en-tête `Timeout:`.
- **Émetteur** : tourne dans un **crun** (non-bloquant, te ping au retour).

## Intégration
- sandbox : le watcher est un crun (visible dans `crun list`).
- accueil (mode Infos) : « Liens : ouvert/fermé » + missions en cours (v2 : `mission ls`).
- launcher `dev` : `thedev-link open` au démarrage d'un espace sur VPS.

## Sécurité
- Seul SSH livre les missions → seul le détenteur des clés (toi) peut envoyer. Zéro
  surface réseau ouverte.
- crun-mission en `jlal`, dans ta sandbox → périmètre. Sur jlax il lit `~/.claude/CLAUDE.md`
  natif → ne touche pas à maxime.
- ⚠️ mission = instructions exécutées en autonomie (`--dangerously-skip-permissions`).
  Garde-fou = la livraison passe par TON SSH (même confiance qu'une connexion manuelle).

## Identité d'un espace
espace = `$ZELLIJ_SESSION_NAME` (le nom de la session thedev). Adresse : `<machine>/<espace>`.
