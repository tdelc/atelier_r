---
titre: Mise en route
resume: La table des entreprises, ses lignes et ses colonnes ; afficher, regarder la structure, garder un résultat, enchaîner les étapes.
partie: Les bases
---

# La table des entreprises : entreprises

Chaque ligne de la table `entreprises` est **une entreprise** active en 2025 : son activité, sa localisation, son emploi salarié et son chiffre d'affaires.

| Colonne | Contenu |
|---|---|
| `num_entreprise` | numéro d'entreprise (format BCE, texte) |
| `nace`, `section`, `secteur` | activité principale : classe NACE (`"56.10"`), section (`"I"`) et son libellé |
| `forme`, `creation` | forme juridique, année de création |
| `code_ins`, `commune`, `arrondissement`, `province`, `region` | où se trouve le siège |
| `emploi` | nombre de salariés (postes de travail) au 31 décembre 2025 |
| `ca` | chiffre d'affaires 2025, en **milliers d'euros**, d'après les déclarations TVA |

Le bouton **Dictionnaire**, en haut de l'écran, décrit chaque colonne.

::: piege
**Ces entreprises sont fictives.** Elles ont été simulées pour l'atelier, avec des ordres de grandeur plausibles, dans de vraies communes et avec de vraies classes NACE. Aucun chiffre ne décrit une entreprise réelle : ne citez jamais ces résultats comme des statistiques belges.
:::

Ce cours est écrit pour les habitués de **SAS** : on part tout de suite d'une table, et on apprend à lui poser des questions. Le langage Python lui-même (listes, boucles, fonctions) viendra à la fin, quand il servira.

::: sas
Une table pandas (un **DataFrame**) joue le rôle d'une table SAS : des lignes (observations) et des colonnes (variables), chacune avec un type. Mais elle vit **en mémoire**, sans bibliothèque `WORK` : on la charge, on travaille, on enregistre ce qu'on veut garder.
:::

# Charger pandas et la table

Dans vos propres scripts (Jupyter, VS Code…), ces lignes se placent **en haut** :

```python norun
import pandas as pd

entreprises = pd.read_csv("entreprises_2025.csv", sep=";", decimal=",",
                          dtype={"num_entreprise": str, "code_ins": str})
```

::: usage
- `import pandas as pd` charge **pandas**, la bibliothèque des tableaux de données. Par convention, on l'appelle `pd`.
- `pd.read_csv()` lit un fichier CSV : `sep=";"` le séparateur, `decimal=","` la virgule décimale, `dtype=` garde les codes en texte. La leçon « Importer et exporter » détaille tous les réglages.
- Le `=` range le résultat sous un nom : `entreprises`.
:::

::: note
**Dans cet atelier, tout est déjà fait** : pandas est chargé et la table `entreprises` est prête.
:::

# Afficher la table

Taper le nom d'une table l'affiche. Pour une grande table, pandas montre les premières et les dernières lignes, et indique la taille en bas.

```python
entreprises
```

**Lecture :** 12 000 lignes (entreprises) et 13 colonnes. À gauche, en gris, l'**index** : le numéro de chaque ligne, à partir de 0.

# head() : les premières lignes

```python
entreprises.head()
```

::: usage
`.head()` affiche les 5 premières lignes ; `.head(10)` les 10 premières ; `.tail()` les dernières. Le point se lit « **de** » : `entreprises.head()`, c'est « le début de `entreprises` ».
:::

::: sas
`PROC PRINT DATA=entreprises (OBS=5);`
:::

# shape et info() : la taille et la structure

```python
entreprises.shape
```

```python
entreprises.info()
```

::: usage
`shape` donne `(lignes, colonnes)`, **sans parenthèses** : c'est une caractéristique de la table. `.info()` donne, pour chaque colonne, le nombre de valeurs renseignées (*Non-Null Count*) et le type.
:::

**Lecture :** `ca` n'a que 10 627 valeurs sur 12 000. Les 1 373 entreprises sans chiffre d'affaires ne sont pas des erreurs : elles sont **exonérées de TVA** (médecins, banques, assurances, enseignement, ASBL du social…) et ne déclarent donc pas de chiffre d'affaires à la TVA.

::: piege
Une valeur manquante n'est pas un zéro. Une banque a un chiffre d'affaires, mais il n'est pas dans cette source. La remplacer par 0 sous-estimerait tous les totaux.
:::

::: sas
`PROC CONTENTS DATA=entreprises;`
:::

# Une colonne : entreprises["emploi"]

```python
entreprises["emploi"]
```

`table["colonne"]` désigne **une colonne**, sur laquelle on peut calculer :

```python
entreprises["emploi"].sum()
```

**Lecture :** les 12 000 entreprises emploient 73 991 salariés.

# = : garder un résultat

Sans `=`, le résultat s'affiche puis disparaît. Avec `=`, on lui donne un nom pour le réutiliser, comme une nouvelle table SAS.

```python
horeca = entreprises.query("section == 'I'")

horeca.shape
```

::: piege
Écrire `entreprises = entreprises.query(...)` **écrase** la table : vous perdez toutes les autres lignes. Pour une sous-table, choisissez un **nouveau nom**. (Dans l'atelier, on récupère la table d'origine avec « Nouvel environnement ».)
:::

::: sas
`DATA horeca; SET entreprises; WHERE section = 'I'; RUN;`
:::

# Enchaîner les étapes

Une étape prend la table, la suivante prend le résultat. On écrit **une étape par ligne**, entre **parenthèses** : la chaîne se lit de haut en bas, avec « **puis** ».

```python
(entreprises                                   # je prends les entreprises,
 .query("region == 'Wallonie'")                # puis je garde la Wallonie,
 .sort_values("emploi", ascending=False)       # puis je trie par emploi décroissant,
 .head(3))                                     # puis je garde les 3 premières
```

::: note
Les parenthèses autour de la chaîne permettent de passer à la ligne entre les étapes.
:::
