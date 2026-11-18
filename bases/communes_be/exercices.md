---
base: communes_be
---

# Calculer la part des femmes à Namur
niveau: 1
groupe: Demi-journée 1 · À vous
theme: opérateurs, round()

## Énoncé
Au 1er janvier 2026, Namur compte 56 248 hommes et 59 209 femmes.

1. Créez les variables `hommes` et `femmes`.
2. Calculez la population totale.
3. Affichez `True` si les femmes sont plus nombreuses que les hommes.
4. Calculez la part des femmes en %, arrondie à 2 décimales, et écrivez-la **seule sur la dernière ligne** : c'est elle qui est vérifiée.

## Indice
`round(valeur, 2)` arrondit à 2 décimales. La part en % : `femmes / total * 100`.

## Code de départ
```python
hommes = 56248
femmes = 59209
```

## Correction
```python
hommes = 56248
femmes = 59209
total = hommes + femmes
print(total)
print(femmes > hommes)
part_femmes = round(femmes / total * 100, 2)
part_femmes
```

## Commentaire
Namur compte 115 457 habitants, dont 51,28 % de femmes. Écrire `round(100 * femmes / total, 2)` donne le même résultat : l'ordre des multiplications ne change rien.

# Les grandes villes dans un dictionnaire
niveau: 1
groupe: Demi-journée 1 · À vous
theme: dictionnaire

## Énoncé
1. Créez `pop = {"Bruxelles": 198674, "Anvers": 565615, "Gand": 274042}` (population au 1er janvier 2026).
2. Affichez la population de Gand.
3. Ajoutez Charleroi, avec 206 900 habitants.
4. Sur la dernière ligne, calculez le total des quatre villes avec `sum(pop.values())`.

## Indice
On ajoute une clé comme on modifie une valeur : `pop["Charleroi"] = 206900`.

## Code de départ
```python
pop = {"Bruxelles": 198674, "Anvers": 565615, "Gand": 274042}
```

## Correction
```python
pop = {"Bruxelles": 198674, "Anvers": 565615, "Gand": 274042}
print(pop["Gand"])
pop["Charleroi"] = 206900
sum(pop.values())
```

## Commentaire
Les quatre villes comptent 1 245 231 habitants. « Bruxelles » désigne ici la **commune** de Bruxelles (198 674 habitants), pas la Région de Bruxelles-Capitale, qui en compte 1 255 834 : un libellé ne suffit pas, c'est le code INS qui identifie un territoire (21004 pour la commune, 04000 pour la région).

# Découper un code INS et une date
niveau: 1
groupe: Demi-journée 1 · À vous
theme: slicing

## Énoncé
Le code INS de Bastogne est `"82039"` : son premier chiffre désigne la province, ses deux premiers l'arrondissement.

1. Extrayez par slicing le code de la province, puis celui de l'arrondissement, et affichez-les.
2. Sur la dernière ligne, extrayez l'année de la chaîne `"2026-01-01"`.

## Indice
`texte[:2]` donne les deux premiers caractères.

## Correction
```python
code_ins = "82039"
print(code_ins[:1], code_ins[:2])
date_texte = "2026-01-01"
date_texte[:4]
```

## Commentaire
Bastogne est dans la province 8 (Luxembourg, code 80000) et l'arrondissement 82 (Bastogne, code 82000). L'année obtenue est du **texte**, `"2026"` : `int(date_texte[:4])` la convertirait en nombre.

# Un mauvais séparateur, puis le bon
niveau: 2
groupe: Demi-journée 1 · À vous
theme: read_csv, sep

## Énoncé
1. Lisez `donnees/population_communes_2026.csv` avec `sep=","` (volontairement faux) et affichez `.shape`. Que constatez-vous ?
2. Corrigez le séparateur.
3. Sur la dernière ligne, affichez `.shape` du tableau bien lu : vous devez obtenir 565 lignes et 5 colonnes.

## Indice
Ouvrez le fichier dans votre tête : `code_ins;commune;hommes;femmes;total`. Quel caractère sépare les colonnes ?

## Code de départ
```python
import pandas as pd

faux = pd.read_csv("donnees/population_communes_2026.csv", sep=",",
                   dtype_backend="pyarrow")
print(faux.shape)
```

## Correction
```python
import pandas as pd

faux = pd.read_csv("donnees/population_communes_2026.csv", sep=",",
                   dtype_backend="pyarrow")
print(faux.shape)
pop = pd.read_csv("donnees/population_communes_2026.csv", sep=";",
                  dtype_backend="pyarrow")
pop.shape
```

