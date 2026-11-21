---
titre: Empiler et fusionner des tables
resume: Empiler trois fichiers régionaux ; coupler l'enquête au Registre national et aux fichiers de l'ONEM, du SPF Finances et des CPAS ; clés pseudonymisées, couverture, niveau personne ou ménage.
partie: Vos propres fichiers
---

# Coupler des sources : le cadre belge

Les statistiques sociales combinent de plus en plus une **enquête** et des **données administratives** : on ne demande plus aux ménages ce que l'administration sait déjà (revenus, allocations), et on gagne en précision.

- Le **Registre national** enregistre chaque habitant : identité, adresse, composition du ménage. Il identifie chaque personne par son numéro de registre national ; les personnes qui n'y sont pas inscrites (travailleurs frontaliers, par exemple) ont un numéro **BIS** à la Banque-Carrefour de la Sécurité Sociale. Ces numéros forment le **NISS**, la clé de la sécurité sociale.
- La **Banque-Carrefour de la Sécurité Sociale (BCSS)** relie les institutions sociales (ONSS, ONEM, INAMI, CPAS…) ; son **datawarehouse marché du travail et protection sociale** rassemble leurs données.
- Un couplage à des fins statistiques passe par une **autorisation** (le Comité de sécurité de l'information) et un **tiers de confiance**, qui remplace le NISS par un **pseudonyme** : l'analyste ne voit jamais le numéro réel.

::: piege
**Ce que vous ne ferez jamais** : coupler sur le nom, la date de naissance et l'adresse « pour retrouver » une personne, ou chercher à ré-identifier quelqu'un à partir de ses caractéristiques. Le RGPD et le secret statistique l'interdisent. Le pseudonyme sert à relier des fichiers, pas à identifier.
:::

# Empiler trois fichiers régionaux : pd.concat()

Le revenu d'intégration arrive en un fichier par région, avec les **mêmes colonnes** : on les empile, en gardant la trace de la région.

```python
ris_bxl = pd.read_csv("donnees/ris_2025_bruxelles.csv", sep=";", decimal=",", dtype={"id_pseudo": str})
ris_fla = pd.read_excel("donnees/ris_2025_flandre.xlsx", dtype={"id_pseudo": str})
ris_wal = pd.read_csv("donnees/ris_2025_wallonie.txt", sep="\t", dtype={"id_pseudo": str})
ris_bxl["region_ris"], ris_fla["region_ris"], ris_wal["region_ris"] = "Bruxelles", "Flandre", "Wallonie"

ris = pd.concat([ris_bxl, ris_fla, ris_wal], ignore_index=True)
print(len(ris_bxl) + len(ris_fla) + len(ris_wal), "->", len(ris))
ris.head(3)
```

::: usage
`pd.concat([t1, t2, t3])` reçoit une **liste** de tables ; `ignore_index=True` renumérote les lignes. Contrôle : les lignes empilées sont la somme des lignes de chaque table.
:::

::: sas
`DATA ris; SET ris_bxl ris_fla ris_wal; RUN;`
:::

# Coupler au Registre national : merge()

```python
rn = pd.read_csv("donnees/registre_national_2026.csv", sep=";",
                 dtype={"id_pseudo": str, "code_ins": str})
avec_rn = personnes.merge(rn, on="id_pseudo", how="left", suffixes=("", "_rn"))
print(len(personnes), "->", len(avec_rn))
```

**Lecture :** 13 683 personnes au départ… et 13 833 lignes à l'arrivée. Aucune erreur, et pourtant le résultat est faux.

::: usage
`suffixes=("", "_rn")` : quand une colonne existe des deux côtés (`sexe`, `code_ins`), celle du registre reçoit le suffixe `_rn` et l'on peut comparer les deux.
:::

# Le piège : une clé en double

```python
print(rn["id_pseudo"].duplicated().sum())
doublon = rn.loc[rn["id_pseudo"].duplicated(), "id_pseudo"].iloc[0]
rn.query("id_pseudo == @doublon")
```

**Lecture :** 150 personnes ont **deux lignes** dans l'extrait : elles ont déménagé en 2025, et l'extrait donne l'historique des adresses. Chacune a été dupliquée à la jointure.

Se protéger : `validate="many_to_one"` exige une seule ligne par pseudonyme à droite. **Erreur volontaire** :

```python erreur
personnes.merge(rn, on="id_pseudo", how="left", validate="many_to_one")
```

La correction : décider d'une **date de référence**. Ici, on garde l'adresse la plus récente.

```python
rn_dernier = rn.sort_values("date_debut_adresse").drop_duplicates("id_pseudo", keep="last")
avec_rn = personnes.merge(rn_dernier, on="id_pseudo", how="left", suffixes=("", "_rn"),
                          validate="one_to_one", indicator=True)
avec_rn["_merge"].value_counts()
```

**Lecture :** 205 personnes de l'enquête (1,5 %) ne sont pas retrouvées dans le registre. Elles ne disparaissent pas : avec `how="left"`, elles restent, avec des colonnes vides.

::: piege
**Les non-retrouvés ne sont pas pris au hasard** : personnes arrivées récemment, inscrites sous un numéro BIS, erreurs de saisie… Si on les supprime, on biaise les résultats. On compte, on décrit, et on documente.
:::

# Coupler les allocations de chômage

```python
onem = pd.read_excel("donnees/onem_allocations_2025.xlsx", header=2, dtype={"id_pseudo": str})
avec_onem = personnes.merge(onem, on="id_pseudo", how="left", validate="one_to_one")
avec_onem["type_allocation"] = avec_onem["type_allocation"].fillna("aucune")
avec_onem["montant_annuel"] = avec_onem["montant_annuel"].fillna(0)
```

::: note
Ici, `fillna(0)` est **légitime** : absent du fichier de l'ONEM signifie « n'a pas perçu d'allocation ». Ce n'était pas le cas pour un chiffre d'affaires manquant ou une personne absente du registre. La règle dépend de ce que signifie l'absence.
:::

# Chômeur selon l'enquête, chômeur selon l'ONEM

```python
pd.crosstab(avec_onem.query("age.between(15, 64)")["statut"],
            avec_onem.query("age.between(15, 64)")["type_allocation"])
```

**Lecture :** les deux notions ne coïncident pas. Des chômeurs au sens du BIT ne touchent pas d'allocation (jeunes sans droits, personnes exclues) ; des personnes en emploi en reçoivent (**chômage temporaire**) ; des inactifs aussi (dispensés de recherche d'emploi). Le « chômage administratif » et le « chômage BIT » sont deux statistiques différentes, toutes deux utiles.

