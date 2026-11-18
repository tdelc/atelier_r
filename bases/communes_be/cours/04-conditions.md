---
titre: Structures conditionnelles
resume: if, elif et else ; l'indentation ; combiner des conditions et traiter une valeur manquante ; des règles de validation.
partie: Demi-journée 2 · Conditions et boucles
---

# Demi-journée 2 : conditions et boucles

**À l'issue de la séance, vous saurez**

- écrire des conditions avec `if`, `elif` et `else` pour valider ou classer une valeur ;
- combiner des expressions booléennes et traiter une valeur manquante ;
- répéter un traitement avec `for` et `while`, `range()` et `enumerate()` ;
- parcourir plusieurs fichiers et produire un bilan des anomalies.

**Le fil rouge des demi-journées 2 à 5** : Statbel livre la population par commune et par sexe en trois fichiers, un par région, dans trois formats.

| Fichier | Région | Format |
|---|---|---|
| `donnees/population_bruxelles_2026.csv` | Bruxelles-Capitale | CSV, séparateur `;` |
| `donnees/population_flandre_2026.xlsx` | Flandre | Excel, deux lignes de titre |
| `donnees/population_wallonie_2026.txt` | Wallonie | texte tabulé |

Les chiffres sont ceux de Statbel. **Quelques anomalies ont été ajoutées volontairement**, pour apprendre à les repérer : un sexe écrit en minuscule, un code avec une espace, une population manquante, une population négative, une ligne en double et une commune inconnue.

# if, elif, else : agir selon une condition

`if` exécute un bloc si la condition est vraie ; `elif` teste une autre condition ; `else` couvre tous les autres cas.

La ligne se termine par `:` et le bloc est **indenté** de 4 espaces.

Les conditions sont testées dans l'ordre : seul le premier bloc vrai s'exécute.

```python
population = 198102          # Liège

if population < 5000:
    taille = "petite"
elif population < 50000:
    taille = "moyenne"
else:
    taille = "grande"
print(taille)
```

::: sas
La logique est celle de `IF ... THEN ...; ELSE IF ...; ELSE ...;`. Python remplace `THEN` par `:` et délimite les blocs par l'indentation plutôt que par `DO; ... END;`.
:::

# L'indentation fait partie de la syntaxe

En Python, l'indentation n'est pas une mise en forme : elle **délimite les blocs**.

Tout ce qui est indenté sous `if` dépend de la condition ; le retour à la marge termine le bloc.

```python
population = -1059
if population < 0:
    print("valeur négative")
print("contrôle terminé")      # hors du bloc : toujours exécuté
```

**Erreur volontaire** : le bloc n'est pas indenté.

```python erreur
if population < 0:
print("valeur négative")
```

L'éditeur de l'atelier, comme JupyterLab, indente automatiquement après `:`. Gardez 4 espaces par niveau.

# Combiner des conditions et traiter une valeur manquante

`and`, `or`, `not` combinent des conditions ; `in` vérifie une modalité autorisée.

`None` signifie « pas de valeur ». On le teste avec `is None` ou `is not None`.

Testez l'absence de valeur **avant** de comparer : Python s'arrête dès que le résultat d'un `and` est connu.

```python
sexe = "f"
population = None

sexe_valide = sexe in ("H", "F")
population_valide = population is not None and population >= 0
print(sexe_valide, population_valide)

if not sexe_valide or not population_valide:
    print("ligne à contrôler")
```

::: sas
En SAS, une valeur manquante (`.`) est inférieure à tout nombre : `if population < 0` la retient. En Python, comparer `None` à un nombre provoque une erreur `TypeError` : testez d'abord l'absence de valeur.
:::

# Appliquer des règles de validation à une ligne

Quatre règles, que l'on réutilisera toute la journée :

- **R1** · `sexe` vaut H ou F
- **R2** · `population` est renseignée
- **R3** · `population` est positive ou nulle
- **R4** · `code_ins` compte 5 caractères

Chaque règle non respectée ajoute un libellé à la liste `anomalies`. La ligne ci-dessous vient du fichier wallon : son code a une espace en tête.

```python
ligne = {"code_ins": " 62063", "commune": "Liège", "annee": 2026,
         "sexe": "H", "population": 98484}
anomalies = []
if ligne["sexe"] not in ("H", "F"):
    anomalies.append("R1 sexe")
if ligne["population"] is None:
    anomalies.append("R2 population manquante")
elif ligne["population"] < 0:
    anomalies.append("R3 population négative")
if len(ligne["code_ins"]) != 5:
    anomalies.append("R4 format du code")
print(anomalies)
```

`elif` évite de tester R3 quand la population manque : comparer `None < 0` provoquerait une erreur.