## Commentaire
Avec `sep=","`, pandas ne trouve qu'une colonne : `(565, 1)`. Une dimension inattendue est le premier signal d'un paramètre mal réglé.

# Le type des colonnes du fichier Statbel
niveau: 2
groupe: Demi-journée 1 · À vous
theme: read_csv, dtypes, thousands

## Énoncé
1. Lisez `donnees/population_2026.txt` (tabulé) **sans** `thousands="."` et affichez `.dtypes` : quel est le type de la colonne `Total` ?
2. Relisez-le avec `thousands="."` et `skiprows=[1, 2]`.
3. Sur la dernière ligne, écrivez la population totale de la Belgique : la valeur de la colonne `Total` sur la première ligne, `brut["Total"][0]`.

## Indice
Le séparateur est la tabulation, `sep="\t"`. Avec `skiprows=[1, 2]`, la ligne de la Belgique devient la ligne 0.

## Correction
```python
import pandas as pd

brut = pd.read_csv("donnees/population_2026.txt", sep="\t",
                   dtype_backend="pyarrow")
print(brut.dtypes)
brut = pd.read_csv("donnees/population_2026.txt", sep="\t",
                   skiprows=[1, 2], thousands=".",
                   dtype_backend="pyarrow")
print(brut.dtypes)
brut["Total"][0]
```

## Commentaire
Sans `thousands="."`, `Total` est du texte (`string[pyarrow]`) : `"11.867.634"` contient deux points, ce n'est pas un nombre. Avec le paramètre, la colonne devient un entier (`int64[pyarrow]`) et la Belgique compte 11 867 634 habitants.

# Atelier 1 · Étape 1 : importer les quatre fichiers
niveau: 3
groupe: Atelier 1 · Premier contact avec les données
theme: read_csv, read_excel

## Énoncé
**Objectif de l'atelier** : importer les fichiers de Statbel, vérifier leur structure, réaliser de premiers calculs et exporter un extrait.

Importez les quatre fichiers avec les bons paramètres :

- `pop` : `donnees/population_communes_2026.csv`, en gardant `code_ins` en texte ;
- `brut` : `donnees/population_2026.txt` ;
- `prov` : `donnees/population_provinces_2026.xlsx` ;
- `ref` : `referentiels/nuts_lau_2027.txt`.

Vérifiez la structure de chaque table (`.shape`, `.columns`, `.dtypes`). Sur la dernière ligne, écrivez la liste de leurs dimensions : `[pop.shape, brut.shape, prov.shape, ref.shape]`.

## Indice
Reprenez les paramètres de la leçon « Lire et exporter des fichiers » : `sep`, `encoding`, `skiprows`, `thousands`, `header`, `dtype`.

## Code de départ
```python
import pandas as pd

pop = pd.read_csv(...)
```

## Correction
```python
import pandas as pd

pop = pd.read_csv("donnees/population_communes_2026.csv", sep=";",
                  dtype={"code_ins": str}, dtype_backend="pyarrow")
brut = pd.read_csv("donnees/population_2026.txt", sep="\t",
                   skiprows=[1, 2], thousands=".",
                   dtype={" Code INS": str}, dtype_backend="pyarrow")
prov = pd.read_excel("donnees/population_provinces_2026.xlsx", header=2,
                     dtype={"code_ins": str}, dtype_backend="pyarrow")
ref = pd.read_csv("referentiels/nuts_lau_2027.txt", sep="|",
                  encoding="latin-1", dtype_backend="pyarrow")
print(pop.dtypes)
[pop.shape, brut.shape, prov.shape, ref.shape]
```

## Commentaire
Dimensions attendues : 565 × 5, 622 × 5, 11 × 5 et 919 × 10. Si vous trouvez 624 lignes pour `brut`, les deux lignes vides sont restées : ajoutez `skiprows=[1, 2]`.

# Atelier 1 · Étape 2 : une commune dans un dictionnaire
niveau: 3
groupe: Atelier 1 · Premier contact avec les données
theme: dictionnaire, calcul

## Énoncé
Affichez la ligne d'Arlon (code INS 81001) avec `pop[pop["code_ins"] == "81001"]` (filtre fourni : cette syntaxe sera expliquée en demi-journée 4).

1. Saisissez dans un dictionnaire `arlon` les populations lues à l'écran, avec les clés `"hommes"` et `"femmes"`.
2. Calculez la population totale d'Arlon.
3. Sur la dernière ligne, calculez la part des **hommes** en %, arrondie à 1 décimale.

## Indice
La part : `arlon["hommes"] / total * 100`, puis `round(..., 1)`.

