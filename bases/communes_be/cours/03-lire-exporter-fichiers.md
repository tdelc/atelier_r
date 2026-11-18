---
titre: Lire et exporter des fichiers
resume: Lire des fichiers CSV, TXT et Excel avec pandas en réglant séparateur, encodage, en-têtes et types ; exporter un tableau.
partie: Demi-journée 1 · Fondamentaux et fichiers
---

# Les fichiers du cours

Votre dossier de travail contient trois dossiers. Les fichiers sont ceux de **Statbel**, tels qu'ils sont publiés, avec leurs particularités.

| Fichier | Contenu | Format |
|---|---|---|
| `donnees/population_communes_2026.csv` | population des 565 communes | CSV, séparateur `;` |
| `donnees/population_2026.txt` | le fichier Statbel d'origine : communes, arrondissements, provinces, régions | texte tabulé, points des milliers |
| `donnees/population_provinces_2026.xlsx` | population des provinces | Excel, deux lignes de titre |
| `referentiels/nuts_lau_2027.txt` | nomenclature des territoires (codes NUTS 2027) | séparateur `\|`, encodage latin-1 |
| `sortie/` | vos résultats | vide au départ |

Le CSV et l'Excel ont été tirés du fichier d'origine, pour pratiquer d'autres formats : les chiffres sont identiques.

`os.listdir()` liste le contenu d'un dossier :

```python
import os
print(os.listdir("donnees"))
print(os.listdir("referentiels"))
```

::: note
Dans l'atelier, ces fichiers sont dans votre navigateur. Ce que vous écrivez dans `sortie/` y reste jusqu'à la fermeture de la page : rien n'est envoyé au serveur.
:::

# Lire un fichier CSV avec pandas

*Recette à réutiliser telle quelle.*

**pandas** est la bibliothèque de référence pour les tableaux de données. Elle est expliquée en demi-journée 4. Pour l'instant, retenez la recette : `pd.read_csv()` lit un fichier et renvoie un tableau, un **DataFrame**.

`.shape` donne le nombre de lignes et de colonnes ; `.head()` affiche les premières lignes.

`dtype_backend="pyarrow"` utilise les types PyArrow, recommandés dans votre environnement.

```python
import pandas as pd

pop = pd.read_csv("donnees/population_communes_2026.csv",
                  sep=";",
                  dtype_backend="pyarrow")
print(pop.shape)     # (lignes, colonnes)
pop.head(3)
```

**Lecture :** 565 lignes (une par commune) et 5 colonnes.

# Cinq paramètres qui évitent la plupart des erreurs

| Paramètre | Rôle | Valeurs courantes | Symptôme s'il est mal réglé |
|---|---|---|---|
| `sep` | séparateur de colonnes | `";"`, `"\t"`, `"\|"` | une seule colonne lue |
| `encoding` | encodage des caractères | `"utf-8"`, `"latin-1"` | erreur `UnicodeDecodeError` ou accents illisibles |
| `header`, `skiprows` | ligne des en-têtes, lignes à sauter | `0` (par défaut), `2` | lignes de titre ou lignes vides prises pour des données |
| `decimal`, `thousands` | séparateur décimal, des milliers | `","`, `"."` | nombres lus comme du texte |
| `dtype` | type imposé à une colonne | `{"code_ins": str}` | zéros initiaux perdus (`04000` devient `4000`) |

Le premier symptôme, avec un mauvais séparateur :

```python
faux = pd.read_csv("donnees/population_communes_2026.csv", sep=",",
                   dtype_backend="pyarrow")
print(faux.shape)
faux.head(2)
```

**Lecture :** une seule colonne, dont le nom contient tous les autres séparés par des `;`. Vérifier `.shape` juste après la lecture suffit à le voir.

::: sas
`PROC IMPORT` règle le délimiteur (`DELIMITER=`) et les en-têtes (`GETNAMES=`, `DATAROW=`) ; l'encodage se précise sur l'instruction `FILENAME` (`ENCODING=`). En Python, tout passe par les paramètres de la fonction.
:::

# Une erreur d'encodage : la lire

La nomenclature NUTS de Statbel est encodée en **latin-1**. pandas suppose **UTF-8** par défaut et s'arrête au premier caractère accentué (ici le « ü » de *Brüssel*).

**Erreur volontaire** : lisez la dernière ligne du message, elle nomme le problème.

```python erreur
ref = pd.read_csv("referentiels/nuts_lau_2027.txt", sep="|",
                  dtype_backend="pyarrow")
```

# … puis la corriger

Correction : préciser `encoding="latin-1"`. Le séparateur de ce fichier est la barre verticale `|`.

```python
ref = pd.read_csv("referentiels/nuts_lau_2027.txt", sep="|",
                  encoding="latin-1", dtype_backend="pyarrow")
print(ref.shape)
ref.head(4)
```

**Lecture :** 919 lignes. Chaque territoire a un code NUTS (`CD_LAU`), un code INS (`CD_MUNTY_REFNIS`), un nom en quatre langues, des dates de validité et un niveau (`CD_LVL` : 1 = région, 2 = province, 3 = arrondissement, 4 = commune). Les communes qui ont disparu (fusions de 2019 et de 2025) y sont encore, avec leur date de fin.

