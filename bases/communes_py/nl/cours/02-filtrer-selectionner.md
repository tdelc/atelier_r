---
titre: Filteren en selecteren
resume: Bepaalde rijen behouden met query(), bepaalde kolommen met [[...]]; voorwaarden combineren.
partie: De basis
---

# query(): de rijen behouden die aan een voorwaarde voldoen

Welke gemeenten tellen meer dan 100 000 inwoners?

```python
gemeenten.query("totaal > 100000")
```

::: usage
`.query("voorwaarde")` behoudt de rijen waarvoor de voorwaarde **waar** is. De voorwaarde staat tussen aanhalingstekens, met de namen van de kolommen.
:::

::: sas
`WHERE totaal > 100000;`
:::

# De vergelijkingsoperatoren

| Operator | Betekenis | Voorbeeld |
|---|---|---|
| `==` | gelijk aan | `provincie == 'Namen'` |
| `!=` | verschillend van | `gewest != 'Vlaanderen'` |
| `>`, `>=` | groter dan (of gelijk) | `totaal >= 50000` |
| `<`, `<=` | kleiner dan (of gelijk) | `totaal < 1000` |

```python
gemeenten.query("totaal < 2000")
```

**Interpretatie:** 4 gemeenten tellen minder dan 2 000 inwoners. De kleinste van België, Herstappe (Limburg), telt er 78.

::: piege
**Gelijk aan schrijf je `==`** (twee tekens). Eén `=` dient om een resultaat onder een naam te bewaren. In SAS dient `=` voor allebei: dat is in het begin de meest gemaakte fout.
:::

# Tekst staat tussen aanhalingstekens

In een voorwaarde op een tekstkolom staat de waarde tussen **enkele** aanhalingstekens, omdat de hele voorwaarde al tussen dubbele aanhalingstekens staat.

```python
gemeenten.query("provincie == 'Luxemburg'")
```

::: piege
Hoofdletters en accenten tellen: `'luik'` of `'Luxembourg'` vinden niets. Bekijk bij twijfel de exacte waarden met `gemeenten["provincie"].unique()`.
:::

```python
gemeenten["provincie"].unique()
```

# Meerdere voorwaarden: and, or

- `and`: **beide** voorwaarden zijn waar;
- `or`: **minstens één** van de voorwaarden is waar.

De Waalse gemeenten met meer dan 50 000 inwoners:

```python
gemeenten.query("gewest == 'Wallonië' and totaal > 50000")
```

De gemeenten van Namen **of** Luxemburg met minder dan 3 000 inwoners: de haakjes bepalen de volgorde.

```python
gemeenten.query("(provincie == 'Namen' or provincie == 'Luxemburg') and totaal < 3000")
```

::: sas
`WHERE (provincie = 'Namen' or provincie = 'Luxemburg') and totaal < 3000;`
:::

# in: een lijst van waarden

Voor meerdere waarden van eenzelfde kolom zijn `in` en een lijst tussen vierkante haken korter dan een reeks `or`.

```python
gemeenten.query("gemeente in ['Luik', 'Namen', 'Charleroi', 'Bergen']")
```

::: sas
`WHERE gemeente in ('Luik', 'Namen', 'Charleroi', 'Bergen');`
:::

# [[...]]: bepaalde kolommen behouden

Een **lijst** van kolomnamen, tussen dubbele vierkante haken, behoudt die kolommen, in die volgorde.

```python
gemeenten[["gemeente", "provincie", "totaal"]]
```

::: usage
- De buitenste haken betekenen « neem in de tabel… »; de binnenste vormen de **lijst** van kolommen.
- Met enkele haken, `gemeenten["totaal"]`, krijg je één kolom (zie « Aan de slag »).
:::

::: sas
`KEEP gemeente provincie totaal;`
:::

# drop(): kolommen weglaten

```python
gemeenten.drop(columns=["mannen", "vrouwen"]).head(3)
```

::: sas
`DROP mannen vrouwen;`
:::

# rename(): kolommen hernoemen

```python
gemeenten.rename(columns={"totaal": "bevolking"}).head(3)
```

::: usage
`{"oud": "nieuw"}` is een **woordenboek** (*dictionary*): elke oude naam wordt gekoppeld aan zijn nieuwe naam. Je kunt er meerdere hernoemen: `{"totaal": "bevolking", "gewest": "regio"}`.
:::

::: sas
`RENAME totaal = bevolking;`
:::

# Filteren en dan selecteren

De stappen volgen elkaar op: de gemeenten van de provincie Luik met meer dan 30 000 inwoners, enkel met hun naam en hun bevolking.

```python
(gemeenten
 .query("provincie == 'Luik' and totaal > 30000")
 [["gemeente", "totaal"]])
```

# Een andere, heel gangbare schrijfwijze van de filter

In code die je online vindt, zie je vaak een andere schrijfwijze: een voorwaarde op een kolom, tussen vierkante haken.

```python
gemeenten[gemeenten["totaal"] > 100000][["gemeente", "totaal"]]
```

Meerdere voorwaarden schrijf je dan met `&` (en), `|` (of), en **haakjes rond elke voorwaarde**:

```python
gemeenten[(gemeenten["gewest"] == "Wallonië") & (gemeenten["totaal"] > 50000)]
```

::: note
Beide schrijfwijzen geven hetzelfde resultaat. In deze cursus geven we de voorkeur aan `query()`, dat leesbaarder is en dichter bij de `WHERE` van SAS staat. Maar je moet de andere kunnen lezen.
:::

# Voorwaarden op tekst

`.str.startswith()` test het begin van een tekst, `.str.contains()` zoekt een stukje tekst. Ze werken in `query()` als een voorwaarde.

De gemeenten van het arrondissement Luik: hun NIS-code begint met `62`.

```python
gemeenten.query("nis_code.str.startswith('62')").shape
```

De gemeenten waarvan de naam « Sint » bevat:

```python
gemeenten.query("gemeente.str.contains('Sint')")[["gemeente", "provincie"]]
```

::: sas
`WHERE nis_code =: '62';` en `WHERE index(gemeente, 'Sint') > 0;`
:::
