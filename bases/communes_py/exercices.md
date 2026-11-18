---
base: communes_py
---

# Les communes de la province de Namur
niveau: 1
theme: query + len

## Énoncé
Combien de communes compte la province de Namur ?

## Indice
Filtrez avec `query()` (le nom de la province entre guillemets simples), puis comptez les lignes avec `len()`.

## Code de départ
```python
len(communes.query(...))
```

## Correction
```python
len(communes.query("province == 'Namur'"))
```

## Commentaire
38 communes. `communes["province"].value_counts()` donne la réponse pour toutes les provinces à la fois.

# La population de la Région wallonne
niveau: 1
theme: query + sum

## Énoncé
Quelle est la population totale de la Wallonie au 1er janvier 2026 ?

## Indice
Filtrez la région, prenez la colonne `total`, puis faites la somme.

## Correction
```python
communes.query("region == 'Wallonie'")["total"].sum()
```

## Commentaire
3 713 450 habitants. On retrouve exactement le chiffre publié par Statbel pour la Région wallonne : la table est complète.

# Les grandes villes de Flandre
niveau: 1
theme: query + colonnes

## Énoncé
Affichez le nom et la population des communes flamandes de plus de 100 000 habitants.

## Indice
Deux conditions avec `and`, puis `[["commune", "total"]]`.

## Correction
```python
communes.query("region == 'Flandre' and total > 100000")[["commune", "total"]]
```

## Commentaire
Quatre villes : Anvers (565 615 habitants, la plus grande commune du pays), Gand, Bruges et Louvain. Malines, avec 90 355 habitants, reste sous le seuil.

# La plus petite commune de chaque région
niveau: 1
theme: nsmallest

## Énoncé
Quelle est la plus petite commune de Wallonie ? Affichez son nom et sa population.

## Indice
Filtrez la région, puis `nsmallest(1, "total")`.

## Correction
```python
communes.query("region == 'Wallonie'").nsmallest(1, "total")[["commune", "total"]]
```

## Commentaire
Daverdisse (province de Luxembourg), 1 397 habitants. En Flandre, c'est Herstappe, la plus petite commune de Belgique avec 78 habitants.

# Combien de communes de moins de 5 000 habitants ?
niveau: 1
theme: query + len

## Énoncé
Combien de communes belges comptent moins de 5 000 habitants ?

## Correction
```python
len(communes.query("total < 5000"))
```

## Commentaire
66 communes. Écrire `communes.query("total < 5000").shape[0]` donne le même résultat : `shape[0]` est le nombre de lignes.

# Les communes dont le nom contient « Saint »
niveau: 1
theme: query + str.contains

## Énoncé
Combien de communes ont « Saint » dans leur nom ?

## Indice
`commune.str.contains('Saint')` dans `query()`.

## Correction
```python
len(communes.query("commune.str.contains('Saint')"))
```

## Commentaire
Attention à la casse : `'saint'` en minuscules ne trouverait rien. Pour ignorer les majuscules : `commune.str.contains('saint', case=False)`.

# Le nombre de communes par province
niveau: 2
theme: groupby + size

## Énoncé
Calculez le nombre de communes de chaque province, sous forme de table (une colonne `province`, une colonne avec le nombre).

## Indice
`groupby("province", as_index=False)` puis `.size()`.

## Correction
```python
communes.groupby("province", as_index=False).size()
```

## Commentaire
La province de Liège a le plus de communes (84), le Brabant wallon le moins (27), sans compter les 19 communes de Bruxelles-Capitale. `communes["province"].value_counts()` donne les mêmes chiffres, triés.

# Population et taille médiane par région
niveau: 2
theme: groupby + agg

## Énoncé
Pour chaque région, calculez la population totale (`population`) et la population médiane d'une commune (`mediane`).

## Indice
`.agg(population=("total", "sum"), mediane=("total", "median"))`.

## Correction
```python
(communes
 .groupby("region", as_index=False)
 .agg(population=("total", "sum"),
      mediane=("total", "median")))
```

