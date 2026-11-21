---
titre: Calculer par groupe
resume: groupby() et agg() pour un tableau par secteur, par région ; plusieurs indicateurs ; trier ; garder les groupes intéressants.
partie: Les bases
---

# Un indicateur par groupe : groupby()

Le nombre d'entreprises, l'emploi et le chiffre d'affaires **par région** :

```python
(entreprises
 .groupby("region", as_index=False)
 .agg(entreprises=("num_entreprise", "count"),
      emploi=("emploi", "sum"),
      ca=("ca", "sum")))
```

::: usage
- `groupby("region")` découpe la table en groupes ;
- `agg(nom=("colonne", "fonction"))` calcule un indicateur par groupe et le nomme ;
- `as_index=False` garde la région comme une **colonne** ordinaire (sinon elle devient l'index).

Fonctions courantes : `"count"`, `"sum"`, `"mean"`, `"median"`, `"min"`, `"max"`, `"nunique"`.
:::

::: sas
```
PROC MEANS DATA=entreprises NWAY NOPRINT;
  CLASS region; VAR emploi ca;
  OUTPUT OUT=par_region N(emploi)=entreprises SUM(emploi ca)=emploi ca;
RUN;
```
:::

# Par secteur, trié

```python
par_secteur = (entreprises
               .groupby(["section", "secteur"], as_index=False)
               .agg(entreprises=("num_entreprise", "count"),
                    emploi=("emploi", "sum"),
                    taille_mediane=("emploi", "median"))
               .sort_values("emploi", ascending=False))
par_secteur.head(6)
```

**Lecture :** la finance (K) et l'industrie (C) emploient le plus de salariés avec peu d'entreprises : quelques grandes banques et usines. Les activités spécialisées (M), pourtant les plus nombreuses (1 910 entreprises), n'apparaissent pas dans les six premières : leur taille médiane est nulle (consultants, avocats, comptables indépendants).

# Deux critères : région et secteur

```python
(entreprises
 .groupby(["region", "section"], as_index=False)
 .agg(emploi=("emploi", "sum"))
 .query("section in ['C', 'K', 'N']"))
```

::: usage
Une liste dans `groupby([...])` donne un groupe par **combinaison** : une ligne par région et par section.
:::

# count, size, nunique

```python
(entreprises
 .groupby("region", as_index=False)
 .agg(lignes=("ca", "size"),
      ca_renseigne=("ca", "count"),
      communes=("code_ins", "nunique")))
```

::: piege
`"size"` compte les **lignes** du groupe, `"count"` les valeurs **renseignées** de la colonne. Ici, l'écart entre les deux, ce sont les entreprises exonérées de TVA : il est le plus fort à Bruxelles, où sont les banques et les assurances.
:::

# Filtrer après le regroupement

Les secteurs dont l'emploi dépasse 5 000 salariés : le filtre porte sur un résultat **calculé**, il vient donc **après** `agg()`.

```python
(entreprises
 .groupby("secteur", as_index=False)
 .agg(emploi=("emploi", "sum"))
 .query("emploi > 5000")
 .sort_values("emploi", ascending=False))
```

::: sas
C'est le `HAVING` de PROC SQL : `GROUP BY secteur HAVING SUM(emploi) > 5000`.
:::

# Les employeurs seulement

Le filtre sur les lignes vient **avant** le regroupement : la taille médiane des **employeurs**, par région.

```python
(entreprises
 .query("emploi > 0")
 .groupby("region", as_index=False)
 .agg(employeurs=("num_entreprise", "count"),
      taille_mediane=("emploi", "median"),
      taille_moyenne=("emploi", "mean"))
 .round(1))
```
