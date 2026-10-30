---
titre: Les pourcentages d'un tableau croisé
resume: Pourcentage du total, en ligne ou en colonne - choisir le bon dénominateur, c'est choisir la question.
partie: Les bases
---

# Un tableau croisé, trois pourcentages

Un tableau croisé compte les naissances pour chaque combinaison de deux variables catégorielles. Pour comparer, on passe en **pourcentages**, mais **trois** calculs sont possibles. Ils répondent à trois questions différentes :

| Pourcentage | Dénominateur | Chaque … fait 100 % | Question à laquelle il répond |
|---|---|---|---|
| **du total** | toutes les naissances | le tableau entier | « Quelle part de l'ensemble représente chaque case ? » |
| **en ligne** | le total de la ligne | chaque ligne | « Au sein de chaque groupe en ligne, comment se répartit la variable en colonne ? » |
| **en colonne** | le total de la colonne | chaque colonne | « Au sein de chaque groupe en colonne, comment se répartit la variable en ligne ? » |

::: piege
C'est **l'erreur la plus fréquente** dans les rapports : présenter un pourcentage en ligne et le commenter comme un pourcentage en colonne. Avant chaque tableau, demandez-vous : **qu'est-ce qui fait 100 % ?**
:::

Nous croisons ici la **nationalité de la mère** (`INDNATM` : 1 = française, 2 = étrangère) et la **situation de mariage** des parents.

# Le point de départ : les effectifs

```r
BDD_NAIS <- BDD_NAIS |>
  mutate(NATIO_MERE = if_else(INDNATM == 1, "Française", "Étrangère"),
         MARIES     = if_else(AMAR != "0000", "Mariés", "Non mariés"))

BDD_NAIS |>
  count(NATIO_MERE, MARIES) |>
  pivot_wider(names_from = MARIES, values_from = n)
```

::: note
Les effectifs bruts sont difficiles à comparer : il y a 4,5 fois plus de mères françaises que de mères étrangères. On ne peut pas conclure en comparant directement 195 135 et 75 544 naissances de parents mariés.
:::

# 1. Le pourcentage du total

Le dénominateur est le **nombre total** de naissances : on divise chaque effectif par `sum(n)` **sans** `group_by()`.

```r
BDD_NAIS |>
  count(NATIO_MERE, MARIES) |>
  mutate(PCT = round(100 * n / sum(n), 1)) |>
  select(-n) |>
  pivot_wider(names_from = MARIES, values_from = PCT)
```

::: note
**Lecture :** les quatre cases font 100 % au total. « 55,6 % des naissances de 2021 sont des naissances hors mariage d'une mère française. » Ce pourcentage mélange deux informations (la nationalité **et** le mariage) : il décrit la **composition** de la population, mais ne permet pas de comparer les groupes.
:::

# 2. Le pourcentage en ligne

Le dénominateur est le **total de chaque ligne** : on regroupe par la variable **en ligne** avant de diviser.

```r
BDD_NAIS |>
  count(NATIO_MERE, MARIES) |>
  group_by(NATIO_MERE) |>                       # dénominateur = chaque nationalité
  mutate(PCT = round(100 * n / sum(n), 1)) |>
  ungroup() |>
  select(-n) |>
  pivot_wider(names_from = MARIES, values_from = PCT)
```

::: note
**Lecture :** chaque **ligne** fait 100 %. Parmi les naissances de mère française, 67,9 % ont lieu hors mariage ; parmi celles de mère étrangère, 43,6 %. C'est le tableau qui permet de **comparer les nationalités** : la variable en ligne est la variable « explicative », celle en colonne la variable « expliquée ».
:::

::: usage
**La recette :** `count(A, B)` → `group_by(A)` → `mutate(PCT = n / sum(n))` → `ungroup()`.

Le `group_by()` placé **avant** le `mutate()` décide du dénominateur : `sum(n)` devient alors la somme **à l'intérieur de chaque groupe**.
:::

# 3. Le pourcentage en colonne

Même recette, mais on regroupe par la variable **en colonne**.

```r
BDD_NAIS |>
  count(NATIO_MERE, MARIES) |>
  group_by(MARIES) |>                           # dénominateur = chaque statut
  mutate(PCT = round(100 * n / sum(n), 1)) |>
  ungroup() |>
  select(-n) |>
  pivot_wider(names_from = MARIES, values_from = PCT)
```

::: note
**Lecture :** chaque **colonne** fait 100 %. Parmi les naissances hors mariage, 87,6 % ont une mère française ; parmi les naissances de parents mariés, 72,1 %. Ce tableau décrit la **composition** de chaque groupe de parents, il ne dit pas directement « qui se marie le plus ».
:::

