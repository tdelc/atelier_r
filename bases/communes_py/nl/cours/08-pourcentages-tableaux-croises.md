---
titre: De percentages van een kruistabel
resume: Percentage van het totaal, per rij of per kolom met pd.crosstab() - de juiste noemer kiezen is de vraag kiezen.
partie: De basis
---

# De kruistabel: pd.crosstab()

Het aantal gemeenten per gewest en per grootteklasse.

```python
gemeenten["grootte"] = pd.cut(gemeenten["totaal"],
                              bins=[0, 5000, 10000, 20000, 50000, 600000],
                              labels=["< 5 000", "5-10 000", "10-20 000",
                                      "20-50 000", "50 000 en +"])

pd.crosstab(gemeenten["gewest"], gemeenten["grootte"])
```

::: usage
`pd.crosstab(rijen, kolommen)` telt de rijen van de tabel voor elke combinatie: het eerste argument geeft de rijen van de kruistabel, het tweede de kolommen.
:::

::: sas
`PROC FREQ DATA=gemeenten; TABLES gewest*grootte; RUN;`
:::

# De totalen: margins=True

```python
pd.crosstab(gemeenten["gewest"], gemeenten["grootte"],
            margins=True, margins_name="Totaal")
```

# Drie percentages, drie vragen

Eenzelfde kruistabel geeft drie percentages, die op drie verschillende vragen antwoorden. Alles hangt af van de **noemer**: `normalize=`.

| `normalize=` | Noemer | De vraag |
|---|---|---|
| `"all"` | alle gemeenten | Welk deel van **alle** Belgische gemeenten is Waals en telt minder dan 5 000 inwoners? |
| `"index"` | elke **rij** (gewest) | **Van de Waalse gemeenten**, welk deel telt minder dan 5 000 inwoners? |
| `"columns"` | elke **kolom** (grootte) | **Van de gemeenten met minder dan 5 000 inwoners**, welk deel is Waals? |

# Per rij: de structuur van elk gewest

**Van de gemeenten van elk gewest**, hoe verdelen de groottes zich?

```python
(pd.crosstab(gemeenten["gewest"], gemeenten["grootte"], normalize="index")
 * 100).round(1)
```

**Interpretatie:** 20,3 % van de Waalse gemeenten telt minder dan 5 000 inwoners, tegenover 4,6 % van de Vlaamse gemeenten. Elke rij is 100 %.

# Per kolom: waar komen de gemeenten van een grootte vandaan

**Van de gemeenten van elke grootte**, welk deel ligt in elk gewest?

```python
(pd.crosstab(gemeenten["gewest"], gemeenten["grootte"], normalize="columns")
 * 100).round(1)
```

**Interpretatie:** 80,3 % van de gemeenten met minder dan 5 000 inwoners is Waals. Elke kolom is 100 %.

::: piege
« 80 % van de kleine gemeenten is Waals » en « 20 % van de Waalse gemeenten is klein » zeggen **niet** hetzelfde. Schrijf vóór het rekenen de zin op die je wilt bekomen, en zoek het woord « van de »: dat geeft de noemer.
:::

# Een aandeel van de bevolking, niet van de gemeenten

De gemeenten wegen niet allemaal even zwaar. Welk deel van de **bevolking** van elk gewest woont in elke grootteklasse? We tellen de bevolking op (`values`, `aggfunc`) in plaats van de gemeenten te tellen.

```python
(pd.crosstab(gemeenten["gewest"], gemeenten["grootte"],
             values=gemeenten["totaal"], aggfunc="sum", normalize="index")
 * 100).round(1)
```

**Interpretatie:** 20 % van de Waalse gemeenten telt minder dan 5 000 inwoners, maar daar woont maar 5 % van de Waalse bevolking. In Vlaanderen woont een kwart van de bevolking in een gemeente van 50 000 inwoners of meer.

# Dezelfde berekening met groupby

Je kunt het aandeel ook « met de hand » berekenen: groeperen, en dan delen door het totaal van de groep, zoals in de les « Variabelen aanmaken ».

```python
t = gemeenten.groupby(["gewest", "grootte"], as_index=False, observed=False).agg(
    bevolking=("totaal", "sum"))
t["aandeel"] = (t["bevolking"] / t.groupby("gewest")["bevolking"].transform("sum") * 100).round(1)
t.query("gewest == 'Wallonië'")
```

::: note
`crosstab` is korter voor een tabel om te tonen; de methode `groupby` + `transform` houdt een **lange** tabel, makkelijker om te filteren, in een grafiek te zetten of weg te schrijven.
:::
