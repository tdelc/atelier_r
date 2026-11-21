---
titre: Nettoyer une table
resume: Harmoniser des numéros d'entreprise, vérifier une clé de contrôle, traiter les déclarations rectificatives, distinguer une note de crédit d'une erreur, repérer un trimestre manquant ; garder la trace de chaque correction.
partie: Vos propres fichiers
---

# Les quatre trimestres empilés

On reprend les déclarations TVA de la leçon précédente. Elles contiennent les **défauts habituels** des vraies livraisons administratives.

```python
lire = dict(dtype={"numero_tva": str, "nace_tva": str})
t1 = pd.read_csv("donnees/tva_2025_T1.csv", sep=";", decimal=",", thousands=".", **lire)
t2 = pd.read_excel("donnees/tva_2025_T2.xlsx", header=2, **lire)
t3 = pd.read_csv("donnees/tva_2025_T3.txt", sep="\t", **lire)
t4 = pd.read_csv("donnees/tva_2025_T4.csv", **lire)
t1["trimestre"], t2["trimestre"], t3["trimestre"], t4["trimestre"] = "T1", "T2", "T3", "T4"
tva = pd.concat([t1, t2, t3, t4], ignore_index=True)
tva.shape
```

::: etape
**La démarche** : d'abord **repérer** (sans rien modifier), puis **décider** d'une règle, puis **appliquer** et **garder la trace**. Chaque ligne modifiée ou écartée doit pouvoir être expliquée.
:::

# Harmoniser le numéro : str.replace()

Quatre écritures pour un même numéro. On garde seulement les chiffres :

```python
tva["num_entreprise"] = (tva["numero_tva"]
                         .str.upper()
                         .str.replace(r"[^0-9]", "", regex=True))
print(tva["num_entreprise"].str.len().value_counts())
tva[["numero_tva", "num_entreprise"]].drop_duplicates("numero_tva").head(4)
```

::: usage
`str.replace(r"[^0-9]", "", regex=True)` remplace tout ce qui n'est **pas** un chiffre (`[^0-9]`, une *expression régulière*) par rien : lettres `BE`, points, espaces disparaissent d'un coup.
:::

::: sas
`num_entreprise = compress(numero_tva, , 'kd');` (le modificateur `kd` garde les chiffres).
:::

# Vérifier la clé de contrôle

Un numéro d'entreprise belge se termine par une **clé** : les deux derniers chiffres valent 97 moins le reste de la division des huit premiers par 97. Une faute de frappe a presque toujours une clé fausse.

```python
corps = tva["num_entreprise"].str.slice(0, 8).astype(int)
cle = tva["num_entreprise"].str.slice(8, 10).astype(int)
tva["cle_ok"] = (97 - corps % 97) == cle
tva.query("not cle_ok")
```

**Lecture :** un seul numéro a une clé fausse. Il ne peut correspondre à aucune entreprise : on le **rejette**, en le signalant au fournisseur des données.

::: note
Les numéros de cet atelier commencent par 9 pour être sûrement fictifs, mais la clé se calcule comme pour les vrais. Le même principe vaut pour le numéro de registre national, les IBAN, les codes-barres…
:::

# Les déclarations rectificatives

Une entreprise peut corriger sa déclaration : la nouvelle **remplace** l'ancienne. Repérons les numéros déclarés deux fois pour le même trimestre :

```python
doublons = tva.duplicated(subset=["num_entreprise", "trimestre"], keep=False)
tva[doublons].sort_values(["num_entreprise", "date_depot"])[
    ["num_entreprise", "trimestre", "chiffre_affaires", "date_depot"]]
```

Règle : garder la déclaration **la plus récente**. On trie par date de dépôt, puis on garde la dernière ligne de chaque couple numéro × trimestre.

```python
propre = (tva.query("cle_ok")
          .sort_values("date_depot")
          .drop_duplicates(subset=["num_entreprise", "trimestre"], keep="last")
          .copy())
print(len(tva), "->", len(propre))
```

