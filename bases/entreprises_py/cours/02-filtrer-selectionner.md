---
titre: Filtrer et sélectionner
resume: Garder des lignes avec query(), des colonnes avec [[...]] ; conditions sur du texte, des nombres, des listes, des débuts de code.
partie: Les bases
---

# Garder des lignes : query()

`query()` garde les lignes qui respectent une **condition**, écrite comme une phrase entre guillemets.

```python
entreprises.query("emploi >= 250")
```

**Lecture :** 35 entreprises comptent au moins 250 salariés : ce sont les « grandes entreprises » au sens européen.

::: sas
`WHERE emploi >= 250;`
:::

# Texte : entre guillemets simples

Dans la condition, une valeur de texte s'écrit entre guillemets **simples** (les doubles entourent déjà la condition).

```python
entreprises.query("region == 'Bruxelles'").shape
```

::: usage
Les comparaisons : `==` égal, `!=` différent, `<`, `<=`, `>`, `>=`. Attention : `==` (comparer), pas `=` (ranger un résultat).
:::

# Plusieurs conditions : and, or

```python
entreprises.query("region == 'Bruxelles' and section == 'I'").shape
```

```python
entreprises.query("forme == 'SA' or emploi >= 100").shape
```

::: piege
`and` : les deux conditions à la fois (moins de lignes). `or` : l'une ou l'autre (plus de lignes). « Les entreprises de Bruxelles **et** de Wallonie » se traduit par `or` : aucune entreprise n'est dans les deux régions.
:::

# Une liste de valeurs : in

```python
entreprises.query("section in ['C', 'F']").shape
```

::: usage
`in [...]` remplace une suite de `or`. `not in [...]` exclut une liste.
:::

::: sas
`WHERE section IN ('C', 'F');`
:::

# Le début d'un code : str.startswith()

La classe NACE contient la hiérarchie : `56.10` appartient à la **division** `56` (restauration). Pour garder toute une division :

```python
entreprises.query("nace.str.startswith('56')")[["nace", "commune", "emploi", "ca"]].head()
```

::: usage
`colonne.str.startswith('56')` teste le début d'un texte ; `str.contains('...')` cherche un morceau n'importe où. Ces fonctions ne marchent que sur une colonne de texte : c'est une raison de plus de garder les codes en texte.
:::

::: sas
`WHERE nace LIKE '56%';` ou `WHERE substr(nace, 1, 2) = '56';`
:::

# Les valeurs manquantes : isna()

Les entreprises exonérées de TVA n'ont pas de chiffre d'affaires. Pour les retrouver :

```python
(entreprises
 .query("ca.isna()")
 ["secteur"]
 .value_counts())
```

::: usage
`ca.isna()` est vrai quand la valeur manque ; `ca.notna()` quand elle est renseignée.
:::

::: sas
`WHERE ca = .;` (en SAS, `ca < 0` serait **vrai** pour une valeur manquante ; en pandas, toute comparaison avec une valeur manquante est fausse).
:::

# Garder des colonnes : [[...]]

```python
entreprises[["num_entreprise", "nace", "emploi", "ca"]].head(3)
```

::: usage
Des **doubles crochets** : une liste de noms de colonnes. Un seul nom entre simples crochets donne une colonne isolée (une *Series*), deux crochets donnent une table.
:::

::: sas
`KEEP num_entreprise nace emploi ca;`
:::

# Filtrer puis sélectionner

```python
(entreprises
 .query("section == 'J' and emploi >= 20")
 [["nace", "commune", "emploi", "ca"]])
```

::: note
**Lire une ligne de code** : « je prends les entreprises, **puis** je garde l'information-communication de 20 salariés ou plus, **puis** je garde quatre colonnes ».
:::
