---
titre: Mise en route
resume: Charger les données, afficher la base, comprendre ce qu'est une ligne et une colonne.
partie: Les bases
---

# La base météo : BDD_METEO

Relevés météo **quotidiens** de 13 stations françaises, du 1er janvier 2010 au 8 septembre 2026 (source : meteostat.net).

**Une ligne = une ville × un jour.**

| Colonne | Contenu |
|---|---|
| `name` | Nom de la station (la ville) |
| `date` | Jour du relevé |
| `temp`, `tmin`, `tmax` | Température moyenne, minimale, maximale du jour (°C) |
| `rhum` | Humidité de l'air (%) |
| `prcp` | Précipitations du jour (mm) |
| `snwd` | Hauteur de neige au sol (mm) |
| `wspd`, `wpgt` | Vitesse moyenne du vent, rafale maximale (km/h) |
| `pres` | Pression atmosphérique (hPa) |
| `tsun` | Durée d'ensoleillement (minutes) |
| `cldc` | Couverture nuageuse (en octas, de 0 à 9) |
| `latitude`, `longitude`, `elevation`… | Localisation de la station |
| `*_source` | Colonnes techniques indiquant la source de chaque mesure |

Le bouton **Dictionnaire** (en haut de l'écran) donne la liste complète des colonnes.

# Charger le tidyverse et la base

Dans RStudio, ces commandes se placent **en haut de chaque script**.

```r norun
install.packages("tidyverse")   # une seule fois sur votre ordinateur
library(tidyverse)              # à chaque ouverture de RStudio

setwd("G:/Mon Drive/Cours/Initiation R/M1 2026")   # votre dossier de travail
BDD_METEO <- read_csv("meteo_2010_2026.csv")
```

::: usage
- Ce fichier est séparé par des **virgules** : on utilise `read_csv()` (et non `read_csv2()`, qui attend des points-virgules).
- `setwd()` indique à R le dossier où lire et enregistrer les fichiers. Remplacez le chemin par le vôtre, et les antislashs `\` par des slashs `/`.
:::

::: note
**Dans cet atelier, tout est déjà fait** : le tidyverse est chargé et la base `BDD_METEO` est prête. Ces lignes ne sont pas exécutées ici, mais vous devrez les écrire dans vos propres scripts. Attention, sur les ordinateurs de l'université, il faut installer préalablement les packages R6 et feaver pour que le package tidyverse fonctionne.
:::

# Afficher la base

```r
BDD_METEO
```

L'en-tête donne **79 232 lignes** et **35 colonnes**. Sous chaque nom de colonne, son **type** : `<dbl>` pour un nombre, `<chr>` pour du texte, `<date>` pour une date.

::: piege
La première colonne s'appelle `...1` : le fichier contenait une colonne **sans nom** (un ancien numéro de ligne, créé lors de l'export). En l'important, `read_csv()` lui a donné ce nom par défaut et a affiché un message « New names ». Elle ne contient aucune information utile, tout comme la colonne `X`.
:::

# dim(), nrow(), ncol() : la taille du tableau

```r
dim(BDD_METEO)
nrow(BDD_METEO)
ncol(BDD_METEO)
```

::: note
**Vérification de bon sens :** 13 villes × environ 16,7 ans × 365 jours ≈ 79 000 lignes. L'ordre de grandeur est le bon.
:::

# glimpse() : aperçu de toutes les colonnes

```r
glimpse(BDD_METEO)
```

::: usage
`glimpse()` affiche, pour **chaque** colonne, son nom, son type et ses premières valeurs. C'est la première commande à lancer sur une base inconnue.
:::

::: piege
Vérifiez tout de suite les **types** : une date importée en texte, ou une température importée en texte à cause d'une virgule décimale, se repère ici et pas plus tard. Ici, `date` est bien de type `<date>` et les températures sont des nombres.
:::

# $ : désigner une colonne

```r
BDD_METEO$temp |> head()   # les 6 premières températures
BDD_METEO$name |> head()
```

::: usage
`BDD$COLONNE` extrait **une colonne** du tableau, sous forme de vecteur. On s'en sert pour donner une colonne à une fonction de R base : `summary()`, `hist()`, `table()`, `mean()`…
:::

# <- : conserver un résultat

```r
BDD_LILLE <- BDD_METEO |> filter(name == "Lille")

nrow(BDD_LILLE)
```

::: piege
Écrire `BDD_METEO <- BDD_METEO |> filter(...)` **écrase** la base d'origine : vous perdez toutes les autres villes. Pour une sous-base, choisissez un **nouveau nom**.
:::

# |> : le pipe

Le pipe prend le résultat de gauche et l'envoie dans la fonction de droite. Il se lit « **puis** ».

```r
BDD_METEO |>                    # je prends la base météo,
  filter(name == "Lille") |>    # puis je garde Lille,
  count()                       # puis je compte les lignes
```

::: note
On passe à la ligne après chaque `|>` pour que le code reste lisible. Dans du code trouvé en ligne, vous verrez souvent `%>%` : c'est l'ancien pipe, qui fait la même chose dans presque tous les cas.
:::
