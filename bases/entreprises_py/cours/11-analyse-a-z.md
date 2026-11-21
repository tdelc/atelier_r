---
titre: Une analyse de A à Z
resume: Étude de cas complète - les PME portent-elles l'emploi ? De la question à la conclusion, avec ses limites et le secret statistique.
partie: Étude de cas
---

# La question

On entend souvent que « les PME sont le moteur de l'emploi ». Que disent nos données ?

On découpe la question en sous-questions, chacune traduite en quelques étapes pandas :

1. Combien d'entreprises dans chaque classe de taille, et combien de salariés ?
2. Le poids des PME est-il le même d'un secteur à l'autre ?
3. Et d'une région à l'autre ?
4. Que peut-on conclure, et que ne peut-on **pas** conclure ?

::: etape
**La démarche** : une question → les données utiles → un tableau → un graphique → une conclusion en une phrase, avec ses limites. On garde les tables intermédiaires sous un nom, pour les réutiliser.
:::

::: piege
Rappel : ces entreprises sont **fictives**. La démarche est la bonne ; les chiffres ne décrivent pas l'économie belge.
:::

# Étape 1 : les classes de taille

```python
entreprises["taille"] = pd.cut(entreprises["emploi"],
                               bins=[-1, 0, 9, 49, 249, 100000],
                               labels=["0", "1-9", "10-49", "50-249", "250 et +"])
classes = (entreprises
           .groupby("taille", as_index=False, observed=False)
           .agg(entreprises=("num_entreprise", "count"),
                emploi=("emploi", "sum")))
classes["part_entreprises"] = (classes["entreprises"] / classes["entreprises"].sum() * 100).round(1)
classes["part_emploi"] = (classes["emploi"] / classes["emploi"].sum() * 100).round(1)
classes
```

**Lecture :** les entreprises de moins de 50 salariés sont 98,4 % des entreprises et emploient 45,4 % des salariés. Les 35 entreprises de 250 salariés et plus emploient à elles seules un tiers des salariés.

# Étape 2 : la part des PME par secteur

On définit les **PME** comme les employeurs de 1 à 249 salariés.

```python
entreprises["pme"] = entreprises["emploi"].between(1, 249)
par_secteur = (entreprises
               .groupby("secteur", as_index=False)
               .agg(emploi=("emploi", "sum"),
                    emploi_pme=("emploi", lambda x: x[entreprises.loc[x.index, "pme"]].sum())))
par_secteur["part_pme"] = (par_secteur["emploi_pme"] / par_secteur["emploi"] * 100).round(1)
par_secteur.sort_values("part_pme").head(5)
```

::: usage
Une fonction écrite sur place (`lambda x: …`) calcule un indicateur sur mesure. Ici, plus simple encore : créer d'abord une colonne `emploi_pme` (l'emploi si PME, 0 sinon) avec `np.where`, puis la sommer.
:::

La version plus lisible, à préférer :

```python
entreprises["emploi_pme"] = np.where(entreprises["pme"], entreprises["emploi"], 0)
par_secteur = (entreprises
               .groupby("secteur", as_index=False)
               .agg(emploi=("emploi", "sum"), emploi_pme=("emploi_pme", "sum")))
par_secteur["part_pme"] = (par_secteur["emploi_pme"] / par_secteur["emploi"] * 100).round(1)
par_secteur.query("emploi > 1000").sort_values("part_pme")
```

**Lecture :** dans la finance et l'industrie, l'emploi est surtout dans les grandes entreprises ; dans la construction, l'horeca ou les activités spécialisées, il est presque entièrement dans les PME.

# Étape 3 : par région

```python
par_region = (entreprises
              .groupby("region", as_index=False)
              .agg(emploi=("emploi", "sum"), emploi_pme=("emploi_pme", "sum")))
par_region["part_pme"] = (par_region["emploi_pme"] / par_region["emploi"] * 100).round(1)
par_region
```

**Lecture :** la part des PME dans l'emploi va de 41 % à Bruxelles, où se trouvent les grands sièges (banques notamment), à plus de 90 % en Wallonie.

# Étape 4 : un graphique pour le montrer

```python
import seaborn as sns
import matplotlib.pyplot as plt

graphe = par_secteur.query("emploi > 1000").sort_values("part_pme")
sns.barplot(data=graphe, x="part_pme", y="secteur", color="#3b6ea5")
plt.axvline(par_region["emploi_pme"].sum() / par_region["emploi"].sum() * 100,
            color="grey", linestyle="--")
plt.title("Part de l'emploi salarié dans les PME (1 à 249 salariés)")
plt.xlabel("%")
plt.ylabel("")
```

La ligne pointillée marque la moyenne, tous secteurs confondus.

# Étape 5 : vérifier avant de conclure

Les deux tables couvrent-elles bien tout l'emploi ?

```python
print(entreprises["emploi"].sum(), classes["emploi"].sum(),
      par_secteur["emploi"].sum(), par_region["emploi"].sum())
```

Et le **secret statistique** : combien d'entreprises derrière chaque case du tableau par secteur et région ?

```python
cases = entreprises.query("emploi > 0").groupby(["secteur", "region"]).size()
cases[cases < 3]
```

::: piege
Une case qui repose sur une ou deux entreprises ne se publie pas telle quelle : elle révélerait l'emploi ou le chiffre d'affaires d'une entreprise identifiable. On la regroupe avec une autre, ou on la masque.
:::

# Conclusion, et ses limites

**Ce que les données montrent** : les PME (1 à 249 salariés) portent les deux tiers de l'emploi salarié, et les entreprises de moins de 50 salariés près de la moitié ; davantage dans la construction, l'horeca et les services aux personnes ; quelques très grandes entreprises pèsent autant que des milliers de petites.

**Ce qu'elles ne montrent pas** :

- le **dynamisme** : « moteur de l'emploi » parle de **création** d'emplois ; il faudrait comparer deux années (démographie des entreprises) ;
- l'emploi **indépendant** : les 7 036 entreprises sans salarié font travailler au moins leur dirigeant, absent de la colonne `emploi` ;
- les **groupes** : une grande entreprise peut être découpée en plusieurs unités légales, chacune « PME » ; la notion européenne d'entreprise tient compte des liens entre sociétés.

::: etape
**À retenir** : chaque étape tient en quelques lignes, avec les verbes du cours : `pd.cut`, `groupby`, `agg`, `np.where`, `crosstab`. La difficulté n'est pas le code, mais le **choix de l'unité** (entreprise ou salarié) et l'honnêteté de la conclusion.
:::
