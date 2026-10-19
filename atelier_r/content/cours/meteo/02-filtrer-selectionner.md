---
titre: Filtrer et sélectionner
resume: Garder certaines lignes avec filter(), certaines colonnes avec select().
partie: Les bases
---

# filter() : garder certaines lignes

::: usage
**À quoi ça sert ?** Réduire le nombre de **lignes** selon une ou plusieurs conditions, pour travailler sur une sous-population.

**Écriture :** `BDD |> filter(condition)`
:::

```r
# Les relevés de Lille
BDD_METEO |> filter(name == "Lille")
```

# Les opérateurs d'une condition

| Opérateur | Sens | Exemple |
|---|---|---|
| `==` | égal à | `name == "Lille"` |
| `!=` | différent de | `name != "Nice"` |
| `>`, `>=`, `<`, `<=` | comparaisons | `tmax > 35` |
| `&` | ET (les deux conditions) | `name == "Lille" & tmax > 30` |
| `|` | OU (au moins une condition) | `name == "Nice" | name == "Bastia"` |
| `%in%` | fait partie de la liste | `name %in% c("Nice", "Bastia")` |
| `is.na()` | valeur manquante | `is.na(prcp)` |
| `!` | contraire de | `!is.na(prcp)` |

```r
# Les jours à plus de 40 °C
BDD_METEO |> filter(tmax > 40)
```

::: note
**Lecture :** sur près de 80 000 relevés, seuls 26 relevés (ville × jour) dépassent 40 °C, regroupées en quelques vagues de chaleur (juin et juillet 2019, juillet 2022…). Le record de la base est à Montpellier le 28 juin 2019 (43,5 °C).
:::

# Plusieurs conditions

```r
# Les jours de gel à Lille
BDD_METEO |> filter(name == "Lille" & tmin < 0)

# Même chose en enchaînant deux filtres
BDD_METEO |>
  filter(name == "Lille") |>
  filter(tmin < 0) |>
  count()
```

::: piege
`=` sert à nommer un argument ; `==` sert à **tester** une égalité. Dans `filter()`, c'est toujours `==`. Et le texte s'écrit entre guillemets, **exactement** comme dans la base : `"Lyon / Bron"`, pas `"Lyon"`.
:::

# Filtrer sur une date

Une colonne de type `<date>` se compare à une date écrite entre guillemets, au format année-mois-jour, transformée avec `as.Date()`.

```r
# L'été 2019 à Montpellier
BDD_METEO |>
  filter(name == "Montpellier",
         date >= as.Date("2019-06-21"),
         date <= as.Date("2019-09-22"))
```

::: note
Dans `filter()`, une **virgule** entre deux conditions équivaut à `&`.
:::

# %in% : une liste de valeurs

```r
# Les villes du littoral méditerranéen
BDD_METEO |> filter(name %in% c("Nice", "Bastia", "Perpignan", "Marseille / Marignane", "Montpellier"))
```

::: usage
`%in%` teste si une valeur fait partie d'une liste créée avec `c()` : beaucoup plus court qu'une suite de `|`.
:::

# is.na() : les valeurs manquantes

```r
# Les jours où la pluie n'a pas été mesurée
BDD_METEO |> filter(is.na(prcp))

# Le contraire : pluie mesurée
BDD_METEO |> filter(!is.na(prcp)) |> count()
```

::: piege
On n'écrit jamais `prcp == NA` : le résultat est toujours `NA`, et `filter()` ne garde aucune ligne. Pour tester une valeur manquante, c'est `is.na()`.
:::

# select() : garder certaines colonnes

```r
# Lille, avec seulement les colonnes utiles
BDD_LILLE <- BDD_METEO |>
  filter(name == "Lille") |>
  select(name, date, temp, tmin, tmax, prcp)

BDD_LILLE
```

::: note
**À retenir :** `filter()` agit sur les **lignes**, `select()` agit sur les **colonnes**.
:::

# Retirer des colonnes avec les fonctions d'aide

Un signe `-` devant un nom **retire** la colonne. Les fonctions d'aide évitent de citer les colonnes une par une.

```r
# Les colonnes *_source documentent l'origine de chaque mesure : inutiles ici
BDD_METEO |>
  select(-ends_with("_source")) |>
  ncol()
```

| Fonction | Sélectionne les colonnes… |
|---|---|
| `starts_with("tm")` | dont le nom commence par `tm` |
| `ends_with("_source")` | dont le nom se termine par `_source` |
| `contains("temp")` | dont le nom contient `temp` |
| `where(is.numeric)` | qui sont numériques |
