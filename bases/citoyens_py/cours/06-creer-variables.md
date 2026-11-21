---
titre: Créer des variables
resume: Une nouvelle colonne par calcul ; être sous le seuil de pauvreté ; des classes de revenu avec np.select() ; l'intensité de travail du ménage avec transform().
partie: Les bases
---

# Une colonne calculée

Le revenu équivalent **mensuel**, et l'écart au seuil de pauvreté :

```python
tri = personnes.sort_values("revenu_equivalent")
cumul = tri["poids"].cumsum()
mediane = tri.loc[cumul >= tri["poids"].sum() / 2, "revenu_equivalent"].iloc[0]
seuil = 0.6 * mediane

personnes["revenu_mensuel"] = (personnes["revenu_equivalent"] / 12).round(0)
personnes["ecart_seuil"] = personnes["revenu_equivalent"] - seuil
personnes[["age", "revenu_equivalent", "revenu_mensuel", "ecart_seuil"]].head(3)
```

::: usage
`table["nouvelle"] = calcul` crée (ou remplace) une colonne. Le calcul s'applique à **toutes les lignes à la fois** : pas de boucle. On peut y utiliser une valeur unique, comme `seuil`.
:::

::: sas
`DATA personnes; SET personnes; revenu_mensuel = round(revenu_equivalent / 12); RUN;`
:::

# Une condition : vrai ou faux

```python
personnes["pauvre"] = personnes["revenu_equivalent"] < seuil
personnes["pauvre"].value_counts()
```

::: usage
Une comparaison crée une colonne de **booléens** (`True` / `False`). Elle se filtre directement (`query("pauvre")`) et se compte avec `.sum()` : `True` vaut 1.
:::

# Une condition à deux valeurs : np.where()

```python
personnes["age_actif"] = np.where(personnes["age"].between(15, 64), "15-64 ans", "autre")
personnes["age_actif"].value_counts()
```

::: usage
`np.where(condition, valeur_si_vrai, valeur_si_faux)` : l'équivalent d'un `IF … THEN … ELSE` sur toute la colonne.
:::

# Des classes de revenu : np.select()

On situe chaque personne par rapport à la **médiane** : sous le seuil de pauvreté (moins de 60 %), revenus modestes (60 à 100 %), aisés (100 à 200 %), très aisés (plus de 200 %).

```python
r = personnes["revenu_equivalent"] / mediane
personnes["classe_revenu"] = np.select(
    [r < 0.6, r < 1, r < 2],
    ["sous le seuil", "modeste", "aisé"],
    default="très aisé")
personnes["classe_revenu"].value_counts()
```

::: note
Les conditions sont testées **dans l'ordre** : la première vraie l'emporte, comme `IF … ELSE IF …` en SAS. `r < 1` ne concerne donc que les personnes qui ne sont pas déjà « sous le seuil ».
:::

# Des classes d'âge à votre façon : pd.cut()

```python
personnes["age_10"] = pd.cut(personnes["age"], bins=[-1, 14, 24, 34, 44, 54, 64, 74, 120],
                             labels=["0-14", "15-24", "25-34", "35-44", "45-54",
                                     "55-64", "65-74", "75+"])
personnes["age_10"].value_counts().sort_index()
```

::: usage
`bins` donne les **bornes**, `labels` les noms des classes (un de moins que les bornes). Chaque classe contient sa borne de droite : `(14, 24]` va de 15 à 24 ans.
:::

# Une information du ménage sur chaque personne : transform()

La **pauvreté des enfants** dépend du travail de leurs parents. On calcule, pour chaque ménage, le nombre d'adultes de 18 à 59 ans (hors étudiants) et combien d'entre eux travaillent :

```python
adulte = personnes["age"].between(18, 59) & (personnes["statut"] != "étudiant")
personnes["adulte"] = adulte
personnes["adulte_en_emploi"] = adulte & (personnes["statut"] == "en emploi")

par_menage = personnes.groupby("id_menage")
personnes["nb_adultes"] = par_menage["adulte"].transform("sum")
personnes["nb_en_emploi"] = par_menage["adulte_en_emploi"].transform("sum")
personnes[["id_menage", "age", "statut", "nb_adultes", "nb_en_emploi"]].head(6)
```

::: usage
`transform("sum")` calcule la somme **par ménage** mais la recopie sur **chaque personne** du ménage : la table garde ses 13 683 lignes.
:::

::: sas
Un `PROC MEANS` par ménage, puis un `MERGE` sur `id_menage` ; ou un `PROC SQL` avec `GROUP BY id_menage` et une sous-requête.
:::

# L'intensité de travail du ménage

```python
personnes["intensite"] = np.select(
    [personnes["nb_adultes"] == 0,
     personnes["nb_en_emploi"] == 0,
     personnes["nb_en_emploi"] < personnes["nb_adultes"]],
    ["sans adulte d'âge actif", "personne ne travaille", "une partie travaille"],
    default="tous travaillent")

enfants = personnes.query("age < 18")
(enfants.groupby("intensite")["poids"].sum() / enfants["poids"].sum() * 100).round(1)
```

**Lecture :** près de 7 % des enfants vivent dans un ménage où **aucun** adulte ne travaille. C'est peu, mais l'étude de cas montrera que c'est là que la pauvreté des enfants se concentre.
