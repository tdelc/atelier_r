---
titre: Structurer un traitement
resume: Décomposer un traitement en fonctions simples, les enchaîner, les appliquer à plusieurs fichiers et vérifier les résultats avec assert.
partie: Demi-journée 3 · Fonctions et traitements réutilisables
---

# Cellule de départ : les outils

*Recette à réutiliser telle quelle.*

Les traitements de cette partie lisent les trois fichiers régionaux, comme en demi-journée 2. On importe `date` (pour l'atelier), pandas, les fonctions fournies dans `outils_cours.py`, et on redéfinit la liste des fichiers.

```python
from datetime import date
import pandas as pd
from outils_cours import charger_lignes, harmoniser_code, harmoniser_sexe

fichiers = ["donnees/population_bruxelles_2026.csv",
            "donnees/population_flandre_2026.xlsx",
            "donnees/population_wallonie_2026.txt"]
print(len(fichiers), "fichiers")
```

# Décomposer un traitement en opérations simples

| Étape | Fonction | Entrée → sortie |
|---|---|---|
| 1 · Charger | `charger_lignes(chemin)` | un fichier → une liste de lignes (fournie) |
| 2 · Harmoniser | `harmoniser_ligne(ligne)` | une ligne → une copie aux formats attendus |
| 3 · Contrôler | `controler_ligne(ligne)` | une ligne → la liste de ses anomalies |
| 4 · Transformer | `transformer_ligne(ligne)` | une ligne → une ligne enrichie |
| 5 · Écrire | `ecrire_resultat(lignes, chemin)` | des lignes → un fichier, nombre de lignes écrites |

Chaque fonction fait **une seule chose** et se teste seule. Le traitement complet devient un enchaînement d'appels, réunis dans `traiter_fichier(chemin)`.

# Une fonction de contrôle qui renvoie une liste

Les règles de la demi-journée 2 deviennent une fonction : une ligne en entrée, une liste en sortie. Liste vide : la ligne est conforme.

```python
def controler_ligne(ligne):
    """Anomalies d'une ligne ([] si conforme)."""
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

ok = {"code_ins": "62063", "sexe": "F", "population": 99618}
ko = {"code_ins": " 62063", "sexe": "x", "population": None}
print(controler_ligne(ok))
print(controler_ligne(ko))
```

# Enchaîner les fonctions

`harmoniser_ligne()` appelle les fonctions déjà écrites : chacune reste simple.

`dict(ligne)` crée une **copie** : la ligne d'origine reste intacte, ce qui permet de comparer avant et après.

```python
def harmoniser_ligne(ligne):
    """Copie harmonisée d'une ligne."""
    nouvelle = dict(ligne)          # copie
    nouvelle["code_ins"] = harmoniser_code(ligne["code_ins"])
    nouvelle["sexe"] = harmoniser_sexe(ligne["sexe"])
    return nouvelle

brute = {"code_ins": " 62063", "commune": "Liège", "sexe": "h", "population": 98484}
propre = harmoniser_ligne(brute)
print(repr(brute["code_ins"]), brute["sexe"])
print(repr(propre["code_ins"]), propre["sexe"])
print(controler_ligne(propre))
```

# Réutiliser les fonctions sur plusieurs fichiers

Une liste vide vaut `False` dans une condition : `if controler_ligne(ligne):` signifie « s'il y a au moins une anomalie ».

`return valides, rejets` renvoie deux listes, récupérées en une seule affectation.

```python
def traiter_fichier(chemin):
    """Charge, harmonise, contrôle un fichier."""
    valides, rejets = [], []
    for ligne in charger_lignes(chemin):
        ligne = harmoniser_ligne(ligne)
        if controler_ligne(ligne):     # liste non vide
            rejets.append(ligne)
        else:
            valides.append(ligne)
    return valides, rejets

for chemin in fichiers:
    valides, rejets = traiter_fichier(chemin)
    print(chemin[8:], len(valides), len(rejets))
```

**Lecture :** grâce à l'harmonisation, Liège (`" 62063"`) et Namur (`"f"`) ne sont plus rejetées. Il reste 2 rejets en Wallonie : la population manquante de Daverdisse et la population négative de Martelange, qu'aucune fonction ne peut deviner.

# Vérifier les entrées et les résultats

`assert condition, message` ne dit rien si la condition est vraie, et s'arrête avec `AssertionError` sinon.

Vérifiez une fonction sur des cas connus avant de l'appliquer à tout un fichier. Vérifiez le résultat global : aucune ligne ne doit être perdue.

```python
assert harmoniser_code(" 62063") == "62063"
assert harmoniser_sexe(" f") == "F"
assert controler_ligne({"code_ins": "62063", "sexe": "H",
                        "population": 10}) == []

chemin = "donnees/population_wallonie_2026.txt"
nb_lus = len(charger_lignes(chemin))
valides, rejets = traiter_fichier(chemin)
assert len(valides) + len(rejets) == nb_lus, "lignes perdues"
print("Contrôles OK :", nb_lus, "lignes lues")
```

# Démonstration : vérifier la présence des valeurs attendues

- harmoniser une variable : `harmoniser_code()` ;
- vérifier les valeurs attendues : `verifier_attendus()` ;
- appliquer le tout aux trois fichiers.

`ensemble.add(x)` ajoute une valeur ; `a - b` donne les éléments de `a` absents de `b`. Les codes attendus sont ceux des communes **en vigueur** dans la nomenclature NUTS.

```python
def verifier_attendus(lignes, attendus, champ):
    """Valeurs présentes dans les lignes mais absentes des attendus."""
    presents = set()
    for ligne in lignes:
        presents.add(ligne[champ])
    return presents - attendus

ref = pd.read_csv("referentiels/nuts_lau_2027.txt", sep="|", encoding="latin-1")
codes_communes = set()
for code, niveau, fin in zip(ref["CD_MUNTY_REFNIS"], ref["CD_LVL"], ref["DT_VLDT_STOP"]):
    if niveau == 4 and fin == "31/12/9999":
        codes_communes.add(code)
print(len(codes_communes), "communes en vigueur")

for chemin in fichiers:
    inattendus = verifier_attendus(charger_lignes(chemin), codes_communes, "code_ins")
    print(chemin[8:], sorted(inattendus))
```

**Lecture :** en Wallonie, deux codes ne sont pas des communes en vigueur : `" 62063"`, que `harmoniser_code()` corrige, et `"99999"`, une commune inconnue qu'il faudra signaler (on la retrouvera à la jointure de la demi-journée 5).

# Ce qu'il faut retenir

- **Fonctions intégrées** : `len`, `sum`, `min`, `max`, `round`, `sorted`, et les méthodes de texte `.strip()`, `.upper()`, `.zfill()`.
- **Définir** : `def nom(paramètres):`, une docstring, un bloc indenté, `return`.
- **Paramètres** : valeurs par défaut pour les options ; arguments nommés à l'appel pour la lisibilité.
- **Renvoyer** : `return` transmet un résultat ; `print` ne fait qu'afficher. Sans `return` : `None`.
- **Structurer** : une fonction = une opération : charger, harmoniser, contrôler, transformer, écrire.
- **Vérifier** : `assert` sur des cas connus ; lignes lues = lignes valides + rejets.
