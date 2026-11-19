---
titre: Een tabel vormgeven
resume: Sorteren, waarden naar kolommen omzetten (pivot_table), terug naar het lange formaat (melt), ontdubbelen.
partie: De basis
---

# Sorteren: sort_values()

```python
gemeenten.sort_values("totaal", ascending=False).head(5)[["gemeente", "totaal"]]
```

Sorteren op meerdere kolommen: per provincie (alfabetisch), en dan op dalende bevolking binnen elke provincie.

```python
(gemeenten
 .sort_values(["provincie", "totaal"], ascending=[True, False])
 [["provincie", "gemeente", "totaal"]]
 .head(6))
```

::: sas
`PROC SORT DATA=gemeenten; BY provincie DESCENDING totaal; RUN;` In pandas dient sorteren alleen voor de **weergave** of het wegschrijven: groeperingen en koppelingen hebben het niet nodig.
:::

# Lang en breed formaat

De tabel `bevolking_geslacht` bevat dezelfde cijfers als `gemeenten`, maar in **lang formaat**: één rij per gemeente **en per geslacht**.

```python
bevolking_geslacht.head(6)
```

| Formaat | Eén rij = | Handig om |
|---|---|---|
| lang (`bevolking_geslacht`) | een gemeente × een geslacht | te groeperen, voor te stellen (één kolom per variabele) |
| breed (`gemeenten`) | een gemeente | te lezen, mannen en vrouwen naast elkaar te vergelijken |

Van het ene naar het andere gaan is een vaak voorkomende bewerking: in SAS is dat `PROC TRANSPOSE`.

# pivot_table(): waarden naar kolommen

De bevolking per provincie en per geslacht, met de geslachten **in kolommen**:

```python
bevolking_geslacht.pivot_table(index="provincie", columns="geslacht",
                               values="bevolking", aggfunc="sum")
```

::: usage
- `index`: wat **in de rijen** komt;
- `columns`: de variabele waarvan de waarden **kolommen** worden;
- `values`: de variabele om te berekenen; `aggfunc`: de berekening (`"sum"`, `"mean"`, `"count"`…).
:::

::: sas
`PROC TABULATE DATA=bevolking_geslacht; CLASS provincie geslacht; VAR bevolking; TABLE provincie, geslacht*bevolking*SUM;`, of `PROC TRANSPOSE` na een `PROC MEANS`.
:::

# De totalen toevoegen: margins

```python
bevolking_geslacht.pivot_table(index="gewest", columns="geslacht", values="bevolking",
                               aggfunc="sum", margins=True, margins_name="Totaal")
```

# Een kruistabel uit gemeenten

Het aantal gemeenten per gewest en per grootteklasse. We maken eerst de grootteklasse opnieuw aan (vorige les):

```python
gemeenten["grootte"] = pd.cut(gemeenten["totaal"],
                              bins=[0, 5000, 10000, 20000, 50000, 600000],
                              labels=["< 5 000", "5-10 000", "10-20 000",
                                      "20-50 000", "50 000 en +"])

gemeenten.pivot_table(index="gewest", columns="grootte", values="gemeente",
                      aggfunc="count", observed=False)
```

**Interpretatie:** Wallonië telt 53 gemeenten met minder dan 5 000 inwoners, Vlaanderen er maar 13, terwijl het meer gemeenten heeft: de Waalse gemeenten zijn duidelijk kleiner. In Brussel tellen ze allemaal meer dan 20 000 inwoners.

::: note
`observed=False` houdt alle klassen, ook de lege: zonder deze optie zou een klasse die in een gewest ontbreekt, uit de tabel verdwijnen.
:::

# melt(): van breed naar lang formaat

De omgekeerde bewerking: de kolommen `mannen` en `vrouwen` worden twee rijen per gemeente.

```python
lang = gemeenten.melt(id_vars=["nis_code", "gemeente"],
                      value_vars=["mannen", "vrouwen"],
                      var_name="geslacht", value_name="bevolking")
lang.sort_values("nis_code").head(4)
```

::: usage
- `id_vars`: de kolommen die je ongewijzigd houdt (de identificatie van de rij);
- `value_vars`: de kolommen die je onder elkaar zet;
- `var_name`, `value_name`: de namen van de twee nieuwe kolommen.
:::

# Dubbels: drop_duplicates()

De lijst van de provincies en hun gewest, één rij per provincie:

```python
gemeenten[["gewest", "provincie"]].drop_duplicates().sort_values(["gewest", "provincie"])
```

::: sas
`PROC SORT DATA=gemeenten OUT=provincies NODUPKEY; BY gewest provincie; RUN;`
:::

# Opnieuw nummeren na een sortering: reset_index()

Na een sortering of een filter volgen de rijnummers (de index) elkaar niet meer op. `reset_index(drop=True)` nummert ze opnieuw vanaf 0.

```python
(gemeenten
 .nlargest(3, "totaal")
 .reset_index(drop=True)
 [["gemeente", "totaal"]])
```
