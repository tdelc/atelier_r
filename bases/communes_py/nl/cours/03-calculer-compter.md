---
titre: Berekenen en tellen
resume: Een kolom samenvatten in één cijfer (som, gemiddelde, mediaan…), rijen en waarden tellen met len() en value_counts().
partie: De basis
---

# Een kolom samenvatten in één cijfer

Wat is de bevolking van België? En de gemiddelde grootte van een gemeente?

```python
gemeenten["totaal"].sum()
```

```python
gemeenten["totaal"].mean()
```

::: usage
Je neemt een kolom en past er een berekening op toe: `.sum()` (som), `.mean()` (gemiddelde), `.median()` (mediaan), `.min()`, `.max()`, `.std()` (standaardafwijking).
:::

**Interpretatie:** 11 867 634 inwoners; een gemeente telt gemiddeld 21 005 inwoners.

# round(): afronden

```python
gemeenten["totaal"].mean().round(1)
```

::: piege
Het gemiddelde (21 005) ligt veel hoger dan de mediaan (13 089): enkele heel grote gemeenten (Antwerpen, Gent, Charleroi…) trekken het gemiddelde omhoog. De mediaan verdeelt de gemeenten in twee gelijke helften: de helft van de gemeenten telt minder dan 13 089 inwoners.
:::

```python
gemeenten["totaal"].median()
```

# Meerdere indicatoren tegelijk: agg()

`.agg()` krijgt een **lijst** van berekeningen. We passen het hier toe op een deeltabel met één kolom (dubbele haken): het resultaat is een kleine tabel.

```python
gemeenten[["totaal"]].agg(["count", "sum", "mean", "median", "min", "max"]).round(0)
```

::: sas
`PROC MEANS DATA=gemeenten N SUM MEAN MEDIAN MIN MAX; VAR totaal; RUN;`
:::

# Op een deel van de tabel

We filteren eerst en rekenen dan: de totale bevolking van de provincie Namen.

```python
gemeenten.query("provincie == 'Namen'")["totaal"].sum()
```

Of, met aaneengeschakelde stappen:

```python
(gemeenten
 .query("provincie == 'Namen'")
 ["totaal"]
 .sum())
```

# len(): rijen tellen

Hoeveel gemeenten tellen meer dan 50 000 inwoners?

```python
len(gemeenten.query("totaal > 50000"))
```

::: usage
`len()` geeft het aantal rijen van een tabel. Het is de eenvoudigste manier om « hoeveel… » te beantwoorden.
:::

# value_counts(): tellen per waarde

Hoeveel gemeenten in elk gewest?

```python
gemeenten["gewest"].value_counts()
```

::: usage
`.value_counts()` telt de rijen voor elke waarde van een kolom, van de meest naar de minst voorkomende.

- `normalize=True` geeft **aandelen** in plaats van aantallen;
- `.sort_index()` sorteert de waarden alfabetisch.
:::

```python
gemeenten["gewest"].value_counts(normalize=True).round(3)
```

**Interpretatie:** Vlaanderen telt de helft van de gemeenten (285 op 565, 50,4 %), Wallonië 46,2 %, Brussel 19 gemeenten (3,4 %).

::: sas
`PROC FREQ DATA=gemeenten; TABLES gewest; RUN;`
:::

# Tellen op twee kolommen

`.value_counts()` werkt ook op meerdere kolommen: elke combinatie wordt geteld.

```python
gemeenten[["gewest", "provincie"]].value_counts().sort_index()
```

# nunique(): hoeveel verschillende waarden?

```python
gemeenten["arrondissement"].nunique()
```

**Interpretatie:** 44 arrondissementen. België telt 43 administratieve arrondissementen, maar de Europese NUTS-nomenclatuur, waar de kolom vandaan komt, splitst dat van Verviers in tweeën: Franstalige en Duitstalige gemeenten.

# nlargest() en nsmallest(): de grootste, de kleinste

De 5 gemeenten met de meeste inwoners, en dan de 5 met de minste:

```python
gemeenten.nlargest(5, "totaal")[["gemeente", "provincie", "totaal"]]
```

```python
gemeenten.nsmallest(5, "totaal")[["gemeente", "provincie", "totaal"]]
```
