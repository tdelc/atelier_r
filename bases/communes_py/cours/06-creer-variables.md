---
titre: Créer des variables
resume: Ajouter une colonne calculée, une variable oui / non, des classes de taille, un recodage ; calculer une part dans son groupe.
partie: Les bases
---

# Une colonne calculée

La part des femmes dans chaque commune, en % :

```python
communes["part_femmes"] = communes["femmes"] / communes["total"] * 100

communes[["commune", "femmes", "total", "part_femmes"]].head()
```

::: usage
`table["nouvelle"] = calcul` crée une colonne (ou remplace une colonne qui porte déjà ce nom). Le calcul est fait **pour toutes les lignes à la fois** : pas de boucle à écrire.
:::

::: sas
`DATA communes; SET communes; part_femmes = femmes / total * 100; RUN;`
:::

# Arrondir une colonne

```python
communes["part_femmes"] = communes["part_femmes"].round(1)
communes[["commune", "part_femmes"]].head(3)
```

# Une variable oui / non

Une comparaison donne `True` (vrai) ou `False` (faux) pour chaque ligne.

```python
communes["plus_de_femmes"] = communes["femmes"] > communes["hommes"]
communes["plus_de_femmes"].value_counts()
```

::: usage
Les variables `True` / `False` se comptent facilement : `.sum()` compte les `True`, `.mean()` donne leur proportion.
:::

```python
communes["plus_de_femmes"].mean().round(3)
```

**Lecture :** 79,6 % des communes (450 sur 565) comptent plus de femmes que d'hommes.

# Deux modalités : np.where()

`np.where(condition, valeur_si_vrai, valeur_si_faux)` crée une colonne à deux modalités.

```python
communes["urbaine"] = np.where(communes["total"] >= 50000, "50 000 et plus", "moins de 50 000")
communes["urbaine"].value_counts()
```

::: usage
`np` est **NumPy**, la bibliothèque de calcul sur laquelle repose pandas. Elle s'importe avec `import numpy as np` (déjà fait dans l'atelier).
:::

::: sas
`if total >= 50000 then urbaine = '50 000 et plus'; else urbaine = 'moins de 50 000';`
:::

# Des classes : pd.cut()

`pd.cut()` découpe une colonne numérique en classes, avec des **bornes** et des **libellés**.

```python
communes["taille"] = pd.cut(
    communes["total"],
    bins=[0, 5000, 10000, 20000, 50000, 600000],
    labels=["moins de 5 000", "5 000 à 10 000", "10 000 à 20 000",
            "20 000 à 50 000", "50 000 et plus"])

communes["taille"].value_counts().sort_index()
```

::: piege
Par défaut, chaque classe **inclut sa borne de droite** : une commune de 5 000 habitants exactement tombe dans « moins de 5 000 ». La dernière borne doit dépasser le maximum (565 615 pour Anvers), sinon la commune la plus peuplée n'aurait pas de classe.
:::

::: sas
Un format `PROC FORMAT; VALUE taille 0-5000 = 'moins de 5 000' ...;`, ou une suite de `if ... then ... else`.
:::

# Recoder des modalités : map()

`.map()` remplace chaque valeur selon un **dictionnaire** `{ancienne: nouvelle}`.

```python
langue = {"Flandre": "néerlandophone", "Wallonie": "francophone",
          "Bruxelles": "bilingue"}
communes["langue"] = communes["region"].map(langue)
communes[["commune", "region", "langue"]].head(3)
```

::: piege
Une valeur absente du dictionnaire devient **manquante** (`NaN`). C'est d'ailleurs un raccourci : les communes germanophones (arrondissement de Verviers) sont classées ici « francophones ». Vérifiez toujours avec `value_counts(dropna=False)`.
:::

# Une part dans son groupe : transform()

Quelle part de la population de sa province chaque commune représente-t-elle ?

`groupby(...).transform("sum")` calcule la somme de chaque province **et la recopie sur chaque ligne** de cette province : on peut alors diviser ligne à ligne.

```python
communes["pop_province"] = communes.groupby("province")["total"].transform("sum")
communes["part_province"] = (communes["total"] / communes["pop_province"] * 100).round(1)

communes.nlargest(5, "part_province")[["commune", "province", "part_province"]]
```

**Lecture :** Anvers pèse 29,3 % de la population de sa province, Namur 22,8 %. La commune de Bruxelles ne représente que 15,8 % de la Région de Bruxelles-Capitale.

# Rang dans le groupe : rank()

La place de chaque commune dans sa province, de la plus peuplée (1) à la moins peuplée :

```python
communes["rang_province"] = communes.groupby("province")["total"].rank(ascending=False)
communes.query("rang_province == 1")[["province", "commune", "total"]]
```

# Créer des colonnes dans une chaîne : assign()

Dans une chaîne d'étapes, `.assign()` crée une colonne sans modifier la table d'origine.

```python
(communes
 .assign(part_hommes=(communes["hommes"] / communes["total"] * 100).round(1))
 .nsmallest(3, "part_hommes")
 [["commune", "part_hommes"]])
```

::: note
`assign()` est pratique pour une analyse ponctuelle : la colonne n'existe que dans le résultat. Avec `table["nouvelle"] = ...`, la colonne est **ajoutée à la table**, et disponible pour la suite.
:::
