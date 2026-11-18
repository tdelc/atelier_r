---
titre: Explorer une variable
resume: describe(), quantiles, histogramme et diagramme en barres rapides pour regarder une colonne.
partie: Les bases
---

# describe() : le résumé d'une colonne numérique

```python
communes["total"].describe()
```

::: usage
`.describe()` donne l'effectif (`count`), la moyenne (`mean`), l'écart-type (`std`), le minimum, les quartiles (25 %, 50 % = médiane, 75 %) et le maximum.
:::

**Lecture :** un quart des communes compte moins de 7 539 habitants, un quart plus de 23 037. L'écart-type (34 080) est plus grand que la moyenne : les tailles sont très dispersées.

::: sas
`PROC MEANS` ou `PROC UNIVARIATE`.
:::

# describe() sur toute la table

Appliqué à la table, `describe()` résume toutes les colonnes numériques à la fois.

```python
communes.describe().round(0)
```

# quantile() : choisir ses seuils

```python
communes["total"].quantile([0.1, 0.5, 0.9])
```

**Lecture :** 10 % des communes comptent moins de 4 443 habitants, 10 % plus de 38 187.

# Un histogramme rapide

Une colonne a une méthode `.plot.hist()` qui dessine son histogramme : chaque barre compte les communes dont la population tombe dans un intervalle.

```python
communes["total"].plot.hist(bins=40)
```

**Lecture :** la plupart des communes comptent moins de 50 000 habitants ; quelques grandes villes, très à droite, écrasent le graphique.

::: note
Ces graphiques rapides servent à **regarder** ses données. Pour des graphiques soignés, à publier, on utilisera seaborn (leçon « Graphiques »).
:::

# Limiter le graphique à une partie des communes

```python
communes.query("total < 50000")["total"].plot.hist(bins=40)
```

# Explorer une colonne de texte

Pour une colonne de texte, on compte les modalités, puis on les dessine en barres.

```python
communes["province"].value_counts()
```

```python
communes["province"].value_counts().plot.barh()
```

# unique() : les valeurs possibles

```python
communes["region"].unique()
```

::: usage
`.unique()` liste les valeurs différentes d'une colonne. Utile pour vérifier l'orthographe exacte avant d'écrire une condition.
:::
