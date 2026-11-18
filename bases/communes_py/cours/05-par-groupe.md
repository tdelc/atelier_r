---
titre: Calculer par groupe
resume: Découper la table avec groupby() pour obtenir un résultat par province, par région, par arrondissement.
partie: Les bases
---

# Une question par groupe

« Quelle est la population **de chaque** province ? » On pourrait filtrer province par province… ou demander à pandas de le faire pour toutes à la fois.

```python
communes.groupby("province")["total"].sum()
```

::: usage
`.groupby("colonne")` découpe la table en groupes, un par valeur de la colonne. Le calcul qui suit est fait **dans chaque groupe**.

La phrase se lit : « regrouper par province, prendre `total`, faire la somme ».
:::

::: sas
`PROC MEANS DATA=communes SUM; CLASS province; VAR total; RUN;`, ou en SQL : `SELECT province, SUM(total) FROM communes GROUP BY province;`
:::

# Un vrai tableau : as_index=False

Par défaut, les groupes deviennent l'**index** (à gauche, en gras). Avec `as_index=False`, on obtient une table ordinaire, avec une colonne `province` : plus facile à trier, filtrer ou exporter.

```python
communes.groupby("province", as_index=False)["total"].sum()
```

# Plusieurs indicateurs par groupe : agg()

On nomme chaque indicateur : `nom=("colonne", "calcul")`.

```python
(communes
 .groupby("province", as_index=False)
 .agg(communes=("commune", "count"),
      population=("total", "sum"),
      taille_moyenne=("total", "mean"),
      taille_mediane=("total", "median"))
 .round(0))
```

::: usage
Les calculs possibles : `"count"` (nombre de lignes renseignées), `"size"` (nombre de lignes), `"sum"`, `"mean"`, `"median"`, `"min"`, `"max"`, `"std"`, `"nunique"` (nombre de valeurs différentes).
:::

**Lecture :** la province de Liège a le plus de communes (84) ; celle d'Anvers, la plus forte population (1,93 million d'habitants).

# Trier le résultat

```python
(communes
 .groupby("province", as_index=False)
 .agg(population=("total", "sum"))
 .sort_values("population", ascending=False))
```

::: usage
`.sort_values("colonne")` trie par ordre croissant ; `ascending=False`, par ordre décroissant.
:::

# Regrouper sur deux colonnes

Une ligne par **combinaison** région × province :

```python
(communes
 .groupby(["region", "province"], as_index=False)
 .agg(communes=("commune", "count"),
      population=("total", "sum")))
```

# size() : compter les lignes de chaque groupe

```python
communes.groupby("region", as_index=False).size()
```

C'est l'équivalent de `value_counts()`, mais sous forme de table, et pour plusieurs colonnes de regroupement.

# Filtrer, puis regrouper

Combien de communes de plus de 20 000 habitants dans chaque région ?

```python
(communes
 .query("total > 20000")
 .groupby("region", as_index=False)
 .size())
```

# Un calcul par groupe, puis un filtre sur le résultat

Quels arrondissements comptent plus de 500 000 habitants ?

```python
(communes
 .groupby("arrondissement", as_index=False)
 .agg(population=("total", "sum"))
 .query("population > 500000"))
```

::: note
L'ordre des étapes change la question : filtrer **avant** de regrouper sélectionne des communes ; filtrer **après** sélectionne des groupes. En SQL, c'est la différence entre `WHERE` et `HAVING`.
:::
