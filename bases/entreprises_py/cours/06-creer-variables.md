---
titre: Créer des variables
resume: Une nouvelle colonne par calcul ; productivité, âge ; classes de taille avec pd.cut() ; conditions avec np.where() ; part dans le groupe avec transform().
partie: Les bases
---

# Une colonne calculée

Le chiffre d'affaires en millions d'euros, et l'âge de l'entreprise :

```python
entreprises["ca_meur"] = entreprises["ca"] / 1000
entreprises["age"] = 2025 - entreprises["creation"]
entreprises[["nace", "creation", "age", "ca", "ca_meur"]].head(3)
```

::: usage
`table["nouvelle"] = calcul` crée (ou remplace) une colonne. Le calcul s'applique à **toutes les lignes à la fois** : pas de boucle.
:::

::: sas
`DATA entreprises; SET entreprises; ca_meur = ca / 1000; age = 2025 - creation; RUN;`
:::

# La productivité apparente : CA par salarié

```python
employeurs = entreprises.query("emploi > 0").copy()
employeurs["ca_par_salarie"] = employeurs["ca"] / employeurs["emploi"]
(employeurs
 .groupby("secteur", as_index=False)
 .agg(ca_par_salarie=("ca_par_salarie", "median"))
 .sort_values("ca_par_salarie", ascending=False)
 .round(0)
 .head(5))
```

::: piege
On ne divise que pour les **employeurs** : diviser par 0 salarié donnerait l'infini (`inf`). `.copy()` crée une table indépendante, que l'on peut modifier sans avertissement.
:::

**Lecture :** l'énergie et le commerce ont le chiffre d'affaires par salarié le plus élevé : ce n'est pas une mesure de « richesse produite » (pour cela, il faudrait la **valeur ajoutée**, ce que l'entreprise ajoute aux achats qu'elle revend).

# Des classes de taille : pd.cut()

Les classes de taille européennes : micro (moins de 10 salariés), petite (10 à 49), moyenne (50 à 249), grande (250 et plus).

```python
entreprises["taille"] = pd.cut(entreprises["emploi"],
                               bins=[-1, 0, 9, 49, 249, 100000],
                               labels=["0 salarié", "1-9", "10-49", "50-249", "250 et +"])
entreprises["taille"].value_counts().sort_index()
```

::: usage
`bins` donne les **bornes**, `labels` les noms des classes (un de moins que les bornes). Chaque classe contient sa borne de droite : `(0, 9]` va de 1 à 9. La borne `-1` permet de faire une classe pour 0 exactement.
:::

::: sas
Un format : `PROC FORMAT; VALUE taille 0='0 salarié' 1-9='1-9' 10-49='10-49' ...;`
:::

# Une condition : np.where()

```python
entreprises["employeur"] = np.where(entreprises["emploi"] > 0, "oui", "non")
entreprises["employeur"].value_counts()
```

::: usage
`np.where(condition, valeur_si_vrai, valeur_si_faux)` : l'équivalent d'un `IF … THEN … ELSE` sur toute la colonne.
:::

# Plusieurs conditions : np.select()

Une génération d'entreprises selon l'année de création :

```python
conditions = [entreprises["creation"] < 2000,
              entreprises["creation"] < 2015]
entreprises["generation"] = np.select(conditions, ["avant 2000", "2000-2014"],
                                      default="2015 et après")
entreprises["generation"].value_counts()
```

::: note
Les conditions sont testées **dans l'ordre** : la première vraie l'emporte, comme `IF … ELSE IF …` en SAS.
:::

# La part dans le groupe : transform()

Quelle part de l'emploi de sa section chaque entreprise représente-t-elle ?

```python
emploi_section = entreprises.groupby("section")["emploi"].transform("sum")
entreprises["part_section"] = (entreprises["emploi"] / emploi_section * 100).round(2)
entreprises.nlargest(3, "part_section")[["nace", "section", "emploi", "part_section"]]
```

::: usage
`transform("sum")` calcule la somme **par groupe** mais la recopie sur **chaque ligne** du groupe : la table garde ses 12 000 lignes, et on peut diviser ligne à ligne.
:::

**Lecture :** dans certaines sections, une seule entreprise pèse plus d'un cinquième de l'emploi : c'est encore la question du secret statistique.

# Le rang : rank()

Le classement de chaque entreprise par chiffre d'affaires, dans sa région :

```python
entreprises["rang_region"] = entreprises.groupby("region")["ca"].rank(ascending=False)
entreprises.query("rang_region <= 2")[["region", "nace", "commune", "ca", "rang_region"]]
```
