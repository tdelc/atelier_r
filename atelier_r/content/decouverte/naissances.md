---
base: naissances
---

# Explorer une variable au choix

Les trois commandes de base pour découvrir une variable : un aperçu, un résumé, une distribution. Le code ci-dessous regarde l'âge du père.

```r
head(BDD_NAIS$AGEPERE)
summary(BDD_NAIS$AGEPERE)
hist(BDD_NAIS$AGEPERE)
```

## À essayer

- Remplacez `AGEPERE` par `AGEXACTP` (l'âge **exact** du père) : les deux histogrammes sont-ils identiques ?
- Essayez `hist(BDD_NAIS$AGEMERE, breaks = 30, col = "lightblue")`.
- Pour une variable catégorielle comme `SITUATPR`, remplacez `summary()` et `hist()` par `table(BDD_NAIS$SITUATPR, useNA = "ifany")`.
- Que donne `summary()` sur une colonne de texte, comme `DEPNAIS` ?

# Filtrer une population

Combien de naissances dans votre département ? Et parmi elles, combien de filles ?

```r
BDD_NAIS |>
  filter(DEPNAIS == "59") |>
  count()

BDD_NAIS |>
  filter(DEPNAIS == "59" & SEXE == 2) |>
  count()
```

## À essayer

- Changez le département : `"75"`, `"69"`, `"2A"`, `"971"`…
- Retirez les guillemets autour de `"59"` : que se passe-t-il ? Pourquoi ?
- Remplacez `&` par `|` : le résultat a-t-il un sens ?
- Comptez les naissances dont la mère a **moins de 20 ans** dans toute la France.
- Utilisez `%in%` pour compter les naissances de plusieurs départements à la fois.

# Comparer des groupes

Un indicateur, calculé pour chaque modalité d'une variable de groupe. Ici, l'âge moyen des parents selon le nombre d'enfants issus de l'accouchement.

```r
BDD_NAIS |>
  group_by(NBENF) |>
  summarise(NB       = n(),
            AGE_MERE = mean(AGEMERE),
            AGE_PERE = mean(AGEPERE))
```

## À essayer

- Remplacez `NBENF` par `SEXE`, puis par `INDNATM`, puis par `TUDOM`.
- Ajoutez un indicateur : `MEDIANE_MERE = median(AGEMERE)`.
- Ajoutez un `filter()` avant le `group_by()` pour ne garder qu'un département.
- Regroupez selon **deux** variables : `group_by(SEXE, NBENF)`.

# Créer des catégories avec cut()

Découper l'âge de la mère en tranches, puis compter. Les bornes sont un **choix** : modifiez-les et regardez ce qui change.

```r
BDD_NAIS |>
  mutate(TRANCHE = cut(AGEMERE,
                       breaks = c(0, 25, 35, 50),
                       labels = c("25 ans ou moins", "26-35 ans", "36 ans ou plus"))) |>
  count(TRANCHE)
```

## À essayer

- Ajoutez une borne pour avoir 4 tranches (n'oubliez pas d'ajouter une étiquette !).
- Mettez une borne maximale à `40` au lieu de `50` : que deviennent les mères plus âgées ?
- Remplacez `count(TRANCHE)` par `group_by(TRANCHE) |> summarise(PART_MARIES = mean(AMAR != "0000"))`.

# Construire un tableau croisé

Un `count()` sur deux variables, puis un `pivot_wider()` pour passer l'une d'elles en colonnes.

```r
BDD_NAIS |>
  group_by(INDNATM, SEXE) |>
  count() |>
  pivot_wider(names_from = SEXE, values_from = n, names_prefix = "SEXE_")
```

## À essayer

- Remplacez `INDNATM` par `ORIGINOM`, ou `SEXE` par `NBENF`.
- Que se passe-t-il si vous inversez `names_from = SEXE` et la variable des lignes ?
- Remplacez `count()` par `summarise(AGE_MERE = mean(AGEMERE))` (pensez à changer `values_from`).

# Classer les départements

Quels départements ont les mères les plus jeunes ? Un indicateur par département, puis un tri.

```r
BDD_NAIS |>
  group_by(DEPNAIS) |>
  summarise(NB = n(),
            AGE_MERE = mean(AGEMERE)) |>
  arrange(AGE_MERE)
```

## À essayer

- Triez dans l'autre sens avec `arrange(desc(AGE_MERE))`.
- Classez les départements selon la part de naissances multiples : `mean(NBENF >= 2)`.
- Classez-les selon la part de mères nées à l'étranger : `mean(INDLNM == 4)`.
- Ajoutez `|> print(n = 20)` pour voir plus de lignes.

# Un premier graphique

Un graphique ggplot2 : on calcule d'abord un tableau, puis on le dessine.

```r
NAIS_MOIS <- BDD_NAIS |>
  count(MNAIS)

ggplot(NAIS_MOIS, aes(x = MNAIS, y = n)) +
  geom_col(fill = "#3b6ea5") +
  labs(title = "Naissances par mois", x = "Mois", y = "Naissances") +
  theme_minimal()
```

## À essayer

- Changez la couleur (`fill = "darkorange"`), le titre, le thème (`theme_classic()`).
- Remplacez `geom_col` par `geom_point(size = 3)`.
- Comptez par `MNAIS` **et** `SEXE`, puis ajoutez `fill = factor(SEXE)` dans `aes()` et `position = "dodge"` dans `geom_col()`.
- Dessinez un histogramme de l'âge du père : `ggplot(BDD_NAIS, aes(x = AGEPERE)) + geom_histogram(binwidth = 1)`.

# Votre propre question

Un squelette à compléter. Choisissez une population (`filter`), des groupes (`group_by`) et un indicateur (`summarise`).

```r
BDD_NAIS |>
  filter(DEPNAIS %in% c("59", "62")) |>
  group_by(DEPNAIS, SEXE) |>
  summarise(NB = n(),
            AGE_MOYEN_MERE = mean(AGEMERE),
            PART_JUMEAUX = mean(NBENF >= 2))
```

## À essayer

- Écrivez d'abord votre question **en français**, puis traduisez-la avec le dictionnaire de la leçon « Traduire une phrase en R ».
- Ouvrez le **Dictionnaire** (en haut de l'écran) pour trouver d'autres variables.
- Pensez à vérifier chaque variable créée avec `count()` ou `summary()`.
