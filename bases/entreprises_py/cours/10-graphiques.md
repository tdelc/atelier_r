---
titre: Graphiques avec seaborn
resume: Préparer une table, puis la dessiner - barres, histogrammes sur échelle logarithmique, boîtes, nuages de points, barres empilées ; titres, axes et export.
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

L'emploi salarié par secteur, en milliers :

```python
par_secteur = (entreprises
               .groupby("secteur", as_index=False)
               .agg(emploi=("emploi", "sum"))
               .sort_values("emploi", ascending=False))

sns.barplot(data=par_secteur, x="emploi", y="secteur")
plt.title("Emploi salarié par secteur, fin 2025 (données fictives)")
plt.xlabel("Salariés")
plt.ylabel("")
```

::: usage
Des barres **horizontales** (`y=` la catégorie) : les longs libellés restent lisibles. L'ordre des barres suit l'ordre de la table : on trie avant de dessiner.
:::

::: sas
`PROC SGPLOT DATA=par_secteur; HBAR secteur / RESPONSE=emploi; RUN;`
:::

# Un histogramme : sns.histplot()

La distribution du chiffre d'affaires est si asymétrique qu'un histogramme ordinaire montre une seule barre. Avec `log_scale=True`, l'axe est logarithmique : chaque graduation multiplie par 10.

```python
sns.histplot(data=entreprises, x="ca", bins=40, log_scale=True)
plt.title("Distribution du chiffre d'affaires")
plt.xlabel("Chiffre d'affaires (milliers d'euros, échelle logarithmique)")
plt.ylabel("Nombre d'entreprises")
```

::: note
Les entreprises sans chiffre d'affaires (exonérées) sont ignorées : seaborn écarte les valeurs manquantes.
:::

# Comparer des groupes : hue=

`hue=` colore selon une colonne : un histogramme par catégorie, superposés.

```python
employeurs = entreprises.query("emploi > 0")
sns.histplot(data=employeurs, x="emploi", hue="region", bins=30,
             log_scale=True, element="step", stat="density", common_norm=False)
plt.xlabel("Salariés (échelle logarithmique)")
```

::: usage
`stat="density", common_norm=False` : chaque région est ramenée à la même surface. Sans cela, la Flandre, la plus nombreuse, écraserait les deux autres.
:::

# Des boîtes : sns.boxplot()

Le chiffre d'affaires par salarié des employeurs, pour quelques secteurs :

```python
employeurs = entreprises.query("emploi > 0 and section in ['C', 'F', 'G', 'I', 'J', 'M']").copy()
employeurs["ca_par_salarie"] = employeurs["ca"] / employeurs["emploi"]
sns.boxplot(data=employeurs, x="ca_par_salarie", y="secteur", log_scale=True)
plt.xlabel("Chiffre d'affaires par salarié (milliers d'euros, échelle log.)")
plt.ylabel("")
```

::: usage
La boîte va du premier au troisième quartile ; le trait central est la médiane ; les points isolés sont les entreprises atypiques.
:::

# Un nuage de points : sns.scatterplot()

Chaque point est une entreprise : son emploi en abscisse, son chiffre d'affaires en ordonnée.

```python
sns.scatterplot(data=entreprises.query("emploi > 0"), x="emploi", y="ca",
                hue="section", alpha=0.5, legend=False)
plt.xscale("log")
plt.yscale("log")
plt.xlabel("Salariés (échelle log.)")
plt.ylabel("Chiffre d'affaires (milliers d'euros, échelle log.)")
```

**Lecture :** sur deux échelles logarithmiques, le nuage forme une bande : le chiffre d'affaires croît avec l'emploi, mais à emploi égal il varie d'un facteur 10 ou plus selon le secteur.

# Des barres empilées à 100 %

La répartition de l'emploi par classe de taille, dans chaque région :

```python
entreprises["taille"] = pd.cut(entreprises["emploi"], bins=[0, 9, 49, 249, 100000],
                               labels=["1-9", "10-49", "50-249", "250 et +"])
repartition = pd.crosstab(entreprises["region"], entreprises["taille"],
                          values=entreprises["emploi"], aggfunc="sum",
                          normalize="index") * 100

repartition.plot.barh(stacked=True, colormap="viridis")
plt.xlabel("% de l'emploi salarié de la région")
plt.ylabel("")
plt.legend(title="Salariés", bbox_to_anchor=(1, 1))
```

::: note
`bins=[0, 9, …]` commence à 0 exclu : les entreprises sans salarié n'ont pas de classe, elles n'ont de toute façon aucun emploi à répartir.
:::

# Exporter un graphique

```python
sns.barplot(data=par_secteur, x="emploi", y="secteur")
plt.title("Emploi salarié par secteur")
plt.savefig("sortie/emploi_secteurs.png", dpi=150, bbox_inches="tight")
```

::: usage
- `dpi=150` : la résolution (150 suffit pour un document, 300 pour l'impression) ;
- `bbox_inches="tight"` : rogne les marges et évite de couper les libellés.
:::
