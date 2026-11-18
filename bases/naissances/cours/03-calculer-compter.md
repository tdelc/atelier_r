---
titre: Calculer et compter
resume: Résumer une base en un indicateur avec summarise(), compter les lignes avec count().
partie: Les bases
---

# summarise() : calculer un indicateur

::: usage
**À quoi ça sert ?** Résumer tout le tableau (ou chaque groupe, voir la leçon suivante) en **une valeur** : moyenne, médiane, effectif…

**Écriture :** `BDD |> summarise(NOM = fonction(COLONNE))`
:::

```r
# Âge moyen des mères
BDD_NAIS |> summarise(mean(AGEMERE))
```

# Les fonctions de calcul

| Fonction | Calcule |
|---|---|
| `mean()` | la moyenne |
| `median()` | la médiane |
| `min()`, `max()` | le minimum, le maximum |
| `sd()` | l'écart-type |
| `quantile(x, 0.25)` | un quantile (ici le 1er quartile) |
| `n()` | le nombre de lignes |

```r
# Plusieurs indicateurs d'un coup, avec des noms de colonnes lisibles
BDD_NAIS |>
  summarise(AGE_MERE_MOYEN  = mean(AGEMERE),
            AGE_MERE_MEDIAN = median(AGEMERE),
            AGE_MERE_MIN    = min(AGEMERE),
            AGE_MERE_MAX    = max(AGEMERE),
            AGE_MERE_SD     = sd(AGEMERE),
            AGE_MERE_Q1     = quantile(AGEMERE, 0.25),
            AGE_MERE_Q3     = quantile(AGEMERE, 0.75))
```

::: note
Nommer les colonnes (`AGE_MERE_MOYEN = ...`) évite des noms illisibles comme `` `mean(AGEMERE)` ``.
:::

# Filtrer avant de calculer

```r
# Âge moyen des mères dans le Nord : on filtre AVANT de calculer
BDD_NAIS |>
  filter(DEPNAIS == "59") |>
  summarise(AGE_MERE_MOYEN = mean(AGEMERE))
```

::: piege
Si la colonne contient des valeurs manquantes (`NA`), le résultat vaut `NA`. Ajoutez alors `na.rm = TRUE` : `mean(AGEPERE, na.rm = TRUE)`. Dans la base des naissances, `AGEMERE` et `AGEPERE` sont complètes ; ce ne sera pas le cas dans la base météo.
:::

# count() : compter les lignes

::: usage
**À quoi ça sert ?** Compter le nombre de lignes, donc ici le **nombre de naissances**. Le résultat est une colonne appelée `n`.
:::

```r
# Nombre total de naissances
BDD_NAIS |> count()

# Équivalent avec summarise
BDD_NAIS |> summarise(NB = n())
```

# Compter une sous-population

```r
# Nombre de naissances à Paris
BDD_NAIS |>
  filter(DEPNAIS == "75") |>
  count()

# Nombre de naissances multiples (jumeaux ou plus)
BDD_NAIS |>
  filter(NBENF >= 2) |>
  count()
```

::: note
Attention à l'interprétation : une ligne est **un enfant**, et `NBENF` est recopié sur chaque enfant. Des jumeaux nés vivants font donc en général deux lignes, avec chacune `NBENF = 2`. Les 22 687 lignes sont des **enfants** nés d'un accouchement multiple, pas des accouchements.
:::
