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
                  encoding="cp1252", dtype_backend="pyarrow")
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
                  encoding="cp1252", dtype_backend="pyarrow")
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

# Écrire la fonction harmoniser_sexe()
niveau: 2
groupe: Demi-journée 3 · À vous
theme: def, return, None

## Énoncé
1. Écrivez `harmoniser_sexe(valeur)` qui renvoie `"H"` ou `"F"` quels que soient la casse et les espaces (`" f"`, `"h "`).
2. Elle renvoie `None` pour une valeur manquante ou non reconnue.
3. Sur la dernière ligne, testez-la sur quatre valeurs : `[harmoniser_sexe(v) for v in ["f", " H ", "x", None]]`.

## Indice
Traitez d'abord le cas `None` (avec `return None`), puis utilisez `.strip().upper()`.

## Code de départ
```python
def harmoniser_sexe(valeur):
    ...

[harmoniser_sexe(v) for v in ["f", " H ", "x", None]]
```

## Correction
```python
def harmoniser_sexe(valeur):
    """Renvoie 'H' ou 'F', ou None si la valeur n'est pas reconnue."""
    if valeur is None:
        return None
    valeur = valeur.strip().upper()
    if valeur in ("H", "F"):
        return valeur
    return None

[harmoniser_sexe(v) for v in ["f", " H ", "x", None]]
```

## Commentaire
Résultat attendu : `['F', 'H', None, None]`. La dernière ligne est une *liste en compréhension* : elle applique la fonction à chaque valeur, comme une boucle `for` qui remplirait une liste.

# Écrire la fonction ecrire_resultat()
niveau: 2
groupe: Demi-journée 3 · À vous
theme: def, export

## Énoncé
1. Écrivez `ecrire_resultat(lignes, chemin)` qui exporte une liste de dictionnaires en CSV séparé par `;` et renvoie le **nombre de lignes écrites**.
2. Recette : `pd.DataFrame(lignes).to_csv(chemin, sep=";", index=False)`.
3. Sur la dernière ligne, appelez-la sur les lignes valides de Wallonie (déjà calculées dans `valides`) avec le chemin `sortie/valides_wallonie.csv`.

## Indice
`return len(lignes)` après l'export.

## Préparation
```python
import pandas as pd
from outils_cours import charger_lignes, harmoniser_code, harmoniser_sexe
valides = []
for ligne in charger_lignes("donnees/population_wallonie_2026.txt"):
    ligne = dict(ligne, code_ins=harmoniser_code(ligne["code_ins"]),
                 sexe=harmoniser_sexe(ligne["sexe"]))
    if ligne["population"] is not None and ligne["population"] >= 0:
        valides.append(ligne)
```

## Correction
```python
def ecrire_resultat(lignes, chemin):
    """Exporte des lignes en CSV (;) et renvoie le nombre de lignes écrites."""
    pd.DataFrame(lignes).to_csv(chemin, sep=";", index=False)
    return len(lignes)

ecrire_resultat(valides, "sortie/valides_wallonie.csv")
```

## Commentaire
521 lignes écrites. Pour contrôler, relisez le fichier : `pd.read_csv("sortie/valides_wallonie.csv", sep=";").shape`.

# Atelier 3 · Étape 1 : transformer_ligne()
niveau: 3
groupe: Atelier 3 · Un traitement réutilisable
theme: def, date

## Énoncé
**Objectif de l'atelier** : construire un traitement dont les mêmes fonctions s'appliquent aux trois fichiers.

Écrivez `transformer_ligne(ligne)`, qui renvoie une **copie** de la ligne avec deux champs en plus :

- `date_reference` : le 1er janvier de l'année (`date(annee, 1, 1)`) ;
- `taille` : `"petite"` si la population (de ce sexe) est inférieure à 5 000, `"grande"` sinon.

Sur la dernière ligne, appliquez-la à `{"code_ins": "62063", "commune": "Liège", "annee": 2026, "sexe": "H", "population": 98484}`.

## Indice
`nouvelle = dict(ligne)`, deux affectations, `return nouvelle`. Pour `taille`, un `if` ou l'écriture courte `"petite" if ... else "grande"`.

## Préparation
```python
from datetime import date
```

## Code de départ
```python
def transformer_ligne(ligne):
    nouvelle = dict(ligne)
    nouvelle["date_reference"] = ...
    nouvelle["taille"] = ...
    return nouvelle
```

