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

# Écrire deux règles de contrôle
niveau: 1
groupe: Demi-journée 2 · À vous
theme: if, conditions enchaînées

## Énoncé
1. Partez de `ligne = {"annee": 2021, "sexe": "F"}`.
2. Créez une liste vide `anomalies`.
3. Ajoutez `"année hors période"` à la liste si l'année n'est pas comprise entre 2024 et 2026.
4. Ajoutez `"sexe inconnu"` si le sexe n'est ni `"H"` ni `"F"`.
5. Sur la dernière ligne, affichez `anomalies`. Testez aussi avec `{"annee": 2026, "sexe": "f"}`.

## Indice
Python accepte les comparaisons enchaînées : `2024 <= annee <= 2026`. Pour « n'est pas comprise » : `not (...)`.

## Code de départ
```python
ligne = {"annee": 2021, "sexe": "F"}
anomalies = []
```

## Correction
```python
ligne = {"annee": 2021, "sexe": "F"}
anomalies = []
if not 2024 <= ligne["annee"] <= 2026:
    anomalies.append("année hors période")
if ligne["sexe"] not in ("H", "F"):
    anomalies.append("sexe inconnu")
anomalies
```

## Commentaire
Avec 2021, seule la première règle se déclenche. Avec `{"annee": 2026, "sexe": "f"}`, c'est la seconde : Python distingue majuscules et minuscules, `"f"` n'est pas `"F"`.

# Repérer les lignes incohérentes d'un fichier
niveau: 2
groupe: Demi-journée 2 · À vous
theme: for, enumerate, compteur

## Énoncé
Les lignes du fichier wallon sont déjà chargées dans `lignes`.

1. Parcourez `lignes` avec `enumerate()`.
2. Affichez la position, le code INS, la commune et la population de chaque ligne dont la population est **manquante ou négative**.
3. Comptez ces lignes dans `nb` et, sur la dernière ligne, affichez `nb`.

## Indice
Testez d'abord `is None`, puis `< 0` : `if pop is None or pop < 0:`.

## Préparation
```python
from outils_cours import charger_lignes
lignes = charger_lignes("donnees/population_wallonie_2026.txt")
```

## Correction
```python
nb = 0
for position, ligne in enumerate(lignes):
    pop = ligne["population"]
    if pop is None or pop < 0:
        nb += 1
        print(position, ligne["code_ins"], ligne["commune"], pop)
nb
```

## Commentaire
Deux lignes : Martelange (femmes, population négative) et Daverdisse (hommes, population manquante). L'ordre du test compte : avec `pop < 0 or pop is None`, Python comparerait `None < 0` et s'arrêterait sur une erreur `TypeError`.

# Atelier 2 · Étape 1 : un bilan par fichier
niveau: 3
groupe: Atelier 2 · Un premier traitement automatisé
theme: for, règles R1 à R4

## Énoncé
**Objectif de l'atelier** : contrôler les trois fichiers par une même boucle et produire un résultat intermédiaire contrôlable.

Avec une seule boucle sur `fichiers`, appliquez les règles R1 à R4 à chaque ligne et comptez les lignes en anomalie par fichier. Rangez le résultat dans un dictionnaire `bilan` (clé = chemin du fichier, valeur = nombre de lignes en anomalie) et affichez-le sur la dernière ligne.

- **R1** `sexe` vaut H ou F ; **R2** `population` renseignée ; **R3** `population` positive ou nulle ; **R4** `code_ins` de 5 caractères.

## Indice
Initialisez `bilan = {}` avant la boucle des fichiers, et `nb = 0` au début de chaque fichier. Après la boucle des lignes : `bilan[chemin] = nb`.

## Préparation
```python
from outils_cours import charger_lignes
fichiers = ["donnees/population_bruxelles_2026.csv",
            "donnees/population_flandre_2026.xlsx",
            "donnees/population_wallonie_2026.txt"]
```

## Correction
```python
bilan = {}
for chemin in fichiers:
    nb = 0
    for ligne in charger_lignes(chemin):
        pop = ligne["population"]
        if (ligne["sexe"] not in ("H", "F")
                or pop is None or pop < 0
                or len(ligne["code_ins"]) != 5):
            nb += 1
    bilan[chemin] = nb
bilan
```

## Commentaire
Aucune anomalie à Bruxelles ni en Flandre, 4 lignes en anomalie en Wallonie. Ajouter un fichier ne demande qu'une ligne de plus dans la liste `fichiers`.

# Atelier 2 · Étape 2 : collecter les anomalies
niveau: 3
groupe: Atelier 2 · Un premier traitement automatisé
theme: liste de dictionnaires

## Énoncé
Pour chaque anomalie, collectez un dictionnaire dans la liste `anomalies` : `fichier`, `position`, `regle` (par exemple `"R1 sexe"`) et `valeur` contrôlée. Une ligne qui enfreint deux règles produit deux anomalies.

Sur la dernière ligne, affichez le nombre d'anomalies, `len(anomalies)`.

## Indice
Une condition `if` par règle (et non une seule condition avec `or`), chacune suivie d'un `anomalies.append({...})`. Utilisez `enumerate()` pour la position.

## Préparation
```python
from outils_cours import charger_lignes
fichiers = ["donnees/population_bruxelles_2026.csv",
            "donnees/population_flandre_2026.xlsx",
            "donnees/population_wallonie_2026.txt"]
```

