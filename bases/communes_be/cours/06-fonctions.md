---
titre: Fonctions Python
resume: Fonctions intégrées et méthodes de texte ; définir une fonction avec def ; paramètres, valeurs par défaut, return ; variables locales.
partie: Demi-journée 3 · Fonctions et traitements réutilisables
---

# Demi-journée 3 : fonctions et traitements réutilisables

**À l'issue de la séance, vous saurez**

- utiliser les fonctions intégrées et en définir de nouvelles avec `def` ;
- choisir paramètres, valeurs par défaut et valeurs de retour ;
- décomposer un traitement en fonctions simples et les enchaîner ;
- vérifier les entrées et les résultats d'un traitement.

**Pourquoi écrire des fonctions ?**

- **Ne pas répéter** : les règles de la demi-journée 2 étaient recopiées pour chaque cas. Une fonction s'écrit une fois et s'appelle autant que nécessaire.
- **Nommer une intention** : `harmoniser_code(code)` se lit comme une phrase : on comprend le traitement sans lire son détail.
- **Tester séparément** : une fonction se vérifie sur quelques cas connus avant d'être appliquée à des milliers de lignes.

Une fonction reçoit des **valeurs en entrée** (ses paramètres), exécute un bloc et **renvoie un résultat** avec `return`.

# Les fonctions intégrées, toujours disponibles

| Fonction | Rôle |
|---|---|
| `len()` | nombre d'éléments |
| `sum()` | somme |
| `min()`, `max()` | minimum, maximum |
| `round(x, n)` | arrondi à n décimales |
| `sorted()` | liste triée |
| `abs()` | valeur absolue |
| `type()` | type d'une valeur |

```python
valeurs = [198102, 115457, 206900, 97745]   # Liège, Namur, Charleroi, Mons
print(len(valeurs), sum(valeurs))
print(min(valeurs), max(valeurs))
print(round(sum(valeurs) / len(valeurs), 1))
print(sorted(["Namur", "Liège", "Charleroi", "Mons"]))
print(abs(-1059))
```

# Les méthodes de texte : nettoyer une chaîne

Une **méthode** est une fonction attachée à une valeur : `valeur.methode()`.

Les méthodes de texte renvoient un **nouveau** texte : l'original n'est pas modifié. On peut les enchaîner : `code.strip().upper()`.

| Méthode | Effet |
|---|---|
| `.strip()` | retire les espaces aux extrémités |
| `.upper()`, `.lower()` | majuscules, minuscules |
| `.replace(a, b)` | remplace a par b |
| `.zfill(n)` | complète à gauche par des zéros |
| `.startswith(x)` | commence par x ? |

```python
code = " 62063 "
print(repr(code.strip()))
print(" f ".strip().upper())
print("1000".zfill(5))                 # le code de la Belgique, 01000
print("198.102".replace(".", ""))
print("62063".startswith("6"))         # une commune de la province de Liège ?
```

# Définir une fonction avec def

`def nom(paramètres):` puis un bloc indenté ; `return` renvoie le résultat.

La chaîne entre triples guillemets (*docstring*) décrit la fonction : appliquez les conventions de documentation de votre service.

Une fonction définie ne s'exécute que lorsqu'on l'**appelle**.

```python
def part(partie, total):
    """Part de partie dans total, en %, arrondie à 2 décimales."""
    return round(partie / total * 100, 2)

print(part(99618, 198102))      # femmes à Liège
print(part(59209, 115457))      # femmes à Namur
```

# Paramètres, arguments et valeurs par défaut

Les **paramètres** sont les noms déclarés dans `def` ; les **arguments** sont les valeurs passées à l'appel.

Un paramètre doté d'une valeur par défaut devient facultatif. Nommer les arguments à l'appel rend le code lisible : `longueur=5`.

```python
def harmoniser_code(code, longueur=5):
    """' 62063 ' -> '62063' ; '1000' -> '01000'."""
    return str(code).strip().zfill(longueur)

print(harmoniser_code(" 62063"))
print(harmoniser_code("1000"))
print(harmoniser_code("3", longueur=2))
```

# return renvoie un résultat, print l'affiche seulement

Sans `return`, une fonction renvoie `None`.

Un résultat **renvoyé** peut être stocké, réutilisé et testé. Un résultat **affiché** est perdu pour la suite.

Une fonction peut renvoyer plusieurs valeurs : `return valides, rejets`.

```python
def afficher_total(valeurs):
    print(sum(valeurs))          # affiche seulement

def calculer_total(valeurs):
    return sum(valeurs)          # renvoie le résultat

resultat = afficher_total([1, 2, 3])
print(resultat)
print(calculer_total([1, 2, 3]) * 10)
```

# Les variables d'une fonction restent dans la fonction

Les variables créées dans une fonction sont **locales** : elles disparaissent à la fin de l'appel. Pour récupérer une valeur, la fonction doit la renvoyer.

Une fonction qui n'utilise que ses paramètres reste prévisible et facile à tester.

**Erreur volontaire** : `nb` n'existe que dans la fonction.

```python erreur
def compter_manquantes(lignes):
    nb = 0
    for ligne in lignes:
        if ligne["population"] is None:
            nb += 1
    return nb

lignes = [{"population": 120}, {"population": None}]
print(compter_manquantes(lignes))
print(nb)
```

# Macro SAS ou fonction Python ?

| | Macro SAS | Fonction Python |
|---|---|---|
| Ce qu'elle produit | du code SAS, généré avant l'exécution | une valeur, calculée à l'exécution |
| Paramètres | du texte substitué (`&code`) | des valeurs : nombre, texte, liste, table |
| Résultat | les étapes DATA ou PROC générées | ce que renvoie `return` |
| Mise au point | `OPTIONS MPRINT` pour voir le code généré | un appel direct sur un exemple, `assert` |
| Usage type | répéter une étape pour plusieurs tables | harmoniser, contrôler, transformer |

Une fonction Python est plus proche d'une fonction définie avec `PROC FCMP` que d'une macro : elle calcule une valeur. Pour répéter un traitement sur plusieurs tables, on l'appelle dans une boucle.

# La fonction harmoniser_sexe()

C'est l'exercice « À vous » de cette partie : essayez-le d'abord dans le volet **Exercices**. La correction ci-dessous sert dans la suite de la séance.

```python
def harmoniser_sexe(valeur):
    """Renvoie 'H' ou 'F', ou None si la valeur n'est pas reconnue."""
    if valeur is None:
        return None
    valeur = valeur.strip().upper()
    if valeur in ("H", "F"):
        return valeur
    return None

for v in ["f", " H ", "x", None]:
    print(repr(v), "->", harmoniser_sexe(v))
```

`harmoniser_code()` et `harmoniser_sexe()` sont aussi fournies dans `outils_cours.py`, pour la suite.
