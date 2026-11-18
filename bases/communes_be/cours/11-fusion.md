---
titre: Fusion de plusieurs sources
resume: Empiler avec concat(), joindre avec merge() ; choisir le type de jointure ; contrôler une fusion avec indicator et validate.
partie: Demi-journée 5 · Agrégations, fusion et consolidation
---

# Empiler des tables : concat()

`pd.concat([t1, t2, t3])` empile des tables qui ont les **mêmes colonnes**. `ignore_index=True` renumérote les lignes de 0 à n-1.

Contrôle immédiat : le nombre de lignes empilées est la somme des lignes de chaque table.

```python
import pandas as pd

bxl = pd.read_csv("donnees/population_bruxelles_2026.csv", sep=";",
                  dtype={"code_ins": str}, dtype_backend="pyarrow")
fla = pd.read_excel("donnees/population_flandre_2026.xlsx", header=2,
                    dtype={"code_ins": str}, dtype_backend="pyarrow")
wal = pd.read_csv("donnees/population_wallonie_2026.txt", sep="\t",
                  dtype={"code_ins": str}, dtype_backend="pyarrow")

empile = pd.concat([bxl, fla, wal], ignore_index=True)
print(len(bxl) + len(fla) + len(wal), len(empile))
print(empile["sexe"].unique().tolist())
```

::: sas
`SET t1 t2 t3;` dans une étape DATA empile les tables de la même façon.
:::

# Le référentiel : une ligne par commune ?

On veut ajouter à chaque ligne de population son arrondissement, sa province et sa région, à partir de la nomenclature NUTS. La table de population est `propre`, la table nettoyée de l'atelier 4.

```python
propre = pd.read_parquet("donnees/population_nettoyee.parquet",
                         dtype_backend="pyarrow")
ref = pd.read_csv("referentiels/nuts_lau_2027.txt", sep="|",
                  encoding="cp1252", dtype_backend="pyarrow")

communes_toutes = ref[ref["CD_LVL"] == 4]
print(len(communes_toutes), communes_toutes["CD_MUNTY_REFNIS"].nunique())
communes_toutes[communes_toutes["CD_MUNTY_REFNIS"] == "11002"]
```

**Lecture :** 840 lignes de communes, mais seulement 620 codes différents : une même commune peut avoir plusieurs lignes. Anvers en a deux : sa province a changé de code NUTS en 2027 (de `BE21` à `BE26`), la ligne de l'ancien code est close au 31/12/2026. D'autres communes ont disparu lors des fusions de 2019 et 2025. **La clé n'est pas unique** : c'est le piège principal d'une jointure.

# Joindre deux tables : merge()

`merge()` associe les lignes de deux tables qui partagent une **clé**. Ici, la clé s'appelle `code_ins` d'un côté et `CD_MUNTY_REFNIS` de l'autre : on renomme la colonne du référentiel.

Joignons d'abord **toutes** les lignes de communes du référentiel, sans réfléchir :

```python
cles = communes_toutes.rename(columns={"CD_MUNTY_REFNIS": "code_ins",
                                       "CD_LVL_SUP": "nuts3"})
cles = cles[["code_ins", "nuts3", "DT_VLDT_STOP"]]
joint = propre.merge(cles, on="code_ins", how="left")
print(len(propre), "->", len(joint))
```

**Lecture :** la table passe de 1 129 à 1 563 lignes, **sans aucune erreur** : chaque ligne d'Anvers (et des autres communes à plusieurs lignes) est dupliquée, une fois par ligne du référentiel. Les totaux calculés ensuite seraient faux.

# Se protéger : validate

`validate="many_to_one"` vérifie que la clé est unique dans la table de droite (le référentiel) ; sinon, erreur `MergeError`. **Erreur volontaire** :

```python erreur
joint = propre.merge(cles, on="code_ins", how="left",
                     validate="many_to_one")
```

La correction : ne garder que les communes **en vigueur**, dont la date de fin de validité est `31/12/9999`.

```python
en_vigueur = cles[cles["DT_VLDT_STOP"] == "31/12/9999"]
en_vigueur = en_vigueur.drop(columns="DT_VLDT_STOP")
print(len(en_vigueur), en_vigueur["code_ins"].nunique())

enrichi = propre.merge(en_vigueur, on="code_ins", how="left",
                       validate="many_to_one")
print(len(propre), "->", len(enrichi))
enrichi[["code_ins", "commune", "sexe", "population", "nuts3"]].head(3)
```

