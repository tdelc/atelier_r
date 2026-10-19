<!--
Visite guidée. Une section = une étape, dans l'ordre du fichier.
  tab:    onglet à ouvrir (accueil, cours, decouverte, exercices, dashboard)
  target: sélecteur CSS de l'élément à entourer (facultatif -> bulle centrée)
  ##      titre de la bulle, le reste est du markdown
  {base}  nom de la base choisie (BDD_NAIS ou BDD_METEO), {titre_base} son titre
Si la cible n'est pas visible à l'écran, la bulle s'affiche au centre.
-->

# 01-bienvenue
tab: accueil
## Bienvenue dans l'Atelier R
Cet atelier vous accompagne pour apprendre à analyser une base de données avec R.

Cette visite présente l'interface en quelques étapes. Utilisez **Suivant**, les flèches du clavier, ou **Échap** pour quitter.

# 02-base
target: #base
## Choisissez votre base
Deux bases sont disponibles : les **naissances** en France en 2021 (INSEE) et la **météo** quotidienne de 13 villes depuis 2010 (Meteostat).

Vous travaillez actuellement sur **{base}** ({titre_base}). Changer de base met à jour **tous** les volets.

# 03-dico
target: #btn_dico
## Le dictionnaire des variables
À tout moment, ce bouton affiche la liste des colonnes de la base, leur signification et leurs codes. Gardez le réflexe : une variable ne se devine pas, elle se lit dans la documentation.

# 04-cours
tab: cours
target: #cours-lessons
## Le cours, leçon par leçon
Les leçons vont des premières commandes jusqu'à une **étude de cas complète**. Chacune est découpée en cartes.

# 05-carte
tab: cours
target: .lesson-card
## Une carte = une notion
Chaque carte présente une explication, le **code**, son **résultat** (réellement calculé sur la base), puis un commentaire. Les encadrés orange signalent les pièges classiques.

Passez d'une carte à l'autre avec les boutons ou les **flèches du clavier**.

# 06-essayer
tab: cours
target: #cours-try
## Passer à la pratique
Ce bouton copie le code de la carte dans le volet **Découverte**, où vous pourrez le modifier et le relancer.

# 07-decouverte
tab: decouverte
target: #decouverte-pistes
## Le volet Découverte
Des pistes guidées, chacune avec un code de départ et des idées à tester. Et un **bac à sable libre** pour vos propres essais.

# 08-editeur
tab: decouverte
target: .editor-card
## L'éditeur de code
Modifiez le code, puis cliquez sur **Exécuter** ou tapez **Ctrl + Entrée**. Le code s'exécute sur le serveur, dans un espace protégé : vous ne pouvez rien casser, et la base d'origine reste intacte.

# 09-objets
tab: decouverte
target: #decouverte-objets
## Vos objets
Les objets que vous créez avec `<-` apparaissent ici et restent disponibles d'une exécution à l'autre. **Nouvel environnement** repart de zéro.

# 10-exercices
tab: exercices
target: #exercices-liste
## Les exercices
Une progression en cinq niveaux, des premiers filtres aux variables construites avec `lag()`. Les exercices réussis sont cochés, et mémorisés dans votre navigateur.

# 11-verifier
tab: exercices
target: #exercices-check
## Vérifier sa réponse
**Vérifier** compare le résultat de votre dernière ligne de code à celui de la correction. Les noms de colonnes peuvent différer : ce sont les valeurs qui comptent.

Un **indice** est disponible, et la **correction commentée** quand vous le souhaitez.

# 12-dashboard
tab: dashboard
## Le Dashboard
Pour finir, un tableau de bord interactif entièrement écrit en R. Chaque graphique a un bouton **Voir le code** : vous y retrouverez les verbes du cours.

Bon travail !
