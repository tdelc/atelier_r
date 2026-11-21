---
titre: Empiler et fusionner des tables
resume: Empiler les quatre trimestres avec pd.concat() ; joindre l'emploi ONSS avec merge() ; des NACE qui diffèrent d'une source à l'autre ; passer de la NACE 2008 à la NACE 2025.
partie: Vos propres fichiers
---

# Empiler les quatre trimestres : pd.concat()

Les quatre déclarations TVA ont les **mêmes colonnes** : on les empile pour obtenir l'année. Avant d'empiler, une colonne garde la trace du trimestre : elle n'existe pas dans les fichiers.

```python
lire = dict(dtype={"numero_tva": str, "nace_tva": str})
t1 = pd.read_csv("donnees/tva_2025_T1.csv", sep=";", decimal=",", thousands=".", **lire)
t2 = pd.read_excel("donnees/tva_2025_T2.xlsx", header=2, **lire)
t3 = pd.read_csv("donnees/tva_2025_T3.txt", sep="\t", **lire)
t4 = pd.read_csv("donnees/tva_2025_T4.csv", **lire)

t1["trimestre"], t2["trimestre"], t3["trimestre"], t4["trimestre"] = "T1", "T2", "T3", "T4"
tva = pd.concat([t1, t2, t3, t4], ignore_index=True)
print(len(t1) + len(t2) + len(t3) + len(t4), "->", len(tva))
tva["trimestre"].value_counts().sort_index()
```

::: usage
- `pd.concat([t1, t2, t3, t4])` reçoit une **liste** de tables ; `ignore_index=True` renumérote les lignes.
- `**lire` passe les réglages communs rangés dans le dictionnaire `lire` : on ne les écrit qu'une fois.
- Contrôle immédiat : les lignes empilées sont la somme des lignes de chaque table.
:::

::: sas
`DATA tva; SET t1(in=a) t2(in=b) t3 t4; RUN;`
:::

::: note
Les numéros sont encore écrits de quatre façons différentes : on ne peut pas encore joindre `tva` à `entreprises`. Ce sera fait dans la leçon « Nettoyer une table ». Pour l'instant, travaillons avec un fichier propre : l'emploi ONSS.
:::

# L'emploi déclaré à l'ONSS

Les employeurs déclarent chaque trimestre leurs travailleurs à l'**ONSS** (Office national de sécurité sociale) : nombre de postes, équivalents temps plein (ETP) et un code NACE attribué par l'ONSS.

```python
onss = pd.read_csv("donnees/onss_emploi_2025.csv", sep=";", decimal=",",
                   dtype={"num_entreprise": str, "nace_onss": str})
print(onss.shape)
onss.head(3)
```

# merge() : la jointure

On ajoute à chaque employeur de `entreprises` ses ETP et sa NACE selon l'ONSS, en associant les lignes par le **numéro d'entreprise**.

```python
employeurs = entreprises.query("emploi > 0")
avec_onss = employeurs.merge(onss, on="num_entreprise", how="left", validate="one_to_one")
print(len(employeurs), "->", len(avec_onss))
avec_onss[["num_entreprise", "nace", "nace_onss", "emploi", "postes", "etp"]].head(4)
```

::: usage
- `on=` : la clé commune ; `how="left"` garde **toutes** les lignes de la table de gauche ;
- `validate="one_to_one"` exige qu'un numéro n'apparaisse qu'une fois **de chaque côté** ; sinon, erreur. Ne vous en privez jamais.
:::

::: sas
`MERGE employeurs(in=a) onss; BY num_entreprise; IF a;` (après deux `PROC SORT`).
:::

# Contrôler une fusion : indicator=True

```python
controle = employeurs.merge(onss, on="num_entreprise", how="outer",
                            indicator=True, validate="one_to_one")
controle["_merge"].value_counts()
```

**Lecture :** 4 960 employeurs se retrouvent des deux côtés. 4 employeurs de la BCE n'ont pas de déclaration ONSS (retard, erreur de numéro ?), et 6 numéros de l'ONSS n'existent pas dans notre table (entreprises radiées en cours d'année). Aucune de ces lignes ne doit disparaître sans explication.

::: sas
C'est l'équivalent des variables `IN=` de l'étape `MERGE`.
:::

# Postes ou équivalents temps plein ?

```python
apparies = controle.query("_merge == 'both'")
par_secteur = apparies.groupby("secteur", as_index=False).agg(postes=("postes", "sum"),
                                                              etp=("etp", "sum"))
par_secteur["etp_par_poste"] = (par_secteur["etp"] / par_secteur["postes"]).round(2)
par_secteur.sort_values("etp_par_poste").head(5)
```

**Lecture :** dans l'horeca, le nettoyage ou le sport, un poste vaut à peine plus d'un demi-temps plein. Comparer l'emploi de deux secteurs en **postes** ou en **ETP** ne donne pas le même classement : précisez toujours l'unité.

