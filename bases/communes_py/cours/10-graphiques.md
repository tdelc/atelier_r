---
titre: Graphiques avec seaborn
resume: Préparer une table, puis la dessiner - barres, histogrammes, boîtes, nuages de points, barres empilées ; titres, axes et export.
partie: Représenter
---

# Deux bibliothèques : seaborn et matplotlib

- **seaborn** dessine un graphique à partir d'une **table** : on lui donne la table (`data=`) et les colonnes à placer sur chaque axe (`x=`, `y=`), comme dans ggplot2 en R.
- **matplotlib**, sur laquelle seaborn repose, sert à l'habillage : titre, noms des axes, taille, export.

```python
import seaborn as sns
import matplotlib.pyplot as plt

sns.set_theme(style="whitegrid")    # un style sobre, une seule fois
```

::: usage
Ces deux lignes `import` se placent en haut du script, à côté de `import pandas as pd`. `sns` et `plt` sont les abréviations habituelles.
:::

# D'abord la table, ensuite le graphique

Un graphique se prépare comme un tableau : on calcule d'abord la table à dessiner, avec les étapes du cours.

```python
par_province = (communes
                .groupby("province", as_index=False)
                .agg(population=("total", "sum"))
                .sort_values("population", ascending=False))
par_province["milliers"] = par_province["population"] / 1000

sns.barplot(data=par_province, x="milliers", y="province")
plt.title("Population par province, 1er janvier 2026")
plt.xlabel("Habitants (milliers)")
plt.ylabel("")
```

::: usage
Barres horizontales (`y=` la catégorie) : les noms longs restent lisibles. L'ordre des barres suit l'ordre de la table : on trie avant de dessiner. La population est exprimée en milliers, sinon l'axe s'afficherait en notation scientifique (« 1e6 »).
:::

::: sas
`PROC SGPLOT DATA=par_province; HBAR province / RESPONSE=population; RUN;`
:::

# Un histogramme : sns.histplot()

La répartition des communes selon leur population. Avec `log_scale=True`, l'axe est en échelle logarithmique : les petites communes ne sont plus écrasées par Anvers.

```python
sns.histplot(data=communes, x="total", bins=30, log_scale=True)
plt.title("Répartition des communes selon leur population")
plt.xlabel("Habitants (échelle logarithmique)")
plt.ylabel("Nombre de communes")
```

# Comparer des groupes : hue=

`hue=` colore selon une colonne : un histogramme par région, superposés.

```python
sns.histplot(data=communes, x="total", hue="region", bins=30,
             log_scale=True, element="step")
plt.xlabel("Habitants (échelle logarithmique)")
plt.ylabel("Nombre de communes")
```

**Lecture :** les communes wallonnes sont décalées vers la gauche (plus petites), les bruxelloises tout à droite.

# Des boîtes à moustaches : sns.boxplot()

La boîte va du premier au troisième quartile, le trait central est la médiane ; les points isolés sont les communes atypiques.

```python
sns.boxplot(data=communes, x="total", y="region", log_scale=True)
plt.xlabel("Habitants (échelle logarithmique)")
plt.ylabel("")
```

# Un nuage de points : sns.scatterplot()

Chaque point est une commune : sa population en abscisse, la part des femmes en ordonnée.

```python
communes["part_femmes"] = communes["femmes"] / communes["total"] * 100

sns.scatterplot(data=communes, x="total", y="part_femmes", hue="region", alpha=0.6)
plt.xscale("log")
plt.axhline(50, color="grey", linestyle="--")    # la ligne des 50 %
plt.xlabel("Habitants (échelle logarithmique)")
plt.ylabel("Part des femmes (%)")
```

**Lecture :** la part des femmes reste proche de 50 % partout ; elle varie davantage dans les petites communes, où quelques habitants suffisent à la faire bouger.

# Des barres empilées à 100 %

Les pourcentages en ligne d'un tableau croisé (leçon précédente) se dessinent directement avec la méthode `.plot.barh(stacked=True)` du tableau.

```python
communes["taille"] = pd.cut(communes["total"],
                            bins=[0, 5000, 10000, 20000, 50000, 600000],
                            labels=["< 5 000", "5-10 000", "10-20 000",
                                    "20-50 000", "50 000 et +"])
repartition = pd.crosstab(communes["region"], communes["taille"],
                          normalize="index") * 100

repartition.plot.barh(stacked=True, colormap="viridis")
plt.xlabel("% des communes de la région")
plt.ylabel("")
plt.legend(title="Habitants", bbox_to_anchor=(1, 1))
```

# Enregistrer un graphique

`plt.savefig()` enregistre le graphique en cours, au format donné par l'extension (`.png`, `.pdf`, `.svg`).

```python
sns.barplot(data=par_province, x="milliers", y="province")
plt.title("Population par province (milliers d'habitants)")
plt.savefig("sortie/population_provinces.png", dpi=150, bbox_inches="tight")
```

::: usage
- `dpi=150` : la résolution (150 convient à un document, 300 à une impression) ;
- `bbox_inches="tight"` : coupe les marges inutiles et évite que les étiquettes soient tronquées.
:::

::: note
Dans un notebook ou un script, `plt.show()` affiche le graphique ; un nouveau graphique commence ensuite. Dans l'atelier, chaque bloc de code produit ses propres graphiques.
:::
