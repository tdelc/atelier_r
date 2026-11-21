---
titre: Importer et exporter ses fichiers
resume: Lire des déclarations TVA en CSV, Excel et texte tabulé - séparateur, virgule décimale, en-têtes, encodage, types ; contrôler la lecture ; écrire un résultat.
partie: Vos propres fichiers
---

# Les fichiers du dossier

Jusqu'ici, la table `entreprises` était prête. Dans votre travail, vous devrez **lire vos fichiers** : c'est l'équivalent de `PROC IMPORT` ou d'une étape `DATA` avec `INFILE`.

Le dossier `donnees/` contient les **déclarations TVA** de 2025, un fichier par trimestre, chacun livré dans un format différent, et l'emploi déclaré à l'**ONSS**. Le dossier `referentiels/` contient les nomenclatures.

```python
import os
print(sorted(os.listdir("donnees")))
print(sorted(os.listdir("referentiels")))
```

::: note
Dans vos scripts, le chemin part du dossier de travail. Sous Windows, écrivez les chemins avec des `/` (`"G:/Stat/donnees/tva.csv"`) ou précédez-les d'un `r` (`r"G:\Stat\donnees\tva.csv"`).
:::

# Le 1er trimestre : un CSV « à la belge »

Regardons d'abord le fichier brut, comme dans un éditeur de texte :

```python
print(open("donnees/tva_2025_T1.csv", encoding="utf-8").read()[:250])
```

Séparateur `;`, montants écrits `30.491,00` : point des milliers, virgule décimale. Sans précaution :

```python
t1 = pd.read_csv("donnees/tva_2025_T1.csv", sep=";")
t1.dtypes
```

**Lecture :** `chiffre_affaires` est lu comme du **texte** (`str`) : `"30.491,00"` n'est pas un nombre pour Python. Et `nace_tva` est devenu un nombre décimal : `01.11` → `1.11`, le zéro est perdu.

# Les bons réglages

```python
t1 = pd.read_csv("donnees/tva_2025_T1.csv", sep=";",
                 decimal=",", thousands=".",                # montants à la belge
                 dtype={"numero_tva": str, "nace_tva": str})  # codes en texte
print(t1.dtypes)
t1.head(3)
```

| Réglage | Rôle | Symptôme s'il est mal réglé |
|---|---|---|
| `sep` | séparateur de colonnes | une seule colonne lue |
| `decimal`, `thousands` | virgule décimale, point des milliers | nombres lus comme du texte |
| `dtype` | type imposé à une colonne | zéros initiaux perdus (`01.11` → `1.11`) |
| `encoding` | encodage des caractères | erreur `UnicodeDecodeError` ou accents illisibles |
| `skiprows`, `header` | lignes à sauter, ligne des en-têtes | lignes de titre prises pour des données |

::: piege
**Un code n'est jamais un nombre** : NACE, code INS, numéro d'entreprise, code postal. Lisez-les toujours avec `dtype=str`. Un vrai numéro BCE commence par `0` : lu comme un nombre, `0412345678` deviendrait `412345678`.
:::

::: sas
`INFILE ... DLM=';' DSD;` puis un `INFORMAT COMMAX12.` pour les montants à la belge.
:::

# Le 2e trimestre : un classeur Excel

Deux lignes de titre précèdent les en-têtes : `header=2` désigne la troisième ligne (on compte à partir de 0).

```python
t2 = pd.read_excel("donnees/tva_2025_T2.xlsx", header=2,
                   dtype={"numero_tva": str, "nace_tva": str})
print(t2.shape)
t2.head(3)
```

::: note
Même dans Excel, où la cellule contient le texte `01.11`, pandas convertit en nombre tout ce qui en a l'air. `dtype=` l'en empêche.
:::

# Le 3e trimestre : un texte tabulé

```python
t3 = pd.read_csv("donnees/tva_2025_T3.txt", sep="\t",
                 dtype={"numero_tva": str, "nace_tva": str})
t3.head(3)
```

# Le 4e trimestre : un CSV « international »

Séparateur `,` et point décimal : les réglages par défaut de pandas.

```python
t4 = pd.read_csv("donnees/tva_2025_T4.csv", dtype={"numero_tva": str, "nace_tva": str})
t4.head(3)
```

**Lecture :** quatre trimestres, quatre écritures du numéro : `BE9000.019.690`, `9000019690`, `BE 9000 019 690`, ` be9000019690 `. On les harmonisera dans la leçon « Nettoyer une table ».

# Toujours contrôler : shape, dtypes, describe()

```python
for nom, t in [("T1", t1), ("T2", t2), ("T3", t3), ("T4", t4)]:
    print(nom, t.shape, t["chiffre_affaires"].dtype, t["chiffre_affaires"].sum())
```

::: usage
Juste après la lecture : le nombre de lignes est-il plausible ? Les montants sont-ils des nombres (`int64`, `float64`) ? La somme a-t-elle le bon ordre de grandeur ? Une ligne de code évite des heures de recherche plus tard.
:::

# L'encodage : la nomenclature NACE

Le référentiel NACE a été produit sous Windows : il est encodé en **Windows-1252** (`cp1252`). pandas suppose l'UTF-8 et s'arrête au premier caractère accentué. **Erreur volontaire** :

```python erreur
nace = pd.read_csv("referentiels/nace_bel_2008.csv", sep=";")
```

```python
nace = pd.read_csv("referentiels/nace_bel_2008.csv", sep=";", encoding="cp1252",
                   dtype={"classe": str, "division": str})
nace.head(4)
```

::: sas
`FILENAME f "nace_bel_2008.csv" ENCODING="wlatin1";`
:::

# Écrire un résultat

Le chiffre d'affaires du 1er trimestre par division NACE (les deux premiers chiffres), exporté dans `sortie/` :

```python
par_nace = (t1
            .assign(division=lambda t: t["nace_tva"].str.slice(0, 2))
            .groupby("division", as_index=False)
            .agg(declarations=("numero_tva", "count"),
                 ca_t1=("chiffre_affaires", "sum")))

par_nace.to_csv("sortie/tva_t1_divisions.csv", sep=";", decimal=",", index=False, encoding="utf-8")
par_nace.to_excel("sortie/tva_t1_divisions.xlsx", index=False)
par_nace.to_parquet("sortie/tva_t1_divisions.parquet", index=False)
sorted(os.listdir("sortie"))
```

::: usage
`index=False` évite d'écrire une colonne de numéros de ligne. `sep=";", decimal=","` donnent un fichier lisible directement par un Excel belge. Le format **Parquet** garde les types : à préférer pour échanger des tables entre programmes (Python, R, DuckDB, SAS Viya).
:::

# Relire ce qu'on a écrit

Le réflexe, en Python comme en SAS : relire le fichier exporté pour le contrôler.

```python
pd.read_csv("sortie/tva_t1_divisions.csv", sep=";", decimal=",").shape
```
