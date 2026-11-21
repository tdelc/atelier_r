---
base: citoyens_py
---

# Les répondants wallons
niveau: 1
theme: query + len

## Énoncé
Combien de personnes de l'échantillon vivent en Wallonie ?

## Indice
Filtrez avec `query()` (le nom de la région entre guillemets simples), puis comptez les lignes avec `len()`.

## Code de départ
```python
len(personnes.query(...))
```

## Correction
```python
len(personnes.query("region == 'Wallonie'"))
```

## Commentaire
4 128 répondants. C'est la taille de l'**échantillon**, pas la population wallonne : pour celle-ci, il faut additionner les poids.

# La population wallonne
niveau: 1
theme: query + sum des poids

## Énoncé
Combien d'habitants les répondants wallons représentent-ils ? Additionnez leurs poids.

## Correction
```python
personnes.query("region == 'Wallonie'")["poids"].sum()
```

## Commentaire
Environ 3,71 millions d'habitants : les poids reconstituent la population de la région.

# Les familles monoparentales
niveau: 1
theme: query + nunique

## Énoncé
Combien de **ménages** de l'échantillon sont des familles monoparentales ?

## Indice
Filtrez le type de ménage, puis comptez les identifiants de ménage **distincts** : `["id_menage"].nunique()`.

## Correction
```python
personnes.query("type_menage == 'famille monoparentale'")["id_menage"].nunique()
```

## Commentaire
608 ménages. Compter les lignes donnerait le nombre de **personnes** vivant dans ces ménages, parents et enfants. Choisissez toujours l'unité : personne ou ménage.

# Les jeunes chômeurs
niveau: 1
theme: query + between

## Énoncé
Combien de chômeurs de 15 à 24 ans compte l'échantillon ?

## Correction
```python
len(personnes.query("statut == 'chômeur' and age.between(15, 24)"))
```

## Commentaire
211 répondants : un taux de chômage des jeunes calculé par région sur un si petit effectif serait très imprécis.

# Le revenu équivalent médian de l'échantillon
niveau: 1
theme: median

## Énoncé
Quel est le revenu équivalent médian de l'échantillon (sans pondération) ?

## Correction
```python
personnes["revenu_equivalent"].median()
```

## Commentaire
27 529 euros par an. La médiane **pondérée**, qui décrit la population, est plus élevée (28 067 euros) : l'échantillon contient trop de Bruxellois.

# La population par classe d'âge
niveau: 2
theme: groupby + sum des poids

## Énoncé
Calculez la population (somme des poids) de chaque classe d'âge, sous forme de table.

## Correction
```python
personnes.groupby("classe_age", as_index=False).agg(population=("poids", "sum"))
```

## Commentaire
Les poids ont été calés sur une structure par âge de la population : c'est le principe du **calage** des enquêtes.

# Le revenu moyen pondéré par région
niveau: 2
theme: groupby + moyenne pondérée

## Énoncé
Calculez, pour chaque région, le revenu équivalent moyen **pondéré** (colonne `revenu_moyen`).

## Indice
Créez d'abord une colonne `revenu_equivalent * poids`, additionnez-la par région avec la somme des poids, puis divisez.

## Correction
```python
personnes["rp"] = personnes["revenu_equivalent"] * personnes["poids"]
t = personnes.groupby("region", as_index=False).agg(rp=("rp", "sum"), population=("poids", "sum"))
t["revenu_moyen"] = t["rp"] / t["population"]
t[["region", "revenu_moyen"]]
```

## Commentaire
Environ 26 200 euros à Bruxelles, 31 000 en Flandre et 27 700 en Wallonie. `np.average(x, weights=poids)` donnerait le même résultat pour un seul groupe.

# Le taux de pauvreté de l'échantillon
niveau: 2
theme: seuil + mean

## Énoncé
Le seuil de pauvreté est fixé à 16 840 euros. Quelle part de l'échantillon (en %, 1 décimale, **sans** pondération) a un revenu équivalent inférieur au seuil ?

## Correction
```python
round((personnes["revenu_equivalent"] < 16840).mean() * 100, 1)
```

