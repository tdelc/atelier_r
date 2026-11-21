---
base: citoyens_py
---

# Regarder la table sous tous les angles
La table `personnes` est déjà chargée. Changez le nombre de lignes, triez autrement, regardez d'autres colonnes.

```python
personnes.sort_values("revenu_equivalent").head(10)
```

## À essayer
- Ajoutez `ascending=False` dans `sort_values()` : qui sont les plus aisés ?
- Gardez seulement `age`, `statut`, `type_menage` et `revenu_equivalent` avec `[[...]]`.
- Remplacez `head(10)` par `sample(5)` : cinq personnes au hasard.
- Affichez un ménage entier : `personnes.query("id_menage == 'M00003'")`.

# L'échantillon et la population
Comptez des répondants, puis des habitants : comparez.

```python
(personnes
 .groupby("region", as_index=False)
 .agg(repondants=("id_personne", "count"), population=("poids", "sum"))
 .assign(part_echantillon=lambda t: (t["repondants"] / t["repondants"].sum() * 100).round(1),
         part_population=lambda t: (t["population"] / t["population"].sum() * 100).round(1)))
```

## À essayer
- Remplacez `"region"` par `"classe_age"`, puis par `"statut"`.
- Quelle région est suréchantillonnée ? De combien ?
- Ajoutez le poids moyen : `poids_moyen=("poids", "mean")`.
- Ouvrez le **Dictionnaire** pour la définition du poids.

# Un taux pondéré à votre façon
Le taux de risque de pauvreté (seuil : 16 840 €), pondéré, pour le groupe de votre choix.

```python
personnes["pauvres_pond"] = (personnes["revenu_equivalent"] < 16840) * personnes["poids"]
(personnes
 .groupby("type_menage", as_index=False)
 .agg(repondants=("id_personne", "count"),
      pauvres=("pauvres_pond", "sum"), population=("poids", "sum"))
 .assign(taux=lambda t: (t["pauvres"] / t["population"] * 100).round(1))
 .sort_values("taux", ascending=False))
```

## À essayer
- Remplacez `"type_menage"` par `"statut"`, `"diplome"`, ou `["region", "sexe"]`.
- Ajoutez `.query("age >= 65")` avant le `groupby` : la pauvreté des aînés.
- Changez le seuil : 50 % ou 70 % de la médiane (28 067 €).
- Supprimez les poids (`.mean()` sur une colonne vrai/faux) : le classement change-t-il ?

# Chômage et emploi : choisir le dénominateur
Le taux de chômage par région. Modifiez la définition et observez.

```python
actifs = personnes.query("age.between(15, 64) and statut in ['en emploi', 'chômeur']").copy()
actifs["chomeurs_pond"] = (actifs["statut"] == "chômeur") * actifs["poids"]
(actifs
 .groupby("region", as_index=False)
 .agg(chomeurs=("chomeurs_pond", "sum"), actifs=("poids", "sum"))
 .assign(taux=lambda t: (t["chomeurs"] / t["actifs"] * 100).round(1)))
```

## À essayer
- Limitez aux 15-24 ans : le taux de chômage des jeunes.
- Remplacez `"region"` par `"diplome"`.
- Retirez la condition sur le statut : que mesure-t-on alors ?
- Calculez le taux d'emploi : la part des personnes en emploi parmi **tous** les 20-64 ans.

# Des classes de revenu à votre façon
Le choix des seuils change le tableau. Essayez d'autres découpages.

```python
r = personnes["revenu_equivalent"] / 28067        # par rapport à la médiane
personnes["classe"] = pd.cut(r, bins=[-1, 0.6, 1, 1.5, 100],
                             labels=["< 60 %", "60-100 %", "100-150 %", "> 150 %"])
pd.crosstab(personnes["region"], personnes["classe"], values=personnes["poids"],
            aggfunc="sum", normalize="index").round(3) * 100
```

## À essayer
- Ajoutez une classe `< 40 %` : la pauvreté « sévère ».
- Remplacez `normalize="index"` par `normalize="columns"` : que lit-on maintenant ?
- Retirez `values=` et `aggfunc=` : que compte-t-on alors ?
- Remplacez `"region"` par `"classe_age"`.

# Un graphique à modifier
La distribution pondérée du revenu équivalent, avec le seuil de pauvreté.

```python
import seaborn as sns
import matplotlib.pyplot as plt

sns.histplot(data=personnes, x="revenu_equivalent", weights="poids", hue="region",
             element="step", stat="density", common_norm=False, bins=40)
plt.axvline(16840, color="firebrick", linestyle="--")
plt.title("Revenu disponible équivalent (données fictives)")
plt.xlabel("Euros par an")
```

## À essayer
- Retirez `weights="poids"` : la forme change-t-elle ?
- Remplacez `hue="region"` par `hue="classe_age"`.
- Essayez `sns.boxplot(data=personnes, x="revenu_equivalent", y="statut")`.
- Ajoutez `plt.savefig("sortie/revenus.png", dpi=150, bbox_inches="tight")`.

# Coupler l'enquête et l'ONEM
Chômeur selon l'enquête, chômeur selon l'ONEM : deux notions différentes.

```python
onem = pd.read_excel("donnees/onem_allocations_2025.xlsx", header=2, dtype={"id_pseudo": str})
m = personnes.merge(onem, on="id_pseudo", how="left", validate="one_to_one")
m["type_allocation"] = m["type_allocation"].fillna("aucune")
pd.crosstab(m.query("age.between(15, 64)")["statut"],
            m.query("age.between(15, 64)")["type_allocation"], margins=True)
```

## À essayer
- Pondérez le tableau : `values=m["poids"], aggfunc="sum"`.
- Comparez le nombre de mois indemnisés selon le statut : `groupby("statut")["mois_indemnises"].mean()`.
- Couplez aussi les revenus fiscaux (`spf_finances_revenus_2024.txt`, tabulé, virgule décimale).
- Passez à `how="outer", indicator=True` : y a-t-il des allocataires hors de l'enquête ?

# En SQL, comme dans PROC SQL
La même question, écrite en SQL avec DuckDB. Modifiez la requête.

```python
import duckdb

duckdb.sql("""
    SELECT region, classe_age,
           COUNT(*) AS repondants,
           ROUND(100 * SUM(CASE WHEN revenu_equivalent < 16840 THEN poids ELSE 0 END)
                 / SUM(poids), 1) AS taux_pauvrete
    FROM personnes
    GROUP BY region, classe_age
    ORDER BY region, classe_age
""").df()
```

## À essayer
- Ajoutez `HAVING COUNT(*) >= 100` : ne garder que les cases assez précises.
- Remplacez `classe_age` par `type_menage`.
- Calculez le revenu moyen pondéré : `SUM(revenu_equivalent * poids) / SUM(poids)`.
- Ajoutez `WHERE sexe = 'F'`.
