---
titre: Interroger ses tables en SQL avec DuckDB
resume: Écrire en SQL, comme avec PROC SQL, sur des tables pandas ou directement sur des fichiers ; passer de SQL à pandas et inversement.
partie: Vos propres fichiers
---

# Pourquoi DuckDB ?

Beaucoup d'utilisateurs de SAS connaissent **PROC SQL**. **DuckDB** permet d'écrire les mêmes requêtes en Python, sur une table pandas ou directement sur un fichier (CSV, Parquet), et de récupérer le résultat sous forme de table pandas.

```python
import duckdb

duckdb.sql("SELECT region, COUNT(*) AS communes, SUM(total) AS population FROM communes GROUP BY region").df()
```

::: usage
- `duckdb.sql("requête")` exécute la requête ; dans le `FROM`, le nom d'une table pandas (`communes`) suffit ;
- `.df()` transforme le résultat en table pandas, pour continuer avec les verbes du cours.
- `SUM()` renvoie ici un nombre décimal (`1255834.0`) : DuckDB calcule la somme sur un très grand entier, que pandas convertit. Pour garder un entier : `CAST(SUM(total) AS BIGINT)`.
:::

::: sas
```
PROC SQL;
  SELECT region, COUNT(*) AS communes, SUM(total) AS population
  FROM communes GROUP BY region;
QUIT;
```
:::

# Une requête sur plusieurs lignes

Entre trois guillemets, une requête s'écrit sur plusieurs lignes, comme dans PROC SQL.

```python
duckdb.sql("""
    SELECT commune, province, total
    FROM communes
    WHERE region = 'Wallonie' AND total > 50000
    ORDER BY total DESC
""").df()
```

# Les mêmes questions, en pandas et en SQL

| Question | pandas | SQL |
|---|---|---|
| garder des lignes | `.query("total > 50000")` | `WHERE total > 50000` |
| garder des colonnes | `[["commune", "total"]]` | `SELECT commune, total` |
| par groupe | `.groupby("province").agg(...)` | `GROUP BY province` |
| filtrer un résultat calculé | `.query(...)` après `agg` | `HAVING` |
| trier | `.sort_values("total", ascending=False)` | `ORDER BY total DESC` |
| fusionner | `.merge(t2, on="code_ins", how="left")` | `LEFT JOIN t2 USING (code_ins)` |

# GROUP BY et HAVING

Les arrondissements de plus de 500 000 habitants :

```python
duckdb.sql("""
    SELECT arrondissement, SUM(total) AS population
    FROM communes
    GROUP BY arrondissement
    HAVING SUM(total) > 500000
    ORDER BY population DESC
""").df()
```

# Une jointure

La population par sexe et par région, en joignant `pop_sexe` à `communes` sur le code INS :

```python
duckdb.sql("""
    SELECT c.region, p.sexe, SUM(p.population) AS population
    FROM pop_sexe AS p
    LEFT JOIN communes AS c USING (code_ins)
    GROUP BY c.region, p.sexe
    ORDER BY c.region, p.sexe
""").df()
```

# Interroger un fichier directement

DuckDB lit un fichier **sans le charger d'abord** : son nom, entre guillemets simples, remplace la table dans le `FROM`. Pratique pour un gros fichier dont on ne veut qu'une partie.

```python
duckdb.sql("""
    SELECT province, COUNT(*) AS communes
    FROM 'donnees/communes_2026.parquet'
    GROUP BY province
    ORDER BY communes DESC
""").df()
```

Un CSV se lit de la même façon, avec ses réglages :

```python
duckdb.sql("""
    SELECT *
    FROM read_csv('donnees/communes_2026.csv', delim = ';')
    LIMIT 3
""").df()
```

# SQL puis pandas

On peut mélanger : la requête prépare la table, pandas continue (graphique, export…).

```python
par_province = duckdb.sql("""
    SELECT province, SUM(femmes) * 100.0 / SUM(total) AS part_femmes
    FROM communes GROUP BY province
""").df()

par_province.sort_values("part_femmes", ascending=False).round(2).head(3)
```

# DuckDB est-il plus rapide ?

Sur votre poste, avec de grosses tables (des millions de lignes), DuckDB est en général **bien plus rapide** que pandas : il utilise tous les cœurs du processeur et ne lit que les colonnes utiles d'un fichier Parquet. Votre formateur vous le montrera.

**Dans l'atelier, ce n'est pas le cas** : Python tourne dans votre navigateur, sur un seul cœur. Mesurons sur 2 millions de lignes générées au hasard :

```python
import time

rng = np.random.default_rng(1)
n = 2_000_000
grande = pd.DataFrame({"commune": rng.integers(0, 565, n),
                       "sexe": rng.choice(["H", "F"], n),
                       "valeur": rng.random(n)})

debut = time.time()
a = grande.groupby(["commune", "sexe"])["valeur"].sum()
t_pandas = time.time() - debut

debut = time.time()
b = duckdb.sql("SELECT commune, sexe, SUM(valeur) FROM grande GROUP BY ALL").df()
t_duckdb = time.time() - debut

print(f"pandas : {t_pandas:.2f} s   DuckDB : {t_duckdb:.2f} s")
```

**Lecture :** ici, DuckDB n'est pas plus rapide, souvent plus lent. Une mesure de vitesse dépend de la machine : retenez de DuckDB ce qu'il apporte partout (le SQL, la lecture directe des fichiers), et mesurez sa vitesse là où vous travaillerez.
