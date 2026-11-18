# Guide : ajouter du contenu à l'Atelier R

Ce guide explique comment ajouter une **base de données**, puis comment ajouter ou modifier une leçon, une piste de découverte, un exercice ou un graphique du dashboard. Pour tout sauf le dashboard, **aucune ligne de R n'est à écrire** : tout se passe dans le dossier de la base, `bases/<base>/` (un fichier texte de description et des fichiers markdown).

```
bases/
  naissances/
    base.txt          description de la base (obligatoire)
    BDD_NAIS.rds      les données (.rds ou .csv)
    dictionnaire.csv  dictionnaire des variables (facultatif)
    cours/            une leçon par fichier .md (facultatif)
    decouverte.md     les pistes de découverte (facultatif)
    exercices.md      les exercices (facultatif)
    dashboard.R       le tableau de bord (facultatif)
  meteo/
    …
data/                 tables partagées entre plusieurs bases (CARTE_DEP…)
content/tour_fr.md    la visite guidée
```

---

## 0. Le cycle de travail

1. Modifiez ou ajoutez un fichier dans `bases/<base>/`.
2. Lancez le test qui exécute **tout** le contenu dans le bac à sable :

   ```
   Rscript tests/test_contenus.R            # résumé : 0 échec attendu
   Rscript tests/test_contenus.R --verbose  # détail carte par carte, avec la durée
   Rscript tests/test_contenus.R meteo      # une seule base
   Rscript tests/test_bases.R               # description des bases et dashboards
   ```

   Chaque ligne `✗` est une carte, une piste ou une correction qui afficherait une erreur à l'étudiant. Le message dit laquelle et pourquoi (fonction non autorisée, colonne inconnue…).
3. Relancez l'application (`shiny::runApp()`). Les leçons sont mises en cache au premier affichage : **redémarrez** l'application pour voir une leçon modifiée.
4. Relisez la leçon dans l'application, en particulier les commentaires chiffrés (« **Lecture :** … ») : ils doivent correspondre aux résultats affichés.

Pour voir le résultat du code d'une leçon sans lancer l'application :

```r
for (f in list.files("R", full.names = TRUE)) source(f, encoding = "UTF-8")
library(dplyr); library(tidyr); library(ggplot2); library(lubridate)
sandbox_init(); load_bases()
L <- read_course("bases/naissances/cours")[["07-pourcentages-tableaux-croises"]]
env <- sandbox_new_env(base_datasets("naissances"))
for (carte in L$cards) for (s in carte$segments)
  if (s$type == "code" && s$mode != "norun") {
    r <- sandbox_run(s$code, env)
    for (it in r$items) if (it$type == "output") cat(it$text, "\n")
  }
```

---

## A. Ajouter une base de données

Une base = **un dossier** dans `bases/`. Le nom du dossier est l'identifiant de la base (lettres minuscules, chiffres et `_`, sans accent ni espace : `chomage`, `elections_2024`…). Aucune ligne de code de l'application n'est à modifier : au démarrage, l'application lit tous les dossiers de `bases/` qui contiennent un fichier `base.txt`.

### Le minimum : deux fichiers

```
bases/chomage/
  base.txt
  chomage.csv
```

`base.txt` :

```
objet: BDD_CHOMAGE
fichier: chomage.csv
libelle: Chômage
titre: Taux de chômage par région, 2000-2024
```

C'est tout : relancez l'application, la base apparaît sur la page d'accueil et dans le sélecteur du haut. Les étudiants peuvent l'utiliser dans le **bac à sable libre** (volet Découverte) ; les autres volets affichent « Pas encore de … pour cette base » tant que vous n'avez pas ajouté de contenu.

### Toutes les clés de `base.txt`

Une ligne = `clé: valeur`. Les lignes qui commencent par `#` sont des commentaires. Seule `objet` est vraiment utile : toutes les autres ont une valeur par défaut.