## Correction
```python
def transformer_ligne(ligne):
    """Copie de la ligne avec date_reference et taille."""
    nouvelle = dict(ligne)
    nouvelle["date_reference"] = date(ligne["annee"], 1, 1)
    if ligne["population"] < 5000:
        nouvelle["taille"] = "petite"
    else:
        nouvelle["taille"] = "grande"
    return nouvelle

transformer_ligne({"code_ins": "62063", "commune": "Liège", "annee": 2026,
                   "sexe": "H", "population": 98484})
```

## Commentaire
La ligne d'origine n'est pas modifiée : `transformer_ligne()` travaille sur une copie. On n'appelle cette fonction que sur des lignes **déjà contrôlées** : sur une population manquante, `None < 5000` provoquerait une erreur.

# Atelier 3 · Étape 2 : traiter_fichier() sur les trois fichiers
niveau: 4
groupe: Atelier 3 · Un traitement réutilisable
theme: enchaîner des fonctions, assert

## Énoncé
Les fonctions `harmoniser_ligne()`, `controler_ligne()` et `transformer_ligne()` sont déjà définies.

1. Écrivez `traiter_fichier(chemin)` : charger, harmoniser puis contrôler chaque ligne ; les lignes rejetées vont dans `rejets`, les autres sont transformées puis vont dans `valides`. La fonction renvoie `valides, rejets`.
2. Vérifiez par `assert`, pour chaque fichier, qu'aucune ligne n'est perdue.
3. Sur la dernière ligne, affichez la liste des bilans `[(len(valides), len(rejets)), ...]` pour les trois fichiers, dans l'ordre de `fichiers`.

## Indice
Le plan : initialiser `valides, rejets = [], []` ; parcourir `charger_lignes(chemin)` ; harmoniser ; `if controler_ligne(ligne):` → rejet ; sinon transformer et ajouter ; `return valides, rejets`.

## Préparation
```python
from datetime import date
from outils_cours import charger_lignes, harmoniser_code, harmoniser_sexe
fichiers = ["donnees/population_bruxelles_2026.csv",
            "donnees/population_flandre_2026.xlsx",
            "donnees/population_wallonie_2026.txt"]

def harmoniser_ligne(ligne):
    nouvelle = dict(ligne)
    nouvelle["code_ins"] = harmoniser_code(ligne["code_ins"])
    nouvelle["sexe"] = harmoniser_sexe(ligne["sexe"])
    return nouvelle

def controler_ligne(ligne):
    anomalies = []
    if ligne["sexe"] not in ("H", "F"):
        anomalies.append("R1 sexe")
    if ligne["population"] is None:
        anomalies.append("R2 population manquante")
    elif ligne["population"] < 0:
        anomalies.append("R3 population négative")
    if len(ligne["code_ins"]) != 5:
        anomalies.append("R4 format du code")
    return anomalies

def transformer_ligne(ligne):
    nouvelle = dict(ligne)
    nouvelle["date_reference"] = date(ligne["annee"], 1, 1)
    nouvelle["taille"] = "petite" if ligne["population"] < 5000 else "grande"
    return nouvelle
```

## Code de départ
```python
# Plan de traiter_fichier(chemin) :
# 1. Initialiser valides et rejets.
# 2. Parcourir charger_lignes(chemin).
# 3. Harmoniser, puis contrôler chaque ligne.
# 4. Ajouter les lignes rejetées à rejets.
# 5. Transformer les autres lignes, puis les ajouter à valides.
# 6. Renvoyer valides, rejets.
```

## Correction
```python
def traiter_fichier(chemin):
    """Charge, harmonise, contrôle et transforme un fichier."""
    valides, rejets = [], []
    for ligne in charger_lignes(chemin):
        ligne = harmoniser_ligne(ligne)
        if controler_ligne(ligne):
            rejets.append(ligne)
        else:
            valides.append(transformer_ligne(ligne))
    return valides, rejets

bilans = []
for chemin in fichiers:
    valides, rejets = traiter_fichier(chemin)
    assert len(valides) + len(rejets) == len(charger_lignes(chemin)), "lignes perdues"
    bilans.append((len(valides), len(rejets)))
bilans
```

## Commentaire
Bilan attendu : `[(38, 0), (571, 0), (521, 2)]`. Les deux rejets sont Daverdisse (population manquante) et Martelange (population négative) ; le code `" 62063"` et le sexe `"f"` sont **corrigés**, pas rejetés.

