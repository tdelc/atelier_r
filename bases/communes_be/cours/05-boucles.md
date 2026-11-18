---
titre: Boucles et itérations
resume: Répéter un traitement avec for et while, range() et enumerate() ; parcourir une liste de dictionnaires et plusieurs fichiers.
partie: Demi-journée 2 · Conditions et boucles
---

# La boucle for : répéter pour chaque élément

`for element in collection:` exécute le bloc une fois par élément.

La variable de boucle prend successivement chaque valeur.

Un **accumulateur**, initialisé avant la boucle, collecte le résultat. Ici, la population des cinq provinces wallonnes :

```python
populations = [416947, 1368562, 1125300, 296370, 506271]
total = 0                        # accumulateur
for valeur in populations:
    total = total + valeur
    print("ajout de", valeur, "->", total)
print("Total :", total)
```

# Une boucle explicite, là où SAS boucle implicitement

| | Étape DATA en SAS | Python (séances 2 et 3) | pandas (séances 4 et 5) |
|---|---|---|---|
| La boucle sur les lignes | **implicite** : le code s'applique à chaque ligne lue par `SET` | **explicite** : `for ligne in lignes:` | pas de boucle : une instruction s'applique à **toute une colonne** |
| Le numéro de ligne | `_N_` | `enumerate()` | l'index |
| Écrire la ligne | `OUTPUT` | `.append()` | `df["x"] = df["population"] / 1000` |

Pourquoi écrire des boucles avant pandas ? Pour comprendre ce que fait un traitement ligne à ligne, et pour automatiser ce qui n'est pas une table : une liste de fichiers, de périodes ou de règles.

# range() et enumerate()

`range(début, fin)` produit des entiers de `début` à `fin` **exclu**, comme le slicing.

`enumerate()` fournit à la fois la position et l'élément : utile pour signaler où se trouve une anomalie.

```python
for annee in range(2024, 2027):
    print("Traitement de l'année", annee)

codes = ["62003", " 62063", "62006"]
for position, code in enumerate(codes):
    if len(code) != 5:
        print("Position", position, ":", repr(code), "à contrôler")
```

`repr()` affiche le texte avec ses guillemets : l'espace en tête devient visible.

# Parcourir une liste de dictionnaires

Une table peut se représenter par une **liste de dictionnaires** : une ligne = un dictionnaire.

On parcourt les lignes avec `for` et on lit chaque champ par sa clé.

`.items()` parcourt les paires clé-valeur d'un dictionnaire.

```python
lignes = [
    {"code_ins": "92094", "commune": "Namur", "sexe": "H", "population": 56248},
    {"code_ins": "92094", "commune": "Namur", "sexe": "f", "population": 59209},
    {"code_ins": "84016", "commune": "Daverdisse", "sexe": "H", "population": None},
]
for ligne in lignes:
    if ligne["sexe"] not in ("H", "F"):
        print("Sexe à contrôler :", ligne["commune"])
for cle, valeur in lignes[0].items():
    print(cle, "=", valeur)
```

# Compter et collecter pendant une boucle

Un **compteur** et une **liste de collecte** s'initialisent avant la boucle.

`nb += 1` est un raccourci de `nb = nb + 1`.

Collecter des dictionnaires produit une table de sortie que l'on pourra exporter et contrôler.

```python
nb_anomalies = 0
a_controler = []
for position, ligne in enumerate(lignes):
    if ligne["sexe"] not in ("H", "F"):
        nb_anomalies += 1
        a_controler.append({"position": position,
                            "regle": "R1 sexe",
                            "valeur": ligne["sexe"]})
print(nb_anomalies)
print(a_controler)
```

# Parcourir plusieurs fichiers

*Recette à réutiliser telle quelle.*

La fonction fournie `charger_lignes(chemin)` (dans `outils_cours.py`) lit un fichier CSV, Excel ou TXT et renvoie une liste de dictionnaires ; une valeur manquante vaut `None`. Vous saurez écrire ce type de fonction en demi-journée 3.

La boucle applique le même traitement à chaque fichier.

```python
from outils_cours import charger_lignes

fichiers = ["donnees/population_bruxelles_2026.csv",
            "donnees/population_flandre_2026.xlsx",
            "donnees/population_wallonie_2026.txt"]
for chemin in fichiers:
    lignes = charger_lignes(chemin)
    print(chemin, ":", len(lignes), "lignes")
print(lignes[0])
```

**Lecture :** 38 lignes pour Bruxelles (19 communes × 2 sexes), 571 pour la Flandre, 523 pour la Wallonie.

# while : répéter tant qu'une condition est vraie

`while condition:` répète le bloc tant que la condition reste vraie. Utile quand le nombre de répétitions n'est pas connu à l'avance.

Une projection : Namur compte 115 457 habitants. Avec 0,5 % de plus chaque année (hypothèse), quand dépassera-t-elle 120 000 habitants ?

```python
population = 115457
annee = 2026
while population < 120000:       # hypothèse : +0,5 % par an
    population = population * 1.005
    annee += 1
print(annee, round(population))
```

::: piege
**Si la condition ne devient jamais fausse, la boucle ne s'arrête pas.** Ici, la population ne change pas : la boucle tournerait sans fin. Dans JupyterLab, on l'interrompt avec le bouton ■ ; dans l'atelier, Python se bloque et il faut recharger la page. Ce code n'est donc **pas exécuté** ici :
:::

```python norun
population = 115457
while population < 120000:
    print(population)            # on a oublié de modifier population
```

# Démonstration : contrôler les trois fichiers

1. Charger chaque fichier avec `charger_lignes()`
2. Appliquer R1 à R4 à chaque ligne
3. Compter les lignes en anomalie par fichier
4. Lire le bilan

```python
for chemin in fichiers:
    nb = 0
    for ligne in charger_lignes(chemin):
        pop = ligne["population"]
        if (ligne["sexe"] not in ("H", "F")
                or pop is None or pop < 0
                or len(ligne["code_ins"]) != 5):
            nb += 1
    print(chemin[8:], ":", nb, "en anomalie")
```

**À observer :** aucune anomalie en Flandre, alors que le fichier contient une ligne en double (Gand, femmes). Un doublon ne se voit pas ligne à ligne : il faut comparer les lignes entre elles (voir les extensions de l'atelier 2).

# Ce qu'il faut retenir

- **Conditions** : `if`, `elif`, `else` : le premier bloc vrai s'exécute. `:` en fin de ligne, bloc indenté.
- **Booléens** : `and`, `or`, `not`, `in`. Tester `is None` avant de comparer une valeur.
- **Boucle for** : un passage par élément. `range()` pour des entiers, `enumerate()` pour la position.
- **Boucle while** : tant que la condition est vraie. Vérifier qu'elle finira par devenir fausse.
- **Accumuler** : compteurs et listes de collecte s'initialisent **avant** la boucle.
- **Contrôler** : une règle par anomalie, un bilan par fichier : lignes lues = valides + rejetées.
