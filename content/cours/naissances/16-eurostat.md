---
titre: Importer des données d'Eurostat
resume: Chercher, télécharger, comprendre et synthétiser une base européenne avec le paquet eurostat (à faire dans RStudio).
partie: Compléments
---

# Des données prêtes à l'emploi

Eurostat, l'office statistique de l'Union européenne, met à disposition des milliers de tableaux : pauvreté, chômage, PIB, démographie, environnement… Le paquet **eurostat** permet de les chercher et de les télécharger directement depuis R.


```r norun
install.packages("eurostat")   # une seule fois
library(eurostat)
library(tidyverse)
```

# 1. Trouver les données

```r
search_poverty <- search_eurostat("poverty")
head(search_poverty)
```

::: usage
`search_eurostat("mot-clé")` renvoie la liste des tableaux dont le titre contient le mot-clé (en anglais), avec leur **code**. Ici, un tableau intéressant : *People at risk of poverty or social exclusion by age and sex*, code `ilc_peps01`.
:::

```r
bdd_poverty <- get_eurostat("ilc_peps01")
```

# 2. Comprendre les données : chaque colonne

On applique la démarche habituelle : `glimpse()`, puis `table()` sur chaque variable catégorielle.

```r
glimpse(bdd_poverty)

table(bdd_poverty$freq)        # toujours la même valeur : annuelle
table(bdd_poverty$unit)        # plusieurs unités : il faudra en choisir une
table(bdd_poverty$age)         # des tranches d'âge, et un total (TOTAL)
table(bdd_poverty$sex)         # F, M et un total (T)
table(bdd_poverty$geo)         # un code par pays
table(bdd_poverty$TIME_PERIOD) # une date au 1er janvier par année
summary(bdd_poverty$values)    # la valeur, dont l'unité dépend de unit
```

::: piege
**Le piège classique d'Eurostat :** la colonne `values` mélange plusieurs **unités** (pourcentages, milliers de personnes…) et contient des lignes de **total** (`sex == "T"`, `age == "TOTAL"`). Calculer une moyenne sans filtrer additionnerait des pourcentages et des effectifs, et compterait certaines personnes deux fois.
:::

# Des libellés lisibles : label_eurostat()

```r
bdd_poverty_FR <- label_eurostat(bdd_poverty, lang = "fr")
table(bdd_poverty_FR$unit)
```

::: usage
`label_eurostat()` remplace les codes (`PC`, `Y_LT16`…) par leurs libellés. On garde les **codes** pour filtrer (ils sont stables et courts), et on applique les **libellés** juste avant d'afficher.
:::

# 3. Le tableau de synthèse

« Taux de pauvreté ou d'exclusion sociale en France, par âge, depuis 2015 » : on retrouve exactement les verbes du cours.

```r
bdd_poverty |>
  filter(unit == "PC", sex == "T", geo == "FR", year(TIME_PERIOD) >= 2015,
         age %in% c("TOTAL", "Y_LT16", "Y16-24", "Y25-49", "Y50-64", "Y_GE65")) |>
  label_eurostat(lang = "fr") |>
  mutate(ANNEE = year(TIME_PERIOD)) |>
  select(ANNEE, age, values) |>
  pivot_wider(names_from = ANNEE, values_from = values)
```

::: note
`filter()` fixe **toutes** les dimensions sauf celles qu'on veut voir (l'âge et l'année) : une seule unité, le total des sexes, un seul pays. C'est la condition pour que chaque case du tableau contienne **une seule** valeur.
:::

# 4. Le graphique

```r
bdd_poverty |>
  filter(unit == "PC", sex == "T", geo == "FR", year(TIME_PERIOD) >= 2015,
         age %in% c("TOTAL", "Y_LT16", "Y16-24", "Y25-49", "Y50-64", "Y_GE65")) |>
  label_eurostat(lang = "fr") |>
  mutate(ANNEE = year(TIME_PERIOD)) |>
  ggplot(aes(x = ANNEE, y = values, colour = age)) +
  geom_line(linewidth = 1) +
  theme_minimal() +
  theme(legend.position = "bottom") +
  labs(title = "Taux de pauvreté ou d'exclusion sociale en France, par âge",
       subtitle = "Données Eurostat", x = "Année", y = "%", colour = NULL)
```

# À vous de jouer (dans RStudio)

Pour chaque question : trouvez le tableau avec `search_eurostat()`, comprenez ses colonnes avec `table()`, filtrez **toutes** les dimensions, puis présentez le résultat avec `pivot_wider()`.

1. Taux de chômage en Allemagne des 15-74 ans, par sexe et par année, entre 2010 et 2020 (`une_rt_a`).
2. PIB par habitant en France, en Allemagne et en Italie entre 2000 et 2020 (`nama_10_pc`).
3. Espérance de vie à la naissance par sexe en Espagne entre 2005 et 2015 (`demo_mlexpec`).
4. Indice des prix à la consommation en Grèce entre 2010 et 2020 (`prc_hicp_aind`).
5. Part de la population diplômée du supérieur en Suède, par groupe d'âge, en 2018 (`edat_lfse_03`).

::: note
Une correction possible pour la première question :

```
bdd_chomage <- get_eurostat("une_rt_a")

bdd_chomage |>
  filter(geo == "DE", sex %in% c("F", "M"), age == "Y15-74", unit == "PC_ACT",
         year(TIME_PERIOD) >= 2010, year(TIME_PERIOD) <= 2020) |>
  label_eurostat(lang = "fr") |>
  mutate(ANNEE = year(TIME_PERIOD)) |>
  select(ANNEE, sex, values) |>
  pivot_wider(names_from = sex, values_from = values)
```
:::
