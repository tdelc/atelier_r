---
titre: Explorer une variable
resume: summary(), hist(), table() - et le piège des NA qui ne veulent pas dire zéro.
partie: Les bases
---

# La boîte à outils, selon le type de variable

| Type de variable | Commandes à lancer |
|---|---|
| Numérique continue (`temp`, `prcp`) | `summary(BDD$COL)` puis `hist(BDD$COL)` |
| Catégorielle (`cldc`, `name`) | `table(BDD$COL, useNA = "ifany")` ou `count(COL)` |
| Date (`date`) | `min()`, `max()`, `n_distinct()` |

La séquence type, à recopier pour chaque variable :

```r norun
head(BDD_METEO$COLONNE)       # à quoi ressemblent les valeurs ?
summary(BDD_METEO$COLONNE)    # min, quartiles, moyenne, max, nombre de NA
hist(BDD_METEO$COLONNE)       # la distribution est-elle symétrique ? asymétrique ?
# puis, en commentaire : ce que j'ai compris et ce que je décide
```

# Une variable numérique bien remplie : temp

```r
head(BDD_METEO$temp)
summary(BDD_METEO$temp)
hist(BDD_METEO$temp)
```

::: note
**Lecture :** température moyenne de l'air sur la journée, en °C. Distribution assez symétrique, centrée autour de 14 °C, valeurs extrêmes plausibles pour la France (de -11 à +34 °C en moyenne journalière). 745 `NA` : il faudra penser à `na.rm = TRUE`. **Décision : variable centrale de l'étude.**
:::

# Une variable asymétrique : prcp

```r
summary(BDD_METEO$prcp)
hist(BDD_METEO$prcp)
```

::: note
**Lecture :** la médiane est à 0 : il ne pleut pas la moitié des jours. Quelques jours de pluie très abondante (jusqu'à 300 mm) écrasent l'histogramme. Pour une telle variable, la **moyenne** est tirée vers le haut par les extrêmes : la **médiane** ou la **part des jours de pluie** sont souvent plus parlantes.
:::

# Le piège : NA ne veut pas dire 0

Avant de remplacer des `NA` par des 0, il faut vérifier si des **vrais** 0 existent déjà dans la colonne.

```r
# Existe-t-il des jours enregistrés à 0 mm de pluie ?
sum(BDD_METEO$prcp == 0, na.rm = TRUE)

# Et des jours à 0 mm de neige ?
sum(BDD_METEO$snwd == 0, na.rm = TRUE)
summary(BDD_METEO$snwd)
```

::: note
**Lecture :** pour `prcp`, il existe des dizaines de milliers de jours à `0` mm. Les `NA` ne sont donc pas des jours sans pluie : ce sont des **relevés manquants**. On ne les transforme surtout pas en 0, cela inventerait des jours secs.
:::

::: piege
`snwd` ne contient **jamais** de 0 mais presque uniquement des `NA` : c'est suspect. Les jours « sans neige » ont probablement été codés `NA`. Tant qu'on n'a pas tranché, on n'utilise pas la variable. **Décision : `snwd` est écartée.**
:::

# Une variable catégorielle codée en chiffres : cldc

```r
table(BDD_METEO$cldc)
table(BDD_METEO$cldc, useNA = "ifany")
```

::: usage
**`useNA = "ifany"`** ajoute une colonne pour les valeurs manquantes. Sans cet argument, `table()` les ignore **en silence** : vous croyez voir toute la population alors qu'il en manque une partie — ici, plus de 40 % !
:::

::: note
**Lecture :** la couverture nuageuse est mesurée en octas (huitièmes de ciel couvert). Ce sont des chiffres, mais la variable est **catégorielle ordonnée** : on ne calcule pas une « moyenne d'octas », on compte des jours par modalité.

| Octas | Signification |
|---|---|
| 0 | Ciel totalement dégagé |
| 1–2 | Quelques nuages |
| 3–4 | Ciel partiellement nuageux |
| 5–7 | Ciel majoritairement couvert |
| 8 | Ciel entièrement couvert |
| 9 | Ciel invisible (brouillard, fortes chutes de neige) |
:::

# Les variables d'identification

```r
table(BDD_METEO$name)
table(BDD_METEO$country)
n_distinct(BDD_METEO$station)
```

::: note
**Lecture :** 13 stations, chacune avec environ 6 095 jours. `country` ne contient qu'une seule modalité : variable inutile, mais la vérification confirme qu'aucune station étrangère ne s'est glissée dans la base.
:::

# Une date : la période couverte

```r
min(BDD_METEO$date)
max(BDD_METEO$date)
n_distinct(BDD_METEO$date)
```

::: piege
La base s'arrête le **8 septembre 2026** : la dernière année est **incomplète**. Elle n'a pas connu son automne ni son hiver : sa température moyenne sera artificiellement élevée. Il faudra soit l'exclure, soit le signaler à chaque fois.
:::
