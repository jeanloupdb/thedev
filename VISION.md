# Vision

## Ce que c'est

thedev fait d'une **intention** un **résultat fini**, produit par des agents, **sur tes propres machines** — et te laisse aux commandes du tout.

Une session = un contexte borné (un TP, un projet perso, un backend en prod) où un agent télécharge, range, lance, déploie, et te rend un livrable. Toi tu décides, tu vérifies, tu possèdes. Tu ne *tapes* pas le travail : tu le **diriges** et tu en **réponds**.

## Le cœur (fixe)

C'est l'invariant. Il ne bouge pas — c'est l'étoile polaire de toutes les décisions.

> Une intention → une session où un agent fait le travail de bout en bout, sur la bonne machine → un résultat fini que tu possèdes, **toi aux commandes, sur ton infra, à coût maîtrisé**.

Et son centre de gravité durable : **pas** « l'agent exécute » — ça, les labos le rendront banal et gratuit, on le *consomme* — mais **tu gardes la main, la confiance et le coût** sur ce qu'il produit.

En une ligne : **thedev est l'instrument de la part qui ne s'automatise pas** — décider quoi faire, vérifier que c'est bon, posséder le résultat, en répondre.

## La surface (remplaçable)

Tout le reste est un habit de 2026, échangeable sans toucher au cœur :

- le terminal / zellij / la TUI
- Claude Code comme moteur
- le mot « dev »
- l'interface actuelle (picker, Remote Control, missions…)

Si un meilleur moteur sort, thedev l'adopte. Si l'interface devient vocale ou ambiante, le cœur tient quand même. Ne jamais confondre l'habit avec le corps.

## Le pari

Plus les modèles deviennent forts, plus on fait tourner d'agents en parallèle, plus le goulot se déplace :

- de **« est-ce que l'agent sait faire »** — résolu par les labos, de mieux en mieux —
- vers **« est-ce que je peux superviser, faire confiance, payer et orchestrer N agents sur mes machines »** — jamais résolu par les labos, parce que c'est contre leur intérêt (ils vendent le cerveau, pas ta tour de contrôle), et qui **grandit** avec l'autonomie.

thedev parie sur le second. Donc **chaque saut de capacité modèle est un vent dans le dos, pas une menace.**

## Principes de conception

1. **Moteur-agnostique** *(direction, pas état actuel)*. thedev orchestre un moteur ; il n'EST pas le moteur. Réduire les dépendances dures aux internals d'un CLI précis, pour qu'un changement de moteur n'impose pas une réécriture. État des lieux du couplage actuel et plan d'abstraction : [`ENGINE-COUPLING.md`](ENGINE-COUPLING.md).
2. **Primitives qui survivent.** Miser sur les briques ops/sysadmin qui vaudront autant dans cinq ans qu'aujourd'hui : l'**espace** (unité de travail), la **vue de flotte**, la **mission** (dispatch entre machines), le **crun** (tâche longue), les **secrets isolés**, la **conscience coût/quota**.
3. **Consommer le cerveau, pas le reconstruire.** Mémoire native, planification, autonomie, multimodal : quand les labos les livrent, thedev les *expose*, il ne les réimplémente pas.
4. **Humain aux commandes.** Tout ce qui est irréversible, coûteux ou sensible reste sous décision humaine. Secrets hors chat. Une fermeture qui montre d'abord ce qu'elle coupe.
5. **Sur ton infra, sur ton abo, auditable.** Tes machines, ton abonnement (pas d'API), zéro port ouvert, bash + fichiers lisibles. Pas de boîte noire, pas de cloud loué.
6. **Léger.** TUI minimale, empreinte basse — pour faire tourner beaucoup d'agents sans saturer.

## Non-buts

thedev ne cherche **pas** à :

- être un agent plus intelligent → c'est le terrain des labos, on le consomme ;
- être autonome / se self-améliorer tout seul → le but est que *tu* gardes la main ;
- être multi-modèles universel → choix assumé, centré sur ton abo ;
- être un assistant grand public multi-messageries → le pilotage passe par l'app officielle, pas par un bot-shell (moins de surface d'attaque) ;
- devenir un produit à vendre → thedev est un **moteur de production**, pas une marchandise. Sa valeur = ce que *tu* fabriques avec, qui s'accumule.

## Comment ça évolue

Le cœur ne bouge pas. La surface, oui — et c'est voulu. Question-filtre à chaque ajout :

- ça renforce « tu gardes la main / la confiance / le coût » ? → **cœur**, on investit.
- ça reconstruit ce que les labos vont livrer ? → **on attend**, on consommera.
- ça nous couple en dur à un moteur précis ? → **à abstraire**.