## Commentaire
16,3 % de l'échantillon. Avec les poids, le taux de la population est de 14,0 % : l'oubli des poids surestime la pauvreté de plus de deux points.

# Le taux de pauvreté pondéré par région
niveau: 2
theme: groupby + taux pondéré

## Énoncé
Avec le seuil de 16 840 euros, calculez le taux de risque de pauvreté **pondéré** de chaque région (en %, 1 décimale).

## Indice
Une colonne `pauvres_pond` = (revenu sous le seuil) × poids ; par région, la somme de cette colonne divisée par la somme des poids.

## Correction
```python
personnes["pauvres_pond"] = (personnes["revenu_equivalent"] < 16840) * personnes["poids"]
t = personnes.groupby("region", as_index=False).agg(pauvres=("pauvres_pond", "sum"),
                                                    population=("poids", "sum"))
t["taux"] = (t["pauvres"] / t["population"] * 100).round(1)
t[["region", "taux"]]
```

## Commentaire
22,7 % à Bruxelles, 10,9 % en Flandre, 17,0 % en Wallonie (données fictives).

# Le taux de chômage
niveau: 3
theme: dénominateur, taux pondéré

## Énoncé
Calculez le taux de chômage **pondéré** de la Belgique (en %, 1 décimale) : parmi les actifs de 15 à 64 ans (en emploi ou chômeurs), la part des chômeurs.

## Indice
Filtrez d'abord les actifs de 15 à 64 ans ; puis somme des poids des chômeurs divisée par la somme des poids.

## Correction
```python
actifs = personnes.query("age.between(15, 64) and statut in ['en emploi', 'chômeur']")
chomeurs = actifs.query("statut == 'chômeur'")["poids"].sum()
round(chomeurs / actifs["poids"].sum() * 100, 1)
```

## Commentaire
6,4 % (données fictives). Le dénominateur est la population **active**, pas toute la population : les étudiants, retraités et inactifs n'y figurent pas.

# Le taux d'emploi des 20-64 ans
niveau: 3
theme: dénominateur, taux pondéré

## Énoncé
Calculez le taux d'emploi **pondéré** des 20 à 64 ans pour chaque région (en %, 1 décimale).

## Correction
```python
pop = personnes.query("age.between(20, 64)").copy()
pop["emploi_pond"] = (pop["statut"] == "en emploi") * pop["poids"]
t = pop.groupby("region", as_index=False).agg(emploi=("emploi_pond", "sum"), population=("poids", "sum"))
t["taux_emploi"] = (t["emploi"] / t["population"] * 100).round(1)
t[["region", "taux_emploi"]]
```

## Commentaire
Cette fois, le dénominateur est **toute** la population de 20 à 64 ans. Un taux de chômage de 10 % ne correspond pas à un taux d'emploi de 90 %.

# Des classes de revenu
niveau: 3
theme: np.select

## Énoncé
Créez la colonne `classe_revenu` : `"sous le seuil"` (revenu équivalent inférieur à 16 840 €), `"modeste"` (moins de 28 067 €, la médiane), `"aisé"` (moins de 56 134 €, le double de la médiane), `"très aisé"` sinon. Comptez les personnes de chaque classe.

## Indice
`np.select([condition1, condition2, condition3], [valeur1, valeur2, valeur3], default=...)`, puis `value_counts()`.

## Correction
```python
r = personnes["revenu_equivalent"]
personnes["classe_revenu"] = np.select([r < 16840, r < 28067, r < 56134],
                                       ["sous le seuil", "modeste", "aisé"], default="très aisé")
personnes["classe_revenu"].value_counts()
```

## Commentaire
Les conditions sont testées dans l'ordre : `r < 28067` ne concerne que les personnes qui ne sont pas déjà « sous le seuil ».

# Le nombre d'actifs occupés du ménage
niveau: 3
theme: groupby + transform

## Énoncé
Créez la colonne `en_emploi_menage` : le nombre de personnes **en emploi** dans le ménage de chaque personne. Combien de personnes vivent dans un ménage où **personne** ne travaille ?

## Indice
Une colonne vrai/faux « en emploi », puis `groupby("id_menage")[...].transform("sum")`.

