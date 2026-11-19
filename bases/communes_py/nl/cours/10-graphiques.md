---
titre: Grafieken met seaborn
resume: Een tabel voorbereiden en dan tekenen - staven, histogrammen, boxplots, puntenwolken, gestapelde staven; titels, assen en wegschrijven.
partie: Voorstellen
---

# Twee bibliotheken: seaborn en matplotlib

- **seaborn** tekent een grafiek vanuit een **tabel**: je geeft de tabel (`data=`) en de kolommen voor elke as (`x=`, `y=`), zoals ggplot2 in R.
- **matplotlib**, waarop seaborn steunt, dient voor de afwerking: titel, namen van de assen, grootte, wegschrijven.

```python
import seaborn as sns
import matplotlib.pyplot as plt

sns.set_theme(style="whitegrid")    # een sobere stijl, één keer
```

::: usage
Deze twee `import`-regels staan bovenaan het script, naast `import pandas as pd`. `sns` en `plt` zijn de gebruikelijke afkortingen.
:::

# Eerst de tabel, dan de grafiek

Een grafiek bereid je voor zoals een tabel: je berekent eerst de tabel om te tekenen, met de stappen van de cursus.

```python
per_provincie = (gemeenten
                 .groupby("provincie", as_index=False)
                 .agg(bevolking=("totaal", "sum"))
                 .sort_values("bevolking", ascending=False))
per_provincie["duizenden"] = per_provincie["bevolking"] / 1000

sns.barplot(data=per_provincie, x="duizenden", y="provincie")
plt.title("Bevolking per provincie, 1 januari 2026")
plt.xlabel("Inwoners (duizenden)")
plt.ylabel("")
```

::: usage
Horizontale staven (`y=` de categorie): lange namen blijven leesbaar. De volgorde van de staven volgt de volgorde van de tabel: je sorteert vóór het tekenen. De bevolking staat in duizenden, anders zou de as in wetenschappelijke notatie verschijnen (« 1e6 »).
:::

::: sas
`PROC SGPLOT DATA=per_provincie; HBAR provincie / RESPONSE=bevolking; RUN;`
:::

# Een histogram: sns.histplot()

De verdeling van de gemeenten naar bevolking. Met `log_scale=True` staat de as op een logaritmische schaal: de kleine gemeenten worden niet meer platgedrukt door Antwerpen.

```python
sns.histplot(data=gemeenten, x="totaal", bins=30, log_scale=True)
plt.title("Verdeling van de gemeenten naar bevolking")
plt.xlabel("Inwoners (logaritmische schaal)")
plt.ylabel("Aantal gemeenten")
```

# Groepen vergelijken: hue=

`hue=` kleurt volgens een kolom: één histogram per gewest, over elkaar heen.

```python
sns.histplot(data=gemeenten, x="totaal", hue="gewest", bins=30,
             log_scale=True, element="step")
plt.xlabel("Inwoners (logaritmische schaal)")
plt.ylabel("Aantal gemeenten")
```

**Interpretatie:** de Waalse gemeenten liggen meer naar links (kleiner), de Brusselse helemaal rechts.

# Boxplots: sns.boxplot()

De doos loopt van het eerste tot het derde kwartiel, de streep in het midden is de mediaan; de losse punten zijn de atypische gemeenten.

```python
sns.boxplot(data=gemeenten, x="totaal", y="gewest", log_scale=True)
plt.xlabel("Inwoners (logaritmische schaal)")
plt.ylabel("")
```

# Een puntenwolk: sns.scatterplot()

Elk punt is een gemeente: haar bevolking op de horizontale as, het aandeel vrouwen op de verticale.

```python
gemeenten["aandeel_vrouwen"] = gemeenten["vrouwen"] / gemeenten["totaal"] * 100

sns.scatterplot(data=gemeenten, x="totaal", y="aandeel_vrouwen", hue="gewest", alpha=0.6)
plt.xscale("log")
plt.axhline(50, color="grey", linestyle="--")    # de lijn van 50 %
plt.xlabel("Inwoners (logaritmische schaal)")
plt.ylabel("Aandeel vrouwen (%)")
```

**Interpretatie:** het aandeel vrouwen blijft overal dicht bij 50 %; het schommelt meer in de kleine gemeenten, waar enkele inwoners volstaan om het te doen bewegen.

# Gestapelde staven tot 100 %

De rijpercentages van een kruistabel (vorige les) teken je rechtstreeks met de methode `.plot.barh(stacked=True)` van de tabel.

```python
gemeenten["grootte"] = pd.cut(gemeenten["totaal"],
                              bins=[0, 5000, 10000, 20000, 50000, 600000],
                              labels=["< 5 000", "5-10 000", "10-20 000",
                                      "20-50 000", "50 000 en +"])
verdeling = pd.crosstab(gemeenten["gewest"], gemeenten["grootte"],
                        normalize="index") * 100

verdeling.plot.barh(stacked=True, colormap="viridis")
plt.xlabel("% van de gemeenten van het gewest")
plt.ylabel("")
plt.legend(title="Inwoners", bbox_to_anchor=(1, 1))
```

# Een grafiek wegschrijven

`plt.savefig()` bewaart de huidige grafiek, in het formaat van de extensie (`.png`, `.pdf`, `.svg`).

```python
sns.barplot(data=per_provincie, x="duizenden", y="provincie")
plt.title("Bevolking per provincie (duizenden inwoners)")
plt.savefig("uitvoer/bevolking_provincies.png", dpi=150, bbox_inches="tight")
```

::: usage
- `dpi=150`: de resolutie (150 volstaat voor een document, 300 voor een afdruk);
- `bbox_inches="tight"`: snijdt overbodige marges weg en voorkomt dat labels afgeknipt worden.
:::

::: note
In een notebook of een script toont `plt.show()` de grafiek; daarna begint een nieuwe grafiek. In het atelier maakt elk codeblok zijn eigen grafieken.
:::
