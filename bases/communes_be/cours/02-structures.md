---
titre: Structures, indexation et slicing
resume: Listes, tuples, ensembles et dictionnaires ; extraire un élément par sa position ou une tranche.
partie: Demi-journée 1 · Fondamentaux et fichiers
---

# Quatre structures pour regrouper des valeurs

| Structure | Écriture | Ordonnée | Modifiable | Doublons | Usage type |
|---|---|---|---|---|---|
| liste | `[416947, 1368562]` | oui | oui | oui | une série de valeurs |
| tuple | `("région", "province")` | oui | non | oui | une nomenclature fixe |
| ensemble (set) | `{"62063", "92094"}` | non | oui | non | des codes uniques |
| dictionnaire | `{"code_ins": "62063", "population": 198102}` | oui | oui | clés uniques | une ligne de table |

Une ligne de table peut se représenter par un **dictionnaire**, et une table par une **liste de dictionnaires** : c'est la forme utilisée en demi-journées 2 et 3, avant de passer à pandas.

# Les listes : une série ordonnée et modifiable

Une liste s'écrit entre crochets, éléments séparés par des virgules.

`len()` compte les éléments ; `sum()`, `min()`, `max()` calculent sur des nombres.

`.append()` ajoute à la fin ; `liste[i] = ...` remplace l'élément en position `i`.

Les cinq provinces wallonnes et leur population au 1er janvier 2026 :

```python
provinces = ["Brabant walon", "Hainaut", "Liège", "Luxembourg"]
populations = [416947, 1368562, 1125300, 296370]
print(len(provinces))
provinces.append("Namur")             # ajoute à la fin
populations.append(506271)
provinces[0] = "Brabant wallon"       # corrige la faute de frappe
print(provinces)
print(sum(populations), max(populations))
```

**Lecture :** la somme, 3 713 450, est exactement la population de la Région wallonne dans le fichier de Statbel. Le Hainaut est la province la plus peuplée.

# Indexation : la première position est 0

On accède à un élément par sa position entre crochets.

Les positions commencent à **0**. Les positions négatives partent de la fin : `-1` est le dernier.

| Élément | Bruxelles-Capitale | Flandre | Wallonie |
|---|---|---|---|
| Position | 0 | 1 | 2 |
| Depuis la fin | -3 | -2 | -1 |

Une position inexistante provoque une erreur `IndexError`. **Erreur volontaire** sur la dernière ligne :

```python erreur
regions = ["Bruxelles-Capitale", "Flandre", "Wallonie"]
print(regions[0])      # premier élément
print(regions[2])      # troisième élément
print(regions[-1])     # dernier élément
regions[3]             # il n'y a que 3 éléments
```

::: sas
SAS numérote les observations à partir de 1 (`_N_` vaut 1 sur la première). Python compte les positions à partir de 0.
:::

# Slicing : extraire une tranche avec [début:fin]

`liste[début:fin]` renvoie les éléments de `début` **inclus** à `fin` **exclu**.

Sans `début` : depuis le premier élément. Sans `fin` : jusqu'au dernier.

Le slicing fonctionne aussi sur le texte. C'est très utile avec le **code INS** : son premier chiffre désigne la province, ses deux premiers l'arrondissement.

```python
codes = ["62003", "62006", "62009", "62011", "62015", "62022"]
print(codes[1:4])     # positions 1, 2 et 3
print(codes[:2])      # les deux premiers
print(codes[-3:])     # les trois derniers

code_ins = "62063"    # Liège
print(code_ins[:1], code_ins[:2])
```

**Lecture :** `"6"` est le code de la province de Liège (60000) et `"62"` celui de l'arrondissement de Liège (62000).

# Tuples et ensembles

Un **tuple** s'écrit entre parenthèses et ne se modifie pas : il convient à une nomenclature fixe.

Un **ensemble** (`set`) ne garde qu'un exemplaire de chaque valeur, sans ordre : idéal pour obtenir des codes uniques ou tester une appartenance.

`sorted()` renvoie une liste triée.

```python
niveaux = ("région", "province", "arrondissement", "commune")   # tuple
print(niveaux[1])

provinces_lues = ["Liège", "Namur", "Liège", "Hainaut", "Namur"]
provinces_uniques = set(provinces_lues)          # sans doublon
print(len(provinces_lues), len(provinces_uniques))
print(sorted(provinces_uniques))
print("Luxembourg" in provinces_uniques)
```

# Dictionnaires : associer une clé à une valeur

Un dictionnaire associe des **clés** uniques à des **valeurs**.

On lit une valeur par sa clé : `commune["population"]`.

`.get(clé, défaut)` renvoie une valeur par défaut si la clé n'existe pas, au lieu d'une erreur `KeyError`.

```python
commune = {"code_ins": "62063", "nom": "Liège", "population": 198102}
print(commune["population"])
commune["population"] = 198112       # modifier une valeur
commune["province"] = "Liège"        # ajouter une clé
print(list(commune.keys()))
print(commune.get("superficie", "inconnue"))
```
