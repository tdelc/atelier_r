---
titre: Boucles et fonctions
resume: Écrire ses propres fonctions - médiane pondérée, taux pondéré ; les appliquer dans une boucle à chaque région ou chaque fichier ; vérifier avec assert.
partie: Pour aller plus loin
---

# Quand a-t-on besoin d'une boucle ?

Avec pandas, la plupart des calculs se font **sans boucle** : une instruction s'applique à toute une colonne, `groupby` traite tous les groupes d'un coup. On écrit une boucle quand il faut **répéter une action** qui n'est pas un calcul sur une table :

- lire **plusieurs fichiers** (les trois fichiers régionaux du revenu d'intégration) ;
- exporter **un tableau par** région ;
- calculer le même indicateur pour **plusieurs découpages** (région, âge, type de ménage).

C'est le rôle des macros `%DO` en SAS.

# Écrire sa propre fonction : la médiane pondérée

Le calcul de la médiane pondérée revient dans chaque leçon. On l'écrit **une fois** :

```python
def mediane_ponderee(valeurs, poids):
    """Médiane de valeurs pondérées : la valeur qui partage la population en deux."""
    ordre = valeurs.sort_values().index
    cumul = poids[ordre].cumsum()
    return valeurs[ordre][cumul >= poids.sum() / 2].iloc[0]

mediane = mediane_ponderee(personnes["revenu_equivalent"], personnes["poids"])
seuil = 0.6 * mediane
print(mediane, round(seuil, 1))
```

::: usage
- `def nom(paramètres):` déclare la fonction ; le bloc **indenté** (4 espaces) est son contenu ;
- le texte entre triples guillemets décrit la fonction (on le lit avec `help(mediane_ponderee)`) ;
- `return` renvoie le résultat.
:::

::: sas
Une macro `%MACRO mediane(var, poids); ... %MEND;`, ou simplement `PROC MEANS MEDIAN; WEIGHT poids;`. Différence : une fonction Python **renvoie une valeur**, qu'on peut ranger et réutiliser.
:::

# Une fonction de taux pondéré

```python
def taux_pondere(table, condition, groupe):
    """Part pondérée (en %) des personnes qui vérifient la condition, par groupe."""
    t = table.assign(oui=table.eval(condition) * table["poids"])
    r = t.groupby(groupe, as_index=False).agg(repondants=("poids", "size"),
                                              oui=("oui", "sum"), population=("poids", "sum"))
    r["taux"] = (r["oui"] / r["population"] * 100).round(1)
    return r.drop(columns="oui")

taux_pondere(personnes, "revenu_equivalent < @seuil", "region")
```

::: usage
`table.eval("revenu_equivalent < @seuil")` évalue une condition écrite en texte, comme dans `query()` : une seule fonction sert pour tous les taux.
:::

La même fonction, pour le taux de chômage :

```python
actifs = personnes.query("age.between(15, 64) and statut in ['en emploi', 'chômeur']")
taux_pondere(actifs, "statut == 'chômeur'", "region")
```

# La boucle for : plusieurs découpages

`for valeur in liste:` répète les lignes **indentées** une fois pour chaque élément de la liste.

```python
for groupe in ["region", "classe_age", "type_menage"]:
    r = taux_pondere(personnes, "revenu_equivalent < @seuil", groupe)
    print(r[[groupe, "taux"]].to_string(index=False), "\n")
```

::: usage
- La ligne `for` se termine par `:` ; le bloc répété est **indenté**.
- `to_string(index=False)` affiche une table sans ses numéros de ligne, dans un `print()`.
:::

::: sas
`%DO i = 1 %TO 3; ... %END;` dans une macro, avec une liste de variables.
:::

# Lire plusieurs fichiers dans une boucle

Les réglages diffèrent d'un fichier à l'autre : on les range dans un **dictionnaire**.

```python
fichiers = {
    "Bruxelles": ("donnees/ris_2025_bruxelles.csv", dict(sep=";", decimal=",")),
    "Flandre": ("donnees/ris_2025_flandre.xlsx", dict()),
    "Wallonie": ("donnees/ris_2025_wallonie.txt", dict(sep="\t")),
}

tables = []
for region, (chemin, reglages) in fichiers.items():
    lire = pd.read_excel if chemin.endswith(".xlsx") else pd.read_csv
    t = lire(chemin, dtype={"id_pseudo": str}, **reglages)
    t["region_ris"] = region
    tables.append(t)

ris = pd.concat(tables, ignore_index=True)
ris.groupby("region_ris").agg(beneficiaires=("id_pseudo", "count"),
                              montant_moyen=("montant_ris", "mean")).round(0)
```

::: usage
- `fichiers.items()` parcourt les paires « clé : valeur » du dictionnaire ;
- `tables.append(t)` ajoute chaque table à la liste ; `**reglages` « déplie » le dictionnaire des réglages en paramètres.
:::

# Un tableau par région

```python
import os

for region in sorted(personnes["region"].unique()):
    une = personnes.query("region == @region")
    r = taux_pondere(une, "revenu_equivalent < @seuil", "classe_age")
    r.to_csv(f"sortie/pauvrete_{region}.csv", sep=";", decimal=",", index=False)

sorted(os.listdir("sortie"))
```

::: usage
`f"sortie/pauvrete_{region}.csv"` est un texte **à trous** (une *f-string*) : ce qui est entre accolades est remplacé par la valeur de la variable, comme `&region` dans une macro SAS.
:::

::: note
Chaque fichier contient des **taux agrégés**, jamais des lignes individuelles : c'est la règle pour tout ce qui sort d'un environnement de microdonnées.
:::

# Vérifier une fonction : assert

`assert condition` ne dit rien si la condition est vraie, et arrête tout sinon. Vérifiez vos fonctions sur des cas dont vous connaissez la réponse.

```python
test = pd.DataFrame({"x": [10, 20, 30, 40], "poids": [1, 1, 1, 5]})
assert mediane_ponderee(test["x"], test["poids"]) == 40      # le poids 5 l'emporte
assert mediane_ponderee(test["x"], pd.Series([1, 1, 1, 1])) == 20

r = taux_pondere(personnes, "age >= 0", "region")
assert (r["taux"] == 100).all()                               # tout le monde a un âge
assert round(r["population"].sum()) == round(personnes["poids"].sum())
print("Contrôles OK")
```

::: piege
Avec des poids égaux, une médiane « au milieu » de quatre valeurs se discute (20, 30, ou 25 ?). Notre fonction prend la première valeur qui atteint la moitié : c'est une **convention**, à documenter, comme celle de tout logiciel.
:::
