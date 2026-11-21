---
titre: Calculer et compter
resume: Compter des personnes de l'échantillon ou de la population ; sommes et moyennes pondérées ; value_counts() ; l'unité d'observation - personne ou ménage.
partie: Les bases
---

# Compter des lignes, ou des habitants ?

```python
chomeurs = personnes.query("statut == 'chômeur'")
print(len(chomeurs))                 # personnes de l'échantillon
print(chomeurs["poids"].sum())       # habitants représentés
```

**Lecture :** 505 chômeurs dans l'échantillon, qui représentent environ 362 000 habitants. Le premier chiffre décrit l'enquête, le second la population.

# Une moyenne simple, une moyenne pondérée

```python
revenu = personnes["revenu_equivalent"]
poids = personnes["poids"]
print(round(revenu.mean()))                              # moyenne de l'échantillon
print(round((revenu * poids).sum() / poids.sum()))       # moyenne pondérée
```

::: usage
Une moyenne pondérée, c'est la somme des valeurs multipliées par leur poids, divisée par la somme des poids. `np.average(revenu, weights=poids)` fait le même calcul en une fonction.
:::

**Lecture :** la moyenne pondérée est plus élevée : l'échantillon contient trop de Bruxellois, dont les revenus sont plus bas. Les poids corrigent ce déséquilibre.

::: sas
`PROC MEANS DATA=personnes MEAN; VAR revenu_equivalent; WEIGHT poids; RUN;`
:::

# Compter les modalités : value_counts()

```python
personnes["statut"].value_counts()
```

En **population**, on additionne les poids au lieu de compter les lignes :

```python
(personnes.groupby("statut")["poids"].sum() / personnes["poids"].sum() * 100).round(1)
```

::: usage
`value_counts(normalize=True)` donnerait les proportions de l'**échantillon**. Pour la population, on regroupe et on additionne les poids : la leçon « Calculer par groupe » y revient.
:::

# Personnes ou ménages ?

La table a une ligne par **personne**. Combien de **ménages** ?

```python
print(personnes["id_menage"].nunique())
menages = personnes.drop_duplicates("id_menage")
print(len(menages))
```

::: piege
« Le revenu moyen des ménages » et « le revenu moyen des personnes » ne se calculent pas sur la même table. Sur `personnes`, un ménage de cinq personnes compte cinq fois. Pour une statistique **par ménage**, gardez une ligne par ménage (`drop_duplicates("id_menage")`).
:::

```python
print(round(personnes["revenu_menage"].mean()))   # les grands ménages pèsent plus
print(round(menages["revenu_menage"].mean()))     # un ménage = une ligne
```

# Combien de valeurs renseignées : count()

```python
print(len(personnes), personnes["diplome"].count(), personnes["diplome"].isna().sum())
```

::: note
`count()` compte les valeurs **renseignées**, `len()` les **lignes**. L'écart, ce sont les valeurs manquantes (ici, les moins de 25 ans).
:::

# Un calcul sur une sous-table

La part des personnes de 65 ans et plus dans la population wallonne :

```python
wal = personnes.query("region == 'Wallonie'")
round(wal.query("age >= 65")["poids"].sum() / wal["poids"].sum() * 100, 1)
```
