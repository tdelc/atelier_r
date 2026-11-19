---
titre: Variabelen aanmaken
resume: Een berekende kolom toevoegen, een ja/nee-variabele, grootteklassen, een hercodering; een aandeel binnen de eigen groep berekenen.
partie: De basis
---

# Een berekende kolom

Het aandeel vrouwen in elke gemeente, in %:

```python
gemeenten["aandeel_vrouwen"] = gemeenten["vrouwen"] / gemeenten["totaal"] * 100

gemeenten[["gemeente", "vrouwen", "totaal", "aandeel_vrouwen"]].head()
```

::: usage
`tabel["nieuw"] = berekening` maakt een kolom aan (of vervangt een kolom die al zo heet). De berekening gebeurt **voor alle rijen tegelijk**: er hoeft geen lus geschreven te worden.
:::

::: sas
`DATA gemeenten; SET gemeenten; aandeel_vrouwen = vrouwen / totaal * 100; RUN;`
:::

# Een kolom afronden

```python
gemeenten["aandeel_vrouwen"] = gemeenten["aandeel_vrouwen"].round(1)
gemeenten[["gemeente", "aandeel_vrouwen"]].head(3)
```

# Een ja/nee-variabele

Een vergelijking geeft voor elke rij `True` (waar) of `False` (onwaar).

```python
gemeenten["meer_vrouwen"] = gemeenten["vrouwen"] > gemeenten["mannen"]
gemeenten["meer_vrouwen"].value_counts()
```

::: usage
`True`/`False`-variabelen zijn makkelijk te tellen: `.sum()` telt de `True`, `.mean()` geeft hun aandeel.
:::

```python
gemeenten["meer_vrouwen"].mean().round(3)
```

**Interpretatie:** 79,6 % van de gemeenten (450 op 565) telt meer vrouwen dan mannen.

# Twee waarden: np.where()

`np.where(voorwaarde, waarde_indien_waar, waarde_indien_onwaar)` maakt een kolom met twee waarden.

```python
gemeenten["stedelijk"] = np.where(gemeenten["totaal"] >= 50000, "50 000 en meer", "minder dan 50 000")
gemeenten["stedelijk"].value_counts()
```

::: usage
`np` is **NumPy**, de rekenbibliotheek waarop pandas steunt. Je importeert ze met `import numpy as np` (in het atelier al gedaan).
:::

::: sas
`if totaal >= 50000 then stedelijk = '50 000 en meer'; else stedelijk = 'minder dan 50 000';`
:::

# Klassen: pd.cut()

`pd.cut()` deelt een numerieke kolom op in klassen, met **grenzen** en **labels**.

```python
gemeenten["grootte"] = pd.cut(
    gemeenten["totaal"],
    bins=[0, 5000, 10000, 20000, 50000, 600000],
    labels=["minder dan 5 000", "5 000 tot 10 000", "10 000 tot 20 000",
            "20 000 tot 50 000", "50 000 en meer"])

gemeenten["grootte"].value_counts().sort_index()
```

::: piege
Standaard **bevat elke klasse haar rechtergrens**: een gemeente met precies 5 000 inwoners valt in « minder dan 5 000 ». De laatste grens moet boven het maximum liggen (565 615 voor Antwerpen), anders krijgt de grootste gemeente geen klasse.
:::

::: sas
Een formaat `PROC FORMAT; VALUE grootte 0-5000 = 'minder dan 5 000' ...;`, of een reeks `if ... then ... else`.
:::

# Waarden hercoderen: map()

`.map()` vervangt elke waarde volgens een **woordenboek** `{oud: nieuw}`.

```python
taal = {"Vlaanderen": "Nederlandstalig", "Wallonië": "Franstalig",
        "Brussel": "tweetalig"}
gemeenten["taal"] = gemeenten["gewest"].map(taal)
gemeenten[["gemeente", "gewest", "taal"]].head(3)
```

::: piege
Een waarde die niet in het woordenboek staat, wordt **ontbrekend** (`NaN`). Het is trouwens een vereenvoudiging: de Duitstalige gemeenten (arrondissement Verviers) worden hier als « Franstalig » ingedeeld. Controleer altijd met `value_counts(dropna=False)`.
:::

# Een aandeel in de eigen groep: transform()

Welk deel van de bevolking van zijn provincie vertegenwoordigt elke gemeente?

`groupby(...).transform("sum")` berekent de som van elke provincie **en zet ze op elke rij** van die provincie: je kunt dan rij per rij delen.

```python
gemeenten["bev_provincie"] = gemeenten.groupby("provincie")["totaal"].transform("sum")
gemeenten["aandeel_provincie"] = (gemeenten["totaal"] / gemeenten["bev_provincie"] * 100).round(1)

gemeenten.nlargest(5, "aandeel_provincie")[["gemeente", "provincie", "aandeel_provincie"]]
```

**Interpretatie:** Antwerpen weegt 29,3 % van de bevolking van zijn provincie, Namen 22,8 %. De gemeente Brussel vertegenwoordigt slechts 15,8 % van het Brussels Hoofdstedelijk Gewest.

# Rang binnen de groep: rank()

De plaats van elke gemeente in haar provincie, van de grootste (1) tot de kleinste:

```python
gemeenten["rang_provincie"] = gemeenten.groupby("provincie")["totaal"].rank(ascending=False)
gemeenten.query("rang_provincie == 1")[["provincie", "gemeente", "totaal"]]
```

# Kolommen aanmaken in een keten: assign()

In een keten van stappen maakt `.assign()` een kolom aan zonder de oorspronkelijke tabel te wijzigen.

```python
(gemeenten
 .assign(aandeel_mannen=(gemeenten["mannen"] / gemeenten["totaal"] * 100).round(1))
 .nsmallest(3, "aandeel_mannen")
 [["gemeente", "aandeel_mannen"]])
```

::: note
`assign()` is handig voor een eenmalige analyse: de kolom bestaat alleen in het resultaat. Met `tabel["nieuw"] = ...` wordt de kolom **aan de tabel toegevoegd** en blijft ze beschikbaar voor de rest.
:::
