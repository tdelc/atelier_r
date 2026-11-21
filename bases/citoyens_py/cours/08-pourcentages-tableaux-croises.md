---
titre: Les pourcentages d'un tableau croisé
resume: pd.crosstab() pondéré ; pourcentages en ligne, en colonne, du total ; « parmi les pauvres » ou « parmi les chômeurs » - le bon dénominateur.
partie: Les bases
---

# Un tableau croisé pondéré : pd.crosstab()

La population (somme des poids) par région et par statut, en milliers :

```python
(pd.crosstab(personnes["region"], personnes["statut"],
             values=personnes["poids"], aggfunc="sum") / 1000).round(0)
```

::: usage
Sans `values=`, `crosstab` compte les **lignes de l'échantillon**. Avec `values=personnes["poids"], aggfunc="sum"`, il compte les **habitants**.
:::

::: sas
`PROC FREQ DATA=personnes; TABLES region*statut; WEIGHT poids; RUN;`
:::

# Pourcentages en ligne : normalize="index"

**Parmi les habitants de chaque région**, quelle part dans chaque statut ?

```python
(pd.crosstab(personnes["region"], personnes["statut"], values=personnes["poids"],
             aggfunc="sum", normalize="index") * 100).round(1)
```

Chaque **ligne** fait 100 %.

# Deux questions, deux dénominateurs

On reprend le seuil et la variable `pauvre` :

```python
tri = personnes.sort_values("revenu_equivalent")
cumul = tri["poids"].cumsum()
seuil = 0.6 * tri.loc[cumul >= tri["poids"].sum() / 2, "revenu_equivalent"].iloc[0]
personnes["pauvre"] = np.where(personnes["revenu_equivalent"] < seuil, "pauvre", "non pauvre")
```

**Parmi les personnes de chaque statut**, quelle part est pauvre ? (le **taux** de pauvreté)

```python
(pd.crosstab(personnes["statut"], personnes["pauvre"], values=personnes["poids"],
             aggfunc="sum", normalize="index") * 100).round(1)
```

**Parmi les personnes pauvres**, quelle part dans chaque statut ? (la **composition** des pauvres)

```python
(pd.crosstab(personnes["statut"], personnes["pauvre"], values=personnes["poids"],
             aggfunc="sum", normalize="columns") * 100).round(1)
```

**Lecture :** un chômeur sur quatre est pauvre, mais les chômeurs ne sont qu'une petite part des pauvres : les enfants, les inactifs et même les personnes en emploi y sont plus nombreux. Les deux phrases sont vraies ; elles ne répondent pas à la même question.

::: piege
« 25 % des chômeurs sont pauvres » et « 6 % des pauvres sont chômeurs » ne disent pas la même chose. Écrivez d'abord la phrase, cherchez le « **parmi** » : il désigne le dénominateur.
:::

# Le pourcentage du total : normalize="all"

```python
(pd.crosstab(personnes["region"], personnes["pauvre"], values=personnes["poids"],
             aggfunc="sum", normalize="all") * 100).round(1)
```

Chaque case est une part de la **population totale** : toutes les cases ensemble font 100 %.

# Les marges

```python
(pd.crosstab(personnes["type_menage"], personnes["pauvre"], values=personnes["poids"],
             aggfunc="sum", normalize="index", margins=True, margins_name="Ensemble") * 100).round(1)
```

::: usage
Avec `normalize="index"` et `margins=True`, la ligne « Ensemble » donne le taux pour toute la population : le point de comparaison.
:::

# Échantillon et population côte à côte

```python
brut = pd.crosstab(personnes["region"], personnes["pauvre"], normalize="index")["pauvre"]
pondere = pd.crosstab(personnes["region"], personnes["pauvre"], values=personnes["poids"],
                      aggfunc="sum", normalize="index")["pauvre"]
pd.DataFrame({"échantillon": (brut * 100).round(1), "population": (pondere * 100).round(1)})
```

**Lecture :** dans chaque région, les écarts entre les deux colonnes sont faibles : les poids corrigent surtout la répartition **entre** régions. C'est au niveau national que l'oubli des poids fausse le plus le résultat.
