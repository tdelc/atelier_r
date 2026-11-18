---
titre: DataFrames et inspection
resume: Series et DataFrame ; lire un fichier Parquet ; inspecter une table avec shape, head, info, describe et unique.
partie: Demi-journée 4 · Inspection, sélection et nettoyage
---

# Demi-journée 4 : inspection, sélection et nettoyage

**À l'issue de la séance, vous saurez**

- charger des données dans un DataFrame et en inspecter la structure ;
- sélectionner avec `loc` et `iloc`, filtrer par conditions, trier ;
- détecter les doublons et traiter les valeurs manquantes ;
- convertir les types, harmoniser une colonne et créer une variable calculée.

**Avec pandas, on travaille sur des colonnes entières.** Un **DataFrame** est un tableau : des lignes, des colonnes nommées, un type par colonne. Une opération sur une colonne s'applique à toutes ses lignes, sans boucle à écrire. Les fonctions de la demi-journée 3 restent utiles : on les applique à une colonne avec `.map()`.

Python : une boucle (illustration, non exécutée)

```python norun
for ligne in lignes:
    ligne["pop_milliers"] = ligne["population"] / 1000
```

pandas : une instruction pour toute la colonne (illustration, non exécutée)

```python norun
df["pop_milliers"] = df["population"] / 1000
```

::: sas
Une colonne calculée ressemble à une affectation de l'étape DATA (`pop_milliers = population / 1000;`). Différence : pandas traite la colonne entière en une fois, et non une ligne après l'autre.
:::

# Series et DataFrame

Une **Series** est une colonne : des valeurs et un **index**, c'est-à-dire les étiquettes des lignes.

Un **DataFrame** est un ensemble de Series qui partagent le même index. Sélectionner une colonne d'un DataFrame renvoie une Series.

```python
import pandas as pd

s = pd.Series([198102, 115457, 206900],
              index=["Liège", "Namur", "Charleroi"])
print(s["Namur"], s.sum())

df = pd.DataFrame({"code_ins": ["62063", "92094"],
                   "population": [198102, 115457]})
print(type(df["population"]))
df
```

# Charger des données au format Parquet

`pd.read_csv()` et `pd.read_excel()` ont été vus en demi-journée 1. `pd.read_parquet()` lit un fichier **Parquet** : un format en colonnes qui conserve les types.

`population_brut.parquet` réunit les trois fichiers régionaux, anomalies comprises, avec une colonne `region`.

| | CSV | Parquet |
|---|---|---|
| Stockage | texte, ligne par ligne | binaire, colonne par colonne |
| Types | à préciser à chaque lecture | conservés dans le fichier |
| Lisible dans un éditeur | oui | non |
| Moteur utilisé | pandas | PyArrow |

```python
brut = pd.read_parquet("donnees/population_brut.parquet",
                       dtype_backend="pyarrow")
print(type(brut))
print(brut.shape)
```

# Premier coup d'œil : shape, head() et tail()

`shape` donne (lignes, colonnes). `head(n)` affiche les n premières lignes (5 par défaut), `tail(n)` les n dernières. Une liste de noms entre crochets sélectionne des colonnes.

```python
print(brut.shape)
brut.head()
```

```python
colonnes = ["code_ins", "commune", "region", "population"]
brut[colonnes].tail(3)
```

**Lecture :** la dernière ligne est la commune « 99999 », qui n'existe pas : on la retrouvera à la jointure de la demi-journée 5.

::: sas
`PROC PRINT DATA=brut (OBS=5);` correspond à `head()`.
:::

# info() : la structure et les types

`info()` donne les types et le nombre de valeurs **non manquantes** de chaque colonne. Équivalent SAS : `PROC CONTENTS`.

```python
brut.info()
```

**Lecture :** `population` a 1 131 valeurs sur 1 132 : une est manquante. Le fichier la stocke en flottant (`double[pyarrow]`) ; nous la convertirons en entier après nettoyage. Le texte apparaît en `large_string[pyarrow]`, une variante de `string[pyarrow]` pour les longues colonnes : on le manipule de la même façon.

# describe() et unique() : repérer l'anormal

`describe()` calcule effectif, moyenne, écart-type, minimum, quartiles et maximum. Lire le minimum et le maximum est un contrôle rapide. Équivalent SAS : `PROC MEANS`.

`unique()` liste les modalités d'une colonne : une modalité mal écrite saute aux yeux.

```python
brut["population"].describe().round(1)
```

```python
print(brut["sexe"].unique().tolist())
print(brut["region"].unique().tolist())
```

**Lecture :** un minimum de -1 059, impossible pour une population, et un sexe `"f"` en minuscule.
