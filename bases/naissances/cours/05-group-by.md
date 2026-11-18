---
titre: Calculer par groupe
resume: Découper la base avec group_by() pour obtenir un résultat par modalité.
partie: Les bases
---

# group_by() : calculer dans chaque groupe

::: usage
**À quoi ça sert ?** Préparer un découpage de la base selon les modalités d'une (ou plusieurs) variable(s) catégorielle(s), pour que le calcul suivant (`summarise` ou `count`) soit fait **dans chaque groupe**.

**Écriture :** `BDD |> group_by(VARIABLE) |> summarise(...)`
:::

```r
# Nombre de naissances par sexe
BDD_NAIS |>
  group_by(SEXE) |>
  count()
```

Le résultat contient **une ligne par modalité**.

# Plusieurs indicateurs par groupe

```r
# Selon l'origine du nom de famille de l'enfant
BDD_NAIS |>
  group_by(ORIGINOM) |>
  summarise(NB       = n(),
            AGE_MERE = mean(AGEMERE),
            AGE_PERE = mean(AGEPERE))
```

::: note
**Lecture :** `ORIGINOM` = 1 (nom du père) concerne l'immense majorité des naissances. Quand l'enfant porte le nom de sa mère (2), les parents sont en moyenne plus jeunes d'environ 1,5 an. La dernière ligne (`NA`) regroupe les jugements déclaratifs.
:::

# Filtrer, puis regrouper, puis calculer

```r
# Dans le Nord, âge moyen des parents selon le sexe de l'enfant
BDD_NAIS |>
  filter(DEPNAIS == "59") |>
  group_by(SEXE) |>
  summarise(AGE_PERE = mean(AGEPERE),
            AGE_MERE = mean(AGEMERE))
```

::: usage
**L'ordre des verbes** suit presque toujours la même logique :

1. `filter()` — de qui parle-t-on ?
2. `group_by()` — comparé selon quoi ?
3. `summarise()` ou `count()` — quel calcul ?
:::

# Regrouper selon deux variables

```r
BDD_NAIS |>
  group_by(ORIGINOM, INDLNM) |>
  count()
```

On obtient **une ligne par croisement** : 6 modalités × 4 modalités = 24 lignes.

::: note
**À retenir :** `group_by()` seul ne change rien à l'affichage. Il prépare le calcul qui suit.

Si le résultat a beaucoup de lignes, R n'en affiche que 10. Pour en voir plus : `|> print(n = 50)`.
:::

# print(n = ) : afficher toutes les lignes

```r
# Le nombre d'enfants par accouchement dépend-il de l'âge de la mère ?
BDD_NAIS |>
  group_by(AGEMERE) |>
  summarise(NB_ENFANTS_MOYEN = mean(NBENF)) |>
  print(n = 50)
```

::: note
**Lecture :** la moyenne de `NBENF` augmente avec l'âge de la mère, de 1,01 à 17 ans jusqu'à 1,08 pour 46 ans et plus. Les naissances multiples sont plus fréquentes chez les mères plus âgées (effet connu, lié notamment au recours à l'assistance médicale à la procréation).
:::
