---
titre: Sélection, filtrage et nettoyage
resume: loc et iloc ; filtrer et trier ; doublons ; valeurs manquantes ; harmoniser une colonne, convertir les types, créer une variable.
partie: Demi-journée 4 · Inspection, sélection et nettoyage
---

# loc : sélectionner par étiquettes

On repart de la table brute :

```python
import pandas as pd
brut = pd.read_parquet("donnees/population_brut.parquet",
                       dtype_backend="pyarrow")
brut.shape
```

`df.loc[lignes, colonnes]` sélectionne par **étiquettes** : index des lignes, noms des colonnes.

Attention : avec `loc`, la borne de fin est **incluse** (`0:2` donne 3 lignes), contrairement au slicing Python.

```python
brut.loc[0:2, ["code_ins", "commune", "sexe", "population"]]
```

```python
print(brut.loc[5, "commune"])
print(brut.loc[5, "population"])
```

# iloc : sélectionner par positions

`df.iloc[lignes, colonnes]` sélectionne par **positions**, comme une liste Python : la fin est **exclue**. `-1` désigne la dernière ligne.

Préférez `loc` et les noms de colonnes : le code reste juste si l'ordre des colonnes change.

```python
brut.iloc[:3, :2]
```

```python
brut.iloc[-1]
```

# Filtrer les lignes selon des conditions

Une condition sur une colonne renvoie une Series de booléens ; elle garde les lignes vraies.

Pour combiner : `&` (et), `|` (ou), `~` (non), avec des **parenthèses** autour de chaque condition. `.isin([...])` teste l'appartenance à une liste ; `.str.startswith()` applique la méthode de texte à toute la colonne.

En SAS : `WHERE region = 'Wallonie' and sexe = 'F';`

```python
wallonnes = brut[(brut["region"] == "Wallonie") & (brut["sexe"] == "F")]
print(wallonnes.shape)

grandes_villes = brut[brut["commune"].isin(["Liège", "Namur", "Charleroi"])]
print(grandes_villes.shape)

province_liege = brut.loc[brut["code_ins"].str.startswith("6"),
                          ["code_ins", "commune", "population"]]
province_liege.head(3)
```

**Lecture :** 260 lignes de femmes en Wallonie, et non 261 : celle de Namur est écrite `"f"` et échappe au filtre `== "F"`. Les trois grandes villes donnent bien 6 lignes (deux par ville) : le filtre porte sur le nom, que les anomalies n'ont pas touché. Un filtre ne vaut que si la colonne filtrée est propre.

# Trier les observations : sort_values()

`sort_values(colonnes, ascending=...)` trie selon une ou plusieurs colonnes. Une liste dans `ascending` choisit le sens pour chaque colonne.

Le tri renvoie une nouvelle table : `brut` n'est pas modifiée.

```python
tri = brut.sort_values(["region", "population"],
                       ascending=[True, False])
tri.head(4)
```

::: sas
En SAS, `PROC SORT` précède souvent un `MERGE` ou un `BY`. Avec pandas, trier ne sert qu'à l'affichage ou à l'export : jointures et regroupements n'en ont pas besoin.
:::

# Détecter et supprimer les doublons

`duplicated()` marque les lignes identiques à une ligne précédente ; `.sum()` les compte. `subset=` limite la comparaison à une clé. `drop_duplicates()` supprime les doublons et garde la première occurrence. Équivalent SAS : `PROC SORT NODUPKEY`, ici sans tri préalable.

```python
print(brut.duplicated().sum())
cle = ["code_ins", "sexe"]
print(brut.duplicated(subset=cle).sum())
brut[brut.duplicated(keep=False)]
```

```python
sans_doublons = brut.drop_duplicates()
print(len(brut), len(sans_doublons))
```

**Lecture :** la ligne de Gand (femmes) apparaît deux fois, à l'identique : c'est le doublon du fichier flamand, invisible ligne à ligne en demi-journée 2.

# Repérer les valeurs manquantes : isna()

Avec les types PyArrow, une valeur manquante apparaît en `<NA>` (selon le type, pandas peut aussi afficher `NaN`, ou `NaT` pour une date). `isna()` les détecte ; `.sum()` les compte.

Les calculs ignorent les valeurs manquantes par défaut, comme les procédures SAS ignorent `.` : vérifiez le nombre de valeurs réellement utilisées.

```python
print(brut.isna().sum())
```

```python
brut[brut["population"].isna()]
```

# Traiter les valeurs manquantes : fillna() et dropna()

