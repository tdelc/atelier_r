---
titre: Explorer une variable
resume: describe(), médiane et moyenne, quantiles ; une distribution très asymétrique : beaucoup de petites entreprises, quelques géantes.
partie: Les bases
---

# describe() : le résumé d'une colonne

```python
entreprises["emploi"].describe().round(1)
```

**Lecture :** la moyenne vaut 6,2 salariés, mais la **médiane** (50 %) vaut 0 : plus de la moitié des entreprises n'ont aucun salarié. Le maximum dépasse 3 000. La moyenne est tirée vers le haut par quelques grandes entreprises.

::: sas
`PROC MEANS DATA=entreprises N MEAN STD MIN P25 MEDIAN P75 MAX; VAR emploi; RUN;`
:::

# Moyenne ou médiane ?

```python
employeurs = entreprises.query("emploi > 0")
print(round(employeurs["emploi"].mean(), 1), employeurs["emploi"].median())
```

**Lecture :** parmi les employeurs, la moyenne est de 14,9 salariés, la médiane de 4. Pour décrire « l'entreprise typique », la **médiane** ; pour un total (emploi d'un secteur), la **somme** ; la moyenne seule trompe.

# Les quantiles : quantile()

```python
entreprises["emploi"].quantile([0.5, 0.75, 0.9, 0.99])
```

::: usage
`quantile(0.9)` : la valeur sous laquelle se trouvent 90 % des entreprises. Une liste donne plusieurs quantiles d'un coup.
:::

**Lecture :** 90 % des entreprises ont au plus 10 salariés ; il faut monter au 99e centile pour approcher 80 salariés.

# Le chiffre d'affaires : encore plus asymétrique

```python
entreprises["ca"].describe().round(1)
```

**Lecture :** médiane de 164 milliers d'euros, moyenne de 2,9 millions : la moyenne est **17 fois** la médiane.

# Qui sont les plus grandes ? nlargest()

```python
entreprises.nlargest(5, "ca")[["nace", "secteur", "commune", "emploi", "ca"]]
```

::: usage
`nlargest(n, "colonne")` garde les n plus grandes valeurs ; `nsmallest()` les plus petites. C'est plus court que `sort_values()` + `head()`.
:::

# Le poids des plus grandes

Quelle part du chiffre d'affaires total réalisent les 1 % d'entreprises les plus grandes ?

```python
ca = entreprises["ca"].dropna().sort_values(ascending=False)
top1 = ca.head(len(ca) // 100)
round(top1.sum() / ca.sum() * 100, 1)
```

**Lecture :** 1 % des entreprises réalisent plus de 70 % du chiffre d'affaires déclaré. C'est typique des données d'entreprises : une statistique sectorielle peut dépendre de **quelques unités**, et donc du secret statistique.

::: piege
**Secret statistique.** Publier le chiffre d'affaires d'une commune où une seule grande entreprise réalise presque tout revient à publier le chiffre de cette entreprise. Les instituts statistiques masquent ces cases (règle du nombre minimal d'unités, règle de dominance).
:::

# Les modalités d'une colonne de texte

```python
entreprises["section"].value_counts().head(5)
```