## Commentaire
La commune médiane compte 8 719 habitants en Wallonie, 16 742 en Flandre et 49 638 à Bruxelles. Les noms de colonnes peuvent différer des vôtres : la vérification compare les valeurs.

# Les arrondissements les plus peuplés
niveau: 2
theme: groupby + sort_values + head

## Énoncé
Quels sont les 5 arrondissements les plus peuplés ? Affichez leur nom et leur population, du plus peuplé au moins peuplé.

## Correction
```python
(communes
 .groupby("arrondissement", as_index=False)
 .agg(population=("total", "sum"))
 .sort_values("population", ascending=False)
 .head(5))
```

## Commentaire
Bruxelles-Capitale, Anvers, Hal-Vilvorde, Liège et Gand. `.nlargest(5, "population")` remplace `sort_values` + `head`.

# Les provinces de plus d'un million d'habitants
niveau: 2
theme: groupby + query après

## Énoncé
Quelles provinces comptent plus d'un million d'habitants ? (Bruxelles-Capitale compte ici comme une province.)

## Indice
Le filtre porte sur un résultat **calculé** : il vient après le regroupement.

## Correction
```python
(communes
 .groupby("province", as_index=False)
 .agg(population=("total", "sum"))
 .query("population > 1000000"))
```

## Commentaire
Sept : Anvers, Brabant flamand, Bruxelles-Capitale, Flandre occidentale, Flandre orientale, Hainaut et Liège.

# Les communes de plus de 20 000 habitants par région
niveau: 2
theme: query puis groupby

## Énoncé
Pour chaque région, combien de communes comptent plus de 20 000 habitants ?

## Correction
```python
(communes
 .query("total > 20000")
 .groupby("region", as_index=False)
 .size())
```

## Commentaire
Toutes les communes bruxelloises (19), 111 en Flandre, 42 en Wallonie. Ici le filtre porte sur les communes : il vient **avant** le regroupement.

# La part des femmes dans chaque commune
niveau: 3
theme: nouvelle colonne

## Énoncé
Créez la colonne `part_femmes` (en %, arrondie à 1 décimale), puis affichez les 3 communes où elle est la plus élevée, avec leur nom et `part_femmes`.

## Correction
```python
communes["part_femmes"] = (communes["femmes"] / communes["total"] * 100).round(1)
communes.nlargest(3, "part_femmes")[["commune", "part_femmes"]]
```

## Commentaire
Trois communes bruxelloises : Watermael-Boitsfort (53,8 %), Uccle (53,5 %) et Woluwe-Saint-Lambert (53,4 %). Les femmes vivent plus longtemps : les communes dont la population est plus âgée comptent plus de femmes.

# Les communes où les hommes sont majoritaires
niveau: 3
theme: variable vrai / faux

