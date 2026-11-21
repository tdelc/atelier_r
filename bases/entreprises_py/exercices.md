---
base: entreprises_py
---

# Les entreprises de l'horeca
niveau: 1
theme: query + len

## Énoncé
Combien d'entreprises de la table relèvent de l'hébergement et de la restauration (section NACE `I`) ?

## Indice
Filtrez avec `query()` (la lettre entre guillemets simples), puis comptez les lignes avec `len()`.

## Code de départ
```python
len(entreprises.query(...))
```

## Correction
```python
len(entreprises.query("section == 'I'"))
```

## Commentaire
1 365 entreprises. `entreprises["section"].value_counts()` donne la réponse pour toutes les sections à la fois.

# L'emploi salarié en Wallonie
niveau: 1
theme: query + sum

## Énoncé
Combien de salariés les entreprises wallonnes de la table emploient-elles ?

## Correction
```python
entreprises.query("region == 'Wallonie'")["emploi"].sum()
```

## Commentaire
14 887 salariés. Rappel : ces entreprises sont fictives, ce total ne décrit pas l'emploi wallon.

# Les grandes entreprises
niveau: 1
theme: query + colonnes

## Énoncé
Affichez la classe NACE, la commune et l'emploi des entreprises de **250 salariés ou plus**.

## Indice
Une condition sur `emploi`, puis `[["nace", "commune", "emploi"]]`.

## Correction
```python
entreprises.query("emploi >= 250")[["nace", "commune", "emploi"]]
```

## Commentaire
35 entreprises, souvent dans la finance (`64.19`), l'intérim (`78.20`) ou l'industrie. Au sens européen, ce sont les « grandes entreprises ».

# Sans chiffre d'affaires
niveau: 1
theme: isna + value_counts

## Énoncé
Combien d'entreprises n'ont **pas** de chiffre d'affaires renseigné ?

## Indice
`entreprises["ca"].isna()` vaut vrai quand la valeur manque ; `.sum()` compte les vrais.

## Correction
```python
entreprises["ca"].isna().sum()
```

## Commentaire
1 373 entreprises : elles sont **exonérées de TVA** (santé, banques, assurances, enseignement, ASBL). `entreprises.query("ca.isna()")["secteur"].value_counts()` le montre. Ce n'est pas un chiffre d'affaires nul.

# La division de la restauration
niveau: 1
theme: str.startswith

## Énoncé
Combien d'entreprises ont une classe NACE qui commence par `56` (restauration et débits de boissons) ?

## Correction
```python
len(entreprises.query("nace.str.startswith('56')"))
```

## Commentaire
1 233 entreprises, dans les classes `56.10` (restaurants) et `56.30` (débits de boissons). Le code NACE est hiérarchique : ses premiers chiffres donnent la division.

# Le nombre d'entreprises par section
niveau: 2
theme: groupby + size

## Énoncé
Calculez le nombre d'entreprises de chaque section NACE, sous forme de table (une colonne `section`, une colonne avec le nombre).

## Correction
```python
entreprises.groupby("section", as_index=False).size()
```

## Commentaire
Les activités spécialisées (M) sont les plus nombreuses (1 910), devant le commerce (G) et la construction (F).

# Emploi et taille médiane par région
niveau: 2
theme: groupby + agg

## Énoncé
Pour chaque région, calculez l'emploi total (`emploi`) et le chiffre d'affaires médian (`ca_median`).

## Correction
```python
(entreprises
 .groupby("region", as_index=False)
 .agg(emploi=("emploi", "sum"),
      ca_median=("ca", "median")))
```

## Commentaire
Le chiffre d'affaires médian est calculé sur les entreprises qui en déclarent un : les exonérées sont ignorées. Les noms de colonnes peuvent différer des vôtres : la vérification compare les valeurs.

# Les classes NACE qui emploient le plus
niveau: 2
theme: groupby + sort_values + head

## Énoncé
Quelles sont les 5 classes NACE qui emploient le plus de salariés ? Affichez la classe et l'emploi, du plus grand au plus petit.

## Correction
```python
(entreprises
 .groupby("nace", as_index=False)
 .agg(emploi=("emploi", "sum"))
 .sort_values("emploi", ascending=False)
 .head(5))
```