**Pour aller plus loin**
- Écrivez votre propre version de `charger_lignes()` à partir des recettes de la demi-journée 1.
- Ajoutez un paramètre `seuil_min=0` à `controler_ligne()` pour paramétrer la règle R3.
- Tenez un journal : un dictionnaire qui compte les rejets par règle et par fichier.
- Signalez le doublon de Flandre avec un ensemble de clés `(code_ins, sexe)` déjà vues.

# Inspecter la table brute
niveau: 2
groupe: Demi-journée 4 · À vous
theme: info, describe, unique

## Énoncé
La table `brut` est déjà chargée.

1. Combien de lignes et de colonnes compte `brut` ?
2. Quelle colonne contient des valeurs manquantes, et combien ?
3. Quelles modalités prend `sexe` ?
4. Sur la dernière ligne, affichez la plus petite population. Que signifie-t-elle ?

## Indice
`.shape`, `.info()` (ou `.isna().sum()`), `.unique()`, puis `brut["population"].min()`.

## Préparation
```python
import pandas as pd
brut = pd.read_parquet("donnees/population_brut.parquet", dtype_backend="pyarrow")
```

## Correction
```python
print(brut.shape)
print(brut.isna().sum())
print(brut["sexe"].unique().tolist())
brut["population"].min()
```

## Commentaire
1 132 lignes et 6 colonnes ; une population manquante ; trois modalités pour `sexe` (`"H"`, `"F"` et `"f"`). Le minimum, -1 059, est impossible : c'est une erreur de saisie (Martelange, femmes) à écarter et à signaler.

# Nettoyer une région
niveau: 2
groupe: Demi-journée 4 · À vous
theme: filtrer, isna, str

## Énoncé
1. À partir de `brut`, gardez uniquement la Wallonie dans `wal`.
2. Comptez les lignes dont la population est manquante, puis celles dont elle est négative.
3. Créez `nettoye_wal` sans ces lignes, et harmonisez `sexe` avec `.str.strip().str.upper()`.
4. Vérifiez que `sexe` ne prend plus que les valeurs H et F. Sur la dernière ligne, affichez le nombre de lignes de `nettoye_wal`.

## Indice
`wal["population"].isna().sum()` ; `(wal["population"] < 0).sum()`. Pour garder les populations renseignées et positives : `wal[wal["population"].notna() & (wal["population"] >= 0)]`.

## Préparation
```python
import pandas as pd
brut = pd.read_parquet("donnees/population_brut.parquet", dtype_backend="pyarrow")
```

## Correction
```python
wal = brut[brut["region"] == "Wallonie"]
print(wal["population"].isna().sum(), (wal["population"] < 0).sum())
nettoye_wal = wal[wal["population"].notna() & (wal["population"] >= 0)].copy()
nettoye_wal["sexe"] = nettoye_wal["sexe"].str.strip().str.upper()
print(nettoye_wal["sexe"].unique().tolist())
len(nettoye_wal)
```

## Commentaire
Une population manquante et une négative : il reste 521 lignes sur 523. `.copy()` évite l'avertissement de pandas quand on modifie une table extraite d'une autre.

# Atelier 4 · Étape 1 : inspecter et filtrer
niveau: 3
groupe: Atelier 4 · Produire une table nettoyée
theme: inspection, filtre

## Énoncé
**Objectif de l'atelier** : produire une table nettoyée, documentée par un bilan chiffré, à partir de `donnees/population_brut.parquet`.

1. Importez le fichier dans `brut` et inspectez-le : `shape`, `info()`, `describe()`, `unique()`.
2. Extrayez dans `namur_arr` les lignes de l'arrondissement de Namur : code INS commençant par `92`.
3. Sur la dernière ligne, affichez les dimensions de `namur_arr`.

## Indice
`brut["code_ins"].str.startswith("92")` donne une Series de booléens, à placer entre crochets.

## Code de départ
```python
import pandas as pd

brut = pd.read_parquet(...)
```

## Correction
```python
import pandas as pd

brut = pd.read_parquet("donnees/population_brut.parquet", dtype_backend="pyarrow")
print(brut.shape)
brut.info()
print(brut["sexe"].unique().tolist())
namur_arr = brut[brut["code_ins"].str.startswith("92")]
namur_arr.shape
```