## Énoncé
Créez une colonne `plus_d_hommes` (vrai si la commune compte plus d'hommes que de femmes), puis calculez **le nombre** de ces communes.

## Indice
Une comparaison crée une colonne `True` / `False` ; `.sum()` compte les `True`.

## Correction
```python
communes["plus_d_hommes"] = communes["hommes"] > communes["femmes"]
communes["plus_d_hommes"].sum()
```

## Commentaire
113 communes sur 565 comptent plus d'hommes que de femmes, une sur cinq environ. Deux communes, Modave et Peer, ont exactement autant d'hommes que de femmes.

# Des classes de taille
niveau: 3
theme: pd.cut + value_counts

## Énoncé
Créez la colonne `taille` avec trois classes : moins de 10 000 habitants, de 10 000 à 50 000, plus de 50 000. Comptez les communes de chaque classe, dans l'ordre des classes.

## Indice
`pd.cut(communes["total"], bins=[0, 10000, 50000, 600000], labels=[...])`, puis `.value_counts().sort_index()`.

## Correction
```python
communes["taille"] = pd.cut(communes["total"], bins=[0, 10000, 50000, 600000],
                            labels=["< 10 000", "10 000 à 50 000", "50 000 et +"])
communes["taille"].value_counts().sort_index()
```

## Commentaire
203 communes de moins de 10 000 habitants, 330 entre 10 000 et 50 000, 32 au-delà. Une commune de 10 000 habitants exactement tomberait dans la première classe : la borne de droite est incluse.

# Le poids de chaque commune dans sa province
niveau: 3
theme: groupby + transform

## Énoncé
Calculez pour chaque commune sa part dans la population de sa province (en %, 1 décimale), dans une colonne `part_province`. Affichez ensuite la commune qui pèse le plus dans la province de Luxembourg.

## Indice
`communes.groupby("province")["total"].transform("sum")` donne la population de la province sur chaque ligne.

## Correction
```python
communes["part_province"] = (communes["total"]
                             / communes.groupby("province")["total"].transform("sum")
                             * 100).round(1)
communes.query("province == 'Luxembourg'").nlargest(1, "part_province")[["commune", "part_province"]]
```

## Commentaire
Arlon, avec 10,6 % de la population de la province. Aucune commune ne domine le Luxembourg : à comparer avec Anvers, qui pèse 29,3 % de sa province.

# Hommes et femmes par région, en colonnes
niveau: 4
theme: pivot_table

## Énoncé
À partir de la table `pop_sexe`, calculez la population par région (en lignes) et par sexe (en colonnes).

## Indice
`pivot_table(index=..., columns=..., values="population", aggfunc="sum")`.

## Correction
```python
pop_sexe.pivot_table(index="region", columns="sexe", values="population", aggfunc="sum")
```

## Commentaire
Dans les trois régions, les femmes sont plus nombreuses que les hommes. Avec `margins=True`, on ajoute les totaux.

# Passer au format long
niveau: 4
theme: melt

## Énoncé
À partir de `communes`, construisez une table longue avec une ligne par commune et par sexe : colonnes `code_ins`, `commune`, `sexe` (`hommes` ou `femmes`) et `population`. Affichez sa taille.

## Correction
```python
long = communes.melt(id_vars=["code_ins", "commune"], value_vars=["hommes", "femmes"],
                     var_name="sexe", value_name="population")
long.shape
```

## Commentaire
1 130 lignes (565 communes × 2 sexes) et 4 colonnes. C'est la forme de la table `pop_sexe`.

# Région et taille : pourcentages en ligne
niveau: 4
theme: crosstab normalize

## Énoncé
Avec les classes « moins de 10 000 » et « 10 000 et plus », calculez pour chaque région le **pourcentage de ses communes** dans chaque classe (1 décimale).

## Indice
Le dénominateur est la région (la ligne) : `normalize="index"`.

## Code de départ
```python
communes["taille"] = pd.cut(communes["total"], bins=[0, 10000, 600000],
                            labels=["< 10 000", "10 000 et +"])
```

## Correction
```python
communes["taille"] = pd.cut(communes["total"], bins=[0, 10000, 600000],
                            labels=["< 10 000", "10 000 et +"])
(pd.crosstab(communes["region"], communes["taille"], normalize="index") * 100).round(1)
```

## Commentaire
56,7 % des communes wallonnes comptent moins de 10 000 habitants, contre 19,3 % des communes flamandes et aucune commune bruxelloise. Chaque ligne fait 100 %.

# Région et taille : part des habitants
niveau: 4
theme: crosstab values + aggfunc

## Énoncé
Même tableau, mais avec la part des **habitants** de chaque région (et non des communes) qui vivent dans chaque classe.

## Correction
```python
communes["taille"] = pd.cut(communes["total"], bins=[0, 10000, 600000],
                            labels=["< 10 000", "10 000 et +"])
(pd.crosstab(communes["region"], communes["taille"], values=communes["total"],
             aggfunc="sum", normalize="index") * 100).round(1)
```

## Commentaire
En Wallonie, 23,1 % des habitants vivent dans une commune de moins de 10 000 habitants, alors que ces communes représentent 56,7 % des communes wallonnes.

# Un graphique de la population par région
niveau: 4
theme: seaborn
verif: aucune

## Énoncé
Dessinez un diagramme en barres de la population de chaque région, avec un titre.

## Indice
Calculez d'abord la table (`groupby` + `agg`), puis `sns.barplot(data=..., x=..., y=...)` et `plt.title(...)`. N'oubliez pas les `import`.

## Correction
```python
import seaborn as sns
import matplotlib.pyplot as plt

par_region = communes.groupby("region", as_index=False).agg(population=("total", "sum"))
par_region["millions"] = par_region["population"] / 1e6
sns.barplot(data=par_region, x="region", y="millions")
plt.title("Population par région, 1er janvier 2026 (millions)")
plt.xlabel("")
plt.ylabel("Millions d'habitants")
```

## Commentaire
Pas de vérification automatique pour un graphique : comparez avec la correction. Diviser par un million évite une échelle en notation scientifique.

# Une fiche par province
niveau: 5
theme: groupby + agg + nouvelle colonne + tri

## Énoncé
Construisez une table avec une ligne par province : nombre de communes, population, population de la plus grande commune, et la **part** de cette plus grande commune dans la province (en %, 1 décimale). Triez par part décroissante.

## Indice
`agg(communes=("commune", "count"), population=("total", "sum"), plus_grande=("total", "max"))`, puis une nouvelle colonne.

## Correction
```python
fiche = (communes
         .groupby("province", as_index=False)
         .agg(communes=("commune", "count"),
              population=("total", "sum"),
              plus_grande=("total", "max")))
fiche["part_plus_grande"] = (fiche["plus_grande"] / fiche["population"] * 100).round(1)
fiche.sort_values("part_plus_grande", ascending=False)
```

## Commentaire
Anvers (29,3 %) et Namur (22,8 %) sont les provinces les plus dominées par leur plus grande commune ; le Brabant flamand (8,7 %, Louvain) et la Flandre occidentale (9,7 %, Bruges), les moins. Attention : la plus grande commune n'est pas toujours le chef-lieu (Braine-l'Alleud, et non Wavre, dans le Brabant wallon).

