---
titre: Mettre en forme un tableau
resume: Trier, passer des modalités en colonnes (pivot_table), un taux pondéré en tableau à double entrée, revenir au format long (melt), renommer.
partie: Les bases
---

# Trier : sort_values()

```python
(personnes
 .sort_values(["region", "revenu_equivalent"], ascending=[True, False])
 .groupby("region")
 .head(2)
 [["region", "type_menage", "statut", "revenu_equivalent"]])
```

::: usage
`groupby(...).head(2)` garde les 2 **premières lignes de chaque groupe** : après un tri, les 2 revenus les plus élevés de chaque région.
:::

::: sas
`PROC SORT DATA=personnes; BY region DESCENDING revenu_equivalent; RUN;`
:::

# pivot_table() : la population par région et par âge

Les régions en lignes, les classes d'âge en colonnes, la somme des poids dans les cases :

```python
personnes.pivot_table(index="region", columns="classe_age", values="poids",
                      aggfunc="sum").round(0)
```

::: usage
- `index` : ce qui va **en lignes** ;
- `columns` : la variable dont les modalités deviennent **des colonnes** ;
- `values` et `aggfunc` : la variable à calculer et le calcul.
:::

::: sas
`PROC TABULATE DATA=personnes; CLASS region classe_age; VAR poids; TABLE region, classe_age*poids*SUM;`
:::

# Un taux pondéré en tableau

Le taux de risque de pauvreté par région et par classe d'âge : deux tableaux de sommes, puis une division case par case.

```python
tri = personnes.sort_values("revenu_equivalent")
cumul = tri["poids"].cumsum()
seuil = 0.6 * tri.loc[cumul >= tri["poids"].sum() / 2, "revenu_equivalent"].iloc[0]
personnes["pauvres_pond"] = (personnes["revenu_equivalent"] < seuil) * personnes["poids"]

pauvres = personnes.pivot_table(index="region", columns="classe_age", values="pauvres_pond", aggfunc="sum")
population = personnes.pivot_table(index="region", columns="classe_age", values="poids", aggfunc="sum")
taux = (pauvres / population * 100).round(1)
taux
```

::: usage
Deux tableaux de **même forme** se divisent case par case : pandas aligne les lignes et les colonnes par leur nom.
:::

**Lecture :** dans chaque région, les jeunes de 18 à 24 ans et les enfants sont plus souvent sous le seuil que les 65 ans et plus.

# Les marges : la ligne et la colonne « Total »

```python
pauvres = personnes.pivot_table(index="region", columns="classe_age", values="pauvres_pond",
                                aggfunc="sum", margins=True, margins_name="Belgique")
population = personnes.pivot_table(index="region", columns="classe_age", values="poids",
                                   aggfunc="sum", margins=True, margins_name="Belgique")
(pauvres / population * 100).round(1)
```

# melt() : du format large au format long

Pour représenter ou exporter, on revient souvent au format **long** : une ligne par région **et** par classe d'âge.

```python
long = taux.reset_index().melt(id_vars="region", var_name="classe_age", value_name="taux")
long.head(6)
```

| Format | Une ligne = | Utile pour |
|---|---|---|
| long | une région × une classe d'âge | représenter, filtrer, fusionner |
| large | une région | lire, comparer les âges côte à côte |

::: sas
`PROC TRANSPOSE` dans les deux sens.
:::

# Renommer : rename()

```python
(taux
 .rename(columns={"0-17": "Enfants", "18-24": "Jeunes", "25-49": "25-49 ans",
                  "50-64": "50-64 ans", "65+": "65 ans et +"})
 .rename_axis(index="Région", columns="Âge"))
```

::: note
Gardez des noms courts et sans espace pour **calculer**, et ne renommez en beaux libellés qu'à la **fin**, pour présenter.
:::

# Une ligne par ménage : drop_duplicates()

Les caractéristiques des ménages (type, taille, revenu) sont recopiées sur chaque personne. Pour un tableau **des ménages** :

```python
menages = personnes.drop_duplicates("id_menage")[["id_menage", "region", "type_menage",
                                                   "taille_menage", "revenu_menage"]]
menages.pivot_table(index="type_menage", columns="region", values="taille_menage",
                    aggfunc="mean").round(2)
```

::: sas
`PROC SORT DATA=personnes OUT=menages NODUPKEY; BY id_menage; RUN;`
:::