## Commentaire
L'arrondissement de Namur compte 16 communes, soit 32 lignes (hommes et femmes). La ligne de Namur écrite `"f"` y est bien : le filtre porte sur le code, pas sur le sexe.

# Atelier 4 · Étape 2 : doublons, harmonisation et rejets
niveau: 4
groupe: Atelier 4 · Produire une table nettoyée
theme: drop_duplicates, map, rejets

## Énoncé
1. Supprimez les doublons de `brut` dans une nouvelle table `df` (gardez la première occurrence).
2. Harmonisez `code_ins` avec `.map(harmoniser_code)` et `sexe` avec `.str`.
3. Règle donnée : une population manquante ou négative fait **écarter** la ligne, qui va dans une table `rejets`.
4. Sur la dernière ligne, affichez `(len(df), len(rejets))`.

## Indice
Calculez d'abord le masque des lignes à rejeter : `a_rejeter = df["population"].isna() | (df["population"] < 0)`. Puis `rejets = df[a_rejeter]` et `df = df[~a_rejeter]`.

## Préparation
```python
import pandas as pd
from outils_cours import harmoniser_code
brut = pd.read_parquet("donnees/population_brut.parquet", dtype_backend="pyarrow")
```

## Correction
```python
df = brut.drop_duplicates().copy()
df["code_ins"] = df["code_ins"].map(harmoniser_code)
df["sexe"] = df["sexe"].str.strip().str.upper()
a_rejeter = df["population"].isna() | (df["population"] < 0)
rejets = df[a_rejeter]
df = df[~a_rejeter].copy()
print(rejets[["code_ins", "commune", "sexe", "population"]])
(len(df), len(rejets))
```

## Commentaire
1 132 lignes lues, 1 doublon supprimé, 2 lignes rejetées : il en reste 1 129. Attention : `isna() | (... < 0)` fonctionne car une comparaison avec une valeur manquante donne `<NA>`, que `|` combine correctement avec `True`.

# Atelier 4 · Étape 3 : types, variables et export
niveau: 4
groupe: Atelier 4 · Produire une table nettoyée
theme: astype, to_datetime, to_parquet

## Énoncé
La table nettoyée `df` (étape 2) est prête.

1. Convertissez `population` en `int64[pyarrow]` et créez `date_reference` (1er janvier de `annee`) avec `pd.to_datetime()`.
2. Créez `pop_milliers`, la population en milliers arrondie à 2 décimales.
3. Exportez la table dans `sortie/population_nettoyee.parquet` (sans index), puis relisez-la.
4. Sur la dernière ligne, affichez les dimensions du fichier relu.

## Indice
`df["annee"].astype(str) + "-01-01"` construit le texte de la date ; `df.to_parquet(chemin, index=False)` ; `pd.read_parquet(chemin)`.

## Préparation
```python
import pandas as pd
from outils_cours import harmoniser_code
brut = pd.read_parquet("donnees/population_brut.parquet", dtype_backend="pyarrow")
df = brut.drop_duplicates().copy()
df["code_ins"] = df["code_ins"].map(harmoniser_code)
df["sexe"] = df["sexe"].str.strip().str.upper()
a_rejeter = df["population"].isna() | (df["population"] < 0)
rejets = df[a_rejeter]
df = df[~a_rejeter].copy()
```

## Correction
```python
df["population"] = df["population"].astype("int64[pyarrow]")
df["date_reference"] = pd.to_datetime(df["annee"].astype(str) + "-01-01")
df["pop_milliers"] = (df["population"] / 1000).round(2)
df.to_parquet("sortie/population_nettoyee.parquet", index=False)
rejets.to_csv("sortie/rejets.csv", sep=";", index=False)
relu = pd.read_parquet("sortie/population_nettoyee.parquet", dtype_backend="pyarrow")
print(relu.dtypes)
relu.shape
```

## Commentaire
1 129 lignes et 8 colonnes, mêmes types après relecture : c'est l'intérêt du Parquet. La table est **nettoyée, pas complète** : Daverdisse et Martelange n'ont plus qu'une ligne sur deux. On le contrôlera en demi-journée 5.

**Pour aller plus loin**
- Écrivez `nettoyer(df)` qui renvoie la table nettoyée, les rejets et le bilan.
- Ajoutez aux rejets une colonne `motif` : « population manquante » ou « population négative ».
- Comparez avec les sorties de l'atelier 3 : quelle différence, et pourquoi ? (indice : le doublon de Gand).

