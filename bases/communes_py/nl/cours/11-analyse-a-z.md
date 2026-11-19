---
titre: Een analyse van A tot Z
resume: Volledige casestudy - kleine en grote gemeenten, een ander landschap naargelang van het gewest? Van de vraag tot de conclusie, met haar grenzen.
partie: Casestudy
---

# De vraag

Je hoort vaak dat « Wallonië veel kleine gemeenten heeft ». Klopt dat? En wat betekent dat voor de inwoners?

We splitsen de vraag op in deelvragen, die elk in enkele pandas-stappen worden vertaald:

1. Zijn de gemeenten even groot van gewest tot gewest?
2. Welk deel van de gemeenten, en welk deel van de **inwoners**, bevindt zich in de kleine gemeenten?
3. Waar liggen de kleinste gemeenten?
4. Wat kunnen we besluiten, en wat kunnen we **niet** besluiten met deze gegevens?

::: etape
**De werkwijze**: een vraag → de nuttige gegevens → een tabel → een grafiek → een besluit in één zin, met zijn grenzen. We bewaren de tussentabellen onder een naam, om ze opnieuw te gebruiken.
:::

# Stap 1: de grootte van de gemeenten per gewest

```python
grootte_gewest = (gemeenten
                  .groupby("gewest", as_index=False)
                  .agg(gemeenten=("gemeente", "count"),
                       bevolking=("totaal", "sum"),
                       mediaan=("totaal", "median"),
                       gemiddelde=("totaal", "mean"))
                  .round(0))
grootte_gewest
```

**Interpretatie:** de mediaangemeente telt 8 719 inwoners in Wallonië, 16 742 in Vlaanderen en 49 638 in Brussel. Wallonië heeft bijna evenveel gemeenten als Vlaanderen (261 tegen 285) voor bijna twee keer minder inwoners.

# Stap 2: grootteklassen

We kiezen sprekende grenzen en tellen dan.

```python
gemeenten["grootte"] = pd.cut(gemeenten["totaal"],
                              bins=[0, 5000, 10000, 20000, 50000, 600000],
                              labels=["< 5 000", "5-10 000", "10-20 000",
                                      "20-50 000", "50 000 en +"])

pd.crosstab(gemeenten["gewest"], gemeenten["grootte"], margins=True, margins_name="Totaal")
```

# Stap 3: aandeel van de gemeenten, aandeel van de inwoners

Twee tabellen, twee verschillende noemers: de **gemeenten** van het gewest, en dan de **inwoners** van het gewest.

```python
aandeel_gemeenten = (pd.crosstab(gemeenten["gewest"], gemeenten["grootte"],
                                 normalize="index") * 100).round(1)
aandeel_inwoners = (pd.crosstab(gemeenten["gewest"], gemeenten["grootte"],
                                values=gemeenten["totaal"], aggfunc="sum",
                                normalize="index") * 100).round(1)
print(aandeel_gemeenten)
aandeel_inwoners
```

**Interpretatie:** in Wallonië telt 56,7 % van de gemeenten minder dan 10 000 inwoners, maar daar woont maar 23,1 % van de Walen. Een gemeente is een administratieve eenheid, geen bevolkingseenheid: beide gezichtspunten zijn nodig.

# Stap 4: een grafiek om het te tonen

We zetten de twee verdelingen van Wallonië naast elkaar: we gaan naar het lange formaat zodat seaborn kan kleuren volgens het gezichtspunt.

```python
import seaborn as sns
import matplotlib.pyplot as plt

wallonie = pd.DataFrame({
    "grootte": aandeel_gemeenten.columns.astype(str),
    "van de gemeenten": aandeel_gemeenten.loc["Wallonië"].values,
    "van de inwoners": aandeel_inwoners.loc["Wallonië"].values})
wallonie_lang = wallonie.melt(id_vars="grootte", var_name="aandeel", value_name="percentage")

sns.barplot(data=wallonie_lang, x="grootte", y="percentage", hue="aandeel")
plt.title("Wallonië: aandeel van de gemeenten en van de inwoners naar grootte van de gemeente")
plt.xlabel("Inwoners van de gemeente")
plt.ylabel("%")
```

# Stap 5: waar liggen de kleinste gemeenten?

De provincies met de meeste gemeenten van minder dan 5 000 inwoners:

```python
(gemeenten
 .query("totaal < 5000")
 .groupby("provincie", as_index=False)
 .agg(kleine=("gemeente", "count"),
      inwoners=("totaal", "sum"))
 .sort_values("kleine", ascending=False))
```

**Interpretatie:** de provincie Luik telt de meeste gemeenten met minder dan 5 000 inwoners (23 op 84), vóór Luxemburg (17 op 43, of 4 op 10). Samen hebben ze 40 van de 66 kleinste gemeenten van het land.

# Stap 6: controleren, vóór je besluit

Een eenvoudige controle: de twee tabellen dekken wel degelijk alle gemeenten en de hele bevolking.

```python
print(len(gemeenten), gemeenten["totaal"].sum())
pd.crosstab(gemeenten["gewest"], gemeenten["grootte"],
            values=gemeenten["totaal"], aggfunc="sum", margins=True).loc["All", "All"]
```

::: piege
Een percentage zonder zijn aantal kan misleiden: « 47 % van de Brusselse gemeenten telt meer dan 50 000 inwoners », dat zijn 9 gemeenten. Houd altijd de tabel van de aantallen naast de tabel van de percentages.
:::

# Besluit, en zijn grenzen

**Wat de gegevens tonen**: ja, de Waalse gemeenten zijn duidelijk kleiner dan de Vlaamse (mediaan van 8 719 inwoners tegen 16 742), en de provincies Luik en Luxemburg tellen de meeste kleine gemeenten. Maar in die kleine gemeenten woont maar een klein deel van de bevolking: in Wallonië woont minder dan één inwoner op vier in een gemeente met minder dan 10 000 inwoners.

**Wat ze niet tonen**:

- de **oppervlakte**: een kleine gemeente kan uitgestrekt en dunbevolkt zijn; je zou de oppervlakte nodig hebben (Statbel publiceert ze) om over dichtheid te spreken;
- de **geschiedenis**: Vlaanderen kende gemeentefusies in 2019 en 2025, die zijn gemeenten groter maakten;
- de **keuze van de grenzen**: met andere klassen veranderen de percentages. Je moet ze vermelden.

::: etape
**Om te onthouden**: elke stap past in enkele regels, met de werkwoorden van de cursus: `query`, `groupby`, `agg`, `pd.cut`, `crosstab`, `melt`. De moeilijkheid zit niet in de code, maar in de keuze van de **noemer** en de eerlijkheid van het besluit.
:::
