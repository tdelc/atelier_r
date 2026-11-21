---
titre: Importer et exporter ses fichiers
resume: Lire des extraits administratifs en CSV, Excel et texte tabulé - séparateur, virgule décimale, en-têtes, encodage, et surtout des identifiants lus en texte ; contrôler la lecture ; écrire un résultat.
partie: Vos propres fichiers
---

# Les fichiers du dossier

Le dossier `donnees/` contient, à côté de l'enquête, des **extraits de fichiers administratifs** concernant les mêmes personnes, identifiées par un **pseudonyme** (`id_pseudo`) :

| Fichier | Source | Contenu |
|---|---|---|
| `registre_national_2026.csv` | Registre national | date de naissance, sexe, commune, date de décès |
| `onem_allocations_2025.xlsx` | ONEM | allocations de chômage perçues en 2025 |
| `spf_finances_revenus_2024.txt` | SPF Finances | revenu imposable 2024 |
| `ris_2025_bruxelles.csv`, `…flandre.xlsx`, `…wallonie.txt` | CPAS, via le SPP Intégration sociale | revenu d'intégration perçu en 2025 |

```python
import os
print(sorted(os.listdir("donnees")))
print(sorted(os.listdir("referentiels")))
```

::: piege
**Fichiers fictifs.** Ils imitent la forme de vrais extraits administratifs, mais aucune ligne ne concerne une personne réelle. Dans la réalité, ces données ne circulent que pseudonymisées, pour des finalités autorisées : la leçon suivante y revient.
:::

# Un identifiant se lit en texte

```python
rn = pd.read_csv("donnees/registre_national_2026.csv", sep=";")
rn.dtypes
```

**Lecture :** `code_ins` a été lu comme un **nombre** : le code `01000` deviendrait `1000`, et `"11002"` (texte, dans l'enquête) ne correspondrait plus à `11002` (nombre). Les pseudonymes, eux, sont restés du texte… par chance : un pseudonyme fait uniquement de chiffres, ou de la forme `1234e567`, serait lu comme un nombre.

```python
rn = pd.read_csv("donnees/registre_national_2026.csv", sep=";",
                 dtype={"id_pseudo": str, "code_ins": str})
print(rn.dtypes)
rn.head(3)
```

::: piege
**Toute clé de couplage se lit avec `dtype=str`** : pseudonyme, numéro de registre national, numéro d'entreprise, code INS, code postal. Une clé lue comme un nombre perd ses zéros initiaux, ou change de forme, et le couplage échoue **sans message**.
:::

# Le sexe codé 1 et 2

```python
rn["sexe"].value_counts()
```

Le registre code le sexe `1` (homme) et `2` (femme), l'enquête `H` et `F`. Avant tout couplage, on repère ces différences de **codage** : on les harmonisera dans la leçon « Nettoyer une table ».

# Un classeur Excel : les allocations de l'ONEM

Deux lignes de titre précèdent les en-têtes : `header=2` désigne la troisième ligne (on compte à partir de 0).

```python
onem = pd.read_excel("donnees/onem_allocations_2025.xlsx", header=2,
                     dtype={"id_pseudo": str})
print(onem.shape)
onem.head(3)
```

# Un texte tabulé « à la belge » : les revenus fiscaux

```python
print(open("donnees/spf_finances_revenus_2024.txt", encoding="utf-8").read()[:120])
```

Tabulation, point des milliers, virgule décimale :

```python
fisc = pd.read_csv("donnees/spf_finances_revenus_2024.txt", sep="\t",
                   decimal=",", thousands=".", dtype={"id_pseudo": str})
print(fisc.dtypes)
fisc["revenu_imposable"].describe().round(0)
```

| Réglage | Rôle | Symptôme s'il est mal réglé |
|---|---|---|
| `sep` | séparateur de colonnes | une seule colonne lue |
| `decimal`, `thousands` | virgule décimale, point des milliers | nombres lus comme du texte |
| `dtype` | type imposé à une colonne | clés transformées en nombres |
| `encoding` | encodage des caractères | erreur `UnicodeDecodeError` ou accents illisibles |
| `skiprows`, `header` | lignes à sauter, ligne des en-têtes | lignes de titre prises pour des données |

# Trois régions, trois formats : le revenu d'intégration

```python
ris_bxl = pd.read_csv("donnees/ris_2025_bruxelles.csv", sep=";", decimal=",",
                      dtype={"id_pseudo": str})
ris_fla = pd.read_excel("donnees/ris_2025_flandre.xlsx", dtype={"id_pseudo": str})
ris_wal = pd.read_csv("donnees/ris_2025_wallonie.txt", sep="\t", dtype={"id_pseudo": str})
for nom, t in [("Bruxelles", ris_bxl), ("Flandre", ris_fla), ("Wallonie", ris_wal)]:
    print(nom, t.shape, t["montant_ris"].dtype)
```

::: usage
Juste après la lecture : le nombre de lignes est-il plausible ? Les montants sont-ils des nombres (`float64`) ? Une ligne de contrôle évite des heures de recherche plus tard.
:::

# L'encodage : la nomenclature des territoires

La nomenclature NUTS de Statbel est encodée en **Windows-1252** (`cp1252`). pandas suppose l'UTF-8 et s'arrête au premier caractère accentué. **Erreur volontaire** :

```python erreur
nuts = pd.read_csv("referentiels/nuts_lau_2027.txt", sep="|")
```

```python
nuts = pd.read_csv("referentiels/nuts_lau_2027.txt", sep="|", encoding="cp1252",
                   dtype={"CD_MUNTY_REFNIS": str})
nuts.shape
```

::: sas
`FILENAME f "nuts_lau_2027.txt" ENCODING="wlatin1";`
:::

# Écrire un résultat

Le taux de pauvreté pondéré par région, exporté dans `sortie/` :

```python
tri = personnes.sort_values("revenu_equivalent")
cumul = tri["poids"].cumsum()
seuil = 0.6 * tri.loc[cumul >= tri["poids"].sum() / 2, "revenu_equivalent"].iloc[0]
personnes["pauvres_pond"] = (personnes["revenu_equivalent"] < seuil) * personnes["poids"]
resultat = personnes.groupby("region", as_index=False).agg(pauvres=("pauvres_pond", "sum"),
                                                           population=("poids", "sum"))
resultat["taux"] = (resultat["pauvres"] / resultat["population"] * 100).round(1)

resultat.to_csv("sortie/pauvrete_regions.csv", sep=";", decimal=",", index=False, encoding="utf-8")
resultat.to_excel("sortie/pauvrete_regions.xlsx", index=False)
resultat.to_parquet("sortie/pauvrete_regions.parquet", index=False)
pd.read_csv("sortie/pauvrete_regions.csv", sep=";", decimal=",")
```

::: usage
`index=False` évite d'écrire une colonne de numéros de ligne. `sep=";", decimal=","` donnent un fichier lisible directement par un Excel belge. Relire le fichier exporté est le réflexe de contrôle, en Python comme en SAS.
:::

::: piege
**N'exportez que des résultats agrégés.** Un fichier de microdonnées (une ligne par personne), même pseudonymisé, ne sort pas de l'environnement sécurisé où il est traité.
:::