## Préparation
```python
import pandas as pd
pop = pd.read_csv("donnees/population_communes_2026.csv", sep=";",
                  dtype={"code_ins": str}, dtype_backend="pyarrow")
```

## Code de départ
```python
pop[pop["code_ins"] == "81001"]
```

## Correction
```python
print(pop[pop["code_ins"] == "81001"])
arlon = {"hommes": 15647, "femmes": 15793}
total = arlon["hommes"] + arlon["femmes"]
print(total)
round(arlon["hommes"] / total * 100, 1)
```

## Commentaire
Arlon compte 31 440 habitants, dont 49,8 % d'hommes. Recopier des chiffres lus à l'écran est fragile : dès la demi-journée 4, on calculera directement sur la colonne.

# Atelier 1 · Étape 3 : comparer les codes à ceux du référentiel
niveau: 4
groupe: Atelier 1 · Premier contact avec les données
theme: set, différence d'ensembles

## Énoncé
1. Obtenez l'ensemble des codes INS des communes de `pop` avec `set(pop["code_ins"])` : combien y en a-t-il ?
2. Obtenez l'ensemble des codes INS du référentiel : `set(ref["CD_MUNTY_REFNIS"])`.
3. Sur la dernière ligne, comptez les codes du référentiel **absents** de `pop`, avec une différence d'ensembles : `len(a - b)`.

## Indice
`a - b` donne les éléments de `a` qui ne sont pas dans `b`. Les deux tables sont déjà chargées : regardez « Code déjà exécuté avant le vôtre ».

## Préparation
```python
import pandas as pd
pop = pd.read_csv("donnees/population_communes_2026.csv", sep=";",
                  dtype={"code_ins": str}, dtype_backend="pyarrow")
ref = pd.read_csv("referentiels/nuts_lau_2027.txt", sep="|",
                  encoding="latin-1", dtype_backend="pyarrow")
```

## Correction
```python
codes_pop = set(pop["code_ins"])
codes_ref = set(ref["CD_MUNTY_REFNIS"])
print(len(codes_pop), len(codes_ref))
print(len(codes_pop - codes_ref))     # communes absentes du référentiel
len(codes_ref - codes_pop)
```

## Commentaire
Les 565 communes de 2026 sont toutes dans le référentiel. Dans l'autre sens, 113 codes du référentiel n'ont pas de population : les régions, provinces et arrondissements, le tiret `-` des territoires sans code INS, et surtout les **anciennes communes**, disparues lors des fusions de 2019 et de 2025.

Essayez de relire `pop` **sans** `dtype={"code_ins": str}` : la différence passe à 678, car les codes sont alors des nombres (`11001`) et ne correspondent plus aux textes du référentiel (`"11001"`).

# Atelier 1 · Étape 4 : exporter un extrait et le relire
niveau: 4
groupe: Atelier 1 · Premier contact avec les données
theme: to_csv, contrôle

## Énoncé
Le filtre ci-dessous (fourni, expliqué en demi-journée 4) garde les communes de l'arrondissement de Liège, dont le code INS commence par `62` :

```python
extrait = pop[pop["code_ins"].str.startswith("62")]
```

1. Exportez `extrait` dans `sortie/extrait_arrondissement_liege.csv`, séparateur `;`, sans index.
2. Relisez le fichier exporté.
3. Sur la dernière ligne, affichez les dimensions du fichier relu.

## Indice
`extrait.to_csv(chemin, sep=";", index=False)`, puis `pd.read_csv(chemin, sep=";")`.

## Préparation
```python
import pandas as pd
pop = pd.read_csv("donnees/population_communes_2026.csv", sep=";",
                  dtype={"code_ins": str}, dtype_backend="pyarrow")
```

## Code de départ
```python
extrait = pop[pop["code_ins"].str.startswith("62")]
```

## Correction
```python
extrait = pop[pop["code_ins"].str.startswith("62")]
extrait.to_csv("sortie/extrait_arrondissement_liege.csv", sep=";",
               index=False, encoding="utf-8")
relu = pd.read_csv("sortie/extrait_arrondissement_liege.csv", sep=";",
                   dtype_backend="pyarrow")
relu.shape
```

## Commentaire
L'arrondissement de Liège compte 24 communes : le fichier relu a 24 lignes et 5 colonnes. Relire un fichier exporté est un contrôle simple qui évite d'envoyer un fichier vide ou tronqué.

**Pour aller plus loin** : exportez le même extrait au format Excel (`.to_excel()`) et relisez-le ; lisez seulement deux colonnes avec `usecols=["code_ins", "total"]`.
