---
titre: Traduire une phrase en Python
resume: Repérer les mots-clés d'une question et les remplacer par la bonne étape pandas ; taux de chômage, taux d'emploi, taux de pauvreté - choisir le bon dénominateur.
partie: Les bases
---

# Une question, des mots-clés

| Dans la question | L'étape pandas | En SAS |
|---|---|---|
| « des », « pour les », « seulement » | `.query("…")` | `WHERE` |
| « pour chaque », « par », « selon » | `.groupby(…, as_index=False)` | `CLASS`, `BY` |
| « combien d'habitants » | `"poids"` et `"sum"` | `WEIGHT` + `SUM` |
| « en moyenne » (population) | somme de `x × poids` / somme des poids | `WEIGHT` + `MEAN` |
| « la part », « le taux » | une division : **qui** au numérateur, **parmi qui** au dénominateur | `PCTN` |
| « les plus », « classer » | `.sort_values(…)`, `.nlargest(…)` | `PROC SORT` |

# Exemple 1 : le taux de chômage

> « **Parmi les actifs** de 15 à 64 ans, **quelle part** est au chômage, **pour chaque** région ? »

Le dénominateur est la population **active** : les personnes en emploi **et** les chômeurs. Les étudiants, retraités et inactifs n'y sont pas.

```python
actifs = personnes.query("age.between(15, 64) and statut in ['en emploi', 'chômeur']").copy()
actifs["chomeur_pond"] = (actifs["statut"] == "chômeur") * actifs["poids"]
t = actifs.groupby("region", as_index=False).agg(chomeurs=("chomeur_pond", "sum"),
                                                 actifs=("poids", "sum"))
t["taux_chomage"] = (t["chomeurs"] / t["actifs"] * 100).round(1)
t
```

**Lecture :** le taux de chômage est de 11,2 % à Bruxelles, 9,8 % en Wallonie et 4,1 % en Flandre.

# Exemple 2 : le taux d'emploi

> « **Parmi les personnes** de 20 à 64 ans, **quelle part** est en emploi ? »

Cette fois, le dénominateur est **toute** la population de cet âge.

```python
pop = personnes.query("age.between(20, 64)").copy()
pop["emploi_pond"] = (pop["statut"] == "en emploi") * pop["poids"]
t = pop.groupby("region", as_index=False).agg(en_emploi=("emploi_pond", "sum"),
                                              population=("poids", "sum"))
t["taux_emploi"] = (t["en_emploi"] / t["population"] * 100).round(1)
t
```

::: piege
Le taux de chômage et le taux d'emploi n'ont **pas le même dénominateur** : un taux de chômage de 10 % ne signifie pas un taux d'emploi de 90 %. Un étudiant ou une personne au foyer ne sont ni en emploi, ni au chômage.
:::

# Exemple 3

> « **Pour chaque** classe d'âge, **combien** d'habitants vivent sous le seuil de pauvreté ? »

```python
tri = personnes.sort_values("revenu_equivalent")
cumul = tri["poids"].cumsum()
seuil = 0.6 * tri.loc[cumul >= tri["poids"].sum() / 2, "revenu_equivalent"].iloc[0]

(personnes
 .query("revenu_equivalent < @seuil")
 .groupby("classe_age", as_index=False)
 .agg(habitants=("poids", "sum"))
 .round(0))
```

::: usage
Dans `query()`, `@seuil` désigne la **variable** Python `seuil` (et non une colonne de la table).
:::

# Exemple 4 : l'ordre des étapes compte

> « **Pour chaque** commune, le nombre de répondants ; **ne garder que** les communes de **plus de** 100 répondants. »

Le filtre porte sur un résultat **calculé** : il vient **après** le regroupement.

```python
(personnes
 .groupby("commune", as_index=False)
 .agg(repondants=("id_personne", "count"), menages=("id_menage", "nunique"))
 .query("repondants > 100")
 .sort_values("repondants", ascending=False))
```

::: note
Une statistique par commune serait très imprécise : même dans les grandes communes, l'échantillon compte quelques centaines de personnes au mieux. Les enquêtes sont conçues pour des résultats nationaux et régionaux ; pour le local, on se tourne vers les **données administratives**.
:::
