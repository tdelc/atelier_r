---
titre: Filtrer et sélectionner
resume: Garder certaines lignes avec filter(), certaines colonnes avec select().
partie: Les bases
---

# filter() : garder certaines lignes

Un **verbe** du tidyverse prend un tableau en entrée et renvoie un tableau en sortie. C'est ce qui permet de les enchaîner avec `|>`.

::: usage
**À quoi ça sert ?** Réduire le nombre de **lignes** selon une ou plusieurs conditions, pour travailler sur une sous-population.

**Écriture :** `BDD |> filter(condition)`
:::

```r
# Naissances dans le Nord
BDD_NAIS |> filter(DEPNAIS == "59")
```

On passe de 742 052 à 32 220 lignes : ce sont les naissances du Nord.

# Les opérateurs d'une condition

| Opérateur | Sens | Exemple |
|---|---|---|
| `==` | égal à | `DEPNAIS == "59"` |
| `!=` | différent de | `AMAR != "0000"` (parents mariés) |
| `>`, `>=`, `<`, `<=` | comparaisons | `AGEPERE >= 46` |
| `&` | ET (les deux conditions) | `DEPNAIS == "59" & SEXE == 1` |
| `|` | OU (au moins une condition) | `DEPNAIS == "59" | DEPNAIS == "62"` |
| `%in%` | fait partie de la liste | `DEPNAIS %in% c("59", "62")` |
| `is.na()` | valeur manquante | `is.na(ORIGINOM)` |
| `!` | contraire de | `!is.na(ORIGINOM)` |

```r
# Naissances de parents mariés
BDD_NAIS |> filter(AMAR != "0000")
```

::: piege
`=` sert à nommer ou à régler un argument ; `==` sert à **tester** une égalité. Dans `filter()`, c'est toujours `==`.
:::

# Plusieurs conditions

```r
# Garçons nés dans le Nord
BDD_NAIS |> filter(DEPNAIS == "59" & SEXE == 1)
```

On obtient le même résultat en enchaînant deux filtres :

```r
BDD_NAIS |>
  filter(DEPNAIS == "59") |>
  filter(SEXE == 1)
```

::: note
`SEXE` est un nombre : pas de guillemets. `DEPNAIS` est du texte : guillemets obligatoires. En cas de doute, `glimpse()` donne le type de chaque colonne.
:::

# %in% : une liste de valeurs

```r
# Les départements des Hauts-de-France
BDD_NAIS |> filter(DEPNAIS %in% c("59", "62", "02", "60", "80"))
```

::: usage
`%in%` teste si une valeur fait partie d'une liste créée avec `c()`. C'est beaucoup plus court qu'une suite de `|` :
`DEPNAIS == "59" | DEPNAIS == "62" | DEPNAIS == "02" | …`
:::

# is.na() : les valeurs manquantes

```r
# Origine du nom de famille inconnue
BDD_NAIS |> filter(is.na(ORIGINOM))
```

761 naissances n'ont pas d'origine du nom : ce sont les naissances enregistrées par **jugement déclaratif**, pour lesquelles l'INSEE ne dispose pas de l'information.

```r
# Le contraire : origine connue
BDD_NAIS |> filter(!is.na(ORIGINOM)) |> count()
```

::: piege
On n'écrit jamais `ORIGINOM == NA` : le résultat est toujours `NA`, et `filter()` ne garde aucune ligne. Pour tester une valeur manquante, c'est `is.na()`.
:::

# select() : garder certaines colonnes

::: usage
**À quoi ça sert ?** Choisir les **colonnes** à conserver.

**Écriture :** `BDD |> select(COL1, COL2, ...)`
:::

```r
# Enfants nés dans le Rhône : on ne garde que 3 colonnes
BDD_NAIS_RHONE <- BDD_NAIS |>
  filter(DEPNAIS == "69") |>
  select(DEPNAIS, SEXE, AGEMERE)

BDD_NAIS_RHONE
```

::: note
**À retenir :** `filter()` agit sur les **lignes**, `select()` agit sur les **colonnes**.
:::

# Retirer des colonnes

Un signe `-` devant un nom **retire** la colonne. Les fonctions d'aide évitent de citer les colonnes une par une.

```r
# Retirer les jours, mois et années de reconnaissance
BDD_NAIS |>
  select(-starts_with("JREC"), -starts_with("MREC"), -starts_with("AREC")) |>
  ncol()
```

| Fonction | Sélectionne les colonnes… |
|---|---|
| `starts_with("AGE")` | dont le nom commence par `AGE` |
| `ends_with("M")` | dont le nom se termine par `M` |
| `contains("REC")` | dont le nom contient `REC` |
| `where(is.numeric)` | qui sont numériques |
