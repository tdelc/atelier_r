---
titre: Traduire une phrase en Python
resume: Repérer les mots-clés d'une question et les remplacer par la bonne étape pandas.
partie: Les bases
---

# Une question, des mots-clés

Une question bien posée contient déjà le code. Il suffit de repérer ses mots-clés et de les remplacer, dans l'ordre, par les étapes pandas.

| Dans la question | L'étape pandas | En SAS |
|---|---|---|
| « parmi », « pour les », « seulement » | `.query("…")` | `WHERE` |
| « pour chaque », « par », « selon » | `.groupby(…, as_index=False)` | `CLASS`, `BY`, `GROUP BY` |
| « combien » | `.size()`, `len()`, `"count"` | `N`, `PROC FREQ` |
| « en moyenne », « au total » | `.agg(x=("col", "mean"))`, `"sum"` | `MEAN`, `SUM` |
| « la part », « le pourcentage » | une division, ou `normalize=` | `PCTN`, `PCTSUM` |
| « les plus », « classer » | `.sort_values(…)`, `.nlargest(…)` | `PROC SORT` |
| « montrer seulement » | `[["col1", "col2"]]` | `KEEP` |

# Exemple 1

> « **Pour chaque** région, **combien** de communes comptent **plus de** 30 000 habitants ? »

1. « plus de 30 000 habitants » : un filtre ;
2. « pour chaque région » : un regroupement ;
3. « combien » : un comptage.

```python
(communes
 .query("total > 30000")
 .groupby("region", as_index=False)
 .size())
```

# Exemple 2

> « **Parmi** les communes de la province de Liège, **quelles sont les 3 plus** peuplées ? »

```python
(communes
 .query("province == 'Liège'")
 .nlargest(3, "total")
 [["commune", "total"]])
```

# Exemple 3

> « **Pour chaque** province, **quelle est** la population **moyenne** d'une commune, **classée** de la plus grande à la plus petite ? »

```python
(communes
 .groupby("province", as_index=False)
 .agg(taille_moyenne=("total", "mean"))
 .round(0)
 .sort_values("taille_moyenne", ascending=False))
```

# Exemple 4

> « **Quelle part** de la population belge vit **dans** une commune de **moins de** 10 000 habitants ? »

Le numérateur et le dénominateur sont deux sommes : on les calcule l'une après l'autre.

```python
petites = communes.query("total < 10000")["total"].sum()
belgique = communes["total"].sum()
round(petites / belgique * 100, 1)
```

**Lecture :** 10,4 % des Belges vivent dans une commune de moins de 10 000 habitants, alors que ces communes représentent plus d'un tiers des communes (203 sur 565).

# Exemple 5 : l'ordre des étapes compte

> « **Pour chaque** arrondissement, la population totale ; **ne garder que** les arrondissements de **plus de** 400 000 habitants. »

Ici, le filtre porte sur un résultat **calculé** : il vient **après** le regroupement.

```python
(communes
 .groupby("arrondissement", as_index=False)
 .agg(population=("total", "sum"))
 .query("population > 400000")
 .sort_values("population", ascending=False))
```

::: note
**Méthode** : écrivez d'abord la question en français, soulignez les mots-clés, puis écrivez une étape par ligne. Exécutez après chaque étape ajoutée : vous voyez le résultat se construire, et une erreur est tout de suite localisée.
:::
