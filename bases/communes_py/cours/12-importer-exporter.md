---
titre: Importer et exporter ses fichiers
resume: Lire un CSV, un TXT, un Excel, un Parquet en réglant séparateur, encodage, en-têtes et types ; contrôler l'importation ; exporter un résultat.
partie: Vos propres fichiers
---

# Les fichiers de votre dossier

Jusqu'ici, la table `communes` était prête. Dans votre travail, il faudra **lire vos fichiers** : c'est l'équivalent de `PROC IMPORT` ou d'une étape `DATA` avec `INFILE`.

Les fichiers de Statbel sont dans le dossier `donnees/` de l'atelier, tels qu'ils sont publiés :

```python
import os
os.listdir("donnees")
```

::: note
Dans vos scripts, le chemin part du dossier de travail. Sous Windows, écrivez les chemins avec des `/` (`"G:/Statistiques/donnees/fichier.csv"`) ou préfixez-les d'un `r` (`r"G:\Statistiques\donnees\fichier.csv"`).
:::

# Un CSV simple : pd.read_csv()

```python
pop = pd.read_csv("donnees/communes_2026.csv", sep=";")
pop.shape
```

::: usage
`sep=` donne le séparateur des colonnes : `";"` (le plus courant en Belgique et en France, car la virgule sert aux décimales), `","`, `"\t"` (tabulation) ou `"|"`.
:::

::: sas
`PROC IMPORT DATAFILE="communes_2026.csv" OUT=pop DBMS=DLM REPLACE; DELIMITER=';'; RUN;`
:::

# Toujours contrôler : shape et info()

```python
pop.info()
```

::: piege
Le code INS est lu comme un **nombre** (`int64`) : pandas le devine à partir des valeurs. Pour un code, c'est une erreur : `04000` (Bruxelles-Capitale) deviendrait `4000`. On impose le type texte avec `dtype=` :
:::

```python
pop = pd.read_csv("donnees/communes_2026.csv", sep=";", dtype={"code_ins": str})
pop["code_ins"].head(3)
```

# Le fichier d'origine de Statbel

Le fichier « Population par commune » de Statbel est un texte tabulé. Lisons-le sans précaution :

```python
brut = pd.read_csv("donnees/population_2026.txt", sep="\t")
print(brut.shape)
brut.head(5)
```

Quatre problèmes :

1. deux lignes vides sous les en-têtes ;
2. le code INS lu comme un nombre : `01000` est devenu `1000.0` (décimal, à cause des lignes vides) ;
3. les populations sont du **texte**, à cause des points des milliers (`11.867.634`) ;
4. le nom de la première colonne commence par une espace : `" Code INS"`.

# Les bons paramètres

```python
brut = pd.read_csv("donnees/population_2026.txt", sep="\t",
                   skiprows=[1, 2],               # les lignes vides
                   thousands=".",                 # le point des milliers
                   dtype={" Code INS": str})      # le code en texte
brut.columns = ["code_ins", "lieu", "hommes", "femmes", "total"]   # des noms propres
print(brut.dtypes)
brut.head(4)
```

| Paramètre | Rôle | Symptôme s'il est mal réglé |
|---|---|---|
| `sep` | séparateur des colonnes | une seule colonne lue |
| `encoding` | encodage des caractères | erreur `UnicodeDecodeError`, ou accents illisibles |
| `skiprows`, `header` | lignes à sauter, ligne des en-têtes | lignes vides ou titres pris pour des données |
| `thousands`, `decimal` | séparateurs des milliers, des décimales | nombres lus comme du texte |
| `dtype` | type imposé à une colonne | zéros initiaux perdus |

::: note
`brut.columns = [...]` remplace tous les noms de colonnes d'un coup, dans l'ordre. C'est plus simple que `rename()` quand les noms d'origine sont peu pratiques.
:::

# L'encodage : la nomenclature NUTS

La nomenclature des territoires de Statbel est encodée en **Windows-1252** (`cp1252`), l'encodage historique de Windows. pandas suppose UTF-8 par défaut et s'arrête au premier caractère accentué. **Erreur volontaire** :

```python erreur
nuts = pd.read_csv("referentiels/nuts_lau_2027.txt", sep="|")
```

```python
nuts = pd.read_csv("referentiels/nuts_lau_2027.txt", sep="|", encoding="cp1252")
print(nuts.shape)
nuts[["CD_MUNTY_REFNIS", "TX_DESCR_FR", "TX_DESCR_NL", "CD_LVL"]].head(4)
```

::: piege
`encoding="latin-1"` lit aussi ce fichier sans erreur… mais l'apostrophe de « Province d’Anvers » y devient un caractère invisible. Les fichiers produits sous Windows sont presque toujours en `cp1252` ; les fichiers récents, en `utf-8`.
:::

::: sas
`FILENAME f "nuts_lau_2027.txt" ENCODING="wlatin1";`
:::

# Un fichier Excel : pd.read_excel()

Deux lignes de titre précèdent les en-têtes : `header=2` désigne la troisième ligne (on compte à partir de 0).

```python
prov = pd.read_excel("donnees/population_provinces_2026.xlsx", header=2,
                     dtype={"code_ins": str})
prov.head(3)
```

::: usage
`sheet_name="Feuil2"` choisit une autre feuille ; `sheet_name=None` les lit toutes.
:::

# Un fichier Parquet : pd.read_parquet()

Le format **Parquet** stocke les types avec les données : rien à préciser, tout est juste. C'est le format conseillé pour les tables qu'on échange entre programmes (Python, R, DuckDB…).

```python
t = pd.read_parquet("donnees/communes_2026.parquet")
t.dtypes
```

# Exporter un résultat

On calcule un tableau, puis on l'enregistre dans le dossier `sortie/`.

```python
par_province = (communes
                .groupby("province", as_index=False)
                .agg(communes=("commune", "count"), population=("total", "sum")))

par_province.to_csv("sortie/provinces.csv", sep=";", index=False, encoding="utf-8")
par_province.to_excel("sortie/provinces.xlsx", index=False)
par_province.to_parquet("sortie/provinces.parquet", index=False)
os.listdir("sortie")
```

::: usage
`index=False` évite d'écrire une colonne de numéros de ligne en plus. Pour un fichier destiné à Excel en français, `sep=";"` et `decimal=","` donnent des nombres lisibles directement.
:::

::: sas
`PROC EXPORT DATA=par_province OUTFILE="provinces.csv" DBMS=DLM REPLACE; DELIMITER=';'; RUN;`
:::

# Relire ce qu'on a écrit

Le réflexe, en Python comme en SAS : relire le fichier exporté pour le contrôler.

```python
pd.read_csv("sortie/provinces.csv", sep=";").shape
```