## Correction
```python
personnes["en_emploi"] = personnes["statut"] == "en emploi"
personnes["en_emploi_menage"] = personnes.groupby("id_menage")["en_emploi"].transform("sum")
len(personnes.query("en_emploi_menage == 0"))
```

## Commentaire
3 091 personnes, dont beaucoup de retraités : pour parler des « ménages sans emploi », on se limite d'habitude aux adultes d'âge actif (voir la leçon « Créer des variables »).

# Pauvreté par région et par âge, en tableau
niveau: 4
theme: pivot_table + division

## Énoncé
Construisez le tableau des taux de pauvreté pondérés (en %, 1 décimale) avec les régions en lignes et les classes d'âge en colonnes. Seuil : 16 840 €.

## Indice
Deux `pivot_table` (la somme des `pauvres_pond`, la somme des `poids`), puis une division case par case.

## Correction
```python
personnes["pauvres_pond"] = (personnes["revenu_equivalent"] < 16840) * personnes["poids"]
p = personnes.pivot_table(index="region", columns="classe_age", values="pauvres_pond", aggfunc="sum")
n = personnes.pivot_table(index="region", columns="classe_age", values="poids", aggfunc="sum")
(p / n * 100).round(1)
```

## Commentaire
Dans chaque région, les jeunes de 18 à 24 ans et les enfants sont les plus exposés, les 65 ans et plus le moins.

# Taux ou composition ?
niveau: 4
theme: crosstab pondéré normalize

## Énoncé
Avec le seuil de 16 840 €, calculez la **composition** de la population pauvre selon le statut : parmi les personnes sous le seuil, quelle part (pondérée, en %, 1 décimale) dans chaque statut ?

## Indice
Filtrez d'abord les personnes sous le seuil, puis la somme des poids par statut divisée par la somme totale des poids.

## Correction
```python
pauvres = personnes.query("revenu_equivalent < 16840")
(pauvres.groupby("statut")["poids"].sum() / pauvres["poids"].sum() * 100).round(1)
```

## Commentaire
Les chômeurs ne forment qu'environ 5 % des pauvres, alors qu'un chômeur sur quatre est pauvre. Taux (parmi les chômeurs) et composition (parmi les pauvres) répondent à deux questions différentes.

# Le revenu moyen des ménages
niveau: 4
theme: drop_duplicates, unité ménage

## Énoncé
Calculez le revenu disponible **moyen des ménages** de l'échantillon (sans pondération), en gardant **une ligne par ménage**.

## Correction
```python
personnes.drop_duplicates("id_menage")["revenu_menage"].mean()
```

## Commentaire
Environ 44 710 euros. Sur la table des personnes, un ménage de cinq personnes compterait cinq fois : la moyenne serait plus élevée, car les grands ménages ont souvent plusieurs revenus.

# Un graphique du taux de pauvreté par type de ménage
niveau: 4
theme: seaborn
verif: aucune

## Énoncé
Dessinez un diagramme en barres horizontales du taux de pauvreté **pondéré** par type de ménage (seuil : 16 840 €), trié du plus élevé au plus bas, avec un titre.

## Indice
Calculez d'abord la table des taux, triez-la, puis `sns.barplot(data=..., x="taux", y="type_menage")`.

## Correction
```python
import seaborn as sns
import matplotlib.pyplot as plt

personnes["pauvres_pond"] = (personnes["revenu_equivalent"] < 16840) * personnes["poids"]
t = personnes.groupby("type_menage", as_index=False).agg(pauvres=("pauvres_pond", "sum"),
                                                         population=("poids", "sum"))
t["taux"] = t["pauvres"] / t["population"] * 100
sns.barplot(data=t.sort_values("taux", ascending=False), x="taux", y="type_menage")
plt.title("Risque de pauvreté selon le type de ménage (données fictives)")
plt.xlabel("%")
plt.ylabel("")
```

## Commentaire
Pas de vérification automatique pour un graphique : comparez avec la correction. Ne donnez pas la table brute à seaborn : il calculerait des moyennes non pondérées.

# La médiane pondérée
niveau: 5
theme: tri + cumsum

