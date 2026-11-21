---
titre: Calculer par groupe
resume: groupby() et agg() ; compter des habitants par groupe avec les poids ; des moyennes et des taux pondérés par région, âge, type de ménage.
partie: Les bases
---

# La population par groupe : la somme des poids

```python
(personnes
 .groupby("region", as_index=False)
 .agg(repondants=("id_personne", "count"),
      population=("poids", "sum")))
```

::: usage
- `groupby("region")` découpe la table en groupes ;
- `agg(nom=("colonne", "fonction"))` calcule un indicateur par groupe et le nomme ;
- `as_index=False` garde la région comme une colonne ordinaire.
:::

::: sas
`PROC MEANS DATA=personnes NWAY SUM; CLASS region; VAR poids; RUN;`
:::

# Une moyenne pondérée par groupe

`agg()` ne connaît pas les poids. L'astuce : créer d'abord la colonne **revenu × poids**, additionner par groupe, puis diviser par la somme des poids.

```python
personnes["revenu_x_poids"] = personnes["revenu_equivalent"] * personnes["poids"]
par_region = (personnes
              .groupby("region", as_index=False)
              .agg(revenu_x_poids=("revenu_x_poids", "sum"),
                   population=("poids", "sum")))
par_region["revenu_moyen"] = (par_region["revenu_x_poids"] / par_region["population"]).round(0)
par_region[["region", "population", "revenu_moyen"]]
```

::: sas
`PROC MEANS DATA=personnes MEAN; CLASS region; VAR revenu_equivalent; WEIGHT poids; RUN;`
:::

# Un taux pondéré : la même astuce

Une proportion est une moyenne d'une variable qui vaut 1 (oui) ou 0 (non). Le **taux de risque de pauvreté** est donc une moyenne pondérée de « pauvre ou non ». On reprend le seuil de la leçon précédente :

```python
tri = personnes.sort_values("revenu_equivalent")
cumul = tri["poids"].cumsum()
seuil = 0.6 * tri.loc[cumul >= tri["poids"].sum() / 2, "revenu_equivalent"].iloc[0]

personnes["pauvre"] = personnes["revenu_equivalent"] < seuil
personnes["pauvre_x_poids"] = personnes["pauvre"] * personnes["poids"]
taux = (personnes
        .groupby("region", as_index=False)
        .agg(pauvres=("pauvre_x_poids", "sum"), population=("poids", "sum")))
taux["taux_pauvrete"] = (taux["pauvres"] / taux["population"] * 100).round(1)
taux
```

**Lecture :** le risque de pauvreté atteint 22,7 % à Bruxelles, 17,0 % en Wallonie et 10,9 % en Flandre.

::: note
`personnes["pauvre"] * personnes["poids"]` : `True` vaut 1 et `False` vaut 0 dans un calcul.
:::

# Sans les poids, un autre chiffre

```python
print(round(personnes["pauvre"].mean() * 100, 1))                         # échantillon
print(round(personnes["pauvre_x_poids"].sum() / personnes["poids"].sum() * 100, 1))   # population
```

**Lecture :** 16,3 % sans les poids, 14,0 % avec. L'écart vient du suréchantillonnage de Bruxelles, où la pauvreté est plus fréquente : sans les poids, on surestimerait la pauvreté en Belgique.

# Par classe d'âge et par type de ménage

```python
(personnes
 .groupby("type_menage", as_index=False)
 .agg(pauvres=("pauvre_x_poids", "sum"), population=("poids", "sum"))
 .assign(taux=lambda t: (t["pauvres"] / t["population"] * 100).round(1))
 .sort_values("taux", ascending=False))
```

**Lecture :** plus d'une personne sur trois vivant dans une famille monoparentale est sous le seuil, une sur quatre parmi les isolés, contre une sur dix environ dans les couples avec enfants, et moins encore dans les couples sans enfant.

::: usage
`.assign(taux=lambda t: …)` crée une colonne au milieu d'une chaîne, à partir de la table du moment (`t`).
:::

# Filtrer avant ou après le regroupement

Le revenu équivalent médian **des chômeurs**, par région : le filtre porte sur les personnes, il vient **avant**.

```python
(personnes
 .query("statut == 'chômeur'")
 .groupby("region", as_index=False)
 .agg(repondants=("id_personne", "count"),
      revenu_median=("revenu_equivalent", "median")))
```

::: piege
Cette médiane est **non pondérée**. Avec 130 à 200 répondants par région, elle est aussi **imprécise** : une autre enquête donnerait un chiffre un peu différent. Plus le groupe est petit, plus la marge d'erreur est grande.
:::
