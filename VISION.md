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

## Diriger une armée d'agents (la doctrine de commandement)

Le pari ci-dessus pose la question — *superviser, faire confiance, orchestrer N agents* — sans y répondre. Voici la réponse, et c'est l'inverse de ce que font les labos.

**Décomposition descendante vs agrégation ascendante.** Un agent classique, face à une tâche trop grosse, **fabrique des exécutants sous lui** : éphémères, ils font un bout, rendent un résultat, meurent. L'arbre naît de la *tâche* et pousse vers le *bas*. thedev fait l'inverse : face à trop d'**équipes réelles** à commander, tu fabriques du **commandement au-dessus**. Les feuilles sont de vrais soldats qui bossent en continu sur de vrais projets ; les nœuds au-dessus ne *font* pas le travail, ils **répartissent l'attention** et **font circuler** — ordres vers le bas, renseignement vers le haut. On ne crée pas des sous-fifres, on crée des **chefs**.

**Le plat n'est pas renversé : c'est la loi *dans* l'équipe.** Une session = une **équipe** = un groupe de soldats **pairs** qui bossent ensemble, sans chef interne. Permanent, inchangé. La hiérarchie ne descend **jamais** à l'intérieur d'une équipe ; elle organise les équipes **entre elles**. Un **chef** est au-dessus des équipes, pas dedans — et deux équipes sœurs restent pairs (elles ne se commandent pas l'une l'autre ; elles reportent à un chef, d'un autre rang). La grammaire d'armée **ajoute un axe vertical** au plat horizontal ; elle ne le remplace pas.

**Une hiérarchie qui respire.** L'axe vertical n'est pas figé : il grandit et se replie avec la charge, symétrique sur trois axes.

| Inspiration | Expiration |
|---|---|
| **Scinder** — span trop large → promouvoir un sous-chef | **Fusionner** — span trop maigre → replier, rendre les tours |
| **Raid** — tu plonges dans une équipe, la chaîne s'informe et se range | **Retrait** — tu débriefes vers le haut, le chef reprend |
| **Ordres** ↓ — l'intention du chef redescend | **Renseignement** ↑ — l'état remonte, agrégé et résumé |

**Le général n'est jamais prisonnier de sa propre armée.** Deux privilèges absolus :
- *Court-circuit libre* — tu prends la tête de n'importe quelle équipe sans demander à personne. Ta présence est un **fait**, pas une requête : la chaîne **s'informe** (drapeau de présence qui remonte) et **se range** (le chef responsable suspend ses ordres sur cette équipe), elle ne t'**autorise** pas.
- *Disparition intelligente* — tu quittes en **flushant un débrief vers le haut** (ce que tu as changé, l'état, les ordres en cours) ; le drapeau tombe, le chef reprend avec le contexte. Jamais un départ muet : même une fermeture brutale flushe un débrief minimal.

**Les murs, assumés.** Cette doctrine a un prix, et on le dit :
- **Plafond d'abonnement** — chaque chef est une vraie session qui brûle des tours sur ton abo. L'armée ne peut pas grossir sans fin ; son coût permanent doit rester ∝ la charge. C'est *pourquoi* la fusion est vitale, pas optionnelle. « À l'infini » est un asymptote ; 2–3 étages, le réel.
- **Latence de remontée** — l'info monte au *tour* de chaque nœud ; profondeur × cadence = fraîcheur de la vue au sommet.
- **Hystérésis** — scinder à N, fusionner bien en dessous de M, sinon l'arbre oscille.
- **Compression** — chaque étage résume ; le débrief **lie les artefacts** (transcript, fichiers) pour re-creuser sans perte. Avantage natif du socle bash + fichiers.

**Le garde-fou.** Cette auto-organisation n'est *pas* l'autonomie qu'on refuse (cf. Non-buts) : elle ne décide jamais *quoi produire*, elle gère seulement *la portée de ton attention*. Tu es toujours la racine, l'intention part toujours de toi, tu peux toujours court-circuiter. La hiérarchie **sert** ta main, elle ne la **remplace** pas. Le jour où elle déciderait à ta place, ce serait un bug, pas une feature.

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
