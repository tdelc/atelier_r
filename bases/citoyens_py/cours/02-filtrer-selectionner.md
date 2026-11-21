---
titre: Filtrer et sélectionner
resume: Garder des lignes avec query(), des colonnes avec [[...]] ; conditions sur du texte, des nombres, des listes, des intervalles ; les valeurs manquantes.
partie: Les bases
---

# Garder des lignes : query()

`query()` garde les lignes qui respectent une **condition**, écrite comme une phrase entre guillemets.

```python
personnes.query("statut == 'chômeur'")
```

::: sas
`WHERE statut = 'chômeur';`
:::

# Nombres et texte

Une valeur de texte s'écrit entre guillemets **simples** ; un nombre, sans guillemets.

```python
personnes.query("age >= 65").shape
```

```python
personnes.query("type_menage == 'famille monoparentale'").shape
```

::: usage
Les comparaisons : `==` égal, `!=` différent, `<`, `<=`, `>`, `>=`. Attention : `==` (comparer), pas `=` (ranger un résultat).
:::

# Plusieurs conditions : and, or

Les chômeurs bruxellois, puis les personnes de 65 ans et plus **ou** retraitées :

```python
personnes.query("statut == 'chômeur' and region == 'Bruxelles'").shape
```

```python
personnes.query("age >= 65 or statut == 'retraité'").shape
```

# Un intervalle : between()

La population **d'âge actif**, de 15 à 64 ans :

```python
age_actif = personnes.query("age.between(15, 64)")
age_actif["statut"].value_counts()
```

::: usage
`age.between(15, 64)` équivaut à `age >= 15 and age <= 64` : les deux bornes sont comprises.
:::

# Une liste de valeurs : in

Les **actifs** au sens du Bureau international du travail (BIT) : les personnes en emploi et les chômeurs.

```python
actifs = personnes.query("statut in ['en emploi', 'chômeur'] and age.between(15, 64)")
actifs.shape
```

::: note
Un chômeur, au sens du BIT, est une personne **sans emploi**, **disponible** et qui **cherche activement** un travail. Ce n'est pas la même chose qu'un bénéficiaire d'allocations de chômage : on le verra en couplant l'enquête aux données de l'ONEM.
:::

# Les valeurs manquantes : isna()

```python
personnes.query("diplome.isna()")["classe_age"].value_counts()
```

**Lecture :** le diplôme manque seulement pour les moins de 25 ans : c'est voulu, la question ne leur est pas posée.

::: sas
`WHERE diplome = '';` (en pandas, une valeur manquante n'est ni égale ni différente de quoi que ce soit : on utilise `isna()`).
:::

# Garder des colonnes : [[...]]

```python
personnes[["id_personne", "age", "statut", "revenu_equivalent", "poids"]].head(3)
```

::: usage
Des **doubles crochets** : une liste de noms de colonnes. Un seul nom entre simples crochets donne une colonne isolée.
:::

::: sas
`KEEP id_personne age statut revenu_equivalent poids;`
:::

# Filtrer puis sélectionner

Les familles monoparentales wallonnes dont le revenu équivalent est inférieur à 15 000 euros par an :

```python
(personnes
 .query("type_menage == 'famille monoparentale' and region == 'Wallonie' and revenu_equivalent < 15000")
 [["id_menage", "age", "sexe", "statut", "revenu_equivalent"]]
 .head(8))
```

::: note
**Lire une ligne de code** : « je prends les personnes, **puis** je garde les familles monoparentales wallonnes à bas revenu, **puis** je garde cinq colonnes ».
:::