# Des agrégats par région et par sexe
niveau: 2
groupe: Demi-journée 5 · À vous
theme: groupby, agg

## Énoncé
La table nettoyée `propre` est chargée.

1. Calculez la population totale par région, triée par ordre décroissant.
2. Calculez, pour chaque région, la population des femmes et la population totale.
3. Sur la dernière ligne, affichez la part des femmes par région, en %, arrondie à 1 décimale.

## Indice
Filtrez les femmes **avant** de regrouper : `propre[propre["sexe"] == "F"].groupby("region")["population"].sum()`. Deux Series qui ont le même index (les régions) se divisent directement.

## Préparation
```python
import pandas as pd
propre = pd.read_parquet("donnees/population_nettoyee.parquet", dtype_backend="pyarrow")
```

## Correction
```python
total = propre.groupby("region")["population"].sum()
print(total.sort_values(ascending=False))
femmes = propre[propre["sexe"] == "F"].groupby("region")["population"].sum()
(femmes / total * 100).round(1)
```

## Commentaire
51,0 % de femmes à Bruxelles et en Wallonie, 50,5 % en Flandre. La Flandre est de loin la région la plus peuplée : 6,9 millions d'habitants.

# Repérer ce qui n'est pas apparié
niveau: 3
groupe: Demi-journée 5 · À vous
theme: merge, indicator

## Énoncé
La table `propre` et la table `en_vigueur` (les communes en vigueur de la nomenclature, avec `code_ins` et `nuts3`) sont chargées.

1. Joignez `propre` à `en_vigueur` avec `how="inner"`, puis `how="left"` : comparez le nombre de lignes.
2. Avec `indicator=True`, listez sur la dernière ligne les codes INS non appariés.

## Indice
`controle["_merge"] == "left_only"`, puis `.unique().tolist()` sur la colonne `code_ins`.

## Préparation
```python
import pandas as pd
propre = pd.read_parquet("donnees/population_nettoyee.parquet", dtype_backend="pyarrow")
ref = pd.read_csv("referentiels/nuts_lau_2027.txt", sep="|", encoding="cp1252",
                  dtype_backend="pyarrow")
en_vigueur = (ref[(ref["CD_LVL"] == 4) & (ref["DT_VLDT_STOP"] == "31/12/9999")]
              .rename(columns={"CD_MUNTY_REFNIS": "code_ins", "CD_LVL_SUP": "nuts3"})
              [["code_ins", "nuts3"]])
```

## Correction
```python
print(len(propre.merge(en_vigueur, on="code_ins", how="inner")),
      len(propre.merge(en_vigueur, on="code_ins", how="left")))
controle = propre.merge(en_vigueur, on="code_ins", how="left",
                        indicator=True, validate="many_to_one")
controle.loc[controle["_merge"] == "left_only", "code_ins"].unique().tolist()
```

## Commentaire
1 128 lignes avec `inner`, 1 129 avec `left` : la ligne de la commune « 99999 » n'existe pas dans la nomenclature. Elle doit être signalée à la source des données, pas supprimée en silence.

# Atelier de synthèse · Étape 1 : importer et empiler
niveau: 3
groupe: Atelier de synthèse · Consolidation complète
theme: read_*, concat

## Énoncé
**Objectif de l'atelier** : enchaîner toutes les étapes de la formation, des fichiers bruts au fichier consolidé.

1. Importez les trois fichiers régionaux avec les bons paramètres (`code_ins` en texte), et ajoutez à chacun une colonne `region`.
2. Empilez-les dans `empile` et contrôlez la structure : colonnes, types, nombre de lignes.
3. Sur la dernière ligne, affichez `(len(empile), empile["region"].nunique())`.

## Indice
`bxl["region"] = "Bruxelles"` ajoute une colonne constante. `pd.concat([bxl, fla, wal], ignore_index=True)`.

## Correction
```python
import pandas as pd

bxl = pd.read_csv("donnees/population_bruxelles_2026.csv", sep=";",
                  dtype={"code_ins": str}, dtype_backend="pyarrow")
fla = pd.read_excel("donnees/population_flandre_2026.xlsx", header=2,
                    dtype={"code_ins": str}, dtype_backend="pyarrow")
wal = pd.read_csv("donnees/population_wallonie_2026.txt", sep="\t",
                  dtype={"code_ins": str}, dtype_backend="pyarrow")
bxl["region"] = "Bruxelles"
fla["region"] = "Flandre"
wal["region"] = "Wallonie"
empile = pd.concat([bxl, fla, wal], ignore_index=True)
print(empile.dtypes)
(len(empile), empile["region"].nunique())
```

