---
titre: Boucles et fonctions
resume: Répéter une étape pour chaque province ou chaque fichier avec for, puis écrire sa propre fonction pour ne plus recopier de code.
partie: Pour aller plus loin
---

# Quand a-t-on besoin d'une boucle ?

Avec pandas, la plupart des calculs se font **sans boucle** : une instruction s'applique à toute une colonne, `groupby` traite tous les groupes d'un coup. On écrit une boucle quand il faut **répéter une action** qui n'est pas un calcul sur une table :

- exporter **un fichier par** province ;
- lire **plusieurs fichiers** et les empiler ;
- produire **un graphique par** région.

C'est le rôle des macros `%DO` en SAS.

# La boucle for

`for valeur in liste:` répète les lignes **indentées** (décalées de 4 espaces) une fois pour chaque élément de la liste.

```python
for region in ["Bruxelles", "Flandre", "Wallonie"]:
    nb = len(communes.query("region == @region"))
    print(region, ":", nb, "communes")
```

::: usage
- La ligne `for` se termine par `:` ; le bloc répété est **indenté**. Le retour à la marge termine la boucle.
- Dans `query()`, `@region` désigne la **variable** Python `region` (et non une colonne) : c'est ainsi qu'on glisse une valeur qui change dans une condition.
:::

::: sas
`%DO i = 1 %TO 3; ... %END;` dans une macro.
:::

# Un fichier par province

On boucle sur les valeurs de la colonne `province` : chaque tour exporte les communes d'une province.

```python
import os

for province in communes["province"].unique():
    une = communes.query("province == @province")
    une.to_csv(f"sortie/communes_{province}.csv", sep=";", index=False)

sorted(os.listdir("sortie"))
```

::: usage
`f"sortie/communes_{province}.csv"` est un texte **à trous** (une *f-string*) : ce qui est entre accolades est remplacé par la valeur de la variable. C'est l'équivalent de `&province` dans une macro SAS.
:::

# Lire plusieurs fichiers dans une boucle

On lit chaque fichier, on range les tables dans une **liste**, puis on les empile.

```python
fichiers = {"Bruxelles": "donnees/population_bruxelles_2026.csv",
            "Wallonie": "donnees/population_wallonie_2026.txt"}

tables = []
for region, chemin in fichiers.items():
    sep = "\t" if chemin.endswith(".txt") else ";"
    t = pd.read_csv(chemin, sep=sep, dtype={"code_ins": str})
    t["region"] = region
    tables.append(t)

empile = pd.concat(tables, ignore_index=True)
empile["region"].value_counts()
```

::: usage
- `fichiers.items()` parcourt les paires « clé : valeur » d'un dictionnaire ;
- `tables = []` crée une liste vide, que `tables.append(t)` remplit à chaque tour ;
- `"\t" if ... else ";"` choisit une valeur selon une condition, sur une seule ligne.
:::

# Écrire sa propre fonction

Quand on recopie plusieurs fois le même bloc de code en changeant une valeur, on en fait une **fonction**. La fiche résumée d'une province :

```python
def fiche(province):
    """Communes, population et part des femmes d'une province."""
    t = communes.query("province == @province")
    return {"province": province,
            "communes": len(t),
            "population": int(t["total"].sum()),
            "part_femmes": round(float(t["femmes"].sum() / t["total"].sum() * 100), 1)}

fiche("Namur")
```

::: usage
- `def nom(paramètre):` déclare la fonction ; le bloc indenté est son contenu ;
- le texte entre triples guillemets décrit la fonction (on le lit avec `help(fiche)`) ;
- `return` renvoie le résultat ; ici un **dictionnaire** `{nom: valeur}`.
- `int()` et `float()` donnent des nombres Python ordinaires : sans eux, le dictionnaire afficherait `np.int64(506271)`, la façon dont pandas note ses propres nombres.
:::

::: sas
Une macro `%MACRO fiche(province); ... %MEND;`. Différence : une fonction Python **renvoie une valeur**, qu'on peut ranger, réutiliser, empiler.
:::

# Appliquer la fonction à chaque province

Une boucle appelle la fonction pour chaque province ; `pd.DataFrame()` transforme la liste des fiches en table.

```python
fiches = []
for province in sorted(communes["province"].unique()):
    fiches.append(fiche(province))

pd.DataFrame(fiches)
```

::: note
Pour ce calcul précis, un `groupby` aurait suffi (leçon « Calculer par groupe »). La fonction devient vraiment utile quand le traitement est **long** (lire, nettoyer, contrôler, exporter) et qu'on veut l'appliquer, identique, à chaque nouvelle livraison.
:::

# Vérifier une fonction : assert

`assert condition` ne dit rien si la condition est vraie, et arrête tout sinon. Vérifiez une fonction sur un cas dont vous connaissez la réponse.

```python
assert fiche("Bruxelles-Capitale")["communes"] == 19
assert fiche("Luxembourg")["population"] == 296370
print("Contrôles OK")
```

# Attention aux boucles sans fin

La boucle `while` répète un bloc **tant qu'une condition est vraie**. Si la condition ne devient jamais fausse, la boucle ne s'arrête pas : dans Jupyter, on l'interrompt avec le bouton ■ ; dans l'atelier, il faudrait recharger la page. Ce code n'est donc **pas exécuté** ici :

```python norun
population = 115457
while population < 120000:
    print(population)        # on a oublié de faire évoluer population
```

::: piege
Avec pandas, on a rarement besoin de `while`. Une boucle `for` sur une liste connue s'arrête toujours.
:::