## Énoncé
Calculez la médiane **pondérée** du revenu équivalent : triez les personnes par revenu, cumulez les poids, et prenez le revenu de la première personne pour laquelle le cumul atteint la moitié de la somme des poids.

## Indice
`tri = personnes.sort_values("revenu_equivalent")`, `cumul = tri["poids"].cumsum()`, puis `tri.loc[cumul >= ..., "revenu_equivalent"].iloc[0]`.

## Correction
```python
tri = personnes.sort_values("revenu_equivalent")
cumul = tri["poids"].cumsum()
tri.loc[cumul >= tri["poids"].sum() / 2, "revenu_equivalent"].iloc[0]
```

## Commentaire
28 067 euros. Le seuil de pauvreté européen vaut 60 % de cette médiane : 16 840 euros par an pour une personne seule.

# La pauvreté des enfants selon le travail des parents
niveau: 5
theme: transform + np.select + taux pondéré

## Énoncé
Pour les enfants (moins de 18 ans), calculez le taux de pauvreté pondéré (seuil : 16 840 €, en %, 1 décimale) selon que **personne**, **une partie** ou **tous** les adultes de 18 à 59 ans (hors étudiants) de leur ménage sont en emploi. Les colonnes `nb_adultes` et `nb_en_emploi` sont déjà créées.

## Préparation
```python
adulte = personnes["age"].between(18, 59) & (personnes["statut"] != "étudiant")
personnes["adulte"] = adulte
personnes["adulte_en_emploi"] = adulte & (personnes["statut"] == "en emploi")
personnes["nb_adultes"] = personnes.groupby("id_menage")["adulte"].transform("sum")
personnes["nb_en_emploi"] = personnes.groupby("id_menage")["adulte_en_emploi"].transform("sum")
```

## Correction
```python
enfants = personnes.query("age < 18 and nb_adultes > 0").copy()
enfants["intensite"] = np.select([enfants["nb_en_emploi"] == 0,
                                  enfants["nb_en_emploi"] < enfants["nb_adultes"]],
                                 ["personne", "une partie"], default="tous")
enfants["pauvres_pond"] = (enfants["revenu_equivalent"] < 16840) * enfants["poids"]
t = enfants.groupby("intensite", as_index=False).agg(pauvres=("pauvres_pond", "sum"),
                                                     population=("poids", "sum"))
t["taux"] = (t["pauvres"] / t["population"] * 100).round(1)
t[["intensite", "taux"]]
```

## Commentaire
Près de neuf enfants sur dix sont sous le seuil quand aucun adulte ne travaille, contre 6,9 % quand tous travaillent : le travail des parents est le premier facteur de la pauvreté des enfants.

# Lire l'extrait du registre
niveau: 3
groupe: Vos propres fichiers
theme: read_csv, dtype

## Énoncé
Lisez `donnees/registre_national_2026.csv` (séparateur `;`) en gardant `id_pseudo` et `code_ins` en **texte**. Sur la dernière ligne, affichez le nombre de pseudonymes **distincts**.

## Correction
```python
rn = pd.read_csv("donnees/registre_national_2026.csv", sep=";",
                 dtype={"id_pseudo": str, "code_ins": str})
rn["id_pseudo"].nunique()
```

## Commentaire
13 478 personnes pour 13 628 lignes : 150 personnes ont deux lignes (un déménagement en 2025). Une clé qui n'est pas unique est le premier piège d'un couplage.

# Les personnes non retrouvées
niveau: 4
groupe: Vos propres fichiers
theme: merge, validate, indicator

## Énoncé
Gardez la dernière adresse de chaque personne du registre (`date_debut_adresse` la plus récente), couplez-le à `personnes` (`how="left"`, `validate="one_to_one"`, `indicator=True`), et affichez sur la dernière ligne le nombre de personnes de l'enquête **non retrouvées** dans le registre.

## Indice
`sort_values("date_debut_adresse").drop_duplicates("id_pseudo", keep="last")`, puis `(m["_merge"] == "left_only").sum()`.

## Préparation
```python
rn = pd.read_csv("donnees/registre_national_2026.csv", sep=";",
                 dtype={"id_pseudo": str, "code_ins": str})
```

