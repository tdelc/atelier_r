---
titre: Les pourcentages d'un tableau croisé
resume: Pourcentage du total, en ligne ou en colonne - choisir le bon dénominateur, c'est choisir la question.
partie: Les bases
---

# Un tableau croisé, trois pourcentages

Un tableau croisé compte les jours pour chaque combinaison de deux variables catégorielles. Pour comparer, on passe en **pourcentages**, mais **trois** calculs sont possibles. Ils répondent à trois questions différentes :

| Pourcentage | Dénominateur | Chaque … fait 100 % | Question à laquelle il répond |
|---|---|---|---|
| **du total** | tous les jours du tableau | le tableau entier | « Quelle part de l'ensemble représente chaque case ? » |
| **en ligne** | le total de la ligne | chaque ligne | « Au sein de chaque groupe en ligne, comment se répartit la variable en colonne ? » |
| **en colonne** | le total de la colonne | chaque colonne | « Au sein de chaque groupe en colonne, comment se répartit la variable en ligne ? » |

::: piege
C'est **l'erreur la plus fréquente** dans les rapports : présenter un pourcentage en ligne et le commenter comme un pourcentage en colonne. Avant chaque tableau, demandez-vous : **qu'est-ce qui fait 100 % ?**
:::

# Préparer : une variable catégorielle de pluie

On découpe la pluie du jour en classes avec `cut()`, pour quatre villes. Les jours sans mesure de pluie sont retirés (et on le signalera).

```r
PLUIE <- BDD_METEO |>
  filter(name %in% c("Lille", "Rennes", "Strasbourg", "Nice"), !is.na(prcp)) |>
  mutate(CD_PLUIE = cut(prcp,
                        breaks = c(-1, 0, 1, 5, 10, 1000),
                        labels = c("1_Sec", "2_Infime", "3_Faible", "4_Moyenne", "5_Forte")))

PLUIE |> count(CD_PLUIE)
```

::: note
`breaks = c(-1, 0, …)` : la première classe `(-1, 0]` ne contient que les jours à 0 mm, donc les jours **secs**. Les préfixes numériques gardent les classes dans l'ordre.
:::

# Le point de départ : les effectifs

```r
PLUIE |>
  count(name, CD_PLUIE) |>
  pivot_wider(names_from = CD_PLUIE, values_from = n)
```

::: note
Les quatre villes n'ont pas exactement le même nombre de jours mesurés : les effectifs bruts ne sont pas directement comparables. Il faut des pourcentages.
:::

# 1. Le pourcentage du total

Le dénominateur est le **nombre total** de jours du tableau : on divise par `sum(n)` **sans** `group_by()`.

```r
PLUIE |>
  count(name, CD_PLUIE) |>
  mutate(PCT = round(100 * n / sum(n), 1)) |>
  select(-n) |>
  pivot_wider(names_from = CD_PLUIE, values_from = PCT)
```

::: note
**Lecture :** les vingt cases font 100 % au total. Ce pourcentage mélange deux informations (la ville **et** la pluie) : il décrit la composition du tableau, mais ne permet pas de comparer les villes.
:::

# 2. Le pourcentage en ligne

Le dénominateur est le **total de chaque ligne**, ici chaque ville : on regroupe par la variable **en ligne** avant de diviser.

```r
PLUIE |>
  count(name, CD_PLUIE) |>
  group_by(name) |>                              # dénominateur = chaque ville
  mutate(PCT = round(100 * n / sum(n), 1)) |>
  ungroup() |>
  select(-n) |>
  pivot_wider(names_from = CD_PLUIE, values_from = PCT)
```

::: note
**Lecture :** chaque **ligne** fait 100 %. On lit, pour chaque ville, comment se répartissent ses jours : 77,8 % des jours mesurés à Nice sont secs, contre 48,1 % à Lille. C'est le tableau qui permet de **comparer les villes** entre elles, quel que soit leur nombre de jours mesurés.
:::

::: usage
**La recette :** `count(A, B)` → `group_by(A)` → `mutate(PCT = n / sum(n))` → `ungroup()`.

Le `group_by()` placé **avant** le `mutate()` décide du dénominateur : `sum(n)` devient alors la somme **à l'intérieur de chaque groupe**.
:::

# 3. Le pourcentage en colonne

Même recette, mais on regroupe par la variable **en colonne**, ici la classe de pluie.

```r
PLUIE |>
  count(name, CD_PLUIE) |>
  group_by(CD_PLUIE) |>                          # dénominateur = chaque classe de pluie
  mutate(PCT = round(100 * n / sum(n), 1)) |>
  ungroup() |>
  select(-n) |>
  pivot_wider(names_from = CD_PLUIE, values_from = PCT)
```