## Commentaire
1 132 lignes (38 + 571 + 523) et 3 régions : c'est exactement le contenu de `population_brut.parquet`.

# Atelier de synthèse · Étape 2 : nettoyer et fusionner
niveau: 4
groupe: Atelier de synthèse · Consolidation complète
theme: nettoyage, merge, contrôles

## Énoncé
`empile` est prêt (étape 1), ainsi que `en_vigueur` (les communes en vigueur de la nomenclature).

1. Nettoyez avec les règles des ateliers 3 et 4 : doublons, `code_ins` et `sexe` harmonisés, populations manquantes ou négatives écartées.
2. Joignez `en_vigueur` (`how="left"`, `indicator=True`, `validate="many_to_one"`).
3. Vérifiez que la jointure ne change ni le nombre de lignes ni le total de population.
4. Sur la dernière ligne, affichez `(len(consolide), nb_non_apparies)`, où `nb_non_apparies` est le nombre de lignes `left_only`.

## Indice
Reprenez l'étape 2 de l'atelier 4 pour le nettoyage. Pour compter : `(consolide["_merge"] == "left_only").sum()`.

## Préparation
```python
import pandas as pd
from outils_cours import harmoniser_code
empile = pd.read_parquet("donnees/population_brut.parquet", dtype_backend="pyarrow")
ref = pd.read_csv("referentiels/nuts_lau_2027.txt", sep="|", encoding="cp1252",
                  dtype_backend="pyarrow")
en_vigueur = (ref[(ref["CD_LVL"] == 4) & (ref["DT_VLDT_STOP"] == "31/12/9999")]
              .rename(columns={"CD_MUNTY_REFNIS": "code_ins", "CD_LVL_SUP": "nuts3"})
              [["code_ins", "nuts3"]])
```

## Correction
```python
df = empile.drop_duplicates().copy()
df["code_ins"] = df["code_ins"].map(harmoniser_code)
df["sexe"] = df["sexe"].str.strip().str.upper()
df = df[df["population"].notna() & (df["population"] >= 0)].copy()
df["population"] = df["population"].astype("int64[pyarrow]")

consolide = df.merge(en_vigueur, on="code_ins", how="left",
                     indicator=True, validate="many_to_one")
assert len(consolide) == len(df), "lignes ajoutées par la jointure"
assert consolide["population"].sum() == df["population"].sum(), "total modifié"
nb_non_apparies = int((consolide["_merge"] == "left_only").sum())
(len(consolide), nb_non_apparies)
```

## Commentaire
1 129 lignes, dont 1 non appariée (« 99999 »). Les deux `assert` sont des contrôles **automatiques** : si une prochaine livraison contient une clé en double, le traitement s'arrêtera au lieu de produire des totaux faux.

# Atelier de synthèse · Étape 3 : contrôler la complétude
niveau: 4
groupe: Atelier de synthèse · Consolidation complète
theme: groupby, size

## Énoncé
Chaque commune doit compter **2 lignes** (hommes et femmes). Sur la table `consolide` (étape 2), listez sur la dernière ligne les codes INS des communes qui n'ont pas 2 lignes, triés.

## Indice
`consolide.groupby("code_ins").size()` donne le nombre de lignes par commune ; gardez celles `!= 2`, puis `sorted(... .index)`.

## Préparation
```python
import pandas as pd
from outils_cours import harmoniser_code
df = pd.read_parquet("donnees/population_nettoyee.parquet", dtype_backend="pyarrow")
ref = pd.read_csv("referentiels/nuts_lau_2027.txt", sep="|", encoding="cp1252",
                  dtype_backend="pyarrow")
en_vigueur = (ref[(ref["CD_LVL"] == 4) & (ref["DT_VLDT_STOP"] == "31/12/9999")]
              .rename(columns={"CD_MUNTY_REFNIS": "code_ins", "CD_LVL_SUP": "nuts3"})
              [["code_ins", "nuts3"]])
consolide = df.merge(en_vigueur, on="code_ins", how="left",
                     indicator=True, validate="many_to_one")
```

