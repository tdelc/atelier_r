---
titre: Mettre en forme un tableau
resume: Trier, passer des modalités en colonnes (pivot_table), revenir au format long (melt), dédoublonner.
partie: Les bases
---

# Trier : sort_values()

```python
communes.sort_values("total", ascending=False).head(5)[["commune", "total"]]
```

Trier sur plusieurs colonnes : par province (ordre alphabétique), puis par population décroissante dans chaque province.

```python
(communes
 .sort_values(["province", "total"], ascending=[True, False])
 [["province", "commune", "total"]]
 .head(6))
```

::: sas
`PROC SORT DATA=communes; BY province DESCENDING total; RUN;` En pandas, trier ne sert qu'à l'**affichage** ou à l'export : les regroupements et les fusions n'en ont pas besoin.
:::

# Format long et format large

La table `pop_sexe` contient les mêmes chiffres que `communes`, mais en **format long** : une ligne par commune **et par sexe**.

```python
pop_sexe.head(6)
```

| Format | Une ligne = | Utile pour |
|---|---|---|
| long (`pop_sexe`) | une commune × un sexe | regrouper, représenter (une colonne par variable) |
| large (`communes`) | une commune | lire, comparer hommes et femmes côte à côte |

Passer de l'un à l'autre est une opération courante : c'est `PROC TRANSPOSE` en SAS.

# pivot_table() : des modalités en colonnes

La population par province et par sexe, avec les sexes **en colonnes** :

```python
pop_sexe.pivot_table(index="province", columns="sexe",
                     values="population", aggfunc="sum")
```

::: usage
- `index` : ce qui va **en lignes** ;
- `columns` : la variable dont les modalités deviennent **des colonnes** ;
- `values` : la variable à calculer ; `aggfunc` : le calcul (`"sum"`, `"mean"`, `"count"`…).
:::

::: sas
`PROC TABULATE DATA=pop_sexe; CLASS province sexe; VAR population; TABLE province, sexe*population*SUM;`, ou `PROC TRANSPOSE` après un `PROC MEANS`.
:::

# Ajouter les totaux : margins

```python
pop_sexe.pivot_table(index="region", columns="sexe", values="population",
                     aggfunc="sum", margins=True, margins_name="Total")
```

# Un tableau à double entrée à partir de communes

Le nombre de communes par région et par classe de taille. On recrée d'abord la classe de taille (leçon précédente) :

```python
communes["taille"] = pd.cut(communes["total"],
                            bins=[0, 5000, 10000, 20000, 50000, 600000],
                            labels=["< 5 000", "5-10 000", "10-20 000",
                                    "20-50 000", "50 000 et +"])

communes.pivot_table(index="region", columns="taille", values="commune",
                     aggfunc="count", observed=False)
```

**Lecture :** la Wallonie compte 53 communes de moins de 5 000 habitants, la Flandre 13 seulement, alors qu'elle a plus de communes : les communes wallonnes sont nettement plus petites. À Bruxelles, toutes dépassent 20 000 habitants.

::: note
`observed=False` garde toutes les classes, même vides : sans lui, une classe absente d'une région disparaîtrait du tableau.
:::

# melt() : du format large au format long

L'opération inverse : les colonnes `hommes` et `femmes` deviennent deux lignes par commune.

```python
long = communes.melt(id_vars=["code_ins", "commune"],
                     value_vars=["hommes", "femmes"],
                     var_name="sexe", value_name="population")
long.sort_values("code_ins").head(4)
```

::: usage
- `id_vars` : les colonnes à garder telles quelles (l'identifiant de la ligne) ;
- `value_vars` : les colonnes à empiler ;
- `var_name`, `value_name` : les noms des deux nouvelles colonnes.
:::

# Les doublons : drop_duplicates()

La liste des provinces et de leur région, une ligne par province :

```python
communes[["region", "province"]].drop_duplicates().sort_values(["region", "province"])
```

::: sas
`PROC SORT DATA=communes OUT=provinces NODUPKEY; BY region province; RUN;`
:::

# Réindexer après un tri : reset_index()

Après un tri ou un filtre, les numéros de ligne (l'index) ne se suivent plus. `reset_index(drop=True)` les renumérote à partir de 0.

```python
(communes
 .nlargest(3, "total")
 .reset_index(drop=True)
 [["commune", "total"]])
```
