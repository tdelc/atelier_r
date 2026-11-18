---
titre: Nettoyer une table
resume: Repérer et traiter les doublons, les valeurs manquantes, les modalités mal écrites et les valeurs impossibles ; garder la trace de ce qu'on écarte.
partie: Vos propres fichiers
---

# Les trois livraisons régionales

On reprend les trois fichiers empilés de la leçon précédente : une ligne par commune **et par sexe**. Ils contiennent quelques **anomalies ajoutées volontairement**, comme on en rencontre dans les vraies livraisons.

```python
bxl = pd.read_csv("donnees/population_bruxelles_2026.csv", sep=";", dtype={"code_ins": str})
fla = pd.read_excel("donnees/population_flandre_2026.xlsx", header=2, dtype={"code_ins": str})
wal = pd.read_csv("donnees/population_wallonie_2026.txt", sep="\t", dtype={"code_ins": str})
bxl["region"], fla["region"], wal["region"] = "Bruxelles", "Flandre", "Wallonie"
livraisons = pd.concat([bxl, fla, wal], ignore_index=True)
livraisons.shape
```

::: etape
**La démarche** : d'abord **repérer** (sans rien modifier), puis **décider** d'une règle, puis **appliquer** et **garder la trace** de ce qui est écarté. Chaque ligne écartée doit pouvoir être expliquée.
:::

# Repérer : les modalités

```python
livraisons["sexe"].value_counts()
```

**Lecture :** un `f` minuscule, à côté de `F` et `H`.

# Repérer : les valeurs manquantes et impossibles

```python
print(livraisons.isna().sum())
livraisons["population"].describe()
```

**Lecture :** une population manquante, et un minimum négatif (-1 059) : impossible pour une population.

```python
livraisons.query("population.isna() or population < 0")
```

# Repérer : les doublons

`duplicated()` marque les lignes identiques à une ligne précédente.

```python
print(livraisons.duplicated().sum())
livraisons[livraisons.duplicated(keep=False)]
```

::: usage
`keep=False` marque **toutes** les lignes en double (l'original et la copie), pour les voir côte à côte. `subset=["code_ins", "sexe"]` limite la comparaison à une clé : deux lignes avec la même clé mais des chiffres différents sont un doublon plus inquiétant encore.
:::

# Repérer : les codes mal formés

Un code INS compte 5 caractères.

```python
livraisons.query("code_ins.str.len() != 5")
```

**Lecture :** le code de Liège est précédé d'une espace. Invisible à l'œil, il empêcherait toute jointure avec la nomenclature.

# Corriger ce qui peut l'être

Les erreurs d'écriture se corrigent : espaces en trop, minuscules.

```python
propre = livraisons.drop_duplicates().copy()
propre["code_ins"] = propre["code_ins"].str.strip()
propre["sexe"] = propre["sexe"].str.strip().str.upper()
print(propre["sexe"].value_counts())
print(propre.query("code_ins.str.len() != 5").shape)
```

::: usage
- `.str.strip()` retire les espaces au début et à la fin ; `.str.upper()` met en majuscules ;
- `.copy()` crée une table indépendante : modifier `propre` ne touche pas `livraisons`.
:::

::: sas
`code_ins = strip(code_ins); sexe = upcase(strip(sexe));` et `PROC SORT NODUPKEY` pour les doublons.
:::

# Écarter ce qui ne peut pas l'être, en gardant la trace

Une population manquante ou négative ne se devine pas. Règle : la ligne est **écartée** et rangée dans une table de **rejets**, avec le motif.

```python
a_rejeter = propre["population"].isna() | (propre["population"] < 0)
rejets = propre[a_rejeter].copy()
rejets["motif"] = np.where(rejets["population"].isna(),
                           "population manquante", "population négative")
propre = propre[~a_rejeter].copy()
propre["population"] = propre["population"].astype(int)

print(len(livraisons), "lues ;", len(propre), "gardées ;", len(rejets), "rejetées")
rejets
```

::: usage
`|` signifie « ou », `~` signifie « non » : `propre[~a_rejeter]` garde les lignes qui ne sont **pas** à rejeter. `.astype(int)` remet la population en nombre entier (elle était décimale à cause de la valeur manquante).
:::

# Un bilan chiffré : la piste d'audit

```python
bilan = pd.DataFrame({
    "étape": ["lignes lues", "doublons supprimés", "lignes rejetées", "lignes gardées"],
    "lignes": [len(livraisons), livraisons.duplicated().sum(), len(rejets), len(propre)]})
bilan
```

# Contrôler avec une source de référence

La table `communes` est la population officielle. Comparons-la aux livraisons nettoyées, commune par commune.

```python
par_commune = propre.groupby("code_ins", as_index=False).agg(livre=("population", "sum"))
comparaison = communes.merge(par_commune, on="code_ins", how="outer",
                             indicator=True, validate="one_to_one")
comparaison["ecart"] = comparaison["livre"] - comparaison["total"]
comparaison.query("ecart != 0 or _merge != 'both'")[
    ["code_ins", "commune", "total", "livre", "ecart", "_merge"]]
```

**Lecture :** trois différences, toutes expliquées : Daverdisse et Martelange ont perdu une ligne (rejetée), et le code « 99999 » n'existe pas dans la table officielle. Toutes les autres communes concordent au chiffre près.

::: piege
**Nettoyé ne veut pas dire complet.** Après nettoyage, la population de Daverdisse ne compte plus que ses femmes. Toute somme qui l'inclut est sous-estimée : signalez-le, ou demandez une nouvelle livraison.
:::
