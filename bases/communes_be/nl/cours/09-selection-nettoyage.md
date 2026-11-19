---
titre: Selectie, filtering en opschoning
resume: loc en iloc; filteren en sorteren; dubbels; ontbrekende waarden; een kolom harmoniseren, types omzetten, een variabele aanmaken.
partie: Halve dag 4 · Inspectie, selectie en opschoning
---

# loc: selecteren op labels

We vertrekken opnieuw van de ruwe tabel:

```python
import pandas as pd
ruw = pd.read_parquet("gegevens/bevolking_ruw.parquet",
                      dtype_backend="pyarrow")
ruw.shape
```

`df.loc[rijen, kolommen]` selecteert op **labels**: index van de rijen, namen van de kolommen.

Let op: met `loc` is de eindgrens **inbegrepen** (`0:2` geeft 3 rijen), in tegenstelling tot slicing in Python.

```python
ruw.loc[0:2, ["nis_code", "gemeente", "geslacht", "bevolking"]]
```

```python
print(ruw.loc[5, "gemeente"])
print(ruw.loc[5, "bevolking"])
```

# iloc: selecteren op posities

`df.iloc[rijen, kolommen]` selecteert op **posities**, zoals een Python-lijst: het einde is **niet inbegrepen**. `-1` duidt de laatste rij aan.

Gebruik liever `loc` en de kolomnamen: de code blijft juist als de volgorde van de kolommen verandert.

```python
ruw.iloc[:3, :2]
```

```python
ruw.iloc[-1]
```

# Rijen filteren op voorwaarden

Een voorwaarde op een kolom geeft een Series van booleans terug; ze houdt de ware rijen.

Om te combineren: `&` (en), `|` (of), `~` (niet), met **ronde haken** rond elke voorwaarde. `.isin([...])` test of een waarde in een lijst zit; `.str.startswith()` past de tekstmethode toe op de hele kolom.

In SAS: `WHERE gewest = 'Wallonië' and geslacht = 'V';`

```python
waalse_vrouwen = ruw[(ruw["gewest"] == "Wallonië") & (ruw["geslacht"] == "V")]
print(waalse_vrouwen.shape)

grote_steden = ruw[ruw["gemeente"].isin(["Luik", "Namen", "Charleroi"])]
print(grote_steden.shape)

provincie_luik = ruw.loc[ruw["nis_code"].str.startswith("6"),
                         ["nis_code", "gemeente", "bevolking"]]
provincie_luik.head(3)
```

**Interpretatie:** 260 rijen met vrouwen in Wallonië, en niet 261: die van Namen staat als `"v"` en ontsnapt aan de filter `== "V"`. De drie grote steden geven wel 6 rijen (twee per stad): de filter slaat op de naam, die de afwijkingen niet geraakt hebben. Een filter is maar zo goed als de gefilterde kolom schoon is.

# De observaties sorteren: sort_values()

`sort_values(kolommen, ascending=...)` sorteert op een of meer kolommen. Een lijst in `ascending` kiest de richting voor elke kolom.

Het sorteren geeft een nieuwe tabel terug: `ruw` wordt niet gewijzigd.

```python
gesorteerd = ruw.sort_values(["gewest", "bevolking"],
                             ascending=[True, False])
gesorteerd.head(4)
```

::: sas
In SAS gaat `PROC SORT` vaak vooraf aan een `MERGE` of een `BY`. Met pandas dient sorteren alleen voor de weergave of de export: koppelingen en groeperingen hebben het niet nodig.
:::

# Dubbels opsporen en verwijderen

`duplicated()` markeert de rijen die identiek zijn aan een vorige rij; `.sum()` telt ze. `subset=` beperkt de vergelijking tot een sleutel. `drop_duplicates()` verwijdert de dubbels en houdt het eerste exemplaar. SAS-equivalent: `PROC SORT NODUPKEY`, hier zonder voorafgaand sorteren.

```python
print(ruw.duplicated().sum())
sleutel = ["nis_code", "geslacht"]
print(ruw.duplicated(subset=sleutel).sum())
ruw[ruw.duplicated(keep=False)]
```

```python
zonder_dubbels = ruw.drop_duplicates()
print(len(ruw), len(zonder_dubbels))
```

**Interpretatie:** de rij van Gent (vrouwen) komt twee keer voor, identiek: dat is de dubbel van het Vlaamse bestand, onzichtbaar rij per rij in halve dag 2.

# Ontbrekende waarden opsporen: isna()

Met de PyArrow-types verschijnt een ontbrekende waarde als `<NA>` (afhankelijk van het type kan pandas ook `NaN` tonen, of `NaT` voor een datum). `isna()` spoort ze op; `.sum()` telt ze.

De berekeningen negeren ontbrekende waarden standaard, zoals de SAS-procedures `.` negeren: controleer het aantal waarden dat echt gebruikt wordt.

```python
print(ruw.isna().sum())
```

```python
ruw[ruw["bevolking"].isna()]
```

# Ontbrekende waarden behandelen: fillna() en dropna()

`fillna(waarde)` vervangt de ontbrekende waarden; `dropna(subset=...)` verwijdert de betrokken rijen.

