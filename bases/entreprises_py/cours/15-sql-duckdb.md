---
titre: Interroger ses tables en SQL avec DuckDB
resume: Écrire en SQL, comme avec PROC SQL, sur des tables pandas ou directement sur des fichiers ; jointures, HAVING ; passer de SQL à pandas.
partie: Vos propres fichiers
---

# Pourquoi DuckDB ?

Beaucoup d'utilisateurs de SAS connaissent **PROC SQL**. **DuckDB** permet d'écrire les mêmes requêtes en Python, sur une table pandas ou directement sur un fichier (CSV, Parquet), et de récupérer le résultat sous forme de table pandas.

```python
import duckdb

duckdb.sql("""
    SELECT region, COUNT(*) AS entreprises, SUM(emploi) AS emploi
    FROM entreprises
    GROUP BY region
    ORDER BY emploi DESC
""").df()
```

::: usage
- `duckdb.sql("requête")` exécute la requête ; dans le `FROM`, le nom d'une table pandas (`entreprises`) suffit ;
- `.df()` transforme le résultat en table pandas ;
- entre trois guillemets, une requête s'écrit sur plusieurs lignes.
:::

::: sas
```
PROC SQL;
  SELECT region, COUNT(*) AS entreprises, SUM(emploi) AS emploi
  FROM entreprises GROUP BY region ORDER BY emploi DESC;
QUIT;
```
:::

# Les mêmes questions, en pandas et en SQL

| Question | pandas | SQL |
|---|---|---|
| garder des lignes | `.query("emploi >= 50")` | `WHERE emploi >= 50` |
| garder des colonnes | `[["nace", "ca"]]` | `SELECT nace, ca` |
| par groupe | `.groupby("section").agg(...)` | `GROUP BY section` |
| filtrer un résultat calculé | `.query(...)` après `agg` | `HAVING` |
| trier | `.sort_values("ca", ascending=False)` | `ORDER BY ca DESC` |
| fusionner | `.merge(t2, on="num_entreprise", how="left")` | `LEFT JOIN t2 USING (num_entreprise)` |

# CASE WHEN : des classes en SQL

Les classes de taille, calculées dans la requête :

```python
duckdb.sql("""
    SELECT CASE WHEN emploi = 0 THEN '0'
                WHEN emploi < 10 THEN '1-9'
                WHEN emploi < 50 THEN '10-49'
                WHEN emploi < 250 THEN '50-249'
                ELSE '250 et +' END AS taille,
           COUNT(*) AS entreprises,
           SUM(emploi) AS emploi
    FROM entreprises
    GROUP BY taille
    ORDER BY MIN(emploi)
""").df()
```

::: note
`CASE WHEN` est l'équivalent SQL de `np.select()` (leçon « Créer des variables »).
:::

# GROUP BY et HAVING

Les classes NACE qui comptent au moins 1 000 salariés :

```python
duckdb.sql("""
    SELECT nace, COUNT(*) AS entreprises, SUM(emploi) AS emploi
    FROM entreprises
    GROUP BY nace
    HAVING SUM(emploi) >= 1000
    ORDER BY emploi DESC
""").df()
```

# Lire un fichier directement

DuckDB lit un fichier **sans le charger d'abord** : son nom, entre guillemets simples, remplace la table dans le `FROM`.

```python
duckdb.sql("""
    SELECT nace_onss, SUM(postes) AS postes, ROUND(SUM(etp), 1) AS etp
    FROM read_csv('donnees/onss_emploi_2025.csv', delim = ';', decimal_separator = ',',
                  types = {'num_entreprise': 'VARCHAR', 'nace_onss': 'VARCHAR'})
    GROUP BY nace_onss
    ORDER BY postes DESC
    LIMIT 5
""").df()
```

::: usage
`read_csv(...)` prend les mêmes réglages qu'en pandas, sous d'autres noms : `delim`, `decimal_separator`, `types`. Un fichier Parquet se lit encore plus simplement : `FROM 'donnees/entreprises_2025.parquet'`.
:::

# Une jointure : la NACE selon deux sources

Combien d'employeurs ont la même section NACE à la BCE et à l'ONSS, par section BCE ?

```python
onss = pd.read_csv("donnees/onss_emploi_2025.csv", sep=";", decimal=",",
                   dtype={"num_entreprise": str, "nace_onss": str})

duckdb.sql("""
    SELECT e.section,
           COUNT(*) AS employeurs,
           SUM(CASE WHEN e.nace = o.nace_onss THEN 1 ELSE 0 END) AS meme_classe,
           ROUND(100.0 * SUM(CASE WHEN e.nace = o.nace_onss THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct
    FROM entreprises AS e
    INNER JOIN onss AS o USING (num_entreprise)
    GROUP BY e.section
    ORDER BY pct
    LIMIT 6
""").df()
```

**Lecture :** les plus faibles concordances concernent les sections où des classes voisines se confondent facilement : programmation et conseil informatique (J, 78 %), gros œuvre et installation (F), location immobilière et construction (L), restaurants et cafés (I).

# SQL puis pandas

On peut mélanger : la requête prépare la table, pandas continue (graphique, export…).

```python
par_province = duckdb.sql("""
    SELECT province, SUM(ca) / 1000 AS ca_meur, SUM(emploi) AS emploi
    FROM entreprises
    WHERE ca IS NOT NULL
    GROUP BY province
""").df()

par_province["ca_par_emploi"] = (par_province["ca_meur"] * 1000 / par_province["emploi"]).round(0)
par_province.sort_values("ca_meur", ascending=False).head(4)
```

::: piege
`WHERE ca IS NOT NULL` : en SQL comme en pandas, les valeurs manquantes demandent une attention explicite. Ici, l'emploi des entreprises exonérées (banques, hôpitaux) est exclu, sinon le ratio mélangerait un chiffre d'affaires partiel et un emploi complet.
:::

# DuckDB est-il plus rapide ?

Sur votre poste, avec de grosses tables (des millions de lignes), DuckDB est en général **bien plus rapide** que pandas. **Dans l'atelier, ce n'est pas le cas** : Python tourne dans votre navigateur, sur un seul cœur. Retenez de DuckDB ce qu'il apporte partout (le SQL, la lecture directe des fichiers), et mesurez sa vitesse là où vous travaillerez.