`fillna(valeur)` remplace les manquantes ; `dropna(subset=...)` supprime les lignes concernées.

Remplacer par 0 ne change pas la somme, mais modifie la moyenne et les effectifs : c'est une **décision métier**, à documenter. Dans l'atelier, la règle est donnée : la ligne est écartée et tracée dans un fichier de rejets.

**Nettoyé ne signifie pas complet** : après exclusion, une somme porte sur les observations conservées, pas sur toute la population.

```python
avec_zero = brut["population"].fillna(0)
print(round(brut["population"].mean(), 1),
      round(avec_zero.mean(), 1))

complet = brut.dropna(subset=["population"])
positifs = complet[complet["population"] >= 0]
print(len(brut), len(complet), len(positifs))
```

# Harmoniser une colonne et convertir les types

`.str` applique les méthodes de texte à toute une colonne. `.map(fonction)` applique une fonction à chaque valeur : `harmoniser_code()`, écrite en demi-journée 3, est fournie dans `outils_cours.py`.

`astype("int64[pyarrow]")` choisit un entier PyArrow (qui accepte les valeurs manquantes). `pd.to_datetime()` convertit un texte en date.

```python
from outils_cours import harmoniser_code

df = brut.drop_duplicates().copy()
df["sexe"] = df["sexe"].str.strip().str.upper()
df["code_ins"] = df["code_ins"].map(harmoniser_code)
df["population"] = df["population"].astype("int64[pyarrow]")
df["date_reference"] = pd.to_datetime(df["annee"].astype(str) + "-01-01")

print(df["sexe"].unique().tolist())
print(df.loc[df["commune"] == "Liège", "code_ins"].tolist())
print(df[["population", "date_reference"]].dtypes)
```

`.copy()` crée une table indépendante : modifier `df` ne touche pas `brut`.

# Créer une variable calculée

Une nouvelle colonne se crée par affectation : `df["nouvelle"] = ...`.

`.map(dictionnaire)` recode des modalités : chaque valeur est remplacée par la valeur associée. Ici, le premier chiffre du code INS donne la province.

```python
df["pop_milliers"] = (df["population"] / 1000).round(2)

provinces = {"1": "Anvers", "3": "Flandre occidentale", "4": "Flandre orientale",
             "5": "Hainaut", "6": "Liège", "7": "Limbourg",
             "8": "Luxembourg", "9": "Namur",
             "2": "Bruxelles ou Brabant"}
df["province"] = df["code_ins"].str[:1].map(provinces)

df[["commune", "population", "pop_milliers", "province"]].head(3)
```

::: piege
Le chiffre `2` regroupe Bruxelles et les **deux** Brabant (flamand, codes 23 et 24 ; wallon, code 25) : un dictionnaire sur le premier chiffre ne suffit pas. La bonne méthode est une **jointure** avec la nomenclature, en demi-journée 5.
:::

# Démonstration : nettoyer un fichier, étape par étape

1. Vérifier la structure : `info()`, `describe()`
2. Identifier doublons et valeurs manquantes
3. Harmoniser codes et modalités
4. Appliquer les filtres
5. Contrôler : chaque ligne écartée doit être expliquée

Le tableau de bilan sert de **piste d'audit** : il se relit et se compare d'une exécution à l'autre.

```python
etapes = [("lecture", len(brut))]
df = brut.drop_duplicates().copy()
etapes.append(("sans doublon", len(df)))
df["code_ins"] = df["code_ins"].map(harmoniser_code)
df["sexe"] = df["sexe"].str.strip().str.upper()
df = df.dropna(subset=["population"])
etapes.append(("population renseignée", len(df)))
df = df[df["population"] >= 0]
etapes.append(("population positive", len(df)))
pd.DataFrame(etapes, columns=["étape", "lignes"])
```

# Ce qu'il faut retenir

- **Inspecter** : `shape`, `head()`, `info()`, `describe()`, `unique()` : structure, types et valeurs anormales.
- **Sélectionner** : `loc` par étiquettes, fin incluse ; `iloc` par positions, fin exclue.
- **Filtrer et trier** : conditions entre parenthèses avec `&`, `|`, `~` ; `isin()` ; `sort_values()`.
- **Doublons** : `duplicated()` pour compter, `drop_duplicates()` pour supprimer ; `subset=` pour une clé.
- **Manquantes** : `isna()` pour repérer ; `dropna()` ou `fillna()` selon une règle documentée.
- **Transformer** : `.str`, `.map()`, `astype()`, `pd.to_datetime()` ; nouvelle colonne par affectation.
