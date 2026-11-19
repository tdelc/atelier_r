---
titre: Een variabele verkennen
resume: describe(), kwantielen, histogram en staafdiagram om snel naar een kolom te kijken.
partie: De basis
---

# describe(): de samenvatting van een numerieke kolom

```python
gemeenten["totaal"].describe()
```

::: usage
`.describe()` geeft het aantal (`count`), het gemiddelde (`mean`), de standaardafwijking (`std`), het minimum, de kwartielen (25 %, 50 % = mediaan, 75 %) en het maximum.
:::

**Interpretatie:** een kwart van de gemeenten telt minder dan 7 539 inwoners, een kwart meer dan 23 037. De standaardafwijking (34 080) is groter dan het gemiddelde: de groottes liggen sterk uit elkaar.

::: sas
`PROC MEANS` of `PROC UNIVARIATE`.
:::

# describe() op de hele tabel

Op de tabel toegepast, vat `describe()` alle numerieke kolommen tegelijk samen.

```python
gemeenten.describe().round(0)
```

# quantile(): je eigen grenzen kiezen

```python
gemeenten["totaal"].quantile([0.1, 0.5, 0.9])
```

**Interpretatie:** 10 % van de gemeenten telt minder dan 4 443 inwoners, 10 % meer dan 38 187.

# Een snel histogram

Een kolom heeft een methode `.plot.hist()` die haar histogram tekent: elke staaf telt de gemeenten waarvan de bevolking in een interval valt.

```python
gemeenten["totaal"].plot.hist(bins=40)
```

**Interpretatie:** de meeste gemeenten tellen minder dan 50 000 inwoners; enkele grote steden, helemaal rechts, drukken de grafiek plat.

::: note
Deze snelle grafieken dienen om naar je gegevens te **kijken**. Voor verzorgde grafieken, om te publiceren, gebruiken we seaborn (les « Grafieken »).
:::

# De grafiek beperken tot een deel van de gemeenten

```python
gemeenten.query("totaal < 50000")["totaal"].plot.hist(bins=40)
```

# Een tekstkolom verkennen

Bij een tekstkolom tellen we de waarden en tekenen we ze dan als staven.

```python
gemeenten["provincie"].value_counts()
```

```python
gemeenten["provincie"].value_counts().plot.barh()
```

# unique(): de mogelijke waarden

```python
gemeenten["gewest"].unique()
```

::: usage
`.unique()` geeft de verschillende waarden van een kolom. Handig om de exacte spelling te controleren voordat je een voorwaarde schrijft.
:::
