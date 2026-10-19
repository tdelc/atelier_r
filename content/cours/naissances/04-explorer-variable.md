---
titre: Explorer une variable
resume: Les fonctions de R base pour regarder une colonne - summary(), hist(), table(), mean(), quantile().
partie: Les bases
---

# Les fonctions de R base

Elles existent sans charger de paquet. La plupart travaillent sur **une colonne** (un vecteur), qu'on désigne avec `$`, et non sur un tableau entier : on ne les enchaîne pas avec des verbes.

| Je veux… | Fonction |
|---|---|
| un résumé d'une variable numérique | `summary(BDD$COL)` |
| voir sa distribution | `hist(BDD$COL)` |
| compter les modalités d'une variable catégorielle | `table(BDD$COL)` |
| un indicateur précis | `mean()`, `median()`, `quantile()`… |

# summary() : résumé d'une variable numérique

```r
summary(BDD_NAIS$AGEPERE)
```

::: usage
`summary()` affiche en une commande le minimum, les quartiles, la médiane, la moyenne et le maximum. Pratique pour **vérifier** une variable qu'on vient de créer.
:::

::: piege
`summary()` porte sur **toute** la colonne : impossible de filtrer avant. Pour la médiane de l'âge des mères en Loire-Atlantique, il faut passer par les verbes : `filter()` puis `summarise()`.
:::

# hist() : la distribution

```r
hist(BDD_NAIS$AGEPERE)
```

Remarquez le **pic à droite**, sur la dernière barre : il y aurait autant de pères de 46 ans que de pères de 35 ans ?

::: note
**Lecture :** c'est un effet de codage. D'après la documentation de l'INSEE, la valeur 46 signifie « **46 ans ou plus** » (et 17 signifie « 17 ans ou moins »). Tous les pères de 46, 50 ou 60 ans sont regroupés dans la dernière barre. Un histogramme fait apparaître en un coup d'œil ce genre de particularité, qu'une moyenne cacherait.
:::

# hist() avec des réglages

```r
hist(BDD_NAIS$AGEMERE,
     breaks = 30,
     main = "Âge des mères à la naissance (2021)",
     xlab = "Âge de la mère",
     ylab = "Nombre de naissances",
     col = "lightblue")
```

::: usage
`breaks` règle le nombre de barres, `main` le titre, `xlab` / `ylab` les titres des axes, `col` la couleur.
:::

# table() : compter les modalités

```r
table(BDD_NAIS$SEXE)
table(BDD_NAIS$NBENF)
```

::: usage
`table()` compte le nombre d'occurrences de chaque modalité. Équivalent tidyverse : `BDD |> count(COLONNE)`.
:::

# Ne pas oublier les valeurs manquantes

```r
table(BDD_NAIS$SITUATMR)
table(BDD_NAIS$SITUATMR, useNA = "ifany")
```

::: piege
Sans `useNA = "ifany"`, `table()` ignore les `NA` **en silence** : la première version « oublie » plus de 120 000 mères. Ici, d'après la documentation, `NA` signifie « **sans activité ou retraitée** » : ce n'est pas une donnée manquante, c'est une modalité à part entière !
:::

# mean(), median(), quantile() sur une colonne

```r
mean(BDD_NAIS$AGEMERE)
median(BDD_NAIS$AGEMERE)
quantile(BDD_NAIS$AGEMERE, 0.75)
quantile(BDD_NAIS$AGEMERE, c(0.1, 0.9))
```

::: usage
**Arguments utiles :**

- `na.rm = TRUE` pour ignorer les valeurs manquantes ;
- pour `quantile()`, la probabilité voulue : 0.25 (Q1), 0.5 (médiane), 0.75 (Q3), 0.9 (9e décile)…
:::

# c() et %in% : créer une liste de valeurs

```r
c("59", "62", "02", "60", "80")

HDF <- c("59", "62", "02", "60", "80")
BDD_NAIS |> filter(DEPNAIS %in% HDF) |> count()
```

::: note
`c()` rassemble plusieurs valeurs dans un vecteur. On peut le ranger dans un objet (`HDF`) pour le réutiliser plusieurs fois.
:::
