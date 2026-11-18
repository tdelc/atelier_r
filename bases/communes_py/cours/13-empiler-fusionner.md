---
titre: Empiler et fusionner des tables
resume: Empiler des fichiers avec pd.concat(), associer les informations d'une autre table avec merge() ; contrôler une fusion avec indicator et validate.
partie: Vos propres fichiers
---

# Empiler des tables : pd.concat()

Statbel livre parfois un fichier par région. Les trois fichiers de `donnees/` ont les **mêmes colonnes** : on les empile.

```python
bxl = pd.read_csv("donnees/population_bruxelles_2026.csv", sep=";",
                  dtype={"code_ins": str})
fla = pd.read_excel("donnees/population_flandre_2026.xlsx", header=2,
                    dtype={"code_ins": str})
wal = pd.read_csv("donnees/population_wallonie_2026.txt", sep="\t",
                  dtype={"code_ins": str})

livraisons = pd.concat([bxl, fla, wal], ignore_index=True)
print(len(bxl), len(fla), len(wal), "->", len(livraisons))
livraisons.head(3)
```

::: usage
`pd.concat([t1, t2, t3])` reçoit une **liste** de tables. `ignore_index=True` renumérote les lignes de 0 à n-1. Contrôle immédiat : le nombre de lignes empilées est la somme des lignes de chaque table.
:::

::: sas
`DATA livraisons; SET bxl fla wal; RUN;`
:::

# Garder la trace de la source

Avant d'empiler, une colonne indique d'où vient chaque ligne.

```python
bxl["source"] = "Bruxelles"
fla["source"] = "Flandre"
wal["source"] = "Wallonie"
livraisons = pd.concat([bxl, fla, wal], ignore_index=True)
livraisons["source"].value_counts()
```

::: note
Ces fichiers contiennent quelques **anomalies volontaires** (un sexe en minuscule, une population manquante…) : on les traitera dans la leçon « Nettoyer une table ».
:::

# Fusionner : ajouter des colonnes d'une autre table

La table `communes` donne les noms en français. La nomenclature NUTS donne aussi les noms en **néerlandais** et en **allemand**. On veut les ajouter à `communes`, en associant les lignes par le **code INS** : c'est une fusion, ou **jointure**.

```python
nuts = pd.read_csv("referentiels/nuts_lau_2027.txt", sep="|", encoding="cp1252",
                   dtype={"CD_MUNTY_REFNIS": str})
noms = nuts[["CD_MUNTY_REFNIS", "TX_DESCR_NL", "TX_DESCR_DE", "CD_LVL", "DT_VLDT_STOP"]]
noms = noms.rename(columns={"CD_MUNTY_REFNIS": "code_ins",
                            "TX_DESCR_NL": "nom_nl", "TX_DESCR_DE": "nom_de"})
noms.head(3)
```

# merge() : la jointure

```python
avec_noms = communes.merge(noms, on="code_ins", how="left")
print(len(communes), "->", len(avec_noms))
```

**Lecture :** 565 communes au départ… et 782 lignes à l'arrivée ! Aucune erreur, et pourtant le résultat est faux.

# Le piège : une clé en double

La nomenclature contient **plusieurs lignes pour un même code** : les régions, provinces et arrondissements, mais surtout l'historique des communes (une ligne par période de validité). Anvers, par exemple :

```python
noms.query("code_ins == '11002'")
```

Chaque ligne d'Anvers dans `communes` a été associée aux deux lignes d'Anvers de la nomenclature : elle est **dupliquée**. Les totaux calculés ensuite seraient faux.

::: sas
En SAS, `MERGE ... BY` apparie ligne à ligne et signale « MERGE statement has more than one data set with repeats of BY values » dans le journal. pandas, lui, produit **toutes les combinaisons**, sans rien dire.
:::

# Se protéger : validate=

`validate="many_to_one"` exige que chaque code n'apparaisse **qu'une fois** dans la table de droite. Sinon : erreur. **Erreur volontaire** :

```python erreur
communes.merge(noms, on="code_ins", how="left", validate="many_to_one")
```

La correction : ne garder, dans la nomenclature, que les **communes** (niveau 4) **en vigueur** (fin de validité au 31/12/9999).

```python
noms_vigueur = noms.query("CD_LVL == 4 and DT_VLDT_STOP == '31/12/9999'")
noms_vigueur = noms_vigueur.drop(columns=["CD_LVL", "DT_VLDT_STOP"])

avec_noms = communes.merge(noms_vigueur, on="code_ins", how="left",
                           validate="many_to_one")
print(len(communes), "->", len(avec_noms))
avec_noms.query("commune in ['Liège', 'Mons', 'Louvain', 'Anvers', 'Malines', 'Bruxelles']")[["commune", "nom_nl", "nom_de"]]
```

# Choisir les lignes gardées : how=

| `how=` | Lignes gardées | En SAS (`MERGE a(in=a) b(in=b)`) |
|---|---|---|
| `"left"` | toutes celles de la table de gauche | `if a;` |
| `"inner"` | celles présentes des deux côtés | `if a and b;` |
| `"right"` | toutes celles de la table de droite | `if b;` |
| `"outer"` | toutes, des deux côtés | pas de `if` |

`"left"` est le choix habituel pour **enrichir** une table sans en perdre de lignes.

# Contrôler une fusion : indicator=True

`indicator=True` ajoute une colonne `_merge` qui dit d'où vient chaque ligne : `both` (des deux côtés), `left_only`, `right_only`.

```python
controle = communes.merge(noms_vigueur, on="code_ins", how="outer",
                          indicator=True, validate="one_to_one")
controle["_merge"].value_counts()
```

**Lecture :** les 565 communes de la table se retrouvent dans la nomenclature, et inversement : la fusion est complète.

::: sas
C'est l'équivalent des variables `IN=` de l'étape `MERGE`.
:::

# Les réflexes d'une fusion

1. Avant : la clé est-elle **unique** dans la table de droite ? (`validate=`, ou `noms["code_ins"].duplicated().sum()`)
2. Les clés ont-elles le **même type** des deux côtés ? Un code en texte (`"11002"`) ne correspond pas à un code en nombre (`11002`).
3. Après : le nombre de lignes a-t-il changé ? Combien de lignes non appariées ? (`indicator=True`)
4. Les totaux sont-ils restés les mêmes ?

```python
communes["total"].sum() == avec_noms["total"].sum()
```
