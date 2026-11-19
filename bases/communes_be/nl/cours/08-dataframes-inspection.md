---
titre: DataFrames en inspectie
resume: Series en DataFrame; een Parquet-bestand inlezen; een tabel inspecteren met shape, head, info, describe en unique.
partie: Halve dag 4 · Inspectie, selectie en opschoning
---

# Halve dag 4: inspectie, selectie en opschoning

**Na deze sessie kun je**

- gegevens in een DataFrame laden en de structuur ervan inspecteren;
- selecteren met `loc` en `iloc`, filteren op voorwaarden, sorteren;
- dubbels opsporen en ontbrekende waarden behandelen;
- types omzetten, een kolom harmoniseren en een berekende variabele aanmaken.

**Met pandas werk je op hele kolommen.** Een **DataFrame** is een tabel: rijen, benoemde kolommen, één type per kolom. Een bewerking op een kolom geldt voor al haar rijen, zonder dat je een lus moet schrijven. De functies van halve dag 3 blijven nuttig: je past ze toe op een kolom met `.map()`.

Python: een lus (illustratie, niet uitgevoerd)

```python norun
for rij in rijen:
    rij["bevolking_duizend"] = rij["bevolking"] / 1000
```

pandas: één instructie voor de hele kolom (illustratie, niet uitgevoerd)

```python norun
df["bevolking_duizend"] = df["bevolking"] / 1000
```

::: sas
Een berekende kolom lijkt op een toekenning in de DATA-stap (`bevolking_duizend = bevolking / 1000;`). Verschil: pandas behandelt de hele kolom in één keer, en niet rij na rij.
:::

# Series en DataFrame

Een **Series** is een kolom: waarden en een **index**, dat wil zeggen de labels van de rijen.

Een **DataFrame** is een geheel van Series die dezelfde index delen. Een kolom van een DataFrame selecteren geeft een Series terug.

```python
import pandas as pd

s = pd.Series([198102, 115457, 206900],
              index=["Luik", "Namen", "Charleroi"])
print(s["Namen"], s.sum())

df = pd.DataFrame({"nis_code": ["62063", "92094"],
                   "bevolking": [198102, 115457]})
print(type(df["bevolking"]))
df
```

# Gegevens in Parquet-formaat inlezen

`pd.read_csv()` en `pd.read_excel()` heb je in halve dag 1 gezien. `pd.read_parquet()` leest een **Parquet**-bestand: een formaat in kolommen dat de types bewaart.

`bevolking_ruw.parquet` brengt de drie gewestelijke bestanden samen, afwijkingen inbegrepen, met een kolom `gewest`.

| | CSV | Parquet |
|---|---|---|
| Opslag | tekst, rij per rij | binair, kolom per kolom |
| Types | bij elke inlezing op te geven | in het bestand bewaard |
| Leesbaar in een editor | ja | nee |
| Gebruikte motor | pandas | PyArrow |

```python
ruw = pd.read_parquet("gegevens/bevolking_ruw.parquet",
                      dtype_backend="pyarrow")
print(type(ruw))
print(ruw.shape)
```

# Een eerste blik: shape, head() en tail()

`shape` geeft (rijen, kolommen). `head(n)` toont de n eerste rijen (standaard 5), `tail(n)` de n laatste. Een lijst van namen tussen vierkante haken selecteert kolommen.

```python
print(ruw.shape)
ruw.head()
```

```python
kolommen = ["nis_code", "gemeente", "gewest", "bevolking"]
ruw[kolommen].tail(3)
```

**Interpretatie:** de laatste rij is de gemeente « 99999 », die niet bestaat: je komt ze terug tegen bij de koppeling van halve dag 5.

::: sas
`PROC PRINT DATA=ruw (OBS=5);` komt overeen met `head()`.
:::

# info(): de structuur en de types

`info()` geeft de types en het aantal **niet-ontbrekende** waarden van elke kolom. SAS-equivalent: `PROC CONTENTS`.

```python
ruw.info()
```

**Interpretatie:** `bevolking` heeft 1 131 waarden op 1 132: er ontbreekt er één. Het bestand bewaart ze als decimaal getal (`double[pyarrow]`); we zetten ze om naar een geheel getal na het opschonen. Tekst verschijnt als `large_string[pyarrow]`, een variant van `string[pyarrow]` voor lange kolommen: je behandelt ze op dezelfde manier.

# describe() en unique(): het abnormale opsporen

`describe()` berekent aantal, gemiddelde, standaardafwijking, minimum, kwartielen en maximum. Het minimum en het maximum lezen is een snelle controle. SAS-equivalent: `PROC MEANS`.

`unique()` toont de categorieën van een kolom: een slecht geschreven categorie springt in het oog.

```python
ruw["bevolking"].describe().round(1)
```

```python
print(ruw["geslacht"].unique().tolist())
print(ruw["gewest"].unique().tolist())
```

**Interpretatie:** een minimum van -1 059, onmogelijk voor een bevolking, en een geslacht `"v"` in kleine letters.