::: note
`CD_MUNTY_REFNIS` est lu comme du texte (`"04000"` garde son zéro) parce que la colonne contient aussi des `-` : pandas ne peut pas en faire des nombres.
:::

# Un fichier texte tabulé : le fichier d'origine de Statbel

Un fichier TXT tabulé se lit avec `pd.read_csv()` et `sep="\t"` (la tabulation). Lisons-le sans autre précaution, puis regardons les types avec `.dtypes` :

```python
brut = pd.read_csv("donnees/population_2026.txt", sep="\t",
                   dtype_backend="pyarrow")
print(brut.shape)
print(brut.dtypes)
brut.head(5)
```

Quatre problèmes sautent aux yeux :

1. deux lignes vides (`<NA>`) sous les en-têtes ;
2. le code INS est lu comme un nombre : `01000` est devenu `1000` ;
3. les populations sont du **texte** (`string`), à cause des points des milliers ;
4. le nom de la première colonne commence par une espace : `" Code INS"`.

# Corriger la lecture avec les bons paramètres

- `skiprows=[1, 2]` saute les lignes 1 et 2 du fichier (la ligne 0 est celle des en-têtes) ;
- `thousands="."` indique que le point sépare les milliers ;
- `dtype={" Code INS": str}` garde le code en texte, avec l'espace exacte du nom de colonne.

```python
brut = pd.read_csv("donnees/population_2026.txt", sep="\t",
                   skiprows=[1, 2], thousands=".",
                   dtype={" Code INS": str},
                   dtype_backend="pyarrow")
print(brut.shape)
print(brut.dtypes)
brut.head(4)
```

**Lecture :** 622 lignes, les populations sont des entiers et `01000` a gardé son zéro. Mais le fichier mélange les niveaux : la Belgique, 3 régions, 10 provinces, 43 arrondissements et 565 communes. On apprendra à n'en garder qu'un en demi-journée 4.

::: piege
Le nom `" Code INS"` commence par une espace : `brut["Code INS"]` provoquerait une erreur `KeyError`. Affichez `brut.columns` pour voir les noms exacts.
:::

# Lire un fichier Excel

`pd.read_excel()` lit une feuille Excel. Deux lignes de titre précèdent les en-têtes : `header=2` désigne la troisième ligne, car on compte à partir de 0.

Là aussi, `dtype={"code_ins": str}` protège le zéro du code de Bruxelles (`04000`).

```python
prov = pd.read_excel("donnees/population_provinces_2026.xlsx",
                     header=2, dtype={"code_ins": str},
                     dtype_backend="pyarrow")
print(prov.shape)
prov.head(3)
```

**Lecture :** 11 lignes : les 10 provinces et la Région de Bruxelles-Capitale, qui n'appartient à aucune province.

# Exporter un tableau : CSV, TXT tabulé et Excel

Un DataFrame s'exporte avec `.to_csv()` ou `.to_excel()`. Un fichier TXT tabulé s'écrit aussi avec `.to_csv()` : seul le séparateur change, `sep="\t"`.

`index=False` évite d'écrire une colonne de numéros de ligne en plus.

Écrivez toujours dans `sortie/` : les fichiers sources ne se modifient jamais.

```python
extrait = pop.head(10)            # 10 premières lignes
extrait.to_csv("sortie/extrait_2026.csv", sep=";",
               index=False, encoding="utf-8")
extrait.to_csv("sortie/extrait_2026.txt", sep="\t",
               index=False, encoding="utf-8")     # TXT tabulé
extrait.to_excel("sortie/extrait_2026.xlsx", index=False)

relu = pd.read_csv("sortie/extrait_2026.txt", sep="\t",
                   dtype_backend="pyarrow")
print(relu.shape)                 # contrôle
print(os.listdir("sortie"))
```

::: sas
`PROC EXPORT` joue le même rôle. Le réflexe à garder dans les deux langages : relire le fichier exporté pour le contrôler.
:::

# Ce qu'il faut retenir

- **Variables et types** : un nom désigne une valeur : `int`, `float`, `str`, `bool`, `date`. Vérifier avec `type()`.
- **Conversions** : `int()`, `float()`, `str()`. Une valeur lue dans un fichier est souvent du texte ; attention au point des milliers.
- **Opérateurs** : `=` affecte, `==` compare. `and`, `or`, `not` et `in` combinent des conditions.
- **Structures** : liste `[ ]`, tuple `( )`, ensemble `{ }`, dictionnaire `{clé: valeur}`.
- **Positions** : on compte à partir de 0. Dans `[début:fin]`, la fin est exclue. `-1` désigne le dernier élément.
- **Fichiers** : régler `sep`, `encoding`, `header` ou `skiprows`, `thousands` ou `decimal`, `dtype` ; puis toujours vérifier `.shape` et `.dtypes`.

Place aux **exercices** : les « À vous » de la séance et l'**atelier 1**.
