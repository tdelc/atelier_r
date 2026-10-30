# Atelier R

Application Shiny (bslib) pour apprendre l'analyse de bases de données avec R et le tidyverse. Elle comporte quatre volets, tous disponibles pour les deux bases du cours (naissances INSEE 2021, météo Meteostat 2010-2026) :

| Volet | Contenu |
|---|---|
| **Cours** | 17 leçons par base, découpées en cartes (explication → code → résultat réellement calculé → commentaire), des premières commandes jusqu'à une étude de cas complète, puis des compléments (pourcentages d'un tableau croisé, ggplot2, gt, jointures, cartes, boucles et fonctions, Eurostat) |
| **Découverte** | 10 pistes guidées par base (code de départ + idées à tester) et un bac à sable libre. Chaque carte du cours peut y être envoyée pour être modifiée |
| **Exercices** | 27 exercices (naissances) et 24 (météo) en 5 niveaux, avec indice, vérification automatique du résultat et correction commentée |
| **Dashboard** | Un tableau de bord interactif par base. Chaque graphique a un bouton « Voir le code » qui affiche le code R exact qui le produit |

On y trouve aussi une visite guidée (même principe que vizsurvey), un dictionnaire des variables et un sélecteur de base dans la barre du haut.

## Lancer l'application

```r
install.packages(c("shiny", "bslib", "dplyr", "tidyr", "ggplot2", "lubridate",
                   "stringr", "forcats", "scales", "plotly", "shinyAce",
                   "evaluate", "commonmark", "jsonlite", "htmltools"))
shiny::runApp("atelier_r")
```

Les données sont déjà prêtes dans `data/` (fichiers `.rds`). Pour les régénérer à partir des CSV :

```
Rscript data-raw/preparer_donnees.R FD_NAIS_2021.csv meteo_2010_2026.csv
```

## Modifier le contenu (sans toucher au code)

Tout le contenu pédagogique est en markdown, dans `content/` (guide détaillé : `docs/GUIDE_CONTENUS.md`) :

```
content/
  cours/naissances/01-mise-en-route.md …  une leçon par fichier, une carte par titre « # »
  cours/meteo/…
  decouverte/naissances.md, meteo.md      une piste par titre « # »
  exercices/naissances.md, meteo.md       un exercice par titre « # »
  dictionnaires/naissances.csv, meteo.csv
  tour_fr.md                               la visite guidée
```

- **Leçons.** Le texte est en markdown. Les blocs de code s'écrivent ```` ```r ```` (exécuté et affiché), ```` ```r norun ```` (affiché seulement, par exemple pour `setwd`) ou ```` ```r setup ```` (exécuté sans être affiché). Les encadrés du mémo s'écrivent `::: usage`, `::: piege`, `::: note` ou `::: etape`, et se ferment par `:::`. Les cartes d'une leçon s'exécutent dans l'ordre : une variable créée dans une carte est disponible dans les suivantes.
- **Exercices.** Chaque exercice commence par des métadonnées (`niveau: 1` à 5, `theme:`, et `verif: aucune` pour un graphique), puis comporte les sous-sections `## Énoncé`, `## Indice`, `## Code de départ` (facultatif), `## Préparation` (facultatif, exécutée avant le code de l'étudiant), `## Correction` et `## Commentaire`.
- Le format est décrit en détail en tête de `R/content.R`.

**Après toute modification**, lancez le test qui exécute tout le contenu dans le bac à sable :

```
Rscript tests/test_contenus.R          # toutes les cartes, pistes et corrections
Rscript tests/test_verification.R      # vérification automatique des exercices
Rscript tests/test_sandbox.R           # sécurité du bac à sable (104 tests)
```

## Sécurité du code exécuté

Le code des étudiants s'exécute sur le serveur. Il est protégé par quatre barrières (voir `R/sandbox.R`) :

1. **Liste blanche, avant exécution.** Le code est analysé avant d'être lancé : chaque fonction appelée doit faire partie des fonctions du cours (verbes du tidyverse, calculs, ggplot2…). Tout le reste est refusé : `system()`, la lecture et l'écriture de fichiers, `eval`, `get`, `library`, `::`, `<<-`, les boucles `while` et `repeat`, les fonctions récursives, les noms de fonctions passés en texte (`"system"`), etc. Les boucles `for` et les fonctions créées par l'étudiant sont permises, et leur corps est contrôlé de la même façon. Les jointures passent par des versions protégées : la base de droite est limitée à 50 000 lignes et doit avoir une seule ligne par clé.
2. **Environnement isolé.** Le code tourne dans un environnement dont le parent est vide : il ne voit que les fonctions autorisées et les bases. Chaque session a son propre environnement, et les bases d'origine ne sont jamais modifiées.
3. **Limites.** Le calcul est coupé à 15 secondes. La longueur du code, la taille des nombres écrits en dur, le nombre de variables dans `table()` et la longueur de l'affichage sont aussi plafonnés.
4. **Affichage échappé.** Aucun HTML ni JavaScript ne peut être injecté dans la page.

Les étudiants voient la liste des fonctions autorisées (bouton « Fonctions autorisées » dans Découverte). Pour en ajouter une, complétez `SANDBOX_ALLOWED` dans `R/sandbox.R`.

**Recommandations de déploiement**, en défense supplémentaire :

- faire tourner l'application sous un utilisateur système sans droits ;
- limiter sa mémoire (par exemple `MemoryMax=2G` dans systemd, ou `--memory` avec Docker) ;
- prévoir plusieurs processus pour une classe entière, car un processus R exécute un calcul à la fois. Sur Posit Connect ou shinyapps.io, réglez le nombre de processus par instance ; sur Shiny Server Pro, utilisez plusieurs workers.

Comptez environ 1 Go de mémoire par processus : la base des naissances occupe à elle seule 180 Mo.

## Déploiement

- **shinyapps.io / Posit Connect** : `rsconnect::deployApp("atelier_r")`.
- **Shiny Server** : copiez le dossier dans `/srv/shiny-server/`. Le serveur doit utiliser une locale UTF-8 (`LANG=fr_FR.UTF-8` ou `C.UTF-8`), sinon les accents s'affichent mal dans les résultats.
- Le fond de carte du dashboard est fourni dans `www/topojson/` : l'application ne dépend d'aucun CDN extérieur pour ses cartes.

## Organisation du code

```
app.R                 assemblage de l'interface et du serveur
R/sandbox.R           exécution sécurisée
R/render.R            coloration syntaxique, rendu des résultats, markdown
R/content.R           lecture des fichiers de contenu
R/compare.R           vérification automatique des exercices
R/mod_*.R             un module par volet (accueil, cours, découverte, exercices, dashboard, visite)
R/dash_code.R         le code R des graphiques du dashboard (exécuté ET affiché)
www/                  CSS, JavaScript, fonds de carte
```

La progression des exercices est enregistrée dans le navigateur de l'étudiant (localStorage). Rien n'est stocké sur le serveur.
