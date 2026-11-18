---
titre: Mise en route
resume: La table des communes, ses lignes et ses colonnes ; afficher, regarder la structure, garder un résultat, enchaîner les étapes.
partie: Les bases
---

# La table des communes belges : communes

Chaque ligne de la table `communes` est **une commune belge** au 1er janvier 2026 (source : Statbel). Il y en a 565.

| Colonne | Contenu |
|---|---|
| `code_ins` | code INS de la commune (texte : `"62063"` pour Liège) |
| `commune` | nom de la commune |
| `arrondissement`, `province`, `region` | où se trouve la commune |
| `hommes`, `femmes`, `total` | population au 1er janvier 2026 |

Le bouton **Dictionnaire**, en haut de l'écran, décrit chaque colonne.

Ce cours est écrit pour les habitués de **SAS** : on part tout de suite d'une table, comme une table SAS, et on apprend à lui poser des questions. Le langage Python lui-même (listes, boucles, fonctions) viendra à la fin, quand il servira.

::: sas
Une table pandas (un **DataFrame**) joue le rôle d'une table SAS : des lignes (observations) et des colonnes (variables), chacune avec un type. Mais elle vit **en mémoire**, sans bibliothèque `WORK` : on la charge, on travaille, on enregistre ce qu'on veut garder.
:::

# Charger pandas et la table

Dans vos propres scripts (Jupyter, VS Code…), ces lignes se placent **en haut** :

```python norun
import pandas as pd

communes = pd.read_csv("communes_2026.csv", sep=";", dtype={"code_ins": str})
```

::: usage
- `import pandas as pd` charge **pandas**, la bibliothèque des tableaux de données. Par convention, on l'appelle `pd`.
- `pd.read_csv()` lit un fichier CSV. `sep=";"` indique le séparateur ; `dtype={"code_ins": str}` garde le code INS en texte. La leçon « Importer et exporter » détaille tous les réglages.
- Le `=` range le résultat sous un nom : `communes`.
:::

::: note
**Dans cet atelier, tout est déjà fait** : pandas est chargé et la table `communes` est prête. Ces lignes ne sont pas exécutées ici, mais vous les écrirez dans vos propres scripts.
:::

# Afficher la table

Taper le nom d'une table l'affiche. Pour une grande table, pandas montre les premières et les dernières lignes, et indique la taille en bas.

```python
communes
```

**Lecture :** 565 lignes (communes) et 8 colonnes (variables). À gauche, en gris, l'**index** : le numéro de chaque ligne, à partir de 0.

# head() : les premières lignes

```python
communes.head()
```

::: usage
`.head()` affiche les 5 premières lignes. On peut choisir le nombre : `communes.head(10)`. `.tail()` affiche les dernières.

Le point se lit « **de** » : `communes.head()`, c'est « le début de `communes` ».
:::

::: sas
`PROC PRINT DATA=communes (OBS=5);`
:::

# shape : la taille de la table

```python
communes.shape
```

Le résultat se lit `(lignes, colonnes)`. Un ordre de grandeur permet de détecter une importation ratée : 565 communes en Belgique depuis les fusions de 2025, c'est cohérent.

::: note
`shape` s'écrit **sans parenthèses** : c'est une caractéristique de la table, pas une action. Les actions (`head()`, `info()`…) ont des parenthèses.
:::

# info() : aperçu de toutes les colonnes

```python
communes.info()
```

::: usage
`.info()` donne, pour **chaque** colonne, son nom, le nombre de valeurs renseignées (*Non-Null Count*) et son type. C'est la première commande à lancer sur une table inconnue.
:::

::: piege
Regardez les types : `code_ins`, `commune`, `province` sont du texte (`str`), `hommes`, `femmes`, `total` des nombres entiers (`int64`). C'est ce qui décide si l'on écrit des guillemets ou non dans les conditions : `code_ins == "62063"`, mais `total > 50000`.
:::

::: sas
`PROC CONTENTS DATA=communes;`
:::

# Une colonne : communes["total"]

```python
communes["total"]
```

::: usage
`table["colonne"]` désigne **une colonne**. On s'en sert pour la regarder ou faire un calcul dessus : `communes["total"].sum()` donne la population de la Belgique.
:::

```python
communes["total"].sum()
```

# = : garder un résultat

Sans `=`, le résultat s'affiche puis disparaît. Avec `=`, on lui donne un nom pour le réutiliser, comme une nouvelle table SAS.

```python
wallonie = communes.query("region == 'Wallonie'")

wallonie.shape
```

::: piege
Écrire `communes = communes.query(...)` **écrase** la table : vous perdez toutes les autres lignes. Pour une sous-table, choisissez un **nouveau nom**. (Dans l'atelier, on récupère la table d'origine avec « Nouvel environnement ».)
:::

::: sas
`DATA wallonie; SET communes; WHERE region = 'Wallonie'; RUN;`
:::

# Enchaîner les étapes

Une étape prend la table, la suivante prend le résultat, et ainsi de suite. On écrit **une étape par ligne**, et on entoure le tout de **parenthèses** : la chaîne se lit de haut en bas, avec « **puis** ».

```python
(communes                              # je prends les communes,
 .query("region == 'Wallonie'")        # puis je garde la Wallonie,
 .sort_values("total", ascending=False)  # puis je trie par population décroissante,
 .head(3))                             # puis je garde les 3 premières
```

::: note
Les parenthèses autour de la chaîne permettent de passer à la ligne entre les étapes. Sans elles, Python croirait que l'instruction s'arrête au bout de la première ligne.
:::

::: sas
C'est l'équivalent d'une suite d'étapes DATA et PROC, sans les tables intermédiaires : chaque ligne reçoit le résultat de la précédente.
:::