| Clé | Rôle | Par défaut |
|---|---|---|
| `objet` | nom de l'objet R dans le code des étudiants (`BDD_CHOMAGE`) | `BDD_` + nom du dossier en majuscules |
| `fichier` | fichier de données, dans le dossier de la base (ou dans `data/`) : `.rds` ou `.csv` | `<objet>.rds` |
| `separateur` | séparateur d'un CSV : `;` (lu avec `read_csv2()`, virgule décimale) ou `,` (`read_csv()`) | détecté sur la première ligne |
| `libelle` | nom court, dans le sélecteur du haut | nom du dossier |
| `titre` | titre complet (accueil, dictionnaire, visite) | `libelle` |
| `description` | une phrase de présentation sur la page d'accueil | aucune |
| `source` | source des données | aucune |
| `ligne` | ce que représente une ligne (« une naissance ») | « une observation » |
| `icone` | icône [Font Awesome](https://fontawesome.com/search?o=r&m=free) (`baby`, `cloud-sun`, `briefcase`…) | `database` |
| `ordre` | position dans le sélecteur et sur l'accueil (1, 2, 3…) | ordre alphabétique, après les bases numérotées |
| `nom_lignes` | libellé du nombre de lignes sur l'accueil (« naissances ») | « lignes » |
| `compter` | chiffres clés de l'accueil : nombre de valeurs distinctes d'une colonne, `libellé = COLONNE`, séparés par des virgules | aucun |
| `extras` | tables complémentaires disponibles dans le bac à sable (§6), séparées par des virgules | aucune |
| `code_libre` | code proposé dans le bac à sable libre ; `\n` = retour à la ligne | `<objet> \|> glimpse()` |
| `dashboard_titre` | titre du tableau de bord | `titre` |
| `langage` | `r` ou `python` (voir « Une base en Python ») | `r` |
| `dossier_python` | base Python : dossier copié dans le dossier de travail de l'étudiant | `fichiers` |

Exemple complet : `bases/naissances/base.txt`.

### Les données : `.rds` ou `.csv` ?

- **`.csv`** : le plus simple, l'application le lit au démarrage avec `read_csv2()` ou `read_csv()`, exactement comme les étudiants dans RStudio.
- **`.rds`** : plus rapide à charger pour une grosse base (plusieurs centaines de milliers de lignes). Préparez-le une fois avec `saveRDS(BDD, "bases/chomage/BDD_CHOMAGE.rds")`, et gardez le script de préparation dans `data-raw/`.

Pensez à la mémoire : chaque base est chargée une fois, pour tous les étudiants.

### Puis, au fil de l'eau

| Fichier | Contenu | Format |
|---|---|---|
| `dictionnaire.csv` | dictionnaire des variables | §8 (sans lui, un dictionnaire minimal est construit : noms et types des colonnes) |
| `cours/01-….md` | les leçons | §1 |
| `decouverte.md` | les pistes de découverte | §2 |
| `exercices.md` | les exercices | §3 |
| `dashboard.R` | le tableau de bord | §4 |

Le plus simple est de copier les fichiers d'une base existante et de les adapter. Lancez ensuite `Rscript tests/test_bases.R` et `Rscript tests/test_contenus.R chomage`.

### Une base en Python

Une base peut avoir un cours en **Python** plutôt qu'en R : ajoutez `langage: python` dans son `base.txt` (exemple complet : `bases/communes_be/`).

- **Où s'exécute le code ?** Dans le **navigateur** de l'étudiant, avec [Pyodide](https://pyodide.org) (Python compilé pour le web), et non sur le serveur. Il n'y a donc pas de liste de fonctions autorisées : tout Python est disponible. Paquets : pandas, NumPy, PyArrow, DuckDB, Matplotlib (chargés depuis le CDN jsdelivr), Seaborn et openpyxl (fournis dans `www/python/wheels/`). Le premier chargement prend une dizaine de secondes.
- **Les fichiers** : le dossier `fichiers/` de la base (clé `dossier_python`) est copié dans le dossier de travail Python de l'étudiant. On y range `donnees/`, `referentiels/`… ; l'étudiant écrit dans `sortie/`, en mémoire dans son navigateur.
- **Les blocs de code** s'écrivent ```` ```python ````, avec les mêmes options : ```` ```python norun ````, ```` ```python setup ````, et ```` ```python erreur ```` pour une **erreur volontaire** (le bloc s'affiche normalement ; le test vérifie qu'il produit bien une erreur). Comme dans un notebook, la dernière ligne d'un bloc s'affiche sans `print()`, et les tableaux pandas s'affichent en tableau.
- **Les encadrés** `::: sas` affichent une « Passerelle SAS ».
- **Les exercices** ont le même format. La vérification compare la **valeur de la dernière ligne** à celle de la correction (nombre, texte, liste, tuple, ensemble, dictionnaire, Series ou DataFrame), avec les mêmes tolérances qu'en R. La clé `groupe:` remplace le titre de niveau dans la liste (« Atelier 1 · … »).
- **Les tests** : `python tests/test_python.py` exécute tout le contenu Python avec le Python de votre poste (il faut les mêmes paquets), avec le même moteur que dans le navigateur (`www/python/runner.py`). Puis, l'application lancée, `node tests/test_python_navigateur.js` rejoue le même contenu dans un vrai navigateur, avec Pyodide : c'est le test qui fait foi, car Pyodide se comporte parfois autrement (une jointure sur une clé qui contient des valeurs manquantes y provoque une erreur, par exemple).
- **Un défaut de pandas 3.0** : avec les types PyArrow, `serie.str[:4]` provoque une erreur `AttributeError`. Écrivez `serie.str.slice(0, 4)`.
- **Pas de dashboard** pour l'instant dans une base Python, ni de boucle infinie à exécuter : une boucle qui ne s'arrête pas bloque Python dans le navigateur (l'étudiant doit recharger la page). Montrez-la en ```` ```python norun ````.

### Avec plus de trois bases

Le sélecteur du haut passe automatiquement de boutons à une liste déroulante.

---

## 1. Une leçon (volet Cours)

### Où ?

Un fichier par leçon, dans le dossier `cours/` de la base : `bases/naissances/cours/`, `bases/meteo/cours/`… L'ordre des leçons est l'**ordre alphabétique des noms de fichiers** : préfixez-les par un numéro (`17-ma-lecon.md`). Pour insérer une leçon entre deux autres sans tout renuméroter, réutilisez le numéro de la précédente avec un nom qui vient après dans l'alphabet (par exemple `07-pourcentages…` après `07-mettre-en-forme…`).

Pour qu'une leçon existe pour les deux bases, créez deux fichiers, un dans chaque dossier (même nom conseillé), chacun avec le code de sa base.

### Le format

````markdown
---
titre: Ma nouvelle leçon
resume: Une phrase qui s'affiche sous le titre.
partie: Compléments
---

# Titre de la première carte

Texte en markdown : **gras**, `code`, listes, tableaux…

```r
BDD_NAIS |> count(SEXE)
```

Commentaire affiché sous le résultat.

::: note
**Lecture :** …
:::

# Titre de la deuxième carte
…
````

- **L'en-tête** (`---` … `---`) : `titre`, `resume`, `partie`. La `partie` regroupe les leçons dans la liste de gauche (« Les bases », « Pour aller plus loin », « Étude de cas », « Compléments »…). Une nouvelle valeur crée un nouveau groupe.
- **Chaque titre de niveau 1** (`# …`) commence une **carte**. Les commentaires R (`# …`) à l'intérieur des blocs de code ne sont pas confondus avec des titres.
- **Les sous-titres** (`## …`) sont autorisés à l'intérieur d'une carte.

### Les blocs de code

| Écriture | Exécuté ? | Affiché ? | Usage |
|---|---|---|---|
| ```` ```r ```` | oui | oui, avec le résultat | le cas normal |
| ```` ```r norun ```` | non | oui, avec un badge « Non exécuté dans l'atelier » | `setwd()`, `read_csv()`, `library()`, `ggsave()`, `gtsave()`, leaflet, eurostat… |
| ```` ```r setup ```` | oui | non | préparer discrètement des objets utilisés plus loin |

Points importants :

- **Les cartes d'une leçon s'exécutent dans l'ordre, dans le même environnement** : une variable créée dans la carte 3 existe dans la carte 4. Chaque leçon repart, elle, de la base d'origine.
- Le bouton « Modifier ce code dans Découverte » rejoue en silence le code des cartes précédentes : l'étudiant retrouve le même état.
- Une carte peut contenir plusieurs blocs de code, entrecoupés de texte.
- Gardez un temps de calcul raisonnable : chaque bloc est interrompu au-delà de **15 secondes**.
- Un tableau **gt** s'affiche automatiquement dans le Viewer, sous le code, comme dans RStudio (§7) : un bloc ```` ```r ```` normal suffit.

### Les encadrés

````markdown
::: usage
À quoi ça sert ? Écriture…
:::

::: piege
L'erreur classique…
:::

::: note
**Lecture :** …
:::

::: etape
1. … 2. …
:::
````

| Encadré | Couleur | Usage dans le cours |
|---|---|---|
| `usage` | bleu-gris | « À quoi ça sert ? », la syntaxe |
| `piege` | orange | l'erreur classique, l'avertissement |
| `note` | vert | la lecture d'un résultat, un conseil |
| `etape` | bleu encadré | une démarche en plusieurs étapes |

À l'intérieur d'un encadré, tout le markdown fonctionne (tableaux, listes, code). **Pour un exemple de code non exécuté dans un encadré**, utilisez un bloc ```` ``` ```` **sans** le `r`.

---

## 2. Une piste (volet Découverte)

### Où ?

Un fichier par base : `bases/<base>/decouverte.md`. Une piste par titre `#`, dans l'ordre du fichier.

### Le format

````markdown
# Titre de la piste

Description affichée en haut de la page.

```r setup
# (facultatif) code exécuté en silence avant, pour préparer des objets
BDD_NAIS <- BDD_NAIS |> mutate(MARIES = AMAR != "0000")
```

```r
# Le code de départ, placé dans l'éditeur
BDD_NAIS |> count(MARIES)
```

## À essayer

- Une idée à tester
- Une autre idée
````

- Le **premier bloc ```` ```r ````** est le code de départ ; le bouton « Code de départ » y revient.
- Tout ce qui suit le code (la section « À essayer ») s'affiche dans l'encadré de droite.
- Le bloc `setup` est rejoué à chaque fois que l'étudiant choisit la piste ou clique sur « Nouvel environnement ».

---

## 3. Un exercice (volet Exercices)

### Où ?

Un fichier par base : `bases/<base>/exercices.md`. Un exercice par titre `#`.

> **Important.** La progression des étudiants est enregistrée dans leur navigateur **selon la position** de l'exercice (le 1er, le 2e…). **Ajoutez les nouveaux exercices à la fin du fichier** : si vous en insérez un au milieu, les coches « réussi » se décalent.

Les exercices sont regroupés par niveau dans la liste de gauche : un exercice de niveau 3 ajouté en fin de fichier s'affiche bien dans le groupe « Niveau 3 ».

### Le format

````markdown
# Titre de l'exercice
niveau: 2
theme: group_by + summarise
verif: valeur

## Énoncé
Ce que l'étudiant doit faire (markdown).

## Indice
Un coup de pouce, affiché à la demande.

## Code de départ
```r
BDD_NAIS |>
  filter(...)
```

## Préparation
```r
# exécuté AVANT le code de l'étudiant et avant la correction ;
# l'étudiant peut le lire (« Code déjà exécuté avant le vôtre »)
INFO <- tibble(...)
```

## Correction
```r
BDD_NAIS |>
  group_by(SEXE) |>
  summarise(AGE = mean(AGEMERE))
```

## Commentaire
L'explication affichée sous la correction.
````

| Élément | Obligatoire | Remarque |
|---|---|---|
| `niveau:` | oui | 1 à 5 ; détermine le groupe dans la liste |
| `theme:` | non | petite étiquette (ex. `pivot_wider`) |
| `verif:` | non | `valeur` (défaut) ou `aucune` (graphique, question ouverte) |
| `## Énoncé`, `## Correction` | oui | |
| `## Indice`, `## Code de départ`, `## Préparation`, `## Commentaire` | non | |

### Comment fonctionne la vérification automatique

« Vérifier » compare **le résultat de la dernière commande** de l'étudiant à celui de la **dernière commande de la correction**. La comparaison est tolérante :

- les noms et l'ordre des colonnes peuvent différer ;
- l'ordre des lignes peut différer ;
- un tableau d'une case équivaut à un nombre (`summarise(mean(X))` = `mean(BDD$X)`) ;
- `table()` équivaut à `count()` ;
- des colonnes en plus chez l'étudiant sont acceptées ;
- un tableau **gt** est comparé par les données qu'il présente : titres, libellés et formats peuvent différer, et un tibble sans `gt()` est aussi accepté.

Il faut en revanche le **même nombre de lignes** et retrouver **chaque colonne de la correction** avec les mêmes valeurs (à 10⁻⁶ près).

Conséquences pour la rédaction :

- **Terminez la correction par le résultat demandé**, pas par une assignation silencieuse ni par un graphique.
- Si l'exercice demande de **créer une variable**, terminez l'énoncé et la correction par une **vérification** qui l'affiche (`count(MNAIS, SAISON)`), c'est elle qui sera comparée.
- Pour un **graphique**, mettez `verif: aucune` : l'étudiant compare visuellement avec la correction.
- Testez vos variantes : `Rscript tests/test_verification.R` vérifie que chaque correction est acceptée par la vérification ; vous pouvez y ajouter des réponses alternatives qui doivent être acceptées ou refusées (exemples dans le fichier).

---

## 4. Le Dashboard

Le dashboard est le seul volet qui demande d'écrire du R. Chaque base a le sien, dans **`bases/<base>/dashboard.R`** (facultatif : sans ce fichier, l'onglet affiche « Pas de tableau de bord pour cette base »).

### Le principe du fichier `dashboard.R`

Il est chargé au démarrage, dans un environnement propre à la base (deux bases peuvent donc utiliser les mêmes noms). Il doit définir **deux fonctions** :

```r
dashboard_ui <- function(id) {        # l'interface : filtres, graphiques
  ns <- NS(id)
  bslib::layout_sidebar(…)
}
dashboard_server <- function(id) {    # la logique serveur
  moduleServer(id, function(input, output, session) { … })
}
```

Dans ce fichier, `BASE` désigne la base : `BASE$data` (les données), `BASE$objet`, `BASE$dir` (le dossier)… Les outils communs sont disponibles : `dash_card()`, `code_modal()`, `run_dash_code()`, `fmt_num()` (voir `R/mod_dashboard.R`). Les chemins de fichiers s'écrivent depuis la racine de l'application (`"data/departements.csv"`, ou `file.path(BASE$dir, "mon_fichier.csv")`).

Pour démarrer un nouveau dashboard, **copiez celui de la météo** (le plus simple) et adaptez-le.

### Ajouter un graphique : trois ajouts

#### a. Le code du graphique : `DASH_CODE`

Le code est écrit **sous forme de texte**, en haut de `dashboard.R` : il est à la fois exécuté et affiché quand l'étudiant clique sur « Voir le code ».

```r
DASH_CODE$jumeaux <- r"--(
par_age <- donnees |>
  group_by(AGEMERE) |>
  summarise(part = mean(NBENF >= 2))

g <- ggplot(par_age, aes(x = AGEMERE, y = part)) +
  geom_line(linewidth = 1, colour = "#1f3a5f") +
  scale_y_continuous(labels = scales::percent) +
  labs(x = "Âge de la mère", y = "Naissances multiples") +
  theme_minimal()

ggplotly(g))--"
```

- La chaîne s'écrit `r"--( … )--"` : c'est une **chaîne brute** de R, qui accepte guillemets et parenthèses sans échappement.
- La **dernière ligne** doit renvoyer un graphique plotly : `ggplotly(g)` pour un graphique ggplot2, ou un `plot_ly(...)`.
- Les objets disponibles dans ce code sont ceux que le serveur passe à `run_dash_code()` (la liste `objets()`), décrits en tête de chaque `dashboard.R` :
  - **naissances** : `donnees` (BDD_NAIS filtrée sur le territoire choisi), `BDD_NAIS`, `departements` (contours GeoJSON), `indicateur` ;
  - **météo** : `donnees` (BDD_METEO filtrée sur les années), `ville`, `ville2`, `annee_coupure`.
- Ce code n'est **pas** dans le bac à sable (c'est votre code, pas celui des étudiants) : toutes les fonctions R sont disponibles, y compris `scales::percent`.

#### b. La carte dans l'interface : `dashboard_ui()`

Ajoutez une carte à l'endroit voulu, avec **le même nom** que dans `DASH_CODE` :

```r
dash_card(ns, "jumeaux", "Les naissances multiples", "Selon l'âge de la mère")
```

`dash_card()` accepte un argument `height` (par défaut `"340px"`). Pour placer deux cartes côte à côte, mettez-les dans `bslib::layout_columns(col_widths = bslib::breakpoints(sm = 12, lg = c(6, 6)), …)`, comme les autres.

#### c. Le rendu dans `dashboard_server()`

- **Naissances** : rien à faire, la boucle `for (nm in names(DASH_CODE)) render_chart(nm)` prend en compte tout nouveau graphique.
- **Météo** : ajoutez une ligne `render_chart("mon_graphique")` à côté des autres. Si le graphique compare les deux périodes, écrivez `render_chart("mon_graphique", TRUE)` : un message s'affiche quand les années choisies n'encadrent pas l'année de coupure.

### Tester un graphique sans lancer l'application

```r
for (f in list.files("R", full.names = TRUE)) source(f, encoding = "UTF-8")
library(shiny); library(dplyr); library(ggplot2); library(plotly); library(lubridate)
sandbox_init(); load_bases(); load_dashboards()
D <- BASES$naissances$dash_env
B <- BASES$naissances$data
run_dash_code(D$DASH_CODE$jumeaux, list(donnees = B, BDD_NAIS = B))
```

---

## 5. Autoriser une nouvelle fonction dans le bac à sable

Si un code de leçon ou d'exercice échoue avec « La fonction xxx() n'est pas disponible dans l'atelier », deux possibilités :

- la fonction écrit des fichiers, lit Internet ou installe des paquets : mettez le bloc en `norun` ;
- la fonction est inoffensive (un calcul, un verbe, une fonction de graphique) : ajoutez-la à la liste `SANDBOX_ALLOWED` en haut de `R/sandbox.R`, **dans le bloc de son paquet** :

  ```r
  stringr = c("str_detect", …, "str_trim", "str_squish"),   # ← ajout
  ```

  Si le paquet n'est pas encore dans la liste, ajoutez un bloc (`gt = c("gt", "tab_header")`) **et** chargez le paquet dans `app.R`.

Les fonctions de ggplot2 dont le nom commence par `geom_`, `stat_`, `scale_`, `theme`, `facet_`, `coord_`… sont autorisées automatiquement.

**Ne jamais autoriser** : les fonctions qui lisent ou écrivent des fichiers, exécutent du code construit en texte (`eval`, `parse`, `get`, `do.call`, `match.fun`), manipulent des environnements, ou modifient un état global (`options`, `theme_set`, `Sys.setenv`). En cas de doute, ajoutez un test dans `tests/test_sandbox.R` et relancez-le.

---

## 6. Ajouter une table de données

Pour rendre une nouvelle table disponible dans le bac à sable (comme `INFO_DEPARTEMENTS` ou `CARTE_DEP`) :

1. Enregistrez-la en `.rds` (ou `.csv`) dans le dossier de la base, ou dans `data/` si elle sert à plusieurs bases (ajoutez le code de préparation à `data-raw/preparer_donnees.R`, pour garder la trace) ;
2. Déclarez-la dans le `base.txt` de la base concernée, à la ligne `extras` :

   ```
   extras: INFO_DEPARTEMENTS, CARTE_DEP, MA_TABLE
   ```

   Le fichier `MA_TABLE.rds` (ou `MA_TABLE.csv`) est cherché dans le dossier de la base, puis dans `data/`. Pour donner un autre nom à l'objet : `extras: MA_TABLE = mon_fichier.csv`.

3. Elle apparaît alors sous le nom `MA_TABLE` dans toutes les leçons, pistes et exercices de cette base, et dans « Objets disponibles ».

Pensez à la mémoire : chaque table est chargée une fois pour tous les étudiants.

---

## 7. Le Viewer (tableaux gt)

Dans RStudio, un tableau gt ne s'affiche pas dans la console mais dans le **Viewer**. L'atelier fait de même : dès qu'une commande **affiche** un tableau gt, il apparaît sous le code, dans un cadre blanc à la place du texte de la console. Cela vaut **partout, sans aucun réglage** : leçons, pistes de découverte, exercices (énoncé et correction) et code libre des étudiants.

```r
EXPORT1 |>
  gt() |>
  tab_header(title = "Part des naissances hors mariage") |>
  fmt_percent(columns = c(francaise, etrangere), decimals = 1, locale = "fr")
```

- Comme dans RStudio, `TAB <- gt(…)` n'affiche rien : écrivez `TAB` sur la ligne suivante pour voir le tableau.
- Pas de `library(gt)` dans l'atelier (le paquet est déjà chargé). Pour le montrer aux étudiants, mettez-le dans un bloc `norun`.
- Les fonctions gt autorisées sont dans le bloc `gt` de `SANDBOX_ALLOWED` (`R/sandbox.R`) et dans la fenêtre « Fonctions autorisées ». Ne sont **pas** autorisées : `gtsave()` (écrit un fichier, à mettre en `norun`), `html()`, `web_image()` et `local_image()`.
- Pour colorer les cases, écrivez `data_color(columns = …, palette = c("#f7fbff", "#08306b"), domain = c(0, 1))` plutôt que `fn = scales::col_numeric(…)` : l'opérateur `::` est refusé dans l'atelier.
- Avec `fmt_number(dec_mark = ",")`, ajoutez `sep_mark = " "` : sinon la virgule sert aussi de séparateur des milliers et R affiche un avertissement.
- Un tableau trop grand (plus de 400 000 caractères de HTML, soit quelques milliers de lignes) n'est pas affiché : faites d'abord un tableau de synthèse.

**Sécurité.** Le tableau est affiché dans un cadre isolé (`iframe`) qui n'exécute aucun JavaScript et ne charge rien depuis Internet. Même si un texte du tableau contient du HTML (par exemple via `md()`), il ne peut pas agir sur la page de l'atelier.

**Ajouter un autre type d'objet au Viewer.** Le mécanisme est dans `R/viewer.R`. Pour un nouvel objet qui produit du HTML **statique** (sans JavaScript), ajoutez une ligne à `VIEWER_TYPES` (« classe R = fonction qui renvoie le HTML »), puis autorisez ses fonctions dans `SANDBOX_ALLOWED` et chargez le paquet dans `app.R`. Les objets qui ont besoin de JavaScript (htmlwidgets : leaflet, plotly, DT…) ne peuvent pas s'afficher dans ce cadre : laissez leur code en `norun`.

---

## 8. Le dictionnaire et la visite guidée

- **Dictionnaire** : `bases/<base>/dictionnaire.csv`, quatre colonnes (`variable,libelle,type,modalites`). Les valeurs contenant une virgule s'écrivent entre guillemets.
- **Visite guidée** : `content/tour_fr.md`. Une étape par titre `#`, avec `tab:` (l'onglet à ouvrir : `accueil`, `cours`, `decouverte`, `exercices`, `dashboard`) et `target:` (un sélecteur CSS de l'élément à entourer, facultatif). Dans le texte, `{base}`, `{titre_base}`, `{liste_bases}` et `{nb_bases}` sont remplacés par la base choisie, son titre, la liste et le nombre des bases. Le fichier est relu à chaque lancement de la visite : pas besoin de redémarrer.

---

## 9. Aide-mémoire des erreurs du test

| Message dans `test_contenus.R` | Cause probable | Correction |
|---|---|---|
| `La fonction xxx() n'est pas disponible` | fonction hors liste blanche | `norun`, ou ajout dans `SANDBOX_ALLOWED` (§5) |
| `object 'X' not found` | variable créée dans une carte **plus loin**, ou faute de frappe | réordonner les cartes, vérifier le nom |
| `Calcul interrompu : il a dépassé 15 secondes` | calcul trop lourd (boucle, nuage de 742 000 points) | réduire (`slice_sample()`, moins de répétitions) |
| `Seule l'écriture NOM <- valeur est autorisée` | `BDD$X <- …` ou `names(BDD) <- …` | passer par `mutate()` ou `rename()` |
| `La base de droite contient plusieurs lignes pour une même clé` | jointure plusieurs-à-plusieurs | dédoublonner la table de droite |
| `exercice incomplet` | il manque `## Énoncé` ou `## Correction` | compléter |
| `⚠ 'big.mark' et 'decimal.mark' sont tous deux ','` | `fmt_number(dec_mark = ",")` sans `sep_mark` | ajouter `sep_mark = " "` (§7) |
| `⚠ la correction ne produit pas de valeur à comparer` | la correction finit par une assignation ou un graphique | finir par l'affichage du résultat, ou `verif: aucune` |
