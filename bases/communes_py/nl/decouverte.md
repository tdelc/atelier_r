---
base: communes_py
---

# De tabel van alle kanten bekijken
De tabel `gemeenten` is al ingeladen. Verander het aantal rijen, sorteer anders, bekijk andere kolommen.

```python
gemeenten.sort_values("totaal", ascending=False).head(10)
```

## Om te proberen
- Vervang `ascending=False` door `ascending=True`: welke gemeenten verschijnen?
- Sorteer op `vrouwen` in plaats van op `totaal`.
- Houd alleen `gemeente` en `totaal` met `[["gemeente", "totaal"]]` op het einde.
- Vervang `head(10)` door `sample(5)`: vijf willekeurige gemeenten, telkens andere.

# Jouw gemeente en haar buren
Filter je gemeente, en dan de gemeenten van haar arrondissement.

```python
gemeenten.query("gemeente == 'Namen'")
```

## Om te proberen
- Vervang `'Namen'` door je gemeente (let op accenten en hoofdletters).
- Toon alle gemeenten van haar arrondissement: `gemeenten.query("arrondissement == 'Namen'")`.
- Rangschik ze naar bevolking, van groot naar klein.
- Waar staat je gemeente in haar provincie? Probeer `.rank(ascending=False)` (les « Variabelen aanmaken »).

# Hoeveel gemeenten…?
Eén vraag, één regel. Verander de voorwaarde en bekijk het resultaat.

```python
len(gemeenten.query("totaal > 50000"))
```

## Om te proberen
- En met meer dan 100 000 inwoners? Met minder dan 3 000?
- Voeg een voorwaarde op het gewest toe met `and`.
- Hoeveel gemeenten beginnen met « Sint »? `gemeente.str.startswith('Sint')`
- Vervang `len(...)` door `[...]["totaal"].sum()`: hoeveel mensen wonen in die gemeenten?

# Per provincie, per gewest
Een groepering en meerdere indicatoren. Voeg er toe, haal er weg, verander de groeperingskolom.

```python
(gemeenten
 .groupby("provincie", as_index=False)
 .agg(gemeenten=("gemeente", "count"),
      bevolking=("totaal", "sum"))
 .sort_values("bevolking", ascending=False))
```

## Om te proberen
- Vervang `"provincie"` door `"gewest"`, en dan door `"arrondissement"`.
- Voeg de mediane bevolking toe: `mediaan=("totaal", "median")`.
- Voeg de kleinste gemeente toe: `kleinste=("totaal", "min")`.
- Voeg `.query("bevolking > 1000000")` toe op het einde: wat blijft er over?

# Grootteklassen op jouw manier
De keuze van de grenzen verandert de tabel. Probeer andere indelingen.

```python
gemeenten["grootte"] = pd.cut(gemeenten["totaal"],
                              bins=[0, 10000, 50000, 600000],
                              labels=["klein", "middelgroot", "groot"])
pd.crosstab(gemeenten["gewest"], gemeenten["grootte"], margins=True)
```

## Om te proberen
- Voeg een klasse toe: `bins=[0, 5000, 10000, 50000, 600000]` (en een label meer).
- Voeg `normalize="index"` toe: elke rij is 1 (100 %).
- Vervang `normalize="index"` door `normalize="columns"`: wat lees je nu?
- Tel de bevolking in plaats van de gemeenten: `values=gemeenten["totaal"], aggfunc="sum"`.

# Een grafiek om aan te passen
Een staafdiagram van de bevolking per provincie. Verander het type grafiek, de kleuren, de titels.

```python
import seaborn as sns
import matplotlib.pyplot as plt

per_provincie = (gemeenten.groupby(["gewest", "provincie"], as_index=False)
                 .agg(bevolking=("totaal", "sum"))
                 .sort_values("bevolking", ascending=False))
sns.barplot(data=per_provincie, x="bevolking", y="provincie", hue="gewest")
plt.title("Bevolking per provincie")
```

## Om te proberen
- Haal `hue="gewest"` weg: wat gebeurt er?
- Vervang `x="bevolking"` door `x="provincie"` en `y="provincie"` door `y="bevolking"`: de namen worden onleesbaar. Waarom zijn horizontale staven hier beter?
- Probeer `sns.histplot(data=gemeenten, x="totaal", log_scale=True, hue="gewest")`.
- Voeg `plt.xlabel("Inwoners")` toe.

# In SQL, zoals in PROC SQL
Dezelfde vraag, in SQL geschreven met DuckDB. Pas de query aan.

```python
import duckdb

duckdb.sql("""
    SELECT gewest, COUNT(*) AS gemeenten, SUM(totaal) AS bevolking
    FROM gemeenten
    GROUP BY gewest
    ORDER BY bevolking DESC
""").df()
```

## Om te proberen
- Voeg `WHERE totaal > 20000` toe vóór `GROUP BY`.
- Vervang `gewest` door `provincie` (in de `SELECT` en de `GROUP BY`).
- Voeg `HAVING COUNT(*) > 50` toe na de `GROUP BY`: wat is het verschil met `WHERE`?
- Voeg `AVG(totaal) AS gemiddelde` toe in de `SELECT`.

# De nomenclatuur van de gebieden verkennen
De NUTS-nomenclatuur van Statbel beschrijft gewesten, provincies, arrondissementen en gemeenten, met hun naam in vier talen en hun geldigheidsdata.

```python
nuts = pd.read_csv("referenties/nuts_lau_2027.txt", sep="|", encoding="cp1252")
nuts["CD_LVL"].value_counts()
```

## Om te proberen
- Toon de verdwenen gemeenten: `nuts.query("CD_LVL == 4 and DT_VLDT_STOP != '31/12/9999'")`.
- Welke zijn eind 2024 verdwenen? `DT_VLDT_STOP == '31/12/2024'`
- Toon de Franse en Duitse namen van de provincies (`CD_LVL == 2`).
- Wat gebeurt er zonder `encoding="cp1252"`?
