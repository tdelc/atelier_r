---
titre: Regroupements et agrégations
resume: groupby() et agg() ; compter les valeurs ou les lignes ; contrôler la complétude d'une table nettoyée.
partie: Demi-journée 5 · Agrégations, fusion et consolidation
---

# Demi-journée 5 : agrégations, fusion et consolidation

**À l'issue de la séance, vous saurez**

- regrouper des observations et calculer des agrégats avec `groupby()` et `agg()` ;
- empiler des tables avec `concat()` et les joindre avec `merge()` ;
- contrôler la qualité d'une fusion : clés, lignes non appariées, totaux ;
- produire un fichier consolidé au format Parquet, réutilisable dans DuckDB.

**Découper, calculer, réassembler**

1. **Découper** : les lignes sont réparties en groupes selon une ou plusieurs colonnes (`region`, `sexe`…).
2. **Calculer** : une fonction s'applique à chaque groupe : somme, comptage, moyenne.
3. **Réassembler** : les résultats forment une nouvelle table, une ligne par groupe.

`propre.groupby("region")["population"].sum()` se lit : « pour chaque région, la somme de la population ».

# Cellule de départ de la séance

`population_nettoyee.parquet` est le corrigé de l'atelier 4 (fichier de secours) ; `brut` est la table d'origine, anomalies comprises.

```python
import pandas as pd
from outils_cours import harmoniser_code

propre = pd.read_parquet("donnees/population_nettoyee.parquet",
                         dtype_backend="pyarrow")
brut = pd.read_parquet("donnees/population_brut.parquet",
                       dtype_backend="pyarrow")
print(propre.shape, brut.shape)
```

# groupby() avec une agrégation

`groupby(colonnes)` définit les groupes ; on choisit ensuite la colonne à agréger et la fonction. Avec plusieurs colonnes de regroupement, on obtient une ligne par combinaison. `reset_index()` transforme le résultat en table ordinaire.

```python
par_region = propre.groupby("region")["population"].sum()
print(par_region)
```

```python
par_region_sexe = (propre
                   .groupby(["region", "sexe"])
                   ["population"].sum()
                   .reset_index())
par_region_sexe
```

**Lecture :** la Wallonie compte 3 711 794 habitants dans la table nettoyée, et non 3 713 450 comme dans le fichier de Statbel : il manque les deux lignes rejetées (Daverdisse, Martelange), et la commune « 99999 » ajoute 120 habitants qui n'existent pas.

# Compter les valeurs ou compter les lignes

`sum()` additionne, `mean()` fait la moyenne, `count()` compte les valeurs **renseignées**, `size()` compte les **lignes**.

Sur la table brute, comparer `count()` et `size()` révèle les valeurs manquantes d'un groupe.

```python
g = brut.groupby("region")["population"]
print(g.count())
print(g.size())
```

**Lecture :** 522 valeurs renseignées pour 523 lignes en Wallonie.

# Plusieurs indicateurs avec agg()

`agg()` calcule plusieurs indicateurs en une fois : `nouvelle_colonne=("colonne_source", "fonction")`.

```python
synthese = (propre
    .groupby(["region", "sexe"])
    .agg(population=("population", "sum"),
         lignes=("population", "size"),
         moyenne=("population", "mean"))
    .round(1)
    .reset_index())
synthese
```

**Lecture :** une commune bruxelloise compte en moyenne près de 33 000 habitants de chaque sexe, une commune wallonne environ 7 000 : la taille des communes varie beaucoup d'une région à l'autre.

# Nettoyé ne signifie pas complet

Chaque commune compte **2 lignes** : une pour les hommes, une pour les femmes. Compter les lignes par commune montre ce que le nettoyage a retiré.

Une somme calculée sur `propre` est la **population des observations conservées**, pas une population totale.

Limites : ce comptage suppose des clés uniques (doublons supprimés) et ne voit pas une commune entièrement absente ; celle-ci se repère en comparant avec le référentiel.

```python
lignes = propre.groupby(["code_ins", "commune"]).size()
incomplets = lignes[lignes != 2]
incomplets
```

**Lecture :** Martelange et Daverdisse n'ont plus qu'une ligne (les rejets de l'atelier 4) ; « 99999 » n'en a qu'une dès le départ.

::: sas
Même contrôle en SAS : `PROC FREQ` avec `TABLES code_ins / LIST;`, puis repérage des effectifs différents de 2.
:::