# Choisir le type de jointure

`how=` choisit les lignes conservées.

| how | Lignes conservées | Quand l'utiliser |
|---|---|---|
| `inner` | clés présentes dans les deux tables | analyser uniquement ce qui est apparié |
| `left` | toutes les lignes de la table de gauche | enrichir une table sans en perdre de lignes |
| `right` | toutes les lignes de la table de droite | partir du référentiel, communes sans données comprises |

```python
for how in ["inner", "left", "right"]:
    joint = propre.merge(en_vigueur, on="code_ins", how=how)
    print(how, len(joint))
```

**Lecture :** la ligne de la commune « 99999 », absente du référentiel, disparaît avec `inner` et `right`. Avec `left`, elle est conservée, avec un `nuts3` manquant. Avec `right`, Daverdisse et Martelange restent présentes (une ligne chacune).

# Contrôler une fusion : indicator

`indicator=True` ajoute une colonne `_merge` : `both`, `left_only` ou `right_only`. `value_counts()` compte chaque modalité.

Une jointure `left` sur une clé unique ne change ni le nombre de lignes ni le total.

```python
controle = propre.merge(en_vigueur, on="code_ins", how="left",
                        indicator=True, validate="many_to_one")
print(controle["_merge"].value_counts())
non_apparies = controle[controle["_merge"] == "left_only"]
print(non_apparies["code_ins"].unique().tolist())
total_avant = propre["population"].sum()
total_apres = controle["population"].sum()
print(len(propre) == len(controle), total_avant == total_apres)
```

# MERGE … BY en SAS, merge() en pandas

| | Étape DATA : MERGE … BY | pandas : merge() |
|---|---|---|
| Tri préalable | obligatoire : `PROC SORT` sur la clé | inutile |
| Lignes conservées | sans filtre : toutes ; `IF a;` ou `IF a and b;` pour filtrer | `how=` : `outer`, `left`, `inner` (défaut) |
| Origine des lignes | variables `IN=` | colonne `_merge` avec `indicator=True` |
| Clé en double des deux côtés | appariement ligne à ligne dans le groupe, avec une note dans le journal | toutes les combinaisons (produit cartésien) |
| Contrôle de la clé | à programmer | `validate="many_to_one"` |

Le cas « clé en double » est le principal piège : une jointure pandas peut multiplier les lignes sans erreur, comme on l'a vu avec Liège. D'où le contrôle systématique du nombre de lignes et l'option `validate`.

# Remonter la hiérarchie : la province

Le code NUTS 3 de l'arrondissement contient celui de la province : `BE332` (arrondissement de Liège) commence par `BE33` (province de Liège). On découpe donc le code, puis on joint la liste des provinces en vigueur.

On ne remonte la hiérarchie que pour les lignes **appariées** : la commune « 99999 » n'a pas de code NUTS, et une clé de jointure vide n'a pas de sens.

```python
provinces = ref[(ref["CD_LVL"] == 2) & (ref["DT_VLDT_STOP"] == "31/12/9999")]
provinces = provinces.rename(columns={"CD_LAU": "nuts2", "TX_DESCR_FR": "province"})
provinces = provinces[["nuts2", "province"]]
print(provinces)

apparie = controle[controle["_merge"] == "both"].drop(columns="_merge")
apparie["nuts2"] = apparie["nuts3"].str.slice(0, 4)
avec_prov = apparie.merge(provinces, on="nuts2", how="left",
                          validate="many_to_one")
avec_prov["province"].value_counts(dropna=False)
```

::: piege
**Un défaut du fichier d'origine.** La Région de Bruxelles-Capitale n'appartient à aucune province : son niveau 2 (`BE10`) a pour nom `NA`… que pandas lit comme une **valeur manquante**. On le traite explicitement, en visant les seules lignes `BE10` plutôt qu'avec un `fillna()` général, qui masquerait aussi toute autre province manquante.
:::

```python
avec_prov.loc[avec_prov["nuts2"] == "BE10", "province"] = "Région de Bruxelles-Capitale"
avec_prov["province"].value_counts(dropna=False)
```

::: note
**Une clé de jointure ne doit pas être vide.** Dans l'atelier (Python dans le navigateur), joindre sur une clé qui contient des valeurs manquantes provoque même une erreur `ValueError: putmask: output array is read-only`. Filtrez les lignes appariées, ou remplacez la clé manquante par une valeur explicite (`.fillna("-")`), avant de joindre.
:::
