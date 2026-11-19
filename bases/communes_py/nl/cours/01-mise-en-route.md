---
titre: Aan de slag
resume: De tabel van de gemeenten, haar rijen en kolommen; tonen, de structuur bekijken, een resultaat bewaren, stappen aaneenschakelen.
partie: De basis
---

# De tabel van de Belgische gemeenten: gemeenten

Elke rij van de tabel `gemeenten` is **een Belgische gemeente** op 1 januari 2026 (bron: Statbel). Er zijn er 565.

| Kolom | Inhoud |
|---|---|
| `nis_code` | NIS-code van de gemeente (tekst: `"62063"` voor Luik) |
| `gemeente` | naam van de gemeente |
| `arrondissement`, `provincie`, `gewest` | waar de gemeente ligt |
| `mannen`, `vrouwen`, `totaal` | bevolking op 1 januari 2026 |

De knop **Woordenboek**, bovenaan het scherm, beschrijft elke kolom.

Deze cursus is geschreven voor wie **SAS** gewend is: we vertrekken meteen vanuit een tabel, zoals een SAS-tabel, en leren er vragen aan te stellen. De taal Python zelf (lijsten, lussen, functies) komt op het einde, wanneer ze nodig wordt.

::: sas
Een pandas-tabel (een **DataFrame**) speelt de rol van een SAS-tabel: rijen (observaties) en kolommen (variabelen), elk met een type. Maar ze leeft **in het geheugen**, zonder `WORK`-bibliotheek: je laadt ze, je werkt, je bewaart wat je wilt houden.
:::

# pandas en de tabel laden

In je eigen scripts (Jupyter, VS Code…) staan deze regels **bovenaan**:

```python norun
import pandas as pd

gemeenten = pd.read_csv("gemeenten_2026.csv", sep=";", dtype={"nis_code": str})
```

::: usage
- `import pandas as pd` laadt **pandas**, de bibliotheek voor gegevenstabellen. Volgens afspraak noemen we ze `pd`.
- `pd.read_csv()` leest een CSV-bestand. `sep=";"` geeft het scheidingsteken aan; `dtype={"nis_code": str}` houdt de NIS-code als tekst. De les « Inlezen en wegschrijven » bespreekt alle instellingen.
- Het `=`-teken bewaart het resultaat onder een naam: `gemeenten`.
:::

::: note
**In dit atelier is alles al gedaan**: pandas is geladen en de tabel `gemeenten` staat klaar. Deze regels worden hier niet uitgevoerd, maar je schrijft ze in je eigen scripts.
:::

# De tabel tonen

Als je de naam van een tabel typt, wordt ze getoond. Bij een grote tabel toont pandas de eerste en de laatste rijen, en onderaan de grootte.

```python
gemeenten
```

**Interpretatie:** 565 rijen (gemeenten) en 8 kolommen (variabelen). Links, in het grijs, staat de **index**: het nummer van elke rij, vanaf 0.

# head(): de eerste rijen

```python
gemeenten.head()
```

::: usage
`.head()` toont de eerste 5 rijen. Je kunt het aantal kiezen: `gemeenten.head(10)`. `.tail()` toont de laatste.

Het puntje lees je als « **van** »: `gemeenten.head()` is « het begin van `gemeenten` ».
:::

::: sas
`PROC PRINT DATA=gemeenten (OBS=5);`
:::

# shape: de grootte van de tabel

```python
gemeenten.shape
```

Het resultaat lees je als `(rijen, kolommen)`. Een grootteorde helpt om een mislukte inlezing op te sporen: 565 gemeenten in België sinds de fusies van 2025, dat klopt.

::: note
`shape` schrijf je **zonder haakjes**: het is een kenmerk van de tabel, geen actie. Acties (`head()`, `info()`…) hebben haakjes.
:::

# info(): overzicht van alle kolommen

```python
gemeenten.info()
```

::: usage
`.info()` geeft voor **elke** kolom de naam, het aantal ingevulde waarden (*Non-Null Count*) en het type. Het is het eerste commando om te gebruiken op een onbekende tabel.
:::

::: piege
Kijk naar de types: `nis_code`, `gemeente`, `provincie` zijn tekst (`str`), `mannen`, `vrouwen`, `totaal` gehele getallen (`int64`). Dat bepaalt of je in voorwaarden aanhalingstekens schrijft of niet: `nis_code == "62063"`, maar `totaal > 50000`.
:::

::: sas
`PROC CONTENTS DATA=gemeenten;`
:::

# Eén kolom: gemeenten["totaal"]

```python
gemeenten["totaal"]
```

::: usage
`tabel["kolom"]` duidt **één kolom** aan. Je gebruikt het om ze te bekijken of er een berekening op te doen: `gemeenten["totaal"].sum()` geeft de bevolking van België.
:::

```python
gemeenten["totaal"].sum()
```

# =: een resultaat bewaren

Zonder `=` wordt het resultaat getoond en verdwijnt het dan. Met `=` geef je het een naam om het opnieuw te gebruiken, zoals een nieuwe SAS-tabel.

```python
wallonie = gemeenten.query("gewest == 'Wallonië'")

wallonie.shape
```

::: piege
Als je `gemeenten = gemeenten.query(...)` schrijft, **overschrijf** je de tabel: je verliest alle andere rijen. Kies voor een deeltabel een **nieuwe naam**. (In het atelier haal je de oorspronkelijke tabel terug met « Nieuwe omgeving ».)
:::

::: sas
`DATA wallonie; SET gemeenten; WHERE gewest = 'Wallonië'; RUN;`
:::

# Stappen aaneenschakelen

Een stap neemt de tabel, de volgende neemt het resultaat, enzovoort. We schrijven **één stap per regel** en zetten het geheel tussen **haakjes**: de keten lees je van boven naar onder, met « **en dan** ».

```python
(gemeenten                             # ik neem de gemeenten,
 .query("gewest == 'Wallonië'")         # en dan houd ik Wallonië over,
 .sort_values("totaal", ascending=False)  # en dan sorteer ik op dalende bevolking,
 .head(3))                             # en dan houd ik de eerste 3 over
```

::: note
Dankzij de haakjes rond de keten kun je tussen de stappen naar een nieuwe regel gaan. Zonder haakjes zou Python denken dat de instructie stopt aan het einde van de eerste regel.
:::

::: sas
Het is het equivalent van een reeks DATA- en PROC-stappen, zonder de tussentabellen: elke regel krijgt het resultaat van de vorige.
:::
