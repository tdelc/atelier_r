---
titre: Une analyse de A à Z
resume: Étude de cas complète - petites et grandes communes, un paysage différent selon les régions ? De la question à la conclusion, avec ses limites.
partie: Étude de cas
---

# La question

On entend souvent que « la Wallonie a beaucoup de petites communes ». Est-ce vrai ? Et qu'est-ce que cela change pour les habitants ?

Découpons la question en sous-questions, chacune traduite en quelques étapes pandas :

1. Les communes ont-elles la même taille d'une région à l'autre ?
2. Quelle part des communes, et quelle part des **habitants**, se trouve dans les petites communes ?
3. Où sont les plus petites communes ?
4. Que peut-on conclure, et que ne peut-on **pas** conclure avec ces données ?

::: etape
**La démarche** : une question → les données utiles → un tableau → un graphique → une phrase de conclusion, avec ses limites. On garde les tableaux intermédiaires sous un nom, pour les réutiliser.
:::

# Étape 1 : la taille des communes par région

```python
taille_region = (communes
                 .groupby("region", as_index=False)
                 .agg(communes=("commune", "count"),
                      population=("total", "sum"),
                      mediane=("total", "median"),
                      moyenne=("total", "mean"))
                 .round(0))
taille_region
```

**Lecture :** la commune médiane compte 8 719 habitants en Wallonie, 16 742 en Flandre et 49 638 à Bruxelles. La Wallonie a presque autant de communes que la Flandre (261 contre 285) pour près de deux fois moins d'habitants.

# Étape 2 : des classes de taille

On choisit des seuils parlants, puis on compte.

```python
communes["taille"] = pd.cut(communes["total"],
                            bins=[0, 5000, 10000, 20000, 50000, 600000],
                            labels=["< 5 000", "5-10 000", "10-20 000",
                                    "20-50 000", "50 000 et +"])

pd.crosstab(communes["region"], communes["taille"], margins=True, margins_name="Total")
```

# Étape 3 : part des communes, part des habitants

Deux tableaux, deux dénominateurs différents : les **communes** de la région, puis les **habitants** de la région.

```python
part_communes = (pd.crosstab(communes["region"], communes["taille"],
                             normalize="index") * 100).round(1)
part_habitants = (pd.crosstab(communes["region"], communes["taille"],
                              values=communes["total"], aggfunc="sum",
                              normalize="index") * 100).round(1)
print(part_communes)
part_habitants
```

**Lecture :** en Wallonie, 56,7 % des communes comptent moins de 10 000 habitants, mais elles n'abritent que 23,1 % des Wallons. Une commune est une unité administrative, pas une unité de population : les deux points de vue sont nécessaires.

# Étape 4 : un graphique pour le montrer

On met les deux répartitions de la Wallonie côte à côte : on passe en format long pour que seaborn puisse colorer selon le point de vue.

```python
import seaborn as sns
import matplotlib.pyplot as plt

wallonie = pd.DataFrame({
    "taille": part_communes.columns.astype(str),
    "des communes": part_communes.loc["Wallonie"].values,
    "des habitants": part_habitants.loc["Wallonie"].values})
wallonie_long = wallonie.melt(id_vars="taille", var_name="part", value_name="pourcentage")

sns.barplot(data=wallonie_long, x="taille", y="pourcentage", hue="part")
plt.title("Wallonie : part des communes et des habitants selon la taille de la commune")
plt.xlabel("Habitants de la commune")
plt.ylabel("%")
```

# Étape 5 : où sont les plus petites communes ?

Les provinces qui comptent le plus de communes de moins de 5 000 habitants :

```python
(communes
 .query("total < 5000")
 .groupby("province", as_index=False)
 .agg(petites=("commune", "count"),
      habitants=("total", "sum"))
 .sort_values("petites", ascending=False))
```

**Lecture :** la province de Liège compte le plus de communes de moins de 5 000 habitants (23 sur 84), devant le Luxembourg (17 sur 43, soit 4 sur 10). À elles deux, elles réunissent 40 des 66 plus petites communes du pays.

# Étape 6 : vérifier, avant de conclure

Un contrôle simple : les deux tableaux couvrent bien toutes les communes et toute la population.

```python
print(len(communes), communes["total"].sum())
pd.crosstab(communes["region"], communes["taille"],
            values=communes["total"], aggfunc="sum", margins=True).loc["All", "All"]
```

::: piege
Un pourcentage sans son effectif peut tromper : « 47 % des communes bruxelloises comptent plus de 50 000 habitants », c'est 9 communes. Gardez toujours le tableau des effectifs à côté du tableau des pourcentages.
:::

# Conclusion, et ses limites

**Ce que montrent les données** : oui, les communes wallonnes sont nettement plus petites que les flamandes (médiane de 8 719 habitants contre 16 742), et les provinces de Liège et de Luxembourg concentrent les plus petites. Mais ces petites communes n'abritent qu'une faible part de la population : en Wallonie, moins d'un habitant sur quatre vit dans une commune de moins de 10 000 habitants.

**Ce qu'elles ne montrent pas** :

- la **superficie** : une petite commune peut être vaste et peu dense ; il faudrait la superficie (Statbel la publie) pour parler de densité ;
- l'**histoire** : la Flandre a connu des fusions de communes en 2019 et en 2025, qui ont augmenté la taille de ses communes ;
- les **choix de seuils** : avec d'autres classes, les pourcentages changent. Il faut les annoncer.

::: etape
**À retenir** : chaque étape tient en quelques lignes, avec les verbes du cours : `query`, `groupby`, `agg`, `pd.cut`, `crosstab`, `melt`. La difficulté n'est pas le code, mais le choix du **dénominateur** et l'honnêteté de la conclusion.
:::
