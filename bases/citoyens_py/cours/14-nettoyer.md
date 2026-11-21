---
titre: Nettoyer une table
resume: Préparer un extrait du Registre national avant de le coupler - dates en deux formats, sexe codé 1/2, historique d'adresses, anciens codes de communes après les fusions de 2025, décès ; contrôler la cohérence avec l'enquête.
partie: Vos propres fichiers
---

# L'extrait du Registre national

```python
rn = pd.read_csv("donnees/registre_national_2026.csv", sep=";",
                 dtype={"id_pseudo": str, "code_ins": str})
print(rn.shape)
rn.head(3)
```

::: etape
**La démarche** : d'abord **repérer** (sans rien modifier), puis **décider** d'une règle, puis **appliquer** et **garder la trace**. Chaque ligne modifiée ou écartée doit pouvoir être expliquée.
:::

# Des dates écrites de deux façons

```python
print(rn["date_naissance"].str.contains("/").sum(), "dates avec des barres obliques")
rn[rn["date_naissance"].str.contains("/")]["date_naissance"].head(3)
```

**Lecture :** la plupart des dates sont écrites `AAAA-MM-JJ`, mais une partie du fichier les donne en `JJ/MM/AAAA` : deux chaînes de traitement différentes ont produit l'extrait.

On convertit avec les **deux** formats, l'un après l'autre :

```python
iso = pd.to_datetime(rn["date_naissance"], format="%Y-%m-%d", errors="coerce")
fr = pd.to_datetime(rn["date_naissance"], format="%d/%m/%Y", errors="coerce")
rn["naissance"] = iso.fillna(fr)
print(iso.isna().sum(), "dates en JJ/MM/AAAA ;", rn["naissance"].isna().sum(), "non converties")
```

::: usage
- `pd.to_datetime(…, format=…)` lit une date selon un modèle : `%Y` l'année, `%m` le mois, `%d` le jour ;
- `errors="coerce"` met `NaT` (date manquante) au lieu d'arrêter le programme quand le format ne correspond pas ;
- `iso.fillna(fr)` complète les dates non lues au premier format par celles du second.
:::

::: piege
Sans `format=`, pandas devine… et peut lire `03/04/1975` comme le 4 mars (à l'américaine) au lieu du 3 avril. Pour une date, précisez **toujours** le format.
:::

::: sas
`input(date_naissance, ?? yymmdd10.)` puis `input(date_naissance, ?? ddmmyy10.)` si le premier échoue.
:::

# Le sexe : 1 et 2, H et F

```python
rn["sexe_hf"] = rn["sexe"].map({1: "H", 2: "F"})
rn["sexe_hf"].value_counts(dropna=False)
```

::: usage
`.map({ancien: nouveau})` recode chaque valeur grâce à un dictionnaire. Une valeur absente du dictionnaire deviendrait `NaN` : `value_counts(dropna=False)` le vérifie.
:::

# L'historique d'adresses : une ligne par personne

```python
print(rn["id_pseudo"].duplicated().sum(), "personnes ont deux adresses")
rn = rn.sort_values("date_debut_adresse").drop_duplicates("id_pseudo", keep="last")
print(rn["id_pseudo"].is_unique, len(rn))
```

::: piege
« Garder la dernière adresse » est une **règle**, pas une évidence. Pour une enquête de 2025, l'adresse au 1er janvier 2025 serait plus juste : il faudrait garder, pour chaque personne, la dernière adresse dont `date_debut_adresse` est antérieure à cette date. Choisissez la règle selon la question, et écrivez-la.
:::

# Les communes fusionnées au 1er janvier 2025

Au 1er janvier 2025, 27 communes flamandes ont fusionné en 12 : elles ont reçu de **nouveaux codes INS**. Une partie du registre utilise encore les anciens.

```python
fusions = pd.read_csv("referentiels/fusions_communes_2025.csv", sep=";", dtype=str)
fusions.head(5)
```

```python
print(rn["code_ins"].isin(fusions["code_ancien"]).sum(), "adresses avec un ancien code")

correspondance = dict(zip(fusions["code_ancien"], fusions["code_nouveau"]))
rn["code_ins_2025"] = rn["code_ins"].map(correspondance).fillna(rn["code_ins"])
print(rn["code_ins_2025"].isin(fusions["code_ancien"]).sum(), "après recodage")
```

::: usage
`map(correspondance)` donne le nouveau code pour les anciens codes, et `NaN` pour les autres ; `.fillna(rn["code_ins"])` remet alors le code d'origine. Résultat : chaque ancien code est remplacé, les autres sont inchangés.
:::

::: note
La nomenclature `nuts_lau_2027.txt` garde les communes disparues, avec leur date de fin de validité (`DT_VLDT_STOP` = `31/12/2024`). Un code « inconnu » dans un fichier est souvent un code **ancien** : vérifiez-le avant de le rejeter.
:::

# Contrôler la cohérence avec l'enquête

On couple, puis on compare ce qui doit concorder :

```python
m = personnes.merge(rn, on="id_pseudo", how="inner", suffixes=("", "_rn"), validate="one_to_one")

m["age_rn"] = (2025 - m["naissance"].dt.year
               - ((m["naissance"].dt.month > 1) | (m["naissance"].dt.day > 1)).astype(int))
controles = pd.DataFrame({
    "contrôle": ["sexe différent", "âge différent", "commune différente"],
    "personnes": [(m["sexe"] != m["sexe_hf"]).sum(),
                  (m["age"] != m["age_rn"]).sum(),
                  (m["code_ins"] != m["code_ins_2025"]).sum()]})
controles
```

**Lecture :**

- **2 personnes** ont un sexe différent : une erreur d'un côté ou de l'autre. On ne « corrige » pas au hasard : on signale, et on applique une règle documentée (par exemple, le registre fait foi) ;
- **27 âges** diffèrent d'un an : l'âge de l'enquête est **déclaré**, celui du registre est **calculé** ; un écart d'un an est banal ;
- **149 communes** diffèrent : ce sont les déménagements de 2025, puisqu'on a gardé la dernière adresse. Sans le recodage des fusions, il y en aurait bien plus.

```python
(m["code_ins"] != m["code_ins_rn"]).sum()
```

**Lecture :** avec les codes **non recodés**, 733 personnes sembleraient avoir changé de commune : près de 600 « déménagements » ne seraient que des fusions de communes.

# Les décès

```python
m["decede"] = m["date_deces"].notna()
m.query("decede")[["id_personne", "age", "date_deces"]].head(4)
```

Ces personnes sont décédées **après** l'enquête : elles étaient bien vivantes au moment de l'interview. On les **garde** pour les résultats de l'enquête, mais un suivi dans le temps (panel) devra en tenir compte.

# Un bilan chiffré : la piste d'audit

```python
bilan = pd.DataFrame({
    "étape": ["lignes de l'extrait", "personnes distinctes", "dates en JJ/MM/AAAA",
              "anciens codes de communes recodés", "retrouvées dans l'enquête",
              "sexe incohérent", "décédées après l'enquête"],
    "nombre": [13628, len(rn), int(iso.isna().sum()),
               int((rn["code_ins"] != rn["code_ins_2025"]).sum()), len(m),
               int((m["sexe"] != m["sexe_hf"]).sum()), int(m["decede"].sum())]})
bilan
```

::: piege
**Nettoyé ne veut pas dire complet.** 205 personnes de l'enquête n'ont pas été retrouvées dans le registre : la table couplée ne contient que les 13 478 autres. Toute statistique tirée des données du registre doit le dire.
:::
