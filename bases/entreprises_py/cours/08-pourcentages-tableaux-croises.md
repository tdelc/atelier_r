---
titre: Les pourcentages d'un tableau croisé
resume: pd.crosstab() ; pourcentages en ligne, en colonne, du total ; compter les entreprises ou additionner l'emploi.
partie: Les bases
---

# Un tableau croisé : pd.crosstab()

Le nombre d'entreprises par région et par classe de taille. On recrée la classe de taille :

```python
entreprises["taille"] = pd.cut(entreprises["emploi"],
                               bins=[-1, 0, 9, 49, 249, 100000],
                               labels=["0 salarié", "1-9", "10-49", "50-249", "250 et +"])
pd.crosstab(entreprises["region"], entreprises["taille"], margins=True, margins_name="Total")
```

::: sas
`PROC FREQ DATA=entreprises; TABLES region*taille; RUN;`
:::

# Pourcentages en ligne : normalize="index"

**Parmi les entreprises de chaque région**, quelle part dans chaque classe de taille ?

```python
(pd.crosstab(entreprises["region"], entreprises["taille"], normalize="index") * 100).round(1)
```

**Lecture :** dans les trois régions, environ six entreprises sur dix n'ont aucun salarié. Chaque **ligne** fait 100 %.

# Pourcentages en colonne : normalize="columns"

**Parmi les entreprises de chaque taille**, quelle part dans chaque région ?

```python
(pd.crosstab(entreprises["region"], entreprises["taille"], normalize="columns") * 100).round(1)
```

**Lecture :** chaque **colonne** fait 100 %. Bruxelles abrite 26 % des grandes entreprises, mais seulement 13 % des entreprises sans salarié : les sièges sociaux.

::: piege
« 60 % des entreprises bruxelloises n'ont pas de salarié » et « 13 % des entreprises sans salarié sont bruxelloises » ne disent pas la même chose. Écrivez d'abord la phrase, cherchez le « **parmi** » : il désigne le dénominateur.
:::

# Compter des entreprises ou additionner l'emploi ?

Même tableau, mais en **emploi** : quelle part des salariés de chaque région travaille dans chaque classe de taille ?

```python
(pd.crosstab(entreprises["region"], entreprises["taille"],
             values=entreprises["emploi"], aggfunc="sum", normalize="index") * 100).round(1)
```

**Lecture :** les grandes entreprises sont rares (moins de 1 % des entreprises) mais pèsent une grande part de l'emploi, surtout à Bruxelles. C'est le cœur de toute statistique d'entreprises : **compter les unités** ou **peser l'activité** donne deux images opposées.

::: usage
`values=` et `aggfunc=` remplacent le comptage par une somme (ou une moyenne) d'une autre colonne.
:::

# La part du total : normalize="all"

```python
(pd.crosstab(entreprises["section"], entreprises["region"],
             values=entreprises["ca"], aggfunc="sum", normalize="all") * 100).round(1).head(6)
```

Chaque case est une part du **chiffre d'affaires total** de la table : toutes les cases ensemble font 100 %.

# Le même calcul avec groupby

La part de chaque section dans l'emploi de sa région, en format long :

```python
t = entreprises.groupby(["region", "section"], as_index=False).agg(emploi=("emploi", "sum"))
t["part"] = (t["emploi"] / t.groupby("region")["emploi"].transform("sum") * 100).round(1)
t.query("region == 'Bruxelles'").nlargest(3, "part")
```

::: note
`crosstab` est plus court pour un tableau à afficher ; la méthode `groupby` + `transform` garde une table **longue**, plus facile à filtrer, représenter ou exporter.
:::