Vervangen door 0 verandert de som niet, maar wel het gemiddelde en de aantallen: dat is een **inhoudelijke beslissing**, die je moet documenteren. In het atelier is de regel gegeven: de rij wordt verwijderd en bijgehouden in een bestand van afgewezen rijen.

**Opgeschoond betekent niet volledig**: na uitsluiting slaat een som op de behouden observaties, niet op de hele bevolking.

```python
met_nul = ruw["bevolking"].fillna(0)
print(round(ruw["bevolking"].mean(), 1),
      round(met_nul.mean(), 1))

volledig = ruw.dropna(subset=["bevolking"])
positief = volledig[volledig["bevolking"] >= 0]
print(len(ruw), len(volledig), len(positief))
```

# Een kolom harmoniseren en de types omzetten

`.str` past de tekstmethodes toe op een hele kolom. `.map(functie)` past een functie toe op elke waarde: `harmoniseer_code()`, geschreven in halve dag 3, wordt meegeleverd in `outils_cursus.py`.

`astype("int64[pyarrow]")` kiest een PyArrow-geheel getal (dat ontbrekende waarden aanvaardt). `pd.to_datetime()` zet een tekst om in een datum.

```python
from outils_cursus import harmoniseer_code

df = ruw.drop_duplicates().copy()
df["geslacht"] = df["geslacht"].str.strip().str.upper()
df["nis_code"] = df["nis_code"].map(harmoniseer_code)
df["bevolking"] = df["bevolking"].astype("int64[pyarrow]")
df["referentiedatum"] = pd.to_datetime(df["jaar"].astype(str) + "-01-01")

print(df["geslacht"].unique().tolist())
print(df.loc[df["gemeente"] == "Luik", "nis_code"].tolist())
print(df[["bevolking", "referentiedatum"]].dtypes)
```

`.copy()` maakt een onafhankelijke tabel: `df` wijzigen raakt `ruw` niet.

# Een berekende variabele aanmaken

Een nieuwe kolom maak je door toekenning: `df["nieuw"] = ...`.

`.map(woordenboek)` hercodeert categorieën: elke waarde wordt vervangen door de gekoppelde waarde. Hier geeft het eerste cijfer van de NIS-code de provincie.

`.str.slice(0, 1)` houdt het eerste teken van elke waarde, zoals `code[:1]` op een tekst.

::: note
De korte schrijfwijze `df["nis_code"].str[:1]` bestaat ook, maar met de versie van pandas van het atelier (3.0) en de PyArrow-types geeft ze een fout `AttributeError`: gebruik liever `.str.slice(begin, einde)`, dat hetzelfde doet.
:::

```python
df["bevolking_duizend"] = (df["bevolking"] / 1000).round(2)

provincies = {"1": "Antwerpen", "3": "West-Vlaanderen", "4": "Oost-Vlaanderen",
              "5": "Henegouwen", "6": "Luik", "7": "Limburg",
              "8": "Luxemburg", "9": "Namen",
              "2": "Brussel of Brabant"}
df["provincie"] = df["nis_code"].str.slice(0, 1).map(provincies)

df[["gemeente", "bevolking", "bevolking_duizend", "provincie"]].head(3)
```

::: piege
Het cijfer `2` groepeert Brussel en de **twee** Brabanten (Vlaams-Brabant, codes 23 en 24; Waals-Brabant, code 25): een woordenboek op het eerste cijfer volstaat niet. De goede methode is een **koppeling** met de nomenclatuur, in halve dag 5.
:::

# Demonstratie: een bestand opschonen, stap voor stap

1. De structuur controleren: `info()`, `describe()`
2. Dubbels en ontbrekende waarden opsporen
3. Codes en categorieën harmoniseren
4. De filters toepassen
5. Controleren: elke verwijderde rij moet verklaard kunnen worden

De overzichtstabel dient als **auditspoor**: je herleest ze en vergelijkt ze van de ene uitvoering tot de andere.

```python
stappen = [("inlezen", len(ruw))]
df = ruw.drop_duplicates().copy()
stappen.append(("zonder dubbel", len(df)))
df["nis_code"] = df["nis_code"].map(harmoniseer_code)
df["geslacht"] = df["geslacht"].str.strip().str.upper()
df = df.dropna(subset=["bevolking"])
stappen.append(("bevolking ingevuld", len(df)))
df = df[df["bevolking"] >= 0]
stappen.append(("bevolking positief", len(df)))
pd.DataFrame(stappen, columns=["stap", "rijen"])
```

# Om te onthouden

- **Inspecteren**: `shape`, `head()`, `info()`, `describe()`, `unique()`: structuur, types en abnormale waarden.
- **Selecteren**: `loc` op labels, einde inbegrepen; `iloc` op posities, einde niet inbegrepen.
- **Filteren en sorteren**: voorwaarden tussen ronde haken met `&`, `|`, `~`; `isin()`; `sort_values()`.
- **Dubbels**: `duplicated()` om te tellen, `drop_duplicates()` om te verwijderen; `subset=` voor een sleutel.
- **Ontbrekende waarden**: `isna()` om op te sporen; `dropna()` of `fillna()` volgens een gedocumenteerde regel.
- **Transformeren**: `.str`, `.map()`, `astype()`, `pd.to_datetime()`; nieuwe kolom door toekenning.
