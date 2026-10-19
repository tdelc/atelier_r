---
titre: Calculer par groupe
resume: Découper la base par ville, par année, par mois avec group_by().
partie: Les bases
---

# group_by() : calculer dans chaque groupe

::: usage
**À quoi ça sert ?** Préparer un découpage de la base selon les modalités d'une (ou plusieurs) variable(s), pour que le calcul suivant (`summarise` ou `count`) soit fait **dans chaque groupe**.

**Écriture :** `BDD |> group_by(VARIABLE) |> summarise(...)`
:::

```r
# Nombre de relevés par ville
BDD_METEO |>
  group_by(name) |>
  count()
```

# Plusieurs indicateurs par ville

```r
BDD_METEO |>
  group_by(name) |>
  summarise(TEMP_MOY   = mean(temp, na.rm = TRUE),
            NB_JOURS_35 = sum(tmax > 35, na.rm = TRUE),
            PART_PLUIE  = mean(prcp > 0, na.rm = TRUE))
```

::: note
**Lecture :** Nice, Bastia et Perpignan sont les villes les plus chaudes en moyenne… mais ce ne sont pas celles qui connaissent le plus de jours à plus de 35 °C : c'est Montélimar, dans la vallée du Rhône. Une moyenne et un indicateur d'extrême racontent deux histoires différentes.
:::

# Trier le résultat

```r
BDD_METEO |>
  group_by(name) |>
  summarise(TEMP_MOY = mean(temp, na.rm = TRUE)) |>
  arrange(desc(TEMP_MOY))
```

::: usage
`arrange(desc(COLONNE))` trie du plus grand au plus petit. Sans `desc()`, l'ordre est croissant.
:::

# Filtrer, puis regrouper, puis calculer

```r
# Dans les villes méditerranéennes, la pluie selon la ville
BDD_METEO |>
  filter(name %in% c("Nice", "Bastia", "Perpignan", "Marseille / Marignane", "Montpellier")) |>
  group_by(name) |>
  summarise(PLUIE_MOY = mean(prcp, na.rm = TRUE),
            PART_PLUIE = mean(prcp > 0, na.rm = TRUE))
```

::: usage
**L'ordre des verbes** suit presque toujours la même logique :

1. `filter()` — de qui parle-t-on ?
2. `group_by()` — comparé selon quoi ?
3. `summarise()` ou `count()` — quel calcul ?
:::

# Regrouper selon deux variables

Pour regrouper par année, il faut d'abord **extraire l'année** de la date, avec `year()` (voir la leçon « Créer des variables »).

```r
BDD_METEO |>
  filter(name %in% c("Lille", "Nice")) |>
  group_by(name, annee = year(date)) |>
  summarise(TEMP_MOY = mean(temp, na.rm = TRUE)) |>
  print(n = 40)
```

::: note
On obtient **une ligne par croisement** ville × année. `print(n = 40)` affiche plus que les 10 lignes par défaut. La leçon « Mettre en forme » montre comment rendre ce tableau plus lisible avec `pivot_wider()`.
:::