# Quelle part des Belges vit dans une commune de plus de 100 000 habitants ?
niveau: 5
theme: deux sommes, une part

## Énoncé
Calculez le pourcentage de la population belge qui vit dans une commune de plus de 100 000 habitants (1 décimale).

## Correction
```python
grandes = communes.query("total > 100000")["total"].sum()
round(grandes / communes["total"].sum() * 100, 1)
```

## Commentaire
17,2 % des Belges vivent dans l'une des 10 communes de plus de 100 000 habitants.

# Lire le fichier Statbel d'origine
niveau: 3
groupe: Vos propres fichiers
theme: read_csv, paramètres

## Énoncé
Lisez `donnees/population_2026.txt` (texte tabulé de Statbel) avec les bons paramètres : lignes vides sautées, point des milliers, code INS en texte. Sur la dernière ligne, affichez la population totale de la Belgique : la colonne `Total` de la première ligne, `brut["Total"][0]`.

## Indice
`sep="\t"`, `skiprows=[1, 2]`, `thousands="."`, `dtype={" Code INS": str}` (attention à l'espace au début du nom).

## Correction
```python
brut = pd.read_csv("donnees/population_2026.txt", sep="\t", skiprows=[1, 2],
                   thousands=".", dtype={" Code INS": str})
brut["Total"][0]
```

## Commentaire
11 867 634 habitants. Sans `thousands="."`, la colonne `Total` serait du texte, et `"11.867.634"` ne s'additionne pas.

# Ajouter les noms néerlandais
niveau: 4
groupe: Vos propres fichiers
theme: merge, validate

## Énoncé
Lisez la nomenclature `referentiels/nuts_lau_2027.txt` (séparateur `|`, encodage `cp1252`), gardez les communes en vigueur (`CD_LVL == 4` et `DT_VLDT_STOP == '31/12/9999'`), et ajoutez à `communes` leur nom en néerlandais (`TX_DESCR_NL`), avec `validate="many_to_one"`. Sur la dernière ligne, affichez le nom néerlandais de Mons.

## Indice
Renommez `CD_MUNTY_REFNIS` en `code_ins` (et lisez-le en texte : `dtype={"CD_MUNTY_REFNIS": str}`) pour pouvoir joindre `on="code_ins"`.

## Correction
```python
nuts = pd.read_csv("referentiels/nuts_lau_2027.txt", sep="|", encoding="cp1252",
                   dtype={"CD_MUNTY_REFNIS": str})
noms = (nuts.query("CD_LVL == 4 and DT_VLDT_STOP == '31/12/9999'")
        .rename(columns={"CD_MUNTY_REFNIS": "code_ins", "TX_DESCR_NL": "nom_nl"})
        [["code_ins", "nom_nl"]])
avec_nl = communes.merge(noms, on="code_ins", how="left", validate="many_to_one")
avec_nl.query("commune == 'Mons'")["nom_nl"].iloc[0]
```

## Commentaire
Mons se dit « Bergen » en néerlandais. `.iloc[0]` prend la première (et seule) valeur de la colonne filtrée. Sans le filtre sur les communes en vigueur, `validate` arrêterait la fusion : la nomenclature contient plusieurs lignes pour certains codes.

# Nettoyer les livraisons régionales
niveau: 5
groupe: Vos propres fichiers
theme: drop_duplicates, str, isna

## Énoncé
La table `livraisons` (les trois fichiers régionaux empilés) est prête. Supprimez les doublons, harmonisez `code_ins` (espaces) et `sexe` (majuscules), écartez les populations manquantes ou négatives. Sur la dernière ligne, affichez le nombre de lignes gardées.

## Indice
`drop_duplicates()`, `.str.strip()`, `.str.upper()`, puis `query("population >= 0")` (une population manquante ne vérifie pas la condition).

## Préparation
```python
bxl = pd.read_csv("donnees/population_bruxelles_2026.csv", sep=";", dtype={"code_ins": str})
fla = pd.read_excel("donnees/population_flandre_2026.xlsx", header=2, dtype={"code_ins": str})
wal = pd.read_csv("donnees/population_wallonie_2026.txt", sep="\t", dtype={"code_ins": str})
livraisons = pd.concat([bxl, fla, wal], ignore_index=True)
```

## Correction
```python
propre = livraisons.drop_duplicates().copy()
propre["code_ins"] = propre["code_ins"].str.strip()
propre["sexe"] = propre["sexe"].str.strip().str.upper()
propre = propre.query("population >= 0")
len(propre)
```

## Commentaire
1 129 lignes gardées sur 1 132 : un doublon (Gand) et deux populations impossibles (Daverdisse, Martelange). Une valeur manquante (`NaN`) rend toute comparaison fausse : `query("population >= 0")` l'écarte en même temps que les négatives.

# La même question en SQL
niveau: 4
groupe: Vos propres fichiers
theme: DuckDB, GROUP BY

## Énoncé
Avec DuckDB, calculez pour chaque province le nombre de communes de moins de 5 000 habitants, triées de la province qui en a le plus à celle qui en a le moins. Récupérez le résultat en table pandas.

## Indice
`duckdb.sql("""SELECT ... FROM communes WHERE ... GROUP BY ... ORDER BY ... DESC""").df()`, après `import duckdb`.

## Correction
```python
import duckdb

duckdb.sql("""
    SELECT province, COUNT(*) AS petites
    FROM communes
    WHERE total < 5000
    GROUP BY province
    ORDER BY petites DESC
""").df()
```

## Commentaire
Liège (23) et Luxembourg (17) en tête. La même chose en pandas : `communes.query("total < 5000").groupby("province").size().sort_values(ascending=False)`.