## Correction
```python
lignes = consolide.groupby("code_ins").size()
incomplets = lignes[lignes != 2]
print(consolide[consolide["code_ins"].isin(incomplets.index)][["code_ins", "commune", "sexe"]])
sorted(incomplets.index)
```

## Commentaire
Trois communes : Martelange (`81013`) et Daverdisse (`84016`), dont une ligne a été rejetée, et « 99999 », inconnue. Les indicateurs des provinces de ces communes portent sur des observations incomplètes : il faut le dire dans toute publication.

# Atelier de synthèse · Étape 4 : indicateurs par province et export
niveau: 5
groupe: Atelier de synthèse · Consolidation complète
theme: agg, merge, to_parquet, DuckDB

## Énoncé
1. Ajoutez la province à `consolide` : `nuts2` = les 4 premiers caractères de `nuts3` (remplacez d'abord le `nuts3` manquant de la commune inconnue par `"-"` avec `.fillna("-")`), puis jointure avec `provinces` ; nommez « Région de Bruxelles-Capitale » les lignes `BE10`.
2. Pour les lignes appariées, calculez par province : `communes` (nombre de communes distinctes), `population` et `part_femmes` (en %, 1 décimale).
3. Exportez `consolide` (sans `_merge`) en Parquet dans `sortie/population_consolidee.parquet` et vérifiez avec DuckDB que la somme de la population est la même.
4. Sur la dernière ligne, affichez le tableau des indicateurs.

## Indice
`.str.slice(0, 4)` ; `agg(communes=("code_ins", "nunique"), population=("population", "sum"))` ; pour les femmes, filtrez `sexe == "F"` puis regroupez. En SQL : `SELECT SUM(population) FROM 'sortie/population_consolidee.parquet'`.

## Préparation
```python
import pandas as pd
import duckdb
df = pd.read_parquet("donnees/population_nettoyee.parquet", dtype_backend="pyarrow")
ref = pd.read_csv("referentiels/nuts_lau_2027.txt", sep="|", encoding="cp1252",
                  dtype_backend="pyarrow")
en_vigueur = (ref[(ref["CD_LVL"] == 4) & (ref["DT_VLDT_STOP"] == "31/12/9999")]
              .rename(columns={"CD_MUNTY_REFNIS": "code_ins", "CD_LVL_SUP": "nuts3"})
              [["code_ins", "nuts3"]])
provinces = (ref[(ref["CD_LVL"] == 2) & (ref["DT_VLDT_STOP"] == "31/12/9999")]
             .rename(columns={"CD_LAU": "nuts2", "TX_DESCR_FR": "province"})
             [["nuts2", "province"]])
consolide = df.merge(en_vigueur, on="code_ins", how="left",
                     indicator=True, validate="many_to_one")
```

## Correction
```python
consolide["nuts2"] = consolide["nuts3"].fillna("-").str.slice(0, 4)
consolide = consolide.merge(provinces, on="nuts2", how="left", validate="many_to_one")
consolide.loc[consolide["nuts2"] == "BE10", "province"] = "Région de Bruxelles-Capitale"

ok = consolide[consolide["_merge"] == "both"]
indic = ok.groupby("province").agg(communes=("code_ins", "nunique"),
                                   population=("population", "sum"))
femmes = ok[ok["sexe"] == "F"].groupby("province")["population"].sum()
indic["part_femmes"] = (femmes / indic["population"] * 100).round(1)

consolide.drop(columns="_merge").to_parquet("sortie/population_consolidee.parquet", index=False)
total_sql = duckdb.sql("SELECT SUM(population) AS p FROM 'sortie/population_consolidee.parquet'").fetchone()[0]
assert total_sql == consolide["population"].sum()
indic
```

## Commentaire
Onze lignes : les dix provinces et la Région de Bruxelles-Capitale. La part des femmes va de 50,2 % (Limbourg, Luxembourg) à 51,5 % (Brabant wallon). Le Luxembourg, incomplet, est à interpréter avec prudence.

**Pour aller plus loin**
- Écrivez `consolider(fichiers, chemin_ref)` qui enchaîne les étapes et renvoie la table, les indicateurs et le bilan.
- Recalculez les indicateurs par une requête DuckDB et comparez avec le `groupby()` pandas.
- Ajoutez la région à partir du code NUTS : les 3 premiers caractères de `nuts3` (`BE1`, `BE2`, `BE3`).