# Du niveau personne au niveau ménage

Le revenu fiscal est **individuel**, la pauvreté se mesure au niveau du **ménage**. On additionne les revenus des membres de chaque ménage, puis on rattache le total à chaque personne.

```python
fisc = pd.read_csv("donnees/spf_finances_revenus_2024.txt", sep="\t", decimal=",",
                   thousands=".", dtype={"id_pseudo": str})
avec_fisc = personnes.merge(fisc, on="id_pseudo", how="left", validate="one_to_one")
par_menage = (avec_fisc.groupby("id_menage", as_index=False)
              .agg(revenu_fiscal_menage=("revenu_imposable", "sum")))
personnes_fisc = personnes.merge(par_menage, on="id_menage", how="left", validate="many_to_one")
personnes_fisc[["id_menage", "age", "revenu_menage", "revenu_fiscal_menage"]].head(5)
```

::: usage
`validate="many_to_one"` : **plusieurs** personnes (à gauche) pour **un** ménage (à droite). C'est le bon contrôle pour rattacher une information de niveau supérieur.
:::

::: piege
**Deux revenus différents.** Le revenu imposable est **brut** (avant impôts), **individuel** et porte sur **2024** ; le revenu disponible de l'enquête est **net**, du **ménage**, allocations comprises. Coupler ne veut pas dire que les deux colonnes se comparent directement.
:::

# Les réflexes d'un couplage

1. Avant : la clé est-elle **unique** du côté où elle doit l'être ? À quelle **date de référence** ?
2. La clé a-t-elle le **même type** des deux côtés (`dtype=str`) ?
3. Après : combien de personnes **non retrouvées**, et lesquelles ? (`indicator=True`)
4. Que signifie l'**absence** dans chaque fichier : zéro, ou inconnu ?
5. Le nombre de lignes et les totaux sont-ils restés les mêmes ?

```python
len(personnes) == len(avec_onem) == len(personnes_fisc)
```
