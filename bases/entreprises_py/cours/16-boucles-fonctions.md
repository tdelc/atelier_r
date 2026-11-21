---
titre: Boucles et fonctions
resume: Répéter une étape pour chaque secteur ou chaque fichier avec for, puis écrire ses propres fonctions - nettoyer un numéro, vérifier une clé, produire une fiche sectorielle.
partie: Pour aller plus loin
---

# Quand a-t-on besoin d'une boucle ?

Avec pandas, la plupart des calculs se font **sans boucle** : une instruction s'applique à toute une colonne, `groupby` traite tous les groupes d'un coup. On écrit une boucle quand il faut **répéter une action** qui n'est pas un calcul sur une table :

- lire **plusieurs fichiers** (les quatre trimestres) ;
- exporter **un fichier par** région ou par secteur ;
- produire **un graphique par** section.

C'est le rôle des macros `%DO` en SAS.

# La boucle for

`for valeur in liste:` répète les lignes **indentées** (décalées de 4 espaces) une fois pour chaque élément de la liste.

```python
for region in ["Bruxelles", "Flandre", "Wallonie"]:
    n = len(entreprises.query("region == @region and emploi >= 50"))
    print(region, ":", n, "entreprises de 50 salariés ou plus")
```

::: usage
- La ligne `for` se termine par `:` ; le bloc répété est **indenté**.
- Dans `query()`, `@region` désigne la **variable** Python `region` (et non une colonne).
:::

::: sas
`%DO i = 1 %TO 3; ... %END;` dans une macro.
:::

# Lire les quatre trimestres dans une boucle

Les réglages diffèrent d'un fichier à l'autre : on les range dans un **dictionnaire**, puis une boucle lit chaque fichier.

```python
fichiers = {
    "T1": ("donnees/tva_2025_T1.csv", dict(sep=";", decimal=",", thousands=".")),
    "T2": ("donnees/tva_2025_T2.xlsx", dict(header=2)),
    "T3": ("donnees/tva_2025_T3.txt", dict(sep="\t")),
    "T4": ("donnees/tva_2025_T4.csv", dict()),
}

tables = []
for trimestre, (chemin, reglages) in fichiers.items():
    lire = pd.read_excel if chemin.endswith(".xlsx") else pd.read_csv
    t = lire(chemin, dtype={"numero_tva": str, "nace_tva": str}, **reglages)
    t["trimestre"] = trimestre
    tables.append(t)

tva = pd.concat(tables, ignore_index=True)
tva["trimestre"].value_counts().sort_index()
```

::: usage
- `fichiers.items()` parcourt les paires « clé : valeur » du dictionnaire ;
- `tables = []` crée une liste vide, que `tables.append(t)` remplit à chaque tour ;
- `**reglages` « déplie » le dictionnaire des réglages en paramètres de la fonction.
:::

# Écrire sa propre fonction

Quand on recopie plusieurs fois le même bloc en changeant une valeur, on en fait une **fonction**. Nettoyer un numéro d'entreprise :

```python
def nettoyer_numero(colonne):
    """Garde les seuls chiffres d'une colonne de numéros d'entreprise."""
    return colonne.str.upper().str.replace(r"[^0-9]", "", regex=True)

nettoyer_numero(pd.Series(["BE0412.345.678", " be 0412 345 678 ", "0412345678"]))
```

::: usage
- `def nom(paramètre):` déclare la fonction ; le bloc indenté est son contenu ;
- le texte entre triples guillemets décrit la fonction (on le lit avec `help(nettoyer_numero)`) ;
- `return` renvoie le résultat.
:::

# Une fonction qui contrôle

```python
def cle_valide(numero):
    """Vrai si les deux derniers chiffres sont la clé modulo 97 des huit premiers."""
    return 97 - int(numero[:8]) % 97 == int(numero[8:])

print(cle_valide("9000019690"), cle_valide("9000019691"))
```

Appliquée à toute une colonne avec `.map()` :

```python
tva["num_entreprise"] = nettoyer_numero(tva["numero_tva"])
tva["cle_ok"] = tva["num_entreprise"].map(cle_valide)
tva["cle_ok"].value_counts()
```

::: sas
`PROC FCMP` pour une fonction qui calcule une valeur ; une macro `%MACRO` pour un bloc de code répété. Différence : une fonction Python **renvoie une valeur**, qu'on peut ranger, réutiliser, tester.
:::

# Une fiche par secteur

```python
def fiche(section):
    """Entreprises, emploi, part des PME et CA médian d'une section NACE."""
    t = entreprises.query("section == @section")
    employeurs = t.query("emploi > 0")
    return {"section": section,
            "entreprises": len(t),
            "emploi": int(t["emploi"].sum()),
            "part_emploi_pme": round(float(t.query("emploi < 250")["emploi"].sum()
                                           / max(t["emploi"].sum(), 1) * 100), 1),
            "ca_median": round(float(employeurs["ca"].median()), 1)}

fiche("I")
```

::: usage
`int()` et `float()` donnent des nombres Python ordinaires : sans eux, le dictionnaire afficherait `np.int64(5181)`, la façon dont pandas note ses propres nombres. `max(…, 1)` évite une division par zéro.
:::

# Appliquer la fonction à chaque section

```python
fiches = [fiche(s) for s in sorted(entreprises["section"].unique())]
pd.DataFrame(fiches).sort_values("emploi", ascending=False).head(6)
```

::: usage
`[fiche(s) for s in …]` est une **liste en compréhension** : une boucle `for` qui remplit une liste, écrite sur une ligne.
:::

::: note
Pour ce calcul précis, un `groupby` aurait suffi. La fonction devient vraiment utile quand le traitement est **long** (lire, nettoyer, contrôler, exporter) et qu'on veut l'appliquer, identique, à chaque nouvelle livraison trimestrielle.
:::

# Un fichier par région

```python
import os

for region in entreprises["region"].unique():
    une = entreprises.query("region == @region")
    une.to_csv(f"sortie/entreprises_{region}.csv", sep=";", decimal=",", index=False)

sorted(os.listdir("sortie"))
```

::: usage
`f"sortie/entreprises_{region}.csv"` est un texte **à trous** (une *f-string*) : ce qui est entre accolades est remplacé par la valeur de la variable, comme `&region` dans une macro SAS.
:::

# Vérifier une fonction : assert

`assert condition` ne dit rien si la condition est vraie, et arrête tout sinon. Vérifiez une fonction sur des cas dont vous connaissez la réponse.

```python
assert nettoyer_numero(pd.Series([" BE 0412.345.678"]))[0] == "0412345678"
assert cle_valide("9000019690") and not cle_valide("9000019691")
assert fiche("I")["entreprises"] == len(entreprises.query("section == 'I'"))
print("Contrôles OK")
```
