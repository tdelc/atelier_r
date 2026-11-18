---
titre: Les pourcentages d'un tableau croisé
resume: Pourcentage du total, en ligne ou en colonne avec pd.crosstab() - choisir le bon dénominateur, c'est choisir la question.
partie: Les bases
---

# Le tableau croisé : pd.crosstab()

Le nombre de communes par région et par classe de taille.

```python
communes["taille"] = pd.cut(communes["total"],
                            bins=[0, 5000, 10000, 20000, 50000, 600000],
                            labels=["< 5 000", "5-10 000", "10-20 000",
                                    "20-50 000", "50 000 et +"])

pd.crosstab(communes["region"], communes["taille"])
```

::: usage
`pd.crosstab(lignes, colonnes)` compte les lignes de la table pour chaque combinaison : le premier argument donne les lignes du tableau, le second ses colonnes.
:::

::: sas
`PROC FREQ DATA=communes; TABLES region*taille; RUN;`
:::

# Les totaux : margins=True

```python
pd.crosstab(communes["region"], communes["taille"],
            margins=True, margins_name="Total")
```

# Trois pourcentages, trois questions

Un même tableau croisé donne trois pourcentages, qui répondent à trois questions différentes. Tout dépend du **dénominateur** : `normalize=`.

| `normalize=` | Dénominateur | La question |
|---|---|---|
| `"all"` | toutes les communes | Quelle part de **toutes** les communes belges est wallonne et de moins de 5 000 habitants ? |
| `"index"` | chaque **ligne** (région) | **Parmi les communes wallonnes**, quelle part compte moins de 5 000 habitants ? |
| `"columns"` | chaque **colonne** (taille) | **Parmi les communes de moins de 5 000 habitants**, quelle part est wallonne ? |

# En ligne : la structure de chaque région

**Parmi les communes de chaque région**, comment se répartissent les tailles ?

```python
(pd.crosstab(communes["region"], communes["taille"], normalize="index")
 * 100).round(1)
```

**Lecture :** 20,3 % des communes wallonnes comptent moins de 5 000 habitants, contre 4,6 % des communes flamandes. Chaque ligne fait 100 %.

# En colonne : d'où viennent les communes d'une taille

**Parmi les communes de chaque taille**, quelle part est dans chaque région ?

```python
(pd.crosstab(communes["region"], communes["taille"], normalize="columns")
 * 100).round(1)
```

**Lecture :** 80,3 % des communes de moins de 5 000 habitants sont wallonnes. Chaque colonne fait 100 %.

::: piege
« 80 % des petites communes sont wallonnes » et « 20 % des communes wallonnes sont petites » ne disent **pas** la même chose. Avant de calculer, écrivez la phrase que vous voulez obtenir, et repérez le mot « parmi » : il donne le dénominateur.
:::

# Une part de population, pas de communes

Les communes n'ont pas toutes le même poids. Quelle part de la **population** de chaque région vit dans chaque classe de taille ? On additionne la population (`values`, `aggfunc`) au lieu de compter les communes.

```python
(pd.crosstab(communes["region"], communes["taille"],
             values=communes["total"], aggfunc="sum", normalize="index")
 * 100).round(1)
```

**Lecture :** 20 % des communes wallonnes comptent moins de 5 000 habitants, mais elles n'abritent que 5 % de la population wallonne. En Flandre, un quart de la population vit dans une commune de 50 000 habitants ou plus.

# Le même calcul avec groupby

On peut aussi calculer la part « à la main » : regrouper, puis diviser par le total du groupe, comme en leçon « Créer des variables ».

```python
t = communes.groupby(["region", "taille"], as_index=False, observed=False).agg(
    population=("total", "sum"))
t["part"] = (t["population"] / t.groupby("region")["population"].transform("sum") * 100).round(1)
t.query("region == 'Wallonie'")
```

::: note
`crosstab` est plus court pour un tableau à afficher ; la méthode `groupby` + `transform` garde une table **longue**, plus facile à filtrer, à représenter en graphique ou à exporter.
:::
