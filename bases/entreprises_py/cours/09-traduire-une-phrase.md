---
titre: Traduire une phrase en Python
resume: Repérer les mots-clés d'une question et les remplacer par la bonne étape pandas.
partie: Les bases
---

# Une question, des mots-clés

Une question bien posée contient déjà le code. Il suffit d'en repérer les mots-clés et de les remplacer, dans l'ordre, par les étapes pandas.

| Dans la question | L'étape pandas | En SAS |
|---|---|---|
| « des », « pour les », « seulement » | `.query("…")` | `WHERE` |
| « pour chaque », « par », « selon » | `.groupby(…, as_index=False)` | `CLASS`, `BY`, `GROUP BY` |
| « combien » | `.size()`, `len()`, `"count"` | `N`, `PROC FREQ` |
| « en moyenne », « au total » | `.agg(x=("col", "mean"))`, `"sum"` | `MEAN`, `SUM` |
| « la part », « le pourcentage » | une division, ou `normalize=` | `PCTN`, `PCTSUM` |
| « les plus », « classer » | `.sort_values(…)`, `.nlargest(…)` | `PROC SORT` |
| « afficher seulement » | `[["col1", "col2"]]` | `KEEP` |

# Exemple 1

> « **Combien** d'entreprises comptent **au moins** 10 salariés, **pour chaque** région ? »

```python
(entreprises
 .query("emploi >= 10")
 .groupby("region", as_index=False)
 .size())
```

# Exemple 2

> « **Parmi** les entreprises de construction (F) wallonnes, **quelles sont les 3** plus grandes par chiffre d'affaires ? »

```python
(entreprises
 .query("section == 'F' and region == 'Wallonie'")
 .nlargest(3, "ca")
 [["nace", "commune", "emploi", "ca"]])
```

# Exemple 3

> « **Pour chaque** section, **quel est** le chiffre d'affaires **médian** des employeurs, **classé** du plus grand au plus petit ? »

```python
(entreprises
 .query("emploi > 0")
 .groupby("secteur", as_index=False)
 .agg(ca_median=("ca", "median"))
 .sort_values("ca_median", ascending=False)
 .head(5))
```

# Exemple 4

> « **Quelle part** de l'emploi salarié se trouve dans des entreprises de **moins de** 50 salariés ? »

Numérateur et dénominateur sont deux sommes : on les calcule l'une après l'autre.

```python
pme = entreprises.query("emploi < 50")["emploi"].sum()
total = entreprises["emploi"].sum()
round(pme / total * 100, 1)
```

**Lecture :** 45,4 % des salariés travaillent dans une entreprise de moins de 50 salariés, qui représentent pourtant 98,4 % des entreprises.

# Exemple 5 : l'ordre des étapes compte

> « **Pour chaque** commune, l'emploi total ; **ne garder que** les communes de **plus de** 2 000 salariés. »

Ici, le filtre porte sur un résultat **calculé** : il vient **après** le regroupement.

```python
(entreprises
 .groupby("commune", as_index=False)
 .agg(emploi=("emploi", "sum"), entreprises=("num_entreprise", "count"))
 .query("emploi > 2000")
 .sort_values("emploi", ascending=False))
```

::: note
**Méthode** : écrivez d'abord la question en français, soulignez les mots-clés, puis écrivez une étape par ligne. Exécutez après chaque étape ajoutée : vous voyez le résultat se construire, et une erreur est tout de suite localisée.
:::