## Correction
```python
anomalies = []
for chemin in fichiers:
    for position, ligne in enumerate(charger_lignes(chemin)):
        pop = ligne["population"]
        def noter(regle, valeur):
            anomalies.append({"fichier": chemin, "position": position,
                              "regle": regle, "valeur": valeur})
        if ligne["sexe"] not in ("H", "F"):
            noter("R1 sexe", ligne["sexe"])
        if pop is None:
            noter("R2 population manquante", pop)
        elif pop < 0:
            noter("R3 population négative", pop)
        if len(ligne["code_ins"]) != 5:
            noter("R4 format du code", ligne["code_ins"])
for a in anomalies:
    print(a)
len(anomalies)
```

## Commentaire
Quatre anomalies, toutes en Wallonie, une par règle : Namur (`"f"`), Daverdisse (population manquante), Martelange (population négative) et Liège (`" 62063"`, avec une espace). La correction définit une petite fonction `noter()` pour ne pas répéter quatre fois le même `append` : c'est le sujet de la demi-journée 3.

# Atelier 2 · Étape 3 : les lignes valides, enrichies
niveau: 4
groupe: Atelier 2 · Un premier traitement automatisé
theme: copie de dictionnaire, enrichir

## Énoncé
1. Sélectionnez les lignes **sans anomalie** dans une liste `valides`.
2. Ajoutez à chacune `fichier_source` (le chemin) et `region` : `"Bruxelles"`, `"Flandre"` ou `"Wallonie"`, déduite du nom du fichier.
3. Vérifiez que, pour chaque fichier, lignes lues = lignes valides + lignes en anomalie.
4. Sur la dernière ligne, affichez le nombre de lignes valides.

## Indice
Un dictionnaire de correspondance évite trois `if` : `regions = {"bruxelles": "Bruxelles", ...}`, puis cherchez quelle clé est contenue dans le chemin avec `in`.

## Préparation
```python
from outils_cours import charger_lignes
fichiers = ["donnees/population_bruxelles_2026.csv",
            "donnees/population_flandre_2026.xlsx",
            "donnees/population_wallonie_2026.txt"]
```

## Correction
```python
regions = {"bruxelles": "Bruxelles", "flandre": "Flandre", "wallonie": "Wallonie"}
valides = []
for chemin in fichiers:
    lues = charger_lignes(chemin)
    nb_ko = 0
    for ligne in lues:
        pop = ligne["population"]
        if (ligne["sexe"] not in ("H", "F") or pop is None or pop < 0
                or len(ligne["code_ins"]) != 5):
            nb_ko += 1
            continue
        nouvelle = dict(ligne)
        nouvelle["fichier_source"] = chemin
        for cle, nom in regions.items():
            if cle in chemin:
                nouvelle["region"] = nom
        valides.append(nouvelle)
    nb_ok = sum(1 for v in valides if v["fichier_source"] == chemin)
    print(chemin[8:], len(lues), "=", nb_ok, "+", nb_ko)
len(valides)
```

## Commentaire
1 128 lignes valides : 38 + 571 + 519. `continue` passe directement à la ligne suivante. `dict(ligne)` crée une **copie** : la ligne lue reste intacte.

# Atelier 2 · Étape 4 : exporter les deux tables
niveau: 4
groupe: Atelier 2 · Un premier traitement automatisé
theme: export, contrôle

## Énoncé
Les listes `valides` (étape 3) et `anomalies` (étape 2) sont déjà construites.

1. Exportez-les dans `sortie/lignes_valides.csv` et `sortie/anomalies.csv` (séparateur `;`, sans index) avec `pd.DataFrame(liste).to_csv(...)`.
2. Relisez `sortie/lignes_valides.csv` et, sur la dernière ligne, affichez ses dimensions.

## Indice
`import pandas as pd`, puis `pd.DataFrame(valides).to_csv("sortie/lignes_valides.csv", sep=";", index=False)`.

## Préparation
```python
from outils_cours import charger_lignes
fichiers = ["donnees/population_bruxelles_2026.csv",
            "donnees/population_flandre_2026.xlsx",
            "donnees/population_wallonie_2026.txt"]
regions = {"bruxelles": "Bruxelles", "flandre": "Flandre", "wallonie": "Wallonie"}
valides, anomalies = [], []
for chemin in fichiers:
    for position, ligne in enumerate(charger_lignes(chemin)):
        pop = ligne["population"]
        regles = []
        if ligne["sexe"] not in ("H", "F"):
            regles.append(("R1 sexe", ligne["sexe"]))
        if pop is None:
            regles.append(("R2 population manquante", pop))
        elif pop < 0:
            regles.append(("R3 population négative", pop))
        if len(ligne["code_ins"]) != 5:
            regles.append(("R4 format du code", ligne["code_ins"]))
        for regle, valeur in regles:
            anomalies.append({"fichier": chemin, "position": position,
                              "regle": regle, "valeur": valeur})
        if not regles:
            nouvelle = dict(ligne, fichier_source=chemin)
            nouvelle["region"] = [n for c, n in regions.items() if c in chemin][0]
            valides.append(nouvelle)
```

## Correction
```python
import pandas as pd

pd.DataFrame(valides).to_csv("sortie/lignes_valides.csv", sep=";", index=False)
pd.DataFrame(anomalies).to_csv("sortie/anomalies.csv", sep=";", index=False)
relu = pd.read_csv("sortie/lignes_valides.csv", sep=";")
relu.shape
```

## Commentaire
1 128 lignes et 7 colonnes : les 5 colonnes d'origine, plus `fichier_source` et `region`.

**Pour aller plus loin**
- Comptez les anomalies par règle dans un dictionnaire `{"R1 sexe": 1, ...}`.
- Détectez le doublon de Flandre : mémorisez chaque clé `(code_ins, sexe)` dans un ensemble de tuples et signalez une clé déjà vue.
- Listez les fichiers automatiquement : `sorted(str(p) for p in Path("donnees").glob("population_*_2026.*"))`, après `from pathlib import Path`.
