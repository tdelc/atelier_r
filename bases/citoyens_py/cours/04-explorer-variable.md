---
titre: Explorer une variable
resume: Le revenu disponible équivalent - describe(), médiane, quantiles et déciles ; la médiane pondérée ; le seuil de pauvreté.
partie: Les bases
---

# describe() : le résumé d'une colonne

```python
personnes["revenu_equivalent"].describe().round(0)
```

**Lecture :** la moitié des personnes de l'échantillon vivent dans un ménage dont le revenu équivalent est inférieur à 27 529 euros par an. La moyenne est un peu plus haute que la médiane : quelques revenus élevés la tirent vers le haut.

::: sas
`PROC MEANS DATA=personnes N MEAN STD MIN P25 MEDIAN P75 MAX; VAR revenu_equivalent; RUN;`
:::

# Pourquoi un revenu « équivalent » ?

Un ménage de quatre personnes qui gagne 40 000 euros ne vit pas comme une personne seule avec 40 000 euros. On divise le revenu du ménage par un nombre d'**unités de consommation** (échelle de l'OCDE modifiée) :

| Membre du ménage | Unités |
|---|---|
| le premier adulte | 1 |
| chaque autre personne de 14 ans et plus | 0,5 |
| chaque enfant de moins de 14 ans | 0,3 |

```python
(personnes
 .query("type_menage == 'couple avec enfants'")
 [["id_menage", "age", "taille_menage", "revenu_menage", "revenu_equivalent"]]
 .head(4))
```

**Lecture :** le ménage `M00003`, un couple et un adolescent de 15 ans, compte 1 + 0,5 + 0,5 = 2 unités : 47 950 euros divisés par 2 donnent 23 975 euros. Le ménage `M00004`, un couple avec deux enfants de moins de 14 ans, compte 1 + 0,5 + 0,3 + 0,3 = 2,1 unités. Toutes les personnes d'un ménage ont le même revenu équivalent.

# Les quantiles et les déciles

```python
personnes["revenu_equivalent"].quantile([0.1, 0.25, 0.5, 0.75, 0.9]).round(0)
```

::: usage
`quantile(0.1)` : la valeur sous laquelle se trouvent 10 % des personnes, le premier **décile**. Le rapport entre le 9e et le 1er décile (D9/D1) est une mesure courante des inégalités.
:::

```python
d = personnes["revenu_equivalent"].quantile([0.1, 0.9])
round(d[0.9] / d[0.1], 1)
```

# La médiane pondérée

Ces quantiles décrivent l'**échantillon**. Pour la population, il faut tenir compte des poids : on trie les personnes par revenu, on cumule leurs poids, et la médiane est le revenu de la personne qui fait franchir **la moitié** de la population.

```python
tri = personnes.sort_values("revenu_equivalent")
cumul = tri["poids"].cumsum()
mediane = tri.loc[cumul >= tri["poids"].sum() / 2, "revenu_equivalent"].iloc[0]
mediane
```

::: usage
- `cumsum()` : la somme cumulée, ligne après ligne ;
- `tri.loc[condition, "colonne"]` garde les lignes où la condition est vraie, dans la colonne voulue ;
- `.iloc[0]` prend la première de ces valeurs.
:::

**Lecture :** la médiane pondérée vaut 28 067 euros, plus que la médiane de l'échantillon (27 529 euros) : une fois de plus, le suréchantillonnage de Bruxelles tirait le résultat vers le bas.

# Le seuil de pauvreté

En Europe, une personne est « à risque de pauvreté » quand son revenu équivalent est inférieur à **60 % de la médiane** nationale.

```python
seuil = 0.6 * mediane
round(seuil)
```

**Lecture :** dans nos données fictives, le seuil est d'environ 16 840 euros par an pour une personne seule, soit 1 403 euros par mois. Pour un couple avec deux jeunes enfants, il faut multiplier par 2,1.

::: piege
Le seuil est **relatif** : il dépend de la médiane du pays. Si tous les revenus doublaient, le taux de pauvreté ne changerait pas. Ce n'est pas une mesure de la privation, mais de l'**écart** au niveau de vie habituel.
:::

# Les valeurs extrêmes

```python
personnes.nsmallest(5, "revenu_equivalent")[["id_menage", "type_menage", "statut", "revenu_menage"]]
```

::: note
Des revenus nuls existent dans les vraies enquêtes : ménages sans aucun revenu déclaré, indépendants en perte, erreurs de réponse. On ne les supprime pas sans raison : ils comptent parmi les personnes sous le seuil.
:::

# Les modalités d'une colonne de texte

```python
personnes["type_menage"].value_counts()
```
