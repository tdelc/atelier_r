---
titre: Mettre en forme un tableau
resume: Trier, passer des modalités en colonnes (pivot_table), revenir au format long (melt), renommer, dédoublonner.
partie: Les bases
---

# Trier : sort_values()

```python
entreprises.sort_values("ca", ascending=False).head(5)[["nace", "commune", "ca"]]
```

Trier sur plusieurs colonnes : par région, puis par emploi décroissant dans chaque région.

```python
(entreprises
 .sort_values(["region", "emploi"], ascending=[True, False])
 [["region", "nace", "commune", "emploi"]]
 .groupby("region")
 .head(2))
```

::: usage
`groupby(...).head(2)` garde les 2 **premières lignes de chaque groupe**, dans l'ordre de la table : après un tri, ce sont les 2 plus grandes de chaque région.
:::

::: sas
`PROC SORT DATA=entreprises; BY region DESCENDING emploi; RUN;` En pandas, trier ne sert qu'à l'**affichage** ou à l'export : les regroupements et les fusions n'en ont pas besoin.
:::

# pivot_table() : des modalités en colonnes

L'emploi par section (en lignes) et par région (en colonnes) :

```python
emploi = entreprises.pivot_table(index="section", columns="region",
                                 values="emploi", aggfunc="sum")
emploi.head(6)
```

::: usage
- `index` : ce qui va **en lignes** ;
- `columns` : la variable dont les modalités deviennent **des colonnes** ;
- `values` : la variable à calculer ; `aggfunc` : le calcul (`"sum"`, `"mean"`, `"count"`…).
:::

::: sas
`PROC TABULATE DATA=entreprises; CLASS section region; VAR emploi; TABLE section, region*emploi*SUM;`
:::

# Les totaux et les cases vides

```python
entreprises.pivot_table(index="forme", columns="region", values="num_entreprise",
                        aggfunc="count", margins=True, margins_name="Total",
                        fill_value=0)
```

::: usage
`margins=True` ajoute une ligne et une colonne de totaux. `fill_value=0` remplit les cases sans aucune entreprise ; sans lui, elles seraient vides (`NaN`).
:::

::: piege
Pour un **comptage**, une case vide vaut bien 0. Pour une **moyenne** ou un chiffre d'affaires, une case vide signifie « pas d'information » : ne la remplissez pas par 0.
:::

# melt() : du format large au format long

Le tableau `emploi` a une colonne par région. Pour le représenter ou le fusionner, on revient souvent au format **long** : une ligne par section **et** par région.

```python
long = (emploi
        .reset_index()
        .melt(id_vars="section", var_name="region", value_name="emploi"))
long.head(6)
```

::: usage
`reset_index()` refait de `section` une colonne ordinaire ; `melt()` empile les colonnes des régions. C'est l'opération inverse de `pivot_table()`.
:::

| Format | Une ligne = | Utile pour |
|---|---|---|
| long | une section × une région | regrouper, représenter, fusionner |
| large | une section | lire, comparer les régions côte à côte |

::: sas
`PROC TRANSPOSE` dans les deux sens.
:::

# Renommer : rename()

```python
(entreprises
 .groupby("secteur", as_index=False)
 .agg(n=("num_entreprise", "count"), sal=("emploi", "sum"))
 .rename(columns={"n": "Entreprises", "sal": "Salariés", "secteur": "Secteur"})
 .sort_values("Salariés", ascending=False)
 .head(4))
```

::: note
Gardez des noms courts et sans espace pour **calculer** (`emploi`, `ca_meur`), et ne renommez en beaux libellés qu'à la **fin**, pour présenter.
:::

# Les doublons : drop_duplicates()

La liste des sections NACE et de leur libellé, une ligne par section :

```python
entreprises[["section", "secteur"]].drop_duplicates().sort_values("section")
```

::: sas
`PROC SORT DATA=entreprises OUT=sections NODUPKEY; BY section; RUN;`
:::

# Arrondir et présenter

```python
(entreprises
 .groupby("region", as_index=False)
 .agg(ca_meur=("ca", "sum"))
 .assign(ca_meur=lambda t: (t["ca_meur"] / 1000).round(1))
 .reset_index(drop=True))
```

::: usage
`.assign(colonne=lambda t: ...)` crée une colonne **au milieu d'une chaîne**, à partir de la table du moment (`t`). C'est l'équivalent de `table["colonne"] = ...`, sans casser l'enchaînement.
:::