::: piege
`drop_duplicates()` sans réfléchir garde la **première** ligne : ici, la mauvaise. Le tri préalable et `keep="last"` traduisent la règle métier « la rectificative remplace l'originale ».
:::

::: sas
`PROC SORT; BY num_entreprise trimestre date_depot; RUN;` puis `DATA; SET; BY num_entreprise trimestre; IF LAST.trimestre;`
:::

# Un chiffre d'affaires négatif : erreur ou pas ?

```python
propre.query("chiffre_affaires < 0")[["num_entreprise", "trimestre", "chiffre_affaires"]]
```

Un trimestre négatif n'est **pas** forcément une erreur : une entreprise qui a émis plus de **notes de crédit** (remboursements, annulations de factures) que de factures déclare un montant négatif. On le garde, mais on le **signale**.

```python
propre["note_credit"] = propre["chiffre_affaires"] < 0
propre["note_credit"].sum()
```

# Une valeur aberrante

Comparons chaque trimestre à la médiane des trimestres de la même entreprise :

```python
mediane = propre.groupby("num_entreprise")["chiffre_affaires"].transform("median")
propre["ratio"] = propre["chiffre_affaires"] / mediane
propre.query("ratio > 20")[["num_entreprise", "trimestre", "chiffre_affaires", "ratio"]]
```

**Lecture :** un trimestre vaut environ 100 fois les autres : un montant encodé en **centimes** au lieu d'euros. Ce n'est pas certain, mais très probable : on corrige, **en gardant la trace** de la correction.

```python
aberrant = propre["ratio"] > 20
propre["corrige"] = aberrant
propre.loc[aberrant, "chiffre_affaires"] = propre.loc[aberrant, "chiffre_affaires"] / 100
```

# Un trimestre manquant

Chaque entreprise devrait avoir quatre déclarations :

```python
nb = propre.groupby("num_entreprise")["trimestre"].nunique()
nb[nb != 4]
```

**Lecture :** deux entreprises n'ont que trois trimestres. L'une a déposé en retard (sa déclaration n'est pas encore arrivée) ; l'autre est celle dont le numéro a été mal saisi au 1er trimestre. Leur chiffre d'affaires annuel serait **sous-estimé** : à signaler, ou à estimer (par exemple à partir des trois autres trimestres), en le documentant.

# Le chiffre d'affaires annuel, et le contrôle final

```python
annuel = (propre
          .groupby("num_entreprise", as_index=False)
          .agg(ca_tva=("chiffre_affaires", "sum"), trimestres=("trimestre", "nunique")))
annuel["ca_tva"] = annuel["ca_tva"] / 1000          # en milliers d'euros, comme la table

comparaison = entreprises.merge(annuel, on="num_entreprise", how="left",
                                validate="one_to_one")
comparaison["ecart"] = (comparaison["ca_tva"] - comparaison["ca"]).round(1)
comparaison.query("ecart.abs() > 0.1")[["num_entreprise", "nace", "ca", "ca_tva", "trimestres"]]
```

**Lecture :** après nettoyage, toutes les entreprises retrouvent leur chiffre d'affaires de référence, sauf les deux qui n'ont que trois trimestres. Le nettoyage est cohérent, et ses limites sont connues.

# Un bilan chiffré : la piste d'audit

```python
bilan = pd.DataFrame({
    "étape": ["déclarations lues", "numéro à clé fausse", "rectificatives remplacées",
              "notes de crédit (gardées)", "montants corrigés (centimes)",
              "entreprises à 3 trimestres"],
    "nombre": [len(tva), (~tva["cle_ok"]).sum(), len(tva.query("cle_ok")) - len(propre),
               propre["note_credit"].sum(), propre["corrige"].sum(), (nb != 4).sum()]})
bilan
```

::: piege
**Nettoyé ne veut pas dire complet.** Une table nettoyée a toujours des limites : écrivez-les à côté des résultats que vous publiez.
:::