# Le piège : trois sources, trois NACE

Une même entreprise peut recevoir un code NACE différent selon l'administration :

- la **BCE** enregistre les activités déclarées à la création, rarement mises à jour ;
- l'**ONSS** code l'activité de l'employeur, parfois celle de l'établissement où travaillent les salariés ;
- l'administration de la **TVA** a son propre code, déclaré par l'assujetti.

Comparons la BCE (`nace`) et l'ONSS (`nace_onss`) :

```python
apparies = controle.query("_merge == 'both'").copy()
apparies["meme_classe"] = apparies["nace"] == apparies["nace_onss"]
apparies["meme_division"] = apparies["nace"].str.slice(0, 2) == apparies["nace_onss"].str.slice(0, 2)
print(apparies["meme_classe"].mean().round(3), apparies["meme_division"].mean().round(3))
```

**Lecture :** les deux sources donnent la même classe NACE pour 88 % des employeurs seulement, et la même division pour 93 %.

# Où les sources divergent-elles ?

On ajoute la section ONSS grâce au référentiel NACE, puis un tableau croisé :

```python
nace = pd.read_csv("referentiels/nace_bel_2008.csv", sep=";", encoding="cp1252",
                   dtype={"classe": str})
sections = nace[["classe", "section"]].rename(columns={"classe": "nace_onss",
                                                       "section": "section_onss"})
apparies = apparies.merge(sections, on="nace_onss", how="left", validate="many_to_one")
pd.crosstab(apparies["section"], apparies["section_onss"]).loc[["K", "L", "M"], ["F", "K", "L", "M"]]
```

**Lecture :** des holdings (K) sont codées « conseil de gestion » (M) par l'autre source, et inversement ; des sociétés immobilières (L) apparaissent en construction (F). La statistique de l'emploi d'un secteur **dépend de la source choisie**.

::: piege
**Choisir une règle, et l'écrire.** Il n'y a pas de « bonne » NACE dans l'absolu. Une statistique de l'emploi suivra plutôt la NACE de l'ONSS, une statistique du chiffre d'affaires plutôt celle de la TVA ; un répertoire statistique d'entreprises fixe un **ordre de priorité** entre sources. L'essentiel : la même règle pour toutes les entreprises, documentée, et stable d'une année à l'autre.
:::

# Passer de la NACE 2008 à la NACE 2025

Depuis le 1er janvier 2025, la Belgique utilise une nouvelle nomenclature, la **NACE-BEL 2025** (fondée sur la NACE Rev. 2.1). Le référentiel `correspondance_nace_2008_2025.csv` en donne un **extrait simplifié**, pour l'atelier.

```python
corr = pd.read_csv("referentiels/correspondance_nace_2008_2025.csv", sep=";", dtype=str)
corr[corr["nace_2008"] != corr["nace_2025"]]
```

**Lecture :** certaines classes changent simplement de code (`62.01` → `62.10`), d'autres se **regroupent**, d'autres encore **éclatent** en plusieurs : `56.10` (restaurants) devient `56.11` ou `56.12`.

# Une correspondance qui n'est pas « un pour un »

**Erreur volontaire** : une classe 2008 qui éclate en deux apparaît deux fois dans la table de correspondance.

```python erreur
entreprises.merge(corr, left_on="nace", right_on="nace_2008", how="left", validate="many_to_one")
```

Sans `validate`, la jointure **dupliquerait** chaque restaurant, sans message. La bonne démarche : appliquer directement les correspondances **uniques**, et repérer les entreprises à recoder une par une.

```python
eclatees = corr[corr["nace_2008"].duplicated(keep=False)]["nace_2008"].unique()
uniques = corr[~corr["nace_2008"].isin(eclatees)]

recode = entreprises.merge(uniques, left_on="nace", right_on="nace_2008", how="left",
                           validate="many_to_one")
recode["a_recoder"] = recode["nace_2025"].isna()
print(len(entreprises), "->", len(recode))
recode.query("a_recoder")["nace"].value_counts()
```

::: note
Les entreprises « à recoder » ont besoin d'une information de plus (la description de leur activité, une enquête) pour choisir le nouveau code. C'est un vrai chantier pour les producteurs de statistiques à chaque changement de nomenclature.
:::

# Les réflexes d'une fusion

1. Avant : la clé est-elle **unique** du côté où elle doit l'être ? (`validate=`, `duplicated().sum()`)
2. Les clés ont-elles le **même type et la même écriture** des deux côtés ? (`"9000019690"` ne correspond ni à `9000019690`, ni à `"BE9000.019.690"`)
3. Après : le nombre de lignes a-t-il changé ? Combien de lignes non appariées, et pourquoi ? (`indicator=True`)
4. Les totaux sont-ils restés les mêmes ?

```python
employeurs["emploi"].sum() == avec_onss["emploi"].sum()
```
