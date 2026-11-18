---
titre: Types et opérateurs
resume: Variables, types de base (nombres, texte, booléens, dates), conversions, calculs et comparaisons.
partie: Demi-journée 1 · Fondamentaux et fichiers
---

# Demi-journée 1 : fondamentaux et fichiers de données

**À l'issue de la séance, vous saurez**

- créer des variables et identifier leur type : nombres, texte, booléens, dates ;
- calculer avec les opérateurs arithmétiques, de comparaison et logiques ;
- utiliser listes, tuples, ensembles et dictionnaires, et en extraire des éléments ;
- lire et exporter des fichiers CSV, Excel et TXT en réglant séparateur, encodage et en-têtes.

Les données sont **réelles** : la population des 565 communes belges au 1er janvier 2026 et la nomenclature des territoires (codes NUTS), publiées par Statbel.

::: note
**Python s'exécute dans votre navigateur.** La première fois, il faut une dizaine de secondes pour charger Python et ses paquets. Les cartes s'exécutent dans l'ordre, comme les cellules d'un notebook : une variable créée dans une carte est disponible dans les suivantes. Pour modifier un exemple, cliquez sur **Modifier ce code dans Découverte**.
:::

# Une variable est un nom qui désigne une valeur

Le signe `=` **affecte** une valeur à un nom : il ne teste pas une égalité.

Un nom de variable s'écrit en minuscules, chiffres et `_`, sans espace et de préférence sans accent (`pop_2026`).

`print()` affiche des valeurs. Comme dans un notebook, la **dernière ligne** d'une cellule s'affiche aussi, sans `print()`.

```python
annee = 2026
commune = "Liège"
code_ins = "62063"
population = 198102
print(commune, code_ins, annee, population)

population = population + 10    # on réaffecte
population
```

::: sas
En SAS, une variable est une colonne d'une table. En Python, une variable est un nom qui peut désigner un nombre, un texte, une liste ou une table entière.
:::

# Quatre types de base : int, float, str et bool

`type()` indique le type d'une valeur. Le type détermine les opérations possibles.

| Type | Signification | Exemple | Usage |
|---|---|---|---|
| `int` | nombre entier | `198102` | effectifs, années |
| `float` | nombre décimal | `69.4` | superficies, taux |
| `str` | texte | `"62063"` | codes, libellés |
| `bool` | vrai ou faux | `True` | résultat d'un contrôle |

```python
population = 198102      # int
superficie = 69.4        # float : point décimal (km², valeur arrondie)
code_ins = "62063"       # str : entre guillemets
est_ville = True         # bool
print(type(population), type(superficie))
print(type(code_ins), type(est_ville))
```

::: piege
**Un code n'est pas un nombre.** Le code INS de la commune s'écrit entre guillemets : on ne calcule pas avec, et certains codes commencent par un zéro (`"04000"` pour la Région de Bruxelles-Capitale). Écrit comme un nombre, `04000` perdrait son zéro.
:::

# Les dates : le type date du module datetime

On importe le type `date` depuis le module `datetime`.

Une date connaît son année, son mois et son jour ; on peut calculer l'écart entre deux dates.

Dans un fichier, une date est souvent lue comme du texte : c'est le cas des dates de validité de la nomenclature NUTS (`"01/01/2019"`). Il faudra la convertir (demi-journée 4).

```python
from datetime import date
reference = date(2026, 1, 1)     # date des chiffres de population
print(reference)
print(reference.year, reference.month)
fin = date(2026, 12, 31)
print(fin - reference)           # écart en jours
```

::: sas
En SAS, une date est un nombre de jours depuis le 1er janvier 1960, lisible grâce à un format. En Python, une date est un objet qui s'affiche directement au format AAAA-MM-JJ.
:::

# Convertir une valeur d'un type à un autre

Une valeur lue dans un fichier est souvent du **texte**, même si elle ressemble à un nombre. Dans le fichier de Statbel, la population de Liège est écrite `198.102`, avec un point pour séparer les milliers.

`int()`, `float()` et `str()` convertissent une valeur. Une conversion impossible déclenche une erreur `ValueError` : c'est un signal utile, pas un échec.

**Erreur volontaire** : la dernière ligne ne peut pas être convertie. Lisez la dernière ligne du message.

```python erreur
texte = "198.102"                 # tel qu'écrit dans le fichier Statbel
print(texte + "0")                # des textes se collent
print(float(texte))               # piège : le point est lu comme une virgule décimale
nombre = int(texte.replace(".", ""))
print(nombre + 10)
print(str(2026) + "-T1")
int("198 102")                    # espace : conversion impossible
```

::: piege
`float("198.102")` ne provoque **pas** d'erreur : Python lit `198,102`, soit un peu moins de 200. Une erreur silencieuse est plus dangereuse qu'un message d'erreur : on verra à la lecture du fichier comment dire à pandas que le point sépare les milliers.
:::

# Calculer : les opérateurs arithmétiques

| Opérateur | Rôle | Exemple → résultat |
|---|---|---|
| `+` | addition | `98484 + 99618` → `198102` |
| `-` | soustraction | `99618 - 98484` → `1134` |
| `*` | multiplication | `2.5 * 4` → `10.0` |
| `/` | division | `7 / 2` → `3.5` |
| `//` | division entière | `7 // 2` → `3` |
| `%` | reste de la division | `7 % 2` → `1` |
| `**` | puissance | `1.02 ** 2` → `1.0404` |

La population de Liège au 1er janvier 2026 :

```python
hommes = 98484
femmes = 99618
total = hommes + femmes
part_femmes = femmes / total * 100
print(total)
print(round(part_femmes, 1))
print(total // 1000, "milliers et", total % 1000)
```

**Lecture :** Liège compte 198 102 habitants, dont 50,3 % de femmes.

# Comparer et combiner des conditions

Comparaison : `==` égal, `!=` différent, `<`, `<=`, `>`, `>=`. Le résultat est un booléen (`True` ou `False`).

Combinaison : `and` (les deux), `or` (au moins une), `not` (l'inverse).

`in` teste l'appartenance à une liste ou à un texte.

```python
population = 198102
print(population >= 0 and population < 1_000_000)
region = "Wallonie"
print(region == "Wallonie" or region == "Flandre")
print(region in ["Bruxelles-Capitale", "Flandre", "Wallonie"])
print(not population > 100000)
print("Liège" in "Arrondissement de Liège")
```

`1_000_000` s'écrit avec des `_` pour être lisible : Python les ignore.

::: sas
SAS accepte `=` ou `EQ` pour comparer. Python distingue `=` (affecter) et `==` (comparer) : les confondre est l'erreur la plus fréquente au début.
:::