::: note
**Lecture :** chaque **colonne** fait 100 %. On lit, par exemple, la part de chaque ville **parmi les jours de forte pluie** des quatre villes. C'est une question de **composition** : « d'où viennent les jours de forte pluie ? ».
:::

::: piege
« X % des jours de Nice sont secs » (en ligne) et « X % des jours secs sont à Nice » (en colonne) ne disent pas du tout la même chose. Écrivez toujours le dénominateur dans votre phrase : « **parmi** les jours de Nice… », « **parmi** les jours secs… ».
:::

# Vérifier : la somme doit faire 100

```r
PCT_LIGNE <- PLUIE |>
  count(name, CD_PLUIE) |>
  group_by(name) |>
  mutate(PCT = 100 * n / sum(n)) |>
  ungroup()

# Chaque ville doit faire 100
PCT_LIGNE |>
  group_by(name) |>
  summarise(TOTAL = sum(PCT))
```

::: note
Si vous obtenez 100 pour chaque **ligne**, c'est un pourcentage en ligne. Si vous obtenez 100 pour chaque **colonne**, c'est un pourcentage en colonne. Si un seul total fait 100, c'est un pourcentage du total.
:::

# La version R base : prop.table()

`table()` et `prop.table()` donnent les trois pourcentages en une ligne. L'argument `margin` choisit le dénominateur.

```r
TAB <- table(PLUIE$name, PLUIE$CD_PLUIE)
TAB

round(100 * prop.table(TAB), 1)                # du total
round(100 * prop.table(TAB, margin = 1), 1)    # en ligne   (margin = 1 : les lignes)
round(100 * prop.table(TAB, margin = 2), 1)    # en colonne (margin = 2 : les colonnes)
```

::: usage
`addmargins()` ajoute les totaux de lignes et de colonnes, très utile pour vérifier : `addmargins(round(100 * prop.table(TAB, margin = 1), 1))`.
:::

# Le pourcentage en ligne dans le temps

Le pourcentage en ligne sert aussi à suivre une **répartition** au fil des années : chaque année fait 100 %.

```r
PLUIE |>
  filter(name == "Lille", year(date) < 2026) |>
  count(annee = year(date), CD_PLUIE) |>
  group_by(annee) |>
  mutate(PCT = round(100 * n / sum(n), 1)) |>
  ungroup() |>
  select(-n) |>
  pivot_wider(names_from = CD_PLUIE, values_from = PCT)
```

::: note
Comparer des **nombres** de jours d'une année à l'autre serait trompeur si certaines années ont plus de relevés manquants. Avec un pourcentage en ligne, chaque année est ramenée à 100 %.
:::

# Le même raisonnement en graphique

Dans ggplot2, `position = "fill"` dessine des barres qui font toutes 100 % : c'est un pourcentage **par barre**, donc par modalité de la variable en `x`.

```r
ggplot(PLUIE, aes(x = name, fill = CD_PLUIE)) +
  geom_bar(position = "fill") +
  coord_flip() +
  scale_y_continuous(labels = percent) +
  scale_fill_brewer(palette = "Blues") +
  labs(x = NULL, y = NULL, fill = NULL,
       title = "Répartition des jours selon la pluie, par ville") +
  theme_minimal()
```

::: usage
Choisir la variable en `x`, c'est choisir le dénominateur : ici chaque **ville** fait 100 %, c'est l'équivalent graphique du pourcentage en ligne.
:::

# À retenir

::: etape
1. **Qu'est-ce qui fait 100 % ?** C'est la question à se poser avant tout tableau en pourcentages.
2. **Pour comparer des groupes**, on calcule les pourcentages **à l'intérieur** de chaque groupe : le groupe est la variable du `group_by()`.
3. **Écrivez le dénominateur** dans le titre ou la note de lecture : « Part des jours secs, **parmi les jours mesurés à Nice** ».
4. **Vérifiez** que les sommes font 100 dans le bon sens.
:::

| Je veux… | Tidyverse | R base |
|---|---|---|
| % du total | `mutate(n / sum(n))` sans groupe | `prop.table(TAB)` |
| % en ligne | `group_by(VAR_LIGNE)` puis `mutate(n / sum(n))` | `prop.table(TAB, margin = 1)` |
| % en colonne | `group_by(VAR_COLONNE)` puis `mutate(n / sum(n))` | `prop.table(TAB, margin = 2)` |
