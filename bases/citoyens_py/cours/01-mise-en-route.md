---
titre: Mise en route
resume: La table des personnes, ses lignes et ses colonnes ; un échantillon d'enquête et ses pondérations ; afficher, regarder la structure, garder un résultat, enchaîner les étapes.
partie: Les bases
---

# La table des personnes : personnes

Chaque ligne de la table `personnes` est **une personne** interrogée dans une enquête auprès des ménages, en 2025 : son âge, sa situation sur le marché du travail, son ménage et le revenu de ce ménage.

| Colonne | Contenu |
|---|---|
| `id_personne`, `id_menage` | identifiants de la personne et de son ménage (les personnes qui vivent ensemble) |
| `region`, `province`, `commune`, `code_ins` | lieu de résidence |
| `sexe`, `age`, `classe_age` | qui est la personne |
| `statut`, `diplome` | en emploi, chômeur, inactif, étudiant, retraité ; niveau de diplôme |
| `type_menage`, `taille_menage` | isolé, couple avec ou sans enfants, famille monoparentale… |
| `revenu_menage`, `revenu_equivalent` | revenu disponible annuel du ménage, et ce revenu ramené à une personne seule |
| `poids` | **pondération** : combien de personnes de la population cette personne représente |

Le bouton **Dictionnaire**, en haut de l'écran, décrit chaque colonne.

::: piege
**Ces personnes sont fictives.** L'échantillon a été simulé pour l'atelier, avec des ordres de grandeur plausibles. Aucun chiffre ne décrit la Belgique : ne citez jamais ces résultats comme des statistiques officielles.
:::

::: sas
Une table pandas (un **DataFrame**) joue le rôle d'une table SAS : des lignes (observations) et des colonnes (variables). Mais elle vit **en mémoire**, sans bibliothèque `WORK` : on la charge, on travaille, on enregistre ce qu'on veut garder.
:::

# Charger pandas et la table

Dans vos propres scripts (Jupyter, VS Code…), ces lignes se placent **en haut** :

```python norun
import pandas as pd

personnes = pd.read_csv("personnes_2025.csv", sep=";", dtype={"code_ins": str})
```

::: usage
- `import pandas as pd` charge **pandas**, la bibliothèque des tableaux de données ;
- `pd.read_csv()` lit un fichier CSV ; `dtype={"code_ins": str}` garde le code INS en texte. La leçon « Importer et exporter » détaille tous les réglages ;
- le `=` range le résultat sous un nom : `personnes`.
:::

::: note
**Dans cet atelier, tout est déjà fait** : pandas est chargé et la table `personnes` est prête.
:::

# Afficher la table

```python
personnes
```

**Lecture :** 13 683 lignes (personnes) et 17 colonnes. À gauche, en gris, l'**index** : le numéro de chaque ligne, à partir de 0.

# head() : les premières lignes

```python
personnes.head()
```

::: usage
`.head()` affiche les 5 premières lignes ; `.head(10)` les 10 premières ; `.tail()` les dernières. Les personnes d'un même ménage se suivent : elles ont le même `id_menage` et le même `revenu_menage`.
:::

::: sas
`PROC PRINT DATA=personnes (OBS=5);`
:::

# shape et info() : la taille et la structure

```python
personnes.shape
```

```python
personnes.info()
```

**Lecture :** `diplome` n'est renseigné que pour 9 293 personnes : il ne concerne que les 25 ans et plus. Une valeur manquante n'est pas toujours une erreur : ici, la question n'a pas de sens pour un enfant.

::: sas
`PROC CONTENTS DATA=personnes;`
:::

# Un échantillon n'est pas la population

```python
personnes["region"].value_counts()
```

**Lecture :** un quart des personnes interrogées vivent à Bruxelles, alors que la région ne compte que 11 % des habitants du pays. L'enquête a **suréchantillonné** Bruxelles, pour avoir assez de répondants et y publier des résultats précis.

# La pondération : poids

Chaque personne représente un certain nombre d'habitants : c'est son **poids**. La somme des poids donne la population.

```python
print(personnes["poids"].sum())
personnes.groupby("region")["poids"].sum()
```

**Lecture :** les poids reconstituent les 11,87 millions d'habitants et leur vraie répartition entre régions. Un Bruxellois de l'échantillon pèse moins (il représente moins d'habitants) qu'un Flamand.

::: piege
**Règle d'or des enquêtes** : un pourcentage ou une moyenne qui décrit la **population** se calcule avec les poids. Compter les lignes décrit seulement l'**échantillon**. Les leçons suivantes montrent comment faire, et pourquoi le résultat change.
:::

::: sas
L'option `WEIGHT poids;` de `PROC MEANS` ou `PROC FREQ` (ou `PROC SURVEYMEANS`).
:::

# = : garder un résultat, et enchaîner les étapes

```python
jeunes = personnes.query("age >= 18 and age <= 24")
jeunes.shape
```

Une étape par ligne, entre parenthèses, se lit avec « **puis** » :

```python
(personnes                                   # je prends les personnes,
 .query("region == 'Wallonie'")              # puis je garde la Wallonie,
 .sort_values("revenu_equivalent")           # puis je trie par revenu croissant,
 [["id_menage", "age", "statut", "type_menage", "revenu_equivalent"]]
 .head(5))                                   # puis je garde les 5 premières
```

::: piege
Écrire `personnes = personnes.query(...)` **écrase** la table. Pour une sous-table, choisissez un **nouveau nom**. (Dans l'atelier, « Nouvel environnement » recharge la table d'origine.)
:::
