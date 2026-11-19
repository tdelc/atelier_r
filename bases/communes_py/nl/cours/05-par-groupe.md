---
titre: Berekenen per groep
resume: De tabel opdelen met groupby() om een resultaat per provincie, per gewest, per arrondissement te krijgen.
partie: De basis
---

# Een vraag per groep

« Wat is de bevolking **van elke** provincie? » We zouden provincie per provincie kunnen filteren… of pandas vragen het voor alle provincies tegelijk te doen.

```python
gemeenten.groupby("provincie")["totaal"].sum()
```

::: usage
`.groupby("kolom")` deelt de tabel op in groepen, één per waarde van de kolom. De berekening die volgt, gebeurt **binnen elke groep**.

De zin lees je als: « groeperen per provincie, `totaal` nemen, de som maken ».
:::

::: sas
`PROC MEANS DATA=gemeenten SUM; CLASS provincie; VAR totaal; RUN;`, of in SQL: `SELECT provincie, SUM(totaal) FROM gemeenten GROUP BY provincie;`
:::

# Een echte tabel: as_index=False

Standaard worden de groepen de **index** (links, vetgedrukt). Met `as_index=False` krijg je een gewone tabel, met een kolom `provincie`: makkelijker om te sorteren, te filteren of weg te schrijven.

```python
gemeenten.groupby("provincie", as_index=False)["totaal"].sum()
```

# Meerdere indicatoren per groep: agg()

Je geeft elke indicator een naam: `naam=("kolom", "berekening")`.

```python
(gemeenten
 .groupby("provincie", as_index=False)
 .agg(gemeenten=("gemeente", "count"),
      bevolking=("totaal", "sum"),
      gemiddelde_grootte=("totaal", "mean"),
      mediaan_grootte=("totaal", "median"))
 .round(0))
```

::: usage
Mogelijke berekeningen: `"count"` (aantal ingevulde rijen), `"size"` (aantal rijen), `"sum"`, `"mean"`, `"median"`, `"min"`, `"max"`, `"std"`, `"nunique"` (aantal verschillende waarden).
:::

**Interpretatie:** de provincie Luik telt de meeste gemeenten (84); de provincie Antwerpen de grootste bevolking (1,93 miljoen inwoners).

# Het resultaat sorteren

```python
(gemeenten
 .groupby("provincie", as_index=False)
 .agg(bevolking=("totaal", "sum"))
 .sort_values("bevolking", ascending=False))
```

::: usage
`.sort_values("kolom")` sorteert oplopend; `ascending=False` aflopend.
:::

# Groeperen op twee kolommen

Eén rij per **combinatie** gewest × provincie:

```python
(gemeenten
 .groupby(["gewest", "provincie"], as_index=False)
 .agg(gemeenten=("gemeente", "count"),
      bevolking=("totaal", "sum")))
```

# size(): de rijen van elke groep tellen

```python
gemeenten.groupby("gewest", as_index=False).size()
```

Het is het equivalent van `value_counts()`, maar als tabel, en voor meerdere groeperingskolommen.

# Filteren, en dan groeperen

Hoeveel gemeenten met meer dan 20 000 inwoners in elk gewest?

```python
(gemeenten
 .query("totaal > 20000")
 .groupby("gewest", as_index=False)
 .size())
```

# Een berekening per groep, en dan een filter op het resultaat

Welke arrondissementen tellen meer dan 500 000 inwoners?

```python
(gemeenten
 .groupby("arrondissement", as_index=False)
 .agg(bevolking=("totaal", "sum"))
 .query("bevolking > 500000"))
```

::: note
De volgorde van de stappen verandert de vraag: **vóór** het groeperen filteren selecteert gemeenten; **na** het groeperen filteren selecteert groepen. In SQL is dat het verschil tussen `WHERE` en `HAVING`.
:::
