# PlateFaction

Addon sans dépendance pour **WoW Forever 1.60.1 (Interface 16001)** et les nameplates Blizzard. Version publique 1.0.0, par **Syntaxucre**.

## Installation

1. Fermer WoW, puis copier le dossier `PlateFaction` (celui contenant `PlateFaction.toc`) dans `World of Warcraft\_classic_beta_\Interface\AddOns\`.
2. Vérifier que le chemin obtenu est `Interface\AddOns\PlateFaction\PlateFaction.toc`, sans dossier intermédiaire.
3. Relancer le jeu et activer **PlateFaction** dans la liste des addons.
4. Saisir `/platefaction`, ou ouvrir **Options → Add-ons → PlateFaction**.

## Langues

La langue suit automatiquement celle du client : anglais (US/GB), français, allemand, espagnol européen ou latino-américain, italien, portugais brésilien, russe, coréen, chinois simplifié ou traditionnel. Une traduction absente utilise l’anglais. Le panneau défile et adapte les textes à sa largeur. Les traductions ne sont pas toutes relues par des locuteurs natifs.

## Utilisation

L’addon affiche par défaut un emblème de faction à gauche du nom des autres joueurs. Les modes proposés sont **Icône seule**, **Couleur du nom**, **Icône et couleur du nom**. La barre de vie conserve son apparence Blizzard.

Pour ne voir que les icônes Horde : décocher **Afficher l’icône Alliance** et conserver **Afficher l’icône Horde**. Ces deux filtres concernent uniquement les icônes, même en mode combiné. Vous pouvez décocher les deux.

Les couleurs des noms sont fixes : Alliance bleue (`#3399FF`), Horde rouge (`#FF4040`). Elles prennent priorité sur la couleur de classe du nom. La faction indiquée par le jeu est utilisée indépendamment du caractère amical ou hostile du joueur.

La taille de l’icône va de 10 à 64 unités d’interface, avec 16 par défaut. Choisir sa position par rapport au nom : gauche, droite, au-dessus ou en dessous. Les décalages horizontal et vertical sont réglables de -100 à +100 ; une valeur positive déplace l’icône vers la droite ou vers le haut. Par défaut, elle reste à gauche, avec un espacement de 4 et des décalages nuls.

Les modifications s’appliquent immédiatement. Les options sont enregistrées pour le compte dans `PlateFactionDB` lors d’une déconnexion normale ou d’un `/reload`. Elles restent identiques en changeant de personnage, y compris entre Alliance et Horde. Une mise à jour conserve les réglages existants et initialise seulement les nouvelles options de position.

## Visibilité et compatibilité

- Activer les nameplates souhaitées dans les réglages de WoW : l’addon ne change pas ces réglages et ne crée pas de plaques pour les unités cachées par le jeu.
- Seuls les autres joueurs sont concernés : ni PNJ, ni familiers, ni plaque personnelle.
- L’icône suit la visibilité du nom et la taille suit l’échelle de la nameplate.
- Les plaques interdites et les données de faction absentes ou protégées sont ignorées. Les restrictions du jeu, notamment en instance, restent applicables.
- Cible : nameplates Blizzard. Les remplacements tels que Plater ne sont pas pris en charge.
- La bêta peut modifier ses API. Les tests simulés ne remplacent pas une vérification en jeu de l’apparence et des restrictions en combat.

## Vérification en jeu

1. Afficher des joueurs Alliance et Horde. Tester les trois modes, puis les quatre combinaisons des cases de faction.
2. Avec un personnage Alliance, sélectionner « Horde seule » : aucune icône Alliance, icônes Horde visibles. Refaire avec un personnage Horde : même résultat.
3. En mode combiné, décocher les deux factions : les noms restent colorés, les icônes disparaissent, les barres ne changent pas.
4. Modifier taille (jusqu’à 64), position, décalages, mode et activation avec des plaques déjà affichées. Vérifier les quatre positions et les décalages négatifs/positifs. Désactiver l’addon : les noms retrouvent leur couleur Blizzard actuelle.
5. Tester noms longs/courts, nom seul, ciblage, survol, combat, changement de zone et entrée en instance. Masquer les noms : aucune icône isolée ne doit rester.
6. Faire disparaître des joueurs puis apparaître des PNJ : aucun emblème ni couleur de faction ne doit rester sur les plaques réutilisées.
7. Faire `/reload`, puis se déconnecter normalement et se reconnecter sur un autre personnage : vérifier les préférences.
8. Vérifier l’absence d’erreurs avec BugGrabber/BugSack. En cas d’erreur, conserver le texte complet et le résultat de `/dump GetBuildInfo()`.

## Développement

Le dossier `tests` du projet contient un simulateur Lua des API nécessaires et des scénarios de régression. Depuis la racine du projet, exécuter `lua tests/run.lua` avec Lua 5.1 ou ultérieur. Ces tests ne sont pas chargés par le jeu.

Points d’intégration vérifiés dans les sources Blizzard publiées pour Forever :

- [Gestion des nameplates](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_NamePlates/Blizzard_NamePlates.lua)
- [Cycle de vie et réutilisation](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_NamePlates/Blizzard_NamePlateBase.lua)
- [Mise à jour des noms](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UnitFrame/Shared/CompactUnitFrame.lua)

## Publication

Auteur : **Syntaxucre**. Licence [MIT](../LICENSE). [Sources et signalements](https://github.com/Azurix78/PlateFaction). La version publique 1.0.0 inclut toutes les fonctions des versions de développement locales, y compris le positionnement et la taille maximale de 64.
