---
titre: Graphiques avec seaborn
resume: Préparer une table de taux pondérés, puis la dessiner - barres, histogrammes pondérés, boîtes, barres groupées, empilées ; titres, axes et export.
partie: Représenter
---

# Deux bibliothèques : seaborn et matplotlib

- **seaborn** dessine un graphique à partir d'une **table** : on lui donne la table (`data=`) et les colonnes à placer sur chaque axe (`x=`, `y=`).
- **matplotlib**, sur laquelle seaborn repose, sert à l'habillage : titre, noms des axes, taille, export.

```python
import seaborn as sns
import matplotlib.pyplot as plt

sns.set_theme(style="whitegrid")    # un style sobre, une seule fois
```

# D'abord la table, ensuite le graphique

Pour une enquête, on calcule d'abord les **indicateurs pondérés**, puis on dessine la table obtenue.

```python
tri = personnes.sort_values("revenu_equivalent")
cumul = tri["poids"].cumsum()
seuil = 0.6 * tri.loc[cumul >= tri["poids"].sum() / 2, "revenu_equivalent"].iloc[0]
personnes["pauvres_pond"] = (personnes["revenu_equivalent"] < seuil) * personnes["poids"]

par_type = (personnes
            .groupby("type_menage", as_index=False)
            .agg(pauvres=("pauvres_pond", "sum"), population=("poids", "sum")))
par_type["taux"] = par_type["pauvres"] / par_type["population"] * 100
par_type = par_type.sort_values("taux", ascending=False)

sns.barplot(data=par_type, x="taux", y="type_menage")
plt.title("Risque de pauvreté selon le type de ménage (données fictives)")
plt.xlabel("% des personnes sous le seuil")
plt.ylabel("")
```

::: piege
Ne donnez pas `personnes` directement à `sns.barplot(x="pauvre")` : seaborn calculerait une moyenne **non pondérée**. Calculez la table pondérée vous-même, puis dessinez-la.
:::

# Un histogramme pondéré : weights=

La distribution du revenu équivalent, avec le seuil de pauvreté :

```python
sns.histplot(data=personnes, x="revenu_equivalent", weights="poids", bins=50)
plt.axvline(seuil, color="firebrick", linestyle="--")
plt.title("Distribution du revenu disponible équivalent")
plt.xlabel("Euros par an")
plt.ylabel("Habitants")
```

::: usage
`weights="poids"` : chaque personne compte pour son poids. L'axe vertical se lit alors en **habitants**, et non en répondants.
:::

# Comparer des groupes : hue=

```python
sns.histplot(data=personnes, x="revenu_equivalent", weights="poids", hue="region",
             bins=40, element="step", stat="density", common_norm=False)
plt.axvline(seuil, color="grey", linestyle="--")
plt.xlabel("Revenu disponible équivalent (euros par an)")
```

::: usage
`stat="density", common_norm=False` : chaque région est ramenée à la même surface, pour comparer les **formes** des distributions et non les effectifs.
:::

# Des boîtes : sns.boxplot()

Le revenu équivalent selon le statut d'activité, pour les 18-64 ans :

```python
sns.boxplot(data=personnes.query("age.between(18, 64)"), x="revenu_equivalent", y="statut")
plt.axvline(seuil, color="firebrick", linestyle="--")
plt.xlabel("Revenu disponible équivalent (euros par an)")
plt.ylabel("")
```

::: note
Une boîte n'accepte pas de poids : elle décrit l'échantillon. C'est acceptable pour **comparer des formes**, pas pour publier des quartiles.
:::

# Des barres groupées : un taux par région et par âge

```python
t = (personnes
     .groupby(["region", "classe_age"], as_index=False)
     .agg(pauvres=("pauvres_pond", "sum"), population=("poids", "sum")))
t["taux"] = t["pauvres"] / t["population"] * 100

sns.barplot(data=t, x="classe_age", y="taux", hue="region")
plt.title("Risque de pauvreté par âge et par région")
plt.xlabel("Âge")
plt.ylabel("%")
```

# Des barres empilées à 100 %

La composition de la population pauvre selon le statut, dans chaque région :

```python
pauvres = personnes.query("revenu_equivalent < @seuil")
compo = pd.crosstab(pauvres["region"], pauvres["statut"], values=pauvres["poids"],
                    aggfunc="sum", normalize="index") * 100

compo.plot.barh(stacked=True, colormap="viridis")
plt.xlabel("% des personnes sous le seuil")
plt.ylabel("")
plt.legend(title="Statut", bbox_to_anchor=(1, 1))
```

# Exporter un graphique

```python
sns.barplot(data=par_type, x="taux", y="type_menage")
plt.title("Risque de pauvreté selon le type de ménage")
plt.savefig("sortie/pauvrete_type_menage.png", dpi=150, bbox_inches="tight")
```

::: usage
- `dpi=150` : la résolution (150 suffit pour un document, 300 pour l'impression) ;
- `bbox_inches="tight"` : rogne les marges et évite de couper les libellés.
:::
