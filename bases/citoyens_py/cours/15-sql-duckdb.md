---
titre: Interroger ses tables en SQL avec DuckDB
resume: Écrire en SQL, comme avec PROC SQL ; des taux pondérés avec SUM(poids) ; des jointures avec les fichiers administratifs ; lire un fichier directement.
partie: Vos propres fichiers
---

# Pourquoi DuckDB ?

Beaucoup d'utilisateurs de SAS connaissent **PROC SQL**. **DuckDB** permet d'écrire les mêmes requêtes en Python, sur une table pandas ou directement sur un fichier, et de récupérer le résultat sous forme de table pandas.

```python
import duckdb

duckdb.sql("""
    SELECT region,
           COUNT(*)            AS repondants,
           ROUND(SUM(poids))   AS population
    FROM personnes
    GROUP BY region
    ORDER BY population DESC
""").df()
```

::: usage
- `duckdb.sql("requête")` exécute la requête ; dans le `FROM`, le nom d'une table pandas (`personnes`) suffit ;
- `.df()` transforme le résultat en table pandas ;
- entre trois guillemets, une requête s'écrit sur plusieurs lignes.
:::

::: sas
`PROC SQL; SELECT region, COUNT(*) AS repondants, SUM(poids) AS population FROM personnes GROUP BY region; QUIT;`
:::

# Une moyenne et un taux pondérés en SQL

En SQL, la moyenne pondérée s'écrit directement : `SUM(x * poids) / SUM(poids)`.

```python
duckdb.sql("""
    SELECT classe_age,
           ROUND(SUM(revenu_equivalent * poids) / SUM(poids)) AS revenu_moyen,
           ROUND(100 * SUM(CASE WHEN revenu_equivalent < 16840.2 THEN poids ELSE 0 END)
                 / SUM(poids), 1) AS taux_pauvrete
    FROM personnes
    GROUP BY classe_age
    ORDER BY classe_age
""").df()
```

::: usage
`CASE WHEN condition THEN valeur ELSE autre END` : l'équivalent SQL de `np.where()`. Ici, il ne garde le poids que des personnes sous le seuil.
:::

::: note
Le seuil (16 840,2 euros) est écrit en dur pour simplifier. Dans un vrai traitement, on le calcule (leçon « Explorer une variable ») et on l'insère dans la requête : `f"... < {seuil} ..."`.
:::

# Le taux de chômage, en SQL

```python
duckdb.sql("""
    SELECT region,
           ROUND(100 * SUM(CASE WHEN statut = 'chômeur' THEN poids ELSE 0 END) / SUM(poids), 1)
               AS taux_chomage
    FROM personnes
    WHERE age BETWEEN 15 AND 64
      AND statut IN ('en emploi', 'chômeur')
    GROUP BY region
    ORDER BY taux_chomage DESC
""").df()
```

::: piege
Le `WHERE` définit le **dénominateur** : les actifs de 15 à 64 ans. L'oublier donnerait la part des chômeurs dans toute la population, un tout autre indicateur.
:::

# Une jointure avec l'ONEM

```python
onem = pd.read_excel("donnees/onem_allocations_2025.xlsx", header=2, dtype={"id_pseudo": str})

duckdb.sql("""
    SELECT p.statut,
           COALESCE(o.type_allocation, 'aucune') AS allocation,
           COUNT(*) AS repondants
    FROM personnes AS p
    LEFT JOIN onem AS o USING (id_pseudo)
    WHERE p.age BETWEEN 15 AND 64
    GROUP BY ALL
    ORDER BY p.statut, repondants DESC
""").df()
```

::: usage
- `LEFT JOIN … USING (id_pseudo)` : la jointure `how="left"` de pandas ;
- `COALESCE(x, 'aucune')` remplace une valeur manquante, comme `fillna("aucune")` ;
- `GROUP BY ALL` regroupe sur toutes les colonnes qui ne sont pas des calculs.
:::

# Lire un fichier directement

DuckDB lit un fichier **sans le charger d'abord** dans pandas :

```python
duckdb.sql("""
    SELECT type_allocation, COUNT(*) AS beneficiaires, ROUND(AVG(mois_indemnises), 1) AS mois_moyens
    FROM read_csv('donnees/registre_national_2026.csv', delim = ';',
                  types = {'id_pseudo': 'VARCHAR', 'code_ins': 'VARCHAR'}) AS r
    INNER JOIN onem AS o USING (id_pseudo)
    GROUP BY type_allocation
""").df()
```

::: note
La même prudence qu'en pandas : `types = {...}` lit les clés en texte.
:::

# SQL puis pandas

On peut mélanger : la requête prépare la table, pandas continue (graphique, export…).

```python
par_type = duckdb.sql("""
    SELECT type_menage,
           SUM(CASE WHEN revenu_equivalent < 16840.2 THEN poids ELSE 0 END) AS pauvres,
           SUM(poids) AS population
    FROM personnes
    GROUP BY type_menage
""").df()
par_type["taux"] = (par_type["pauvres"] / par_type["population"] * 100).round(1)
par_type.sort_values("taux", ascending=False)
```

# DuckDB est-il plus rapide ?

Sur votre poste, avec de grosses tables (des millions de lignes, comme un fichier administratif complet), DuckDB est en général **bien plus rapide** que pandas. **Dans l'atelier, ce n'est pas le cas** : Python tourne dans votre navigateur, sur un seul cœur. Retenez de DuckDB ce qu'il apporte partout (le SQL, la lecture directe des fichiers), et mesurez sa vitesse là où vous travaillerez.