## Commentaire
Les banques (`64.19`) arrivent en tête avec très peu d'entreprises, devant l'intérim (`78.20`). `.nlargest(5, "emploi")` remplace `sort_values` + `head`.

# Les secteurs de plus de 5 000 salariés
niveau: 2
theme: groupby + query après

## Énoncé
Quels secteurs (colonne `secteur`) emploient plus de 5 000 salariés ?

## Indice
Le filtre porte sur un résultat **calculé** : il vient après le regroupement.

## Correction
```python
(entreprises
 .groupby("secteur", as_index=False)
 .agg(emploi=("emploi", "sum"))
 .query("emploi > 5000"))
```

## Commentaire
Six secteurs : finance, industrie, commerce, services administratifs (dont l'intérim), santé et action sociale, horeca.

# Les employeurs par région
niveau: 2
theme: query puis groupby

## Énoncé
Pour chaque région, combien d'entreprises ont **au moins un** salarié ?

## Correction
```python
(entreprises
 .query("emploi > 0")
 .groupby("region", as_index=False)
 .size())
```

## Commentaire
589 à Bruxelles, 3 017 en Flandre, 1 358 en Wallonie. Ici le filtre porte sur les entreprises : il vient **avant** le regroupement.

# Le chiffre d'affaires par salarié
niveau: 3
theme: nouvelle colonne

## Énoncé
Pour les **employeurs** seulement, créez la colonne `ca_par_salarie` (chiffre d'affaires divisé par l'emploi, en milliers d'euros), puis affichez les 3 entreprises où elle est la plus élevée, avec `nace`, `emploi`, `ca` et `ca_par_salarie`.

## Indice
`employeurs = entreprises.query("emploi > 0").copy()`, puis une nouvelle colonne, puis `nlargest(3, ...)`.

## Correction
```python
employeurs = entreprises.query("emploi > 0").copy()
employeurs["ca_par_salarie"] = employeurs["ca"] / employeurs["emploi"]
employeurs.nlargest(3, "ca_par_salarie")[["nace", "emploi", "ca", "ca_par_salarie"]]
```

## Commentaire
Deux producteurs d'électricité (`35.11`) et un chimiste (`20.14`), à plus de 4 millions d'euros de chiffre d'affaires par salarié. Ce n'est pas de la « richesse produite » : une grande part du chiffre d'affaires rémunère des achats (combustible, matières premières). Il faudrait la valeur ajoutée.

# Les classes de taille
niveau: 3
theme: pd.cut + value_counts

## Énoncé
Créez la colonne `taille` avec les classes européennes : `0`, `1-9`, `10-49`, `50-249`, `250 et +` salariés. Comptez les entreprises de chaque classe, dans l'ordre des classes.

## Indice
`pd.cut(entreprises["emploi"], bins=[-1, 0, 9, 49, 249, 100000], labels=[...])`, puis `.value_counts().sort_index()`.

## Correction
```python
entreprises["taille"] = pd.cut(entreprises["emploi"], bins=[-1, 0, 9, 49, 249, 100000],
                               labels=["0", "1-9", "10-49", "50-249", "250 et +"])
entreprises["taille"].value_counts().sort_index()
```

## Commentaire
7 036 entreprises sans salarié, 3 698 de 1 à 9, 1 079 de 10 à 49, 152 de 50 à 249, 35 de 250 et plus. La borne `-1` permet d'isoler les entreprises à 0 salarié.

# L'âge des entreprises
niveau: 3
theme: nouvelle colonne + groupby

## Énoncé
Créez la colonne `age` (2025 moins l'année de création), puis calculez l'âge médian des entreprises de chaque classe de taille (colonne `taille` de l'exercice précédent, déjà créée ci-dessous).

## Préparation
```python
entreprises["taille"] = pd.cut(entreprises["emploi"], bins=[-1, 0, 9, 49, 249, 100000],
                               labels=["0", "1-9", "10-49", "50-249", "250 et +"])
```

## Correction
```python
entreprises["age"] = 2025 - entreprises["creation"]
entreprises.groupby("taille", as_index=False, observed=False).agg(age_median=("age", "median"))
```

## Commentaire
L'âge médian augmente avec la taille : les grandes entreprises sont plus anciennes. Corrélation n'est pas causalité : grandir prend du temps, mais les entreprises qui survivent sont aussi celles qui ont grandi.

# Le poids de chaque entreprise dans sa section
niveau: 3
theme: groupby + transform

## Énoncé
Calculez pour chaque entreprise sa part dans le chiffre d'affaires de sa section (en %, 1 décimale), dans une colonne `part_section`. Combien d'entreprises réalisent à elles seules **plus de 20 %** du chiffre d'affaires de leur section ?

## Indice
`entreprises.groupby("section")["ca"].transform("sum")` donne le chiffre d'affaires de la section sur chaque ligne.

## Correction
```python
entreprises["part_section"] = (entreprises["ca"]
                               / entreprises.groupby("section")["ca"].transform("sum")
                               * 100).round(1)
len(entreprises.query("part_section > 20"))
```

## Commentaire
Deux entreprises dépassent 20 % du chiffre d'affaires de leur section : publier le chiffre d'affaires de la section revient presque à publier le leur. C'est ce que vérifie la **règle de dominance** du secret statistique.

# Emploi par section et par région, en colonnes
niveau: 4
theme: pivot_table

## Énoncé
Construisez un tableau de l'emploi avec les sections en lignes et les régions en colonnes, avec des 0 dans les cases vides.

## Indice
`pivot_table(index=..., columns=..., values="emploi", aggfunc="sum", fill_value=0)`.

## Correction
```python
entreprises.pivot_table(index="section", columns="region", values="emploi",
                        aggfunc="sum", fill_value=0)
```

## Commentaire
`fill_value=0` est légitime ici : une case vide signifie bien « aucun salarié ». Pour un chiffre d'affaires ou une moyenne, une case vide signifierait « pas d'information ».

# Taille et région : pourcentages en ligne
niveau: 4
theme: crosstab normalize

## Énoncé
Avec les classes de taille (déjà créées), calculez pour chaque région le **pourcentage de ses entreprises** dans chaque classe (1 décimale).

## Indice
Le dénominateur est la région (la ligne) : `normalize="index"`.

## Préparation
```python
entreprises["taille"] = pd.cut(entreprises["emploi"], bins=[-1, 0, 9, 49, 249, 100000],
                               labels=["0", "1-9", "10-49", "50-249", "250 et +"])
```

## Correction
```python
(pd.crosstab(entreprises["region"], entreprises["taille"], normalize="index") * 100).round(1)
```

## Commentaire
Partout, environ six entreprises sur dix n'ont pas de salarié. Chaque ligne fait 100 %.

# Taille et région : la part de l'emploi
niveau: 4
theme: crosstab values + aggfunc

## Énoncé
Même tableau, mais avec la part de l'**emploi** de chaque région (et non des entreprises) dans chaque classe de taille.

## Préparation
```python
entreprises["taille"] = pd.cut(entreprises["emploi"], bins=[-1, 0, 9, 49, 249, 100000],
                               labels=["0", "1-9", "10-49", "50-249", "250 et +"])
```

## Correction
```python
(pd.crosstab(entreprises["region"], entreprises["taille"], values=entreprises["emploi"],
             aggfunc="sum", normalize="index") * 100).round(1)
```

## Commentaire
À Bruxelles, 59 % des salariés travaillent dans une entreprise de 250 salariés ou plus, alors que ces entreprises ne sont que 0,6 % des entreprises bruxelloises. Compter les unités ou peser l'activité donne deux images opposées.

# Un graphique de l'emploi par région
niveau: 4
theme: seaborn
verif: aucune

## Énoncé
Dessinez un diagramme en barres de l'emploi salarié de chaque région, avec un titre.

## Indice
Calculez d'abord la table (`groupby` + `agg`), puis `sns.barplot(data=..., x=..., y=...)` et `plt.title(...)`. N'oubliez pas les `import`.

## Correction
```python
import seaborn as sns
import matplotlib.pyplot as plt

par_region = entreprises.groupby("region", as_index=False).agg(emploi=("emploi", "sum"))
sns.barplot(data=par_region, x="region", y="emploi")
plt.title("Emploi salarié par région (données fictives)")
plt.xlabel("")
plt.ylabel("Salariés")
```

## Commentaire
Pas de vérification automatique pour un graphique : comparez avec la correction.

# La concentration du chiffre d'affaires
niveau: 5
theme: tri + cumul

## Énoncé
Quelle part du chiffre d'affaires total (en %, 1 décimale) réalisent les **10 %** d'entreprises qui ont le plus grand chiffre d'affaires (parmi celles qui en déclarent un) ?

## Indice
`ca = entreprises["ca"].dropna().sort_values(ascending=False)`, puis les `len(ca) // 10` premières valeurs.

## Correction
```python
ca = entreprises["ca"].dropna().sort_values(ascending=False)
round(ca.head(len(ca) // 10).sum() / ca.sum() * 100, 1)
```

## Commentaire
Les 10 % plus grandes réalisent environ 90 % du chiffre d'affaires : la distribution est extrêmement concentrée, comme dans les vraies données d'entreprises.

# Une fiche par section
niveau: 5
theme: groupby + agg + nouvelle colonne + tri

## Énoncé
Construisez une table avec une ligne par section : nombre d'entreprises, emploi, emploi de la plus grande entreprise, et la **part** de cette plus grande entreprise dans l'emploi de la section (en %, 1 décimale). Gardez les sections de plus de 1 000 salariés et triez par part décroissante.

## Correction
```python
fiche = (entreprises
         .groupby("section", as_index=False)
         .agg(entreprises=("num_entreprise", "count"),
              emploi=("emploi", "sum"),
              plus_grande=("emploi", "max")))
fiche["part_plus_grande"] = (fiche["plus_grande"] / fiche["emploi"] * 100).round(1)
fiche.query("emploi > 1000").sort_values("part_plus_grande", ascending=False)
```

## Commentaire
Dans l'industrie (23,1 %) et la finance (18,4 %), une seule entreprise pèse un cinquième de l'emploi de la section : un tableau détaillé par commune ou par classe NACE y poserait vite un problème de secret statistique.

# Lire le 1er trimestre TVA
niveau: 3
groupe: Vos propres fichiers
theme: read_csv, réglages

## Énoncé
Lisez `donnees/tva_2025_T1.csv` avec les bons réglages : séparateur `;`, virgule décimale, point des milliers, numéro et NACE en texte. Sur la dernière ligne, affichez le chiffre d'affaires total déclaré au 1er trimestre, en euros.

## Indice
`sep=";"`, `decimal=","`, `thousands="."`, `dtype={"numero_tva": str, "nace_tva": str}`.

## Correction
```python
t1 = pd.read_csv("donnees/tva_2025_T1.csv", sep=";", decimal=",", thousands=".",
                 dtype={"numero_tva": str, "nace_tva": str})
t1["chiffre_affaires"].sum()
```

## Commentaire
Sans `decimal=","` et `thousands="."`, la colonne serait du texte et `sum()` mettrait bout à bout des chaînes de caractères au lieu de les additionner.

# Comparer la NACE de la BCE et de l'ONSS
niveau: 4
groupe: Vos propres fichiers
theme: merge, validate

## Énoncé
Lisez `donnees/onss_emploi_2025.csv` (séparateur `;`, virgule décimale, numéro et NACE en texte), joignez-le aux employeurs de `entreprises` (`how="inner"`, `validate="one_to_one"`), puis calculez sur la dernière ligne la part (en %, 1 décimale) des employeurs dont la classe NACE est **la même** dans les deux sources.

## Indice
`(m["nace"] == m["nace_onss"]).mean() * 100`.

## Correction
```python
onss = pd.read_csv("donnees/onss_emploi_2025.csv", sep=";", decimal=",",
                   dtype={"num_entreprise": str, "nace_onss": str})
m = entreprises.query("emploi > 0").merge(onss, on="num_entreprise", how="inner",
                                           validate="one_to_one")
round((m["nace"] == m["nace_onss"]).mean() * 100, 1)
```

## Commentaire
88,4 % seulement : plus d'un employeur sur dix change de classe NACE selon la source. Une statistique sectorielle doit dire quelle source elle utilise.

# Nettoyer les numéros et rejeter les clés fausses
niveau: 5
groupe: Vos propres fichiers
theme: str.replace, clé modulo 97

## Énoncé
La table `tva` (les quatre trimestres empilés) est prête. Créez `num_entreprise` en ne gardant que les chiffres de `numero_tva`, puis comptez sur la dernière ligne les numéros dont la **clé de contrôle** est fausse (les deux derniers chiffres doivent valoir 97 moins le reste de la division des huit premiers par 97).

## Indice
`str.replace(r"[^0-9]", "", regex=True)` ; `str.slice(0, 8).astype(int)` et `str.slice(8, 10).astype(int)`.

## Préparation
```python
lire = dict(dtype={"numero_tva": str, "nace_tva": str})
tva = pd.concat([pd.read_csv("donnees/tva_2025_T1.csv", sep=";", decimal=",", thousands=".", **lire),
                 pd.read_excel("donnees/tva_2025_T2.xlsx", header=2, **lire),
                 pd.read_csv("donnees/tva_2025_T3.txt", sep="\t", **lire),
                 pd.read_csv("donnees/tva_2025_T4.csv", **lire)], ignore_index=True)
```

## Correction
```python
tva["num_entreprise"] = tva["numero_tva"].str.upper().str.replace(r"[^0-9]", "", regex=True)
corps = tva["num_entreprise"].str.slice(0, 8).astype(int)
cle = tva["num_entreprise"].str.slice(8, 10).astype(int)
int(((97 - corps % 97) != cle).sum())
```

## Commentaire
Un seul numéro, issu d'une faute de frappe au 1er trimestre. Sans ce contrôle, la déclaration aurait été perdue à la jointure sans que personne ne le remarque.

# Les déclarations rectificatives
niveau: 5
groupe: Vos propres fichiers
theme: sort_values, drop_duplicates keep

## Énoncé
Dans `tva` (numéros nettoyés, trimestre ajouté), une entreprise peut avoir déposé deux déclarations pour le même trimestre : la plus récente (`date_depot`) remplace l'autre. Gardez une seule ligne par entreprise et par trimestre, la plus récente, et affichez sur la dernière ligne le chiffre d'affaires total de l'année, en millions d'euros (1 décimale).

## Indice
`sort_values("date_depot")`, puis `drop_duplicates(subset=["num_entreprise", "trimestre"], keep="last")`.

## Préparation
```python
lire = dict(dtype={"numero_tva": str, "nace_tva": str})
morceaux = []
for q, t in [("T1", pd.read_csv("donnees/tva_2025_T1.csv", sep=";", decimal=",", thousands=".", **lire)),
             ("T2", pd.read_excel("donnees/tva_2025_T2.xlsx", header=2, **lire)),
             ("T3", pd.read_csv("donnees/tva_2025_T3.txt", sep="\t", **lire)),
             ("T4", pd.read_csv("donnees/tva_2025_T4.csv", **lire))]:
    t["trimestre"] = q
    morceaux.append(t)
tva = pd.concat(morceaux, ignore_index=True)
tva["num_entreprise"] = tva["numero_tva"].str.upper().str.replace(r"[^0-9]", "", regex=True)
```

## Correction
```python
propre = (tva
          .sort_values("date_depot")
          .drop_duplicates(subset=["num_entreprise", "trimestre"], keep="last"))
round(propre["chiffre_affaires"].sum() / 1e6, 1)
```

## Commentaire
30 297,6 millions d'euros. Trois déclarations rectificatives remplacent les originales. Avec `keep="first"` (le défaut), on aurait gardé les montants erronés. Le total contient encore le montant encodé en centimes : le nettoyage n'est pas fini !

# La même question en SQL
niveau: 4
groupe: Vos propres fichiers
theme: DuckDB, GROUP BY, HAVING

## Énoncé
Avec DuckDB, calculez pour chaque province le nombre d'employeurs (entreprises d'au moins un salarié) et leur emploi total, en ne gardant que les provinces de plus de 5 000 salariés, triées par emploi décroissant. Récupérez le résultat en table pandas.

## Indice
`duckdb.sql("""SELECT ... FROM entreprises WHERE ... GROUP BY ... HAVING ... ORDER BY ... DESC""").df()`, après `import duckdb`.

## Correction
```python
import duckdb

duckdb.sql("""
    SELECT province, COUNT(*) AS employeurs, SUM(emploi) AS emploi
    FROM entreprises
    WHERE emploi > 0
    GROUP BY province
    HAVING SUM(emploi) > 5000
    ORDER BY emploi DESC
""").df()
```

## Commentaire
`WHERE` filtre les entreprises avant le regroupement, `HAVING` filtre les provinces après. La même chose en pandas : `query`, `groupby`, `agg`, puis `query`.
