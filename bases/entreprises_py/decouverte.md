---
base: entreprises_py
---

# Regarder la table sous tous les angles
La table `entreprises` est déjà chargée. Changez le nombre de lignes, triez autrement, regardez d'autres colonnes.

```python
entreprises.sort_values("emploi", ascending=False).head(10)
```

## À essayer
- Triez par `ca` plutôt que par `emploi` : les mêmes entreprises sont-elles en tête ?
- Gardez seulement `nace`, `secteur`, `commune` et `emploi` avec `[[...]]` à la fin.
- Remplacez `head(10)` par `sample(5)` : cinq entreprises au hasard.
- Ajoutez `.query("region == 'Wallonie'")` avant le tri.

# Un secteur à la loupe
Choisissez une classe NACE et regardez ses entreprises.

```python
(entreprises
 .query("nace == '56.10'")
 .groupby("region", as_index=False)
 .agg(entreprises=("num_entreprise", "count"),
      emploi=("emploi", "sum"),
      ca_median=("ca", "median")))
```

## À essayer
- Remplacez `'56.10'` par `'62.01'` (programmation), `'41.20'` (construction) ou `'47.11'` (supermarchés).
- Remplacez la condition par `nace.str.startswith('47')` : tout le commerce de détail.
- Ajoutez la taille médiane des employeurs : filtrez d'abord `emploi > 0`.
- Ouvrez le **Dictionnaire** pour la liste des colonnes.

# Combien d'entreprises… ?
Une question, une ligne. Modifiez la condition et observez le résultat.

```python
len(entreprises.query("emploi >= 50"))
```

## À essayer
- Et de 10 salariés ou plus ? Sans aucun salarié ?
- Ajoutez une condition sur la région ou la forme juridique (`forme == 'SA'`).
- Combien d'entreprises créées depuis 2020 ? `creation >= 2020`
- Remplacez `len(...)` par `[...]["emploi"].sum()` : combien de salariés dans ces entreprises ?

# Par secteur, par région
Un regroupement et plusieurs indicateurs. Ajoutez-en, retirez-en, changez la colonne de regroupement.

```python
(entreprises
 .groupby("secteur", as_index=False)
 .agg(entreprises=("num_entreprise", "count"),
      emploi=("emploi", "sum"),
      ca_meur=("ca", "sum"))
 .assign(ca_meur=lambda t: (t["ca_meur"] / 1000).round(1))
 .sort_values("emploi", ascending=False))
```

## À essayer
- Remplacez `"secteur"` par `"region"`, puis par `["region", "section"]`.
- Ajoutez l'emploi médian : `emploi_median=("emploi", "median")`.
- Ajoutez le nombre de communes : `communes=("code_ins", "nunique")`.
- Ajoutez `.query("emploi > 3000")` à la fin.

# Des classes de taille à votre façon
Le choix des seuils change le tableau. Essayez d'autres découpages.

```python
entreprises["taille"] = pd.cut(entreprises["emploi"],
                               bins=[-1, 0, 9, 49, 100000],
                               labels=["0", "1-9", "10-49", "50 et +"])
pd.crosstab(entreprises["section"], entreprises["taille"], margins=True)
```

## À essayer
- Ajoutez `normalize="index"` : chaque ligne fait 1 (100 %).
- Comptez l'emploi plutôt que les entreprises : `values=entreprises["emploi"], aggfunc="sum"`.
- Remplacez `entreprises["section"]` par `entreprises["region"]`.
- Essayez les classes européennes : `bins=[-1, 0, 9, 49, 249, 100000]`.

# Un graphique à modifier
La distribution du chiffre d'affaires, par région. Changez le type de graphique, les couleurs, les titres.

```python
import seaborn as sns
import matplotlib.pyplot as plt

sns.histplot(data=entreprises, x="ca", hue="region", log_scale=True,
             element="step", stat="density", common_norm=False)
plt.title("Distribution du chiffre d'affaires (données fictives)")
plt.xlabel("Milliers d'euros (échelle logarithmique)")
```

## À essayer
- Retirez `log_scale=True` : pourquoi le graphique devient-il illisible ?
- Remplacez `histplot` par `boxplot` avec `y="region"`.
- Remplacez `x="ca"` par `x="emploi"` (et filtrez d'abord les employeurs).
- Ajoutez `plt.savefig("sortie/ca.png", dpi=150, bbox_inches="tight")`.

# Trois sources, trois NACE
L'emploi ONSS joint aux entreprises : comparez les codes NACE des deux sources.

```python
onss = pd.read_csv("donnees/onss_emploi_2025.csv", sep=";", decimal=",",
                   dtype={"num_entreprise": str, "nace_onss": str})
m = entreprises.merge(onss, on="num_entreprise", how="inner", validate="one_to_one")
m.query("nace != nace_onss")[["num_entreprise", "nace", "nace_onss", "postes", "etp"]].head(10)
```

## À essayer
- Comptez les paires les plus fréquentes : `m.query("nace != nace_onss").groupby(["nace", "nace_onss"]).size().sort_values(ascending=False)`.
- Calculez l'emploi par section selon la BCE, puis selon l'ONSS : les classements changent-ils ?
- Passez à `how="outer", indicator=True` : qui manque de chaque côté ?
- Comparez `postes` et `etp` par secteur.

# En SQL, comme dans PROC SQL
La même question, écrite en SQL avec DuckDB. Modifiez la requête.

```python
import duckdb

duckdb.sql("""
    SELECT region, section, COUNT(*) AS entreprises, SUM(emploi) AS emploi
    FROM entreprises
    WHERE emploi > 0
    GROUP BY region, section
    ORDER BY emploi DESC
    LIMIT 10
""").df()
```

## À essayer
- Ajoutez `HAVING COUNT(*) >= 3` : le seuil du secret statistique.
- Ajoutez `MEDIAN(emploi) AS taille_mediane` dans le `SELECT`.
- Lisez directement le fichier : `FROM 'donnees/entreprises_2025.parquet'`.
- Remplacez `section` par `nace`.