::: piege
Les deux phrases « 67,9 % des mères françaises ont un enfant hors mariage » (en ligne) et « 87,6 % des naissances hors mariage concernent une mère française » (en colonne) sont toutes deux justes… et ne disent pas du tout la même chose. La seconde reflète surtout le fait que la grande majorité des mères sont françaises.
:::

# Vérifier : la somme doit faire 100

Un pourcentage se vérifie toujours : on additionne dans le sens qui doit faire 100 %.

```r
PCT_LIGNE <- BDD_NAIS |>
  count(NATIO_MERE, MARIES) |>
  group_by(NATIO_MERE) |>
  mutate(PCT = 100 * n / sum(n)) |>
  ungroup()

# Chaque ligne doit faire 100
PCT_LIGNE |>
  group_by(NATIO_MERE) |>
  summarise(TOTAL = sum(PCT))
```

::: note
Si vous obtenez 100 pour chaque **ligne**, c'est un pourcentage en ligne. Si vous obtenez 100 pour chaque **colonne**, c'est un pourcentage en colonne. Si un seul total fait 100, c'est un pourcentage du total.
:::

# La version R base : prop.table()

`table()` et `prop.table()` donnent les trois pourcentages en une ligne. L'argument `margin` choisit le dénominateur.

```r
TAB <- table(BDD_NAIS$NATIO_MERE, BDD_NAIS$MARIES)
TAB

round(100 * prop.table(TAB), 1)                # du total
round(100 * prop.table(TAB, margin = 1), 1)    # en ligne   (margin = 1 : les lignes)
round(100 * prop.table(TAB, margin = 2), 1)    # en colonne (margin = 2 : les colonnes)
```

::: usage
`addmargins()` ajoute les totaux de lignes et de colonnes, très utile pour vérifier : `addmargins(round(100 * prop.table(TAB, margin = 1), 1))`.
:::

# Avec plus de deux modalités

La recette reste la même quand les variables ont plus de modalités. Ici : la part de chaque origine du nom de famille, **pour chaque** tranche d'âge de la mère (pourcentage en ligne).

```r
BDD_NAIS |>
  filter(!is.na(ORIGINOM)) |>
  mutate(AGE_MERE = cut(AGEMERE, breaks = c(0, 24, 34, 50),
                        labels = c("24 ans ou moins", "25-34 ans", "35 ans ou plus"))) |>
  count(AGE_MERE, ORIGINOM) |>
  group_by(AGE_MERE) |>
  mutate(PCT = round(100 * n / sum(n), 1)) |>
  ungroup() |>
  select(-n) |>
  pivot_wider(names_from = ORIGINOM, values_from = PCT, names_prefix = "NOM_")
```

::: note
**Lecture :** chez les mères de 24 ans ou moins, 15,5 % des enfants portent le nom de la mère seule (`NOM_2`), contre 5 à 6 % chez les mères plus âgées. Le pourcentage **en ligne** permet de comparer les tranches d'âge entre elles, quelle que soit leur taille.
:::

# Le même raisonnement en graphique

Dans ggplot2, `position = "fill"` dessine des barres qui font toutes 100 % : c'est un pourcentage **par barre**, donc par modalité de la variable en `x`.

```r
BDD_NAIS |>
  ggplot(aes(x = NATIO_MERE, fill = MARIES)) +
  geom_bar(position = "fill") +
  scale_y_continuous(labels = percent) +
  labs(x = NULL, y = NULL, fill = NULL,
       title = "Part des naissances hors mariage selon la nationalité de la mère") +
  theme_minimal()
```

::: usage
Choisir la variable en `x`, c'est choisir le dénominateur : ici chaque **nationalité** fait 100 %, c'est l'équivalent graphique du pourcentage en ligne.
:::

# À retenir

::: etape
1. **Qu'est-ce qui fait 100 % ?** C'est la question à se poser avant tout tableau en pourcentages.
2. **Pour comparer des groupes**, on calcule les pourcentages **à l'intérieur** de chaque groupe : le groupe est la variable du `group_by()`.
3. **Écrivez le dénominateur** dans le titre ou la note de lecture : « Part des naissances hors mariage, **parmi les naissances de mère française** ».
4. **Vérifiez** que les sommes font 100 dans le bon sens.
:::

| Je veux… | Tidyverse | R base |
|---|---|---|
| % du total | `mutate(n / sum(n))` sans groupe | `prop.table(TAB)` |
| % en ligne | `group_by(VAR_LIGNE)` puis `mutate(n / sum(n))` | `prop.table(TAB, margin = 1)` |
| % en colonne | `group_by(VAR_COLONNE)` puis `mutate(n / sum(n))` | `prop.table(TAB, margin = 2)` |
