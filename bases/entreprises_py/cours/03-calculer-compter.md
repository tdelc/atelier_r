---
titre: Calculer et compter
resume: Sommes, moyennes, comptages ; value_counts() pour les modalités ; len() pour les lignes ; attention aux valeurs manquantes.
partie: Les bases
---

# Une somme, une moyenne

```python
print(entreprises["emploi"].sum())
print(entreprises["emploi"].mean())
```

**Lecture :** 73 991 salariés, soit 6,2 par entreprise en moyenne. Retenez ce chiffre : la leçon suivante montre qu'il décrit très mal l'entreprise « typique ».

::: usage
`.sum()`, `.mean()`, `.median()`, `.min()`, `.max()` s'appliquent à une colonne. `round(x, 1)` arrondit.
:::

::: sas
`PROC MEANS DATA=entreprises SUM MEAN; VAR emploi; RUN;`
:::

# Le chiffre d'affaires total

```python
ca_total = entreprises["ca"].sum()
round(ca_total / 1e6, 1)       # en milliards d'euros (la colonne est en milliers)
```

**Lecture :** 30,3 milliards d'euros.

::: piege
**L'unité d'abord.** `ca` est en **milliers** d'euros : diviser par 1 000 000 donne des milliards. Écrivez l'unité dans le nom des colonnes que vous créez (`ca_meur`, `ca_keur`) ou dans vos commentaires.
:::

::: note
`sum()` **ignore** les valeurs manquantes : ce total ne contient pas les entreprises exonérées. C'est le total **de ce qui est déclaré à la TVA**, pas le chiffre d'affaires de toutes les entreprises.
:::

# Compter des lignes : len()

```python
len(entreprises.query("emploi == 0"))
```

**Lecture :** 7 036 entreprises sur 12 000, soit près de six sur dix, n'ont **aucun salarié** : indépendants, sociétés de gestion, holdings…

# Compter les modalités : value_counts()

```python
entreprises["region"].value_counts()
```

```python
entreprises["forme"].value_counts(normalize=True).round(3)
```

::: usage
`value_counts()` compte chaque valeur et trie du plus fréquent au moins fréquent. `normalize=True` donne des proportions (multipliez par 100 pour des pourcentages).
:::

::: sas
`PROC FREQ DATA=entreprises; TABLES region forme; RUN;`
:::

# Compter des valeurs distinctes : nunique()

```python
print(entreprises["nace"].nunique(), "classes NACE")
print(entreprises["commune"].nunique(), "communes")
```

# Combien de valeurs renseignées : count()

```python
print(len(entreprises))              # lignes
print(entreprises["ca"].count())     # valeurs renseignées
print(entreprises["ca"].isna().sum())  # valeurs manquantes
```

::: piege
`count()` compte les valeurs **renseignées**, `len()` les **lignes**. L'écart, ce sont les valeurs manquantes. Une moyenne de `ca` se calcule sur 10 627 entreprises, pas 12 000 : dites-le quand vous la publiez.
:::

# Un calcul sur une sous-table

Le chiffre d'affaires total de l'horeca bruxellois, en millions d'euros :

```python
horeca_bxl = entreprises.query("section == 'I' and region == 'Bruxelles'")
round(horeca_bxl["ca"].sum() / 1000, 1)
```

**Lecture :** 77,2 millions d'euros, pour 224 entreprises.
