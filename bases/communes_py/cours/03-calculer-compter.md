---
titre: Calculer et compter
resume: Résumer une colonne en un chiffre (somme, moyenne, médiane…), compter les lignes et les modalités avec len() et value_counts().
partie: Les bases
---

# Résumer une colonne en un chiffre

Quelle est la population de la Belgique ? Et la taille moyenne d'une commune ?

```python
communes["total"].sum()
```

```python
communes["total"].mean()
```

::: usage
On prend une colonne, puis on lui applique un calcul : `.sum()` (somme), `.mean()` (moyenne), `.median()` (médiane), `.min()`, `.max()`, `.std()` (écart-type).
:::

**Lecture :** 11 867 634 habitants ; une commune compte en moyenne 21 005 habitants.

# round() : arrondir

```python
communes["total"].mean().round(1)
```

::: piege
La moyenne (21 005) est bien supérieure à la médiane (13 089) : quelques très grandes communes (Anvers, Gand, Charleroi…) tirent la moyenne vers le haut. La médiane, elle, coupe les communes en deux moitiés égales : la moitié des communes compte moins de 13 089 habitants.
:::

```python
communes["total"].median()
```

# Plusieurs indicateurs d'un coup : agg()

`.agg()` reçoit une **liste** de calculs. On l'applique ici à une sous-table d'une colonne (doubles crochets) : le résultat est un petit tableau.

```python
communes[["total"]].agg(["count", "sum", "mean", "median", "min", "max"]).round(0)
```

::: sas
`PROC MEANS DATA=communes N SUM MEAN MEDIAN MIN MAX; VAR total; RUN;`
:::

# Sur une partie de la table

On filtre d'abord, puis on calcule : la population totale de la province de Namur.

```python
communes.query("province == 'Namur'")["total"].sum()
```

Ou, en enchaînant les étapes :

```python
(communes
 .query("province == 'Namur'")
 ["total"]
 .sum())
```

# len() : compter les lignes

Combien de communes comptent plus de 50 000 habitants ?

```python
len(communes.query("total > 50000"))
```

::: usage
`len()` donne le nombre de lignes d'une table. C'est la façon la plus simple de répondre à « combien de… ».
:::

# value_counts() : compter par modalité

Combien de communes dans chaque région ?

```python
communes["region"].value_counts()
```

::: usage
`.value_counts()` compte les lignes pour chaque valeur d'une colonne, de la plus fréquente à la moins fréquente.

- `normalize=True` donne des **proportions** au lieu d'effectifs ;
- `.sort_index()` trie par ordre alphabétique des modalités.
:::

```python
communes["region"].value_counts(normalize=True).round(3)
```

**Lecture :** la Flandre compte la moitié des communes (285 sur 565, 50,4 %), la Wallonie 46,2 %, Bruxelles 19 communes (3,4 %).

::: sas
`PROC FREQ DATA=communes; TABLES region; RUN;`
:::

# Compter sur deux colonnes

`.value_counts()` s'applique aussi à plusieurs colonnes : chaque combinaison est comptée.

```python
communes[["region", "province"]].value_counts().sort_index()
```

# nunique() : combien de valeurs différentes ?

```python
communes["arrondissement"].nunique()
```

**Lecture :** 44 arrondissements. La Belgique compte 43 arrondissements administratifs, mais la nomenclature européenne NUTS, d'où vient la colonne, coupe celui de Verviers en deux : communes francophones et communes germanophones.

# nlargest() et nsmallest() : les plus grandes, les plus petites

Les 5 communes les plus peuplées, puis les 5 moins peuplées :

```python
communes.nlargest(5, "total")[["commune", "province", "total"]]
```

```python
communes.nsmallest(5, "total")[["commune", "province", "total"]]
```
