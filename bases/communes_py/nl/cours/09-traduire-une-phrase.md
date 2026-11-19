---
titre: Een zin vertalen naar Python
resume: De sleutelwoorden van een vraag herkennen en ze vervangen door de juiste pandas-stap.
partie: De basis
---

# Een vraag, sleutelwoorden

Een goed gestelde vraag bevat de code al. Je hoeft alleen haar sleutelwoorden te herkennen en ze, in volgorde, te vervangen door de pandas-stappen.

| In de vraag | De pandas-stap | In SAS |
|---|---|---|
| « van de », « voor de », « alleen » | `.query("…")` | `WHERE` |
| « voor elk(e) », « per », « volgens » | `.groupby(…, as_index=False)` | `CLASS`, `BY`, `GROUP BY` |
| « hoeveel » | `.size()`, `len()`, `"count"` | `N`, `PROC FREQ` |
| « gemiddeld », « in totaal » | `.agg(x=("kol", "mean"))`, `"sum"` | `MEAN`, `SUM` |
| « het aandeel », « het percentage » | een deling, of `normalize=` | `PCTN`, `PCTSUM` |
| « de meeste », « rangschikken » | `.sort_values(…)`, `.nlargest(…)` | `PROC SORT` |
| « alleen tonen » | `[["kol1", "kol2"]]` | `KEEP` |

# Voorbeeld 1

> « Hoeveel gemeenten tellen **meer dan** 30 000 inwoners, **voor elk** gewest? »

1. « meer dan 30 000 inwoners »: een filter;
2. « voor elk gewest »: een groepering;
3. « hoeveel »: een telling.

```python
(gemeenten
 .query("totaal > 30000")
 .groupby("gewest", as_index=False)
 .size())
```

# Voorbeeld 2

> « **Van de** gemeenten van de provincie Luik, **welke zijn de 3** grootste? »

```python
(gemeenten
 .query("provincie == 'Luik'")
 .nlargest(3, "totaal")
 [["gemeente", "totaal"]])
```

# Voorbeeld 3

> « **Voor elke** provincie, **wat is** de **gemiddelde** bevolking van een gemeente, **gerangschikt** van de grootste naar de kleinste? »

```python
(gemeenten
 .groupby("provincie", as_index=False)
 .agg(gemiddelde_grootte=("totaal", "mean"))
 .round(0)
 .sort_values("gemiddelde_grootte", ascending=False))
```

# Voorbeeld 4

> « **Welk deel** van de Belgische bevolking woont **in** een gemeente met **minder dan** 10 000 inwoners? »

Teller en noemer zijn twee sommen: we berekenen ze na elkaar.

```python
kleine = gemeenten.query("totaal < 10000")["totaal"].sum()
belgie = gemeenten["totaal"].sum()
round(kleine / belgie * 100, 1)
```

**Interpretatie:** 10,4 % van de Belgen woont in een gemeente met minder dan 10 000 inwoners, terwijl die gemeenten meer dan een derde van de gemeenten uitmaken (203 op 565).

# Voorbeeld 5: de volgorde van de stappen telt

> « **Voor elk** arrondissement de totale bevolking; **alleen** de arrondissementen met **meer dan** 400 000 inwoners **behouden**. »

Hier slaat de filter op een **berekend** resultaat: hij komt **na** de groepering.

```python
(gemeenten
 .groupby("arrondissement", as_index=False)
 .agg(bevolking=("totaal", "sum"))
 .query("bevolking > 400000")
 .sort_values("bevolking", ascending=False))
```

::: note
**Werkwijze**: schrijf eerst de vraag in het Nederlands, onderstreep de sleutelwoorden, en schrijf dan één stap per regel. Voer uit na elke toegevoegde stap: je ziet het resultaat ontstaan, en een fout is meteen gelokaliseerd.
:::
