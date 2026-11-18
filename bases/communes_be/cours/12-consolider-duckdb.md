---
titre: Consolider et relire avec DuckDB
resume: Un traitement de consolidation complet, des indicateurs par province, un fichier Parquet relu en SQL avec DuckDB ; DuckDB et pandas dans le navigateur.
partie: Demi-journée 5 · Agrégations, fusion et consolidation
---

# Démonstration : consolider et contrôler la fusion

1. Partir de la table nettoyée
2. Agréger au niveau **commune**, en gardant le nombre de lignes
3. Joindre la nomenclature (communes en vigueur, puis provinces) avec `indicator=True`
4. Vérifier le nombre de lignes et les totaux

```python
import pandas as pd

propre = pd.read_parquet("donnees/population_nettoyee.parquet",
                         dtype_backend="pyarrow")
ref = pd.read_csv("referentiels/nuts_lau_2027.txt", sep="|",
                  encoding="cp1252", dtype_backend="pyarrow")

en_vigueur = (ref[(ref["CD_LVL"] == 4) & (ref["DT_VLDT_STOP"] == "31/12/9999")]
              .rename(columns={"CD_MUNTY_REFNIS": "code_ins", "CD_LVL_SUP": "nuts3"})
              [["code_ins", "nuts3"]])
provinces = (ref[(ref["CD_LVL"] == 2) & (ref["DT_VLDT_STOP"] == "31/12/9999")]
             .rename(columns={"CD_LAU": "nuts2", "TX_DESCR_FR": "province"})
             [["nuts2", "province"]])

# femmes : la population si la ligne est celle des femmes, 0 sinon
propre["femmes"] = propre["population"].where(propre["sexe"] == "F", 0)
par_commune = (propre
    .groupby(["code_ins", "commune"], as_index=False)
    .agg(population=("population", "sum"),
         femmes=("femmes", "sum"),
         lignes=("population", "size")))
avec_ref = par_commune.merge(en_vigueur, on="code_ins", how="left",
                             indicator=True, validate="many_to_one")
# clé NUTS manquante (commune inconnue) : remplacée par "-" avant de joindre
avec_ref["nuts2"] = avec_ref["nuts3"].fillna("-").str.slice(0, 4)
avec_ref = avec_ref.merge(provinces, on="nuts2", how="left", validate="many_to_one")
avec_ref.loc[avec_ref["nuts2"] == "BE10", "province"] = "Région de Bruxelles-Capitale"

print(len(par_commune), "->", len(avec_ref), "lignes")
print(avec_ref["_merge"].value_counts().to_dict())
print("Total :", par_commune["population"].sum(), avec_ref["population"].sum())
```

**À vérifier :** même nombre de lignes et même total avant et après la jointure ; la commune non appariée (« 99999 ») est identifiée, pas perdue.

`serie.where(condition, autre)` garde la valeur là où la condition est vraie et met `autre` ailleurs : la colonne `femmes` permet d'additionner les femmes dans le même `agg()`.

# Calculer des indicateurs par province

Par province : nombre de communes, population, part des femmes. On ne garde que les communes appariées.

**Complétude** : chaque commune doit avoir 2 lignes (hommes et femmes). La colonne `complet` signale les provinces touchées par le nettoyage.

```python
apparie = avec_ref[avec_ref["_merge"] == "both"]
indic = (apparie.groupby("province")
         .agg(communes=("code_ins", "size"),
              lignes=("lignes", "sum"),
              population=("population", "sum"),
              femmes=("femmes", "sum")))
indic["part_femmes"] = (indic["femmes"] / indic["population"] * 100).round(1)
indic["complet"] = indic["lignes"] == 2 * indic["communes"]
indic.sort_values("population", ascending=False)
```

**Lecture :** le Luxembourg n'est pas complet : 294 594 habitants dans la table nettoyée, contre 296 370 dans le fichier de Statbel. Ce sont les deux lignes rejetées (Daverdisse, Martelange) : une population calculée sur une table nettoyée est celle des **observations conservées**.

# Relire un fichier Parquet avec DuckDB

Un fichier produit doit être **réutilisable** : on le relit avec un autre outil. **DuckDB** interroge un fichier Parquet en SQL, sans le charger d'abord dans pandas. La requête doit retrouver les totaux de la carte précédente ; « 99999 », non appariée, reste visible, avec une province manquante.

```python
import duckdb

avec_ref.drop(columns="_merge").to_parquet("sortie/communes_consolidees.parquet",
                                           index=False)

duckdb.sql("""
    SELECT province,
           COUNT(*)                      AS communes,
           CAST(SUM(population) AS BIGINT) AS population
    FROM 'sortie/communes_consolidees.parquet'
    GROUP BY province
    ORDER BY population DESC
""").df()
```

DuckDB lit aussi directement un **DataFrame** pandas, désigné par son nom dans la requête :

```python
duckdb.sql("SELECT COUNT(*) AS lignes, SUM(population) AS population FROM propre").df()
```

# DuckDB est-il plus rapide ici ?

Sur votre poste, DuckDB est en général **bien plus rapide** que pandas sur de grosses tables : il utilise tous les cœurs du processeur, ne lit que les colonnes utiles d'un fichier Parquet et peut traiter des fichiers plus gros que la mémoire. Votre formateur vous le montrera.

**Dans l'atelier, ce n'est pas le cas** : Python tourne dans votre navigateur, sur **un seul cœur** et sans disque. Mesurons sur une table de 2 millions de lignes générée avec NumPy :

```python
import time
import numpy as np

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

**Lecture :** ici, DuckDB n'est pas plus rapide, souvent même plus lent. Une mesure de performance dépend de l'environnement : retenez de DuckDB ce qu'il apporte partout (le SQL, la lecture directe des fichiers Parquet), et mesurez sa vitesse là où vous travaillerez.

# Un traitement de données en sept étapes

- **1 · Importer** : `read_csv`, `read_excel`, `read_parquet` : séparateur, encodage, en-têtes, types.
- **2 · Contrôler** : `shape`, `info()`, `describe()`, règles de validation, `assert`.
- **3 · Nettoyer** : doublons, valeurs manquantes, types, harmonisation des modalités.
- **4 · Automatiser** : boucles sur les fichiers, fonctions réutilisables.
- **5 · Fusionner** : `concat()` pour empiler, `merge()` pour joindre, `indicator` et `validate` pour contrôler.
- **6 · Agréger** : `groupby()` et `agg()` par territoire, sexe, catégorie.
- **7 · Exporter** : `to_csv`, `to_parquet` ; relire le fichier produit pour le vérifier.

**Pour progresser** : reprenez un traitement SAS simple de votre service et réécrivez-le en Python, étape par étape. Place à l'**atelier de synthèse**, dans le volet Exercices.