## Correction
```python
dernier = rn.sort_values("date_debut_adresse").drop_duplicates("id_pseudo", keep="last")
m = personnes.merge(dernier, on="id_pseudo", how="left", validate="one_to_one",
                    indicator=True, suffixes=("", "_rn"))
int((m["_merge"] == "left_only").sum())
```

## Commentaire
205 personnes, soit 1,5 % de l'échantillon. Elles ne sont pas prises au hasard : on les compte et on les décrit, on ne les supprime pas en silence.

# Chômeurs sans allocation
niveau: 4
groupe: Vos propres fichiers
theme: merge, fillna

## Énoncé
Lisez `donnees/onem_allocations_2025.xlsx` (deux lignes de titre, `id_pseudo` en texte), couplez-le à `personnes` (`how="left"`), remplacez les types d'allocation manquants par `"aucune"`, et affichez sur la dernière ligne le nombre de **chômeurs au sens du BIT** qui ne perçoivent **aucune** allocation.

## Correction
```python
onem = pd.read_excel("donnees/onem_allocations_2025.xlsx", header=2, dtype={"id_pseudo": str})
m = personnes.merge(onem, on="id_pseudo", how="left", validate="one_to_one")
m["type_allocation"] = m["type_allocation"].fillna("aucune")
len(m.query("statut == 'chômeur' and type_allocation == 'aucune'"))
```

## Commentaire
78 chômeurs sur 505 ne touchent pas d'allocation. Ici, `fillna("aucune")` est juste : absent du fichier de l'ONEM veut dire « pas d'allocation ».

# Recoder les anciennes communes
niveau: 5
groupe: Vos propres fichiers
theme: map, fillna, fusions 2025

## Énoncé
Avec `referentiels/fusions_communes_2025.csv` (codes en texte), remplacez dans le registre chaque **ancien** code INS par le nouveau (les autres codes restent inchangés), dans une colonne `code_ins_2025`. Sur la dernière ligne, affichez le nombre de lignes du registre dont le code a changé.

## Indice
`dict(zip(fusions["code_ancien"], fusions["code_nouveau"]))`, puis `.map(...)` et `.fillna(rn["code_ins"])`.

## Préparation
```python
rn = pd.read_csv("donnees/registre_national_2026.csv", sep=";",
                 dtype={"id_pseudo": str, "code_ins": str})
```

## Correction
```python
fusions = pd.read_csv("referentiels/fusions_communes_2025.csv", sep=";", dtype=str)
correspondance = dict(zip(fusions["code_ancien"], fusions["code_nouveau"]))
rn["code_ins_2025"] = rn["code_ins"].map(correspondance).fillna(rn["code_ins"])
int((rn["code_ins_2025"] != rn["code_ins"]).sum())
```

## Commentaire
590 lignes. Sans ce recodage, ces personnes sembleraient habiter des communes qui n'existent plus depuis le 1er janvier 2025, ou avoir déménagé.

# La même question en SQL
niveau: 4
groupe: Vos propres fichiers
theme: DuckDB, taux pondéré

## Énoncé
Avec DuckDB, calculez pour chaque type de ménage le nombre de répondants et le taux de pauvreté **pondéré** (seuil : 16 840 €, en %, 1 décimale), trié du plus élevé au plus bas. Récupérez le résultat en table pandas.

## Indice
`SUM(CASE WHEN revenu_equivalent < 16840 THEN poids ELSE 0 END) / SUM(poids)`, après `import duckdb`.

## Correction
```python
import duckdb

duckdb.sql("""
    SELECT type_menage,
           COUNT(*) AS repondants,
           ROUND(100 * SUM(CASE WHEN revenu_equivalent < 16840 THEN poids ELSE 0 END)
                 / SUM(poids), 1) AS taux
    FROM personnes
    GROUP BY type_menage
    ORDER BY taux DESC
""").df()
```

## Commentaire
Les familles monoparentales (36,1 %) et les isolés (24,9 %) en tête. En SQL, une moyenne pondérée s'écrit toujours `SUM(x * poids) / SUM(poids)`.
