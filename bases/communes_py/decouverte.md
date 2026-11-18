---
base: communes_py
---

# Regarder la table sous tous les angles
La table `communes` est déjà chargée. Changez le nombre de lignes, triez autrement, regardez d'autres colonnes.

```python
communes.sort_values("total", ascending=False).head(10)
```

## À essayer
- Remplacez `ascending=False` par `ascending=True` : quelles communes apparaissent ?
- Triez par `femmes` plutôt que par `total`.
- Gardez seulement `commune` et `total` avec `[["commune", "total"]]` à la fin.
- Remplacez `head(10)` par `sample(5)` : cinq communes au hasard, différentes à chaque exécution.

# Votre commune et ses voisines
Filtrez votre commune, puis les communes de son arrondissement.

```python
communes.query("commune == 'Namur'")
```

## À essayer
- Remplacez `'Namur'` par votre commune (attention aux accents et aux majuscules).
- Affichez toutes les communes de son arrondissement : `communes.query("arrondissement == 'Namur'")`.
- Classez-les par population, de la plus grande à la plus petite.
- Où se place votre commune dans sa province ? Essayez `.rank(ascending=False)` (leçon « Créer des variables »).

# Combien de communes… ?
Une question, une ligne. Modifiez la condition et observez le résultat.

```python
len(communes.query("total > 50000"))
```

## À essayer
- Et de plus de 100 000 habitants ? De moins de 3 000 ?
- Ajoutez une condition sur la région avec `and`.
- Combien de communes dont le nom commence par « Saint » ? `commune.str.startswith('Saint')`
- Remplacez `len(...)` par `[...]["total"].sum()` : quelle population vit dans ces communes ?

# Par province, par région
Un regroupement et plusieurs indicateurs. Ajoutez-en, retirez-en, changez la colonne de regroupement.

```python
(communes
 .groupby("province", as_index=False)
 .agg(communes=("commune", "count"),
      population=("total", "sum"))
 .sort_values("population", ascending=False))
```

## À essayer
- Remplacez `"province"` par `"region"`, puis par `"arrondissement"`.
- Ajoutez la population médiane : `mediane=("total", "median")`.
- Ajoutez la plus petite commune : `plus_petite=("total", "min")`.
- Ajoutez `.query("population > 1000000")` à la fin : que garde-t-on ?

# Des classes de taille à votre façon
Le choix des seuils change le tableau. Essayez d'autres découpages.

```python
communes["taille"] = pd.cut(communes["total"],
                            bins=[0, 10000, 50000, 600000],
                            labels=["petite", "moyenne", "grande"])
pd.crosstab(communes["region"], communes["taille"], margins=True)
```

## À essayer
- Ajoutez une classe : `bins=[0, 5000, 10000, 50000, 600000]` (et un libellé de plus).
- Ajoutez `normalize="index"` : chaque ligne fait 1 (100 %).
- Remplacez `normalize="index"` par `normalize="columns"` : que lit-on maintenant ?
- Comptez la population plutôt que les communes : `values=communes["total"], aggfunc="sum"`.

# Un graphique à modifier
Un diagramme en barres de la population par province. Changez le type de graphique, les couleurs, les titres.

```python
import seaborn as sns
import matplotlib.pyplot as plt

par_province = (communes.groupby(["region", "province"], as_index=False)
                .agg(population=("total", "sum"))
                .sort_values("population", ascending=False))
sns.barplot(data=par_province, x="population", y="province", hue="region")
plt.title("Population par province")
```

## À essayer
- Retirez `hue="region"` : que se passe-t-il ?
- Remplacez `x="population"` par `x="province"` et `y="province"` par `y="population"` : les noms deviennent illisibles. Pourquoi les barres horizontales sont-elles préférables ici ?
- Essayez `sns.histplot(data=communes, x="total", log_scale=True, hue="region")`.
- Ajoutez `plt.xlabel("Habitants")`.

# En SQL, comme dans PROC SQL
La même question, écrite en SQL avec DuckDB. Modifiez la requête.

```python
import duckdb

duckdb.sql("""
    SELECT region, COUNT(*) AS communes, SUM(total) AS population
    FROM communes
    GROUP BY region
    ORDER BY population DESC
""").df()
```

## À essayer
- Ajoutez `WHERE total > 20000` avant `GROUP BY`.
- Remplacez `region` par `province` (dans le `SELECT` et le `GROUP BY`).
- Ajoutez `HAVING COUNT(*) > 50` après le `GROUP BY` : quelle différence avec `WHERE` ?
- Ajoutez `AVG(total) AS moyenne` dans le `SELECT`.

# Explorer la nomenclature des territoires
La nomenclature NUTS de Statbel décrit régions, provinces, arrondissements et communes, avec leur nom en quatre langues et leurs dates de validité.

```python
nuts = pd.read_csv("referentiels/nuts_lau_2027.txt", sep="|", encoding="cp1252")
nuts["CD_LVL"].value_counts()
```

## À essayer
- Affichez les communes disparues : `nuts.query("CD_LVL == 4 and DT_VLDT_STOP != '31/12/9999'")`.
- Lesquelles ont disparu fin 2024 ? `DT_VLDT_STOP == '31/12/2024'`
- Affichez les noms en néerlandais et en allemand des provinces (`CD_LVL == 2`).
- Que se passe-t-il sans `encoding="cp1252"` ?
