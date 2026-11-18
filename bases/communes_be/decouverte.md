---
base: communes_be
---

# Jouer avec les types
Chaque valeur a un type, qui décide de ce qu'on peut en faire. Modifiez les valeurs et observez les types et les résultats.

```python
population = 198102
code_ins = "62063"
superficie = 69.4
print(type(population), type(code_ins), type(superficie))
print(population / superficie)     # densité, en habitants par km²
print(code_ins * 2)                # un texte multiplié par 2 ?
```

## À essayer
- Remplacez `population / superficie` par `round(population / superficie, 1)`.
- Que donne `code_ins + 1` ? Lisez la dernière ligne du message d'erreur.
- Comparez `int("04000")` et `"04000"` : que devient le zéro ?
- Que donne `float("198.102")` ? Et `int("198.102".replace(".", ""))` ?

# Lire un fichier avec les mauvais paramètres
Les paramètres de lecture décident de ce que pandas comprend du fichier. Changez-les un à un et regardez `.shape` et `.dtypes`.

```python
import pandas as pd

brut = pd.read_csv("donnees/population_2026.txt", sep="\t",
                   dtype_backend="pyarrow")
print(brut.shape)
print(brut.dtypes)
brut.head()
```

## À essayer
- Ajoutez `thousands="."` : quel est maintenant le type de `Total` ?
- Ajoutez `skiprows=[1, 2]`, puis `dtype={" Code INS": str}`.
- Remplacez `sep="\t"` par `sep=";"` : combien de colonnes ?
- Lisez seulement trois lignes avec `nrows=3`.

# Explorer la nomenclature NUTS
Le référentiel de Statbel décrit tous les territoires belges, des régions aux communes, avec leurs dates de validité.

```python
import pandas as pd

ref = pd.read_csv("referentiels/nuts_lau_2027.txt", sep="|",
                  encoding="latin-1", dtype_backend="pyarrow")
print(ref.shape)
print(list(ref.columns))
ref.head(10)
```

## À essayer
- Affichez les dernières lignes avec `ref.tail()`.
- Le code NUTS de Liège (province) est `BE33` : que donnent `"BE332"[:3]` et `"BE332"[:4]` ?
- Que se passe-t-il sans `encoding="latin-1"` ? Et avec `encoding="utf-8"` ?
- Comptez les niveaux avec `ref["CD_LVL"].value_counts()` (une fonction de la demi-journée 4).
