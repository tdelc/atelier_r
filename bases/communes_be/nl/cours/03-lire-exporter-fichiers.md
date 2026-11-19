---
titre: Bestanden inlezen en wegschrijven
resume: CSV-, TXT- en Excel-bestanden inlezen met pandas met het juiste scheidingsteken, de juiste codering, kopregels en types; een tabel wegschrijven.
partie: Halve dag 1 · Basis en bestanden
---

# De bestanden van de cursus

Je werkmap bevat drie mappen. De bestanden zijn die van **Statbel**, zoals ze gepubliceerd worden, met hun eigenaardigheden.

| Bestand | Inhoud | Formaat |
|---|---|---|
| `gegevens/bevolking_gemeenten_2026.csv` | bevolking van de 565 gemeenten | CSV, scheidingsteken `;` |
| `gegevens/bevolking_2026.txt` | het oorspronkelijke bestand van Statbel: gemeenten, arrondissementen, provincies, gewesten | tekst met tabs, punten voor duizendtallen |
| `gegevens/bevolking_provincies_2026.xlsx` | bevolking van de provincies | Excel, twee titelregels |
| `referenties/nuts_lau_2027.txt` | nomenclatuur van de gebieden (NUTS-codes 2027) | scheidingsteken `\|`, codering Windows-1252 |
| `uitvoer/` | je resultaten | leeg bij de start |

De CSV en de Excel zijn uit het oorspronkelijke bestand gehaald, om andere formaten te oefenen: de cijfers zijn identiek. De andere bestanden van `gegevens/` (één per gewest, en twee `.parquet`-bestanden) en `outils_cursus.py` dienen vanaf halve dag 2.

`os.listdir()` toont de inhoud van een map:

```python
import os
print(os.listdir("gegevens"))
print(os.listdir("referenties"))
```

::: note
In het atelier staan deze bestanden in je browser. Wat je in `uitvoer/` schrijft, blijft daar tot je de pagina sluit: er wordt niets naar de server gestuurd.
:::

# Een CSV-bestand inlezen met pandas

*Recept om zo te hergebruiken.*

**pandas** is de standaardbibliotheek voor gegevenstabellen. Ze wordt uitgelegd in halve dag 4. Onthoud voorlopig het recept: `pd.read_csv()` leest een bestand en geeft een tabel terug, een **DataFrame**.

`.shape` geeft het aantal rijen en kolommen; `.head()` toont de eerste rijen.

`dtype_backend="pyarrow"` gebruikt de PyArrow-types, aanbevolen in je omgeving.

```python
import pandas as pd

bev = pd.read_csv("gegevens/bevolking_gemeenten_2026.csv",
                  sep=";",
                  dtype_backend="pyarrow")
print(bev.shape)     # (rijen, kolommen)
bev.head(3)
```

**Interpretatie:** 565 rijen (één per gemeente) en 5 kolommen.

# Vijf instellingen die de meeste fouten voorkomen

| Instelling | Rol | Gangbare waarden | Symptoom als ze verkeerd staat |
|---|---|---|---|
| `sep` | scheidingsteken tussen kolommen | `";"`, `"\t"`, `"\|"` | maar één kolom ingelezen |
| `encoding` | codering van de tekens | `"utf-8"`, `"cp1252"`, `"latin-1"` | fout `UnicodeDecodeError` of onleesbare accenten |
| `header`, `skiprows` | regel met kopregels, over te slaan regels | `0` (standaard), `2` | titelregels of lege regels als gegevens gelezen |
| `decimal`, `thousands` | scheidingsteken decimalen, duizendtallen | `","`, `"."` | getallen als tekst gelezen |
| `dtype` | type opgelegd aan een kolom | `{"nis_code": str}` | voorloopnullen verloren (`04000` wordt `4000`) |

Het eerste symptoom, met een verkeerd scheidingsteken:

```python
fout = pd.read_csv("gegevens/bevolking_gemeenten_2026.csv", sep=",",
                   dtype_backend="pyarrow")
print(fout.shape)
fout.head(2)
```

**Interpretatie:** één enkele kolom, waarvan de naam alle andere bevat, gescheiden door `;`. `.shape` controleren meteen na het inlezen volstaat om het te zien.

::: sas
`PROC IMPORT` regelt het scheidingsteken (`DELIMITER=`) en de kopregels (`GETNAMES=`, `DATAROW=`); de codering geef je op in de `FILENAME`-instructie (`ENCODING=`). In Python loopt alles via de instellingen van de functie.
:::

# Een coderingsfout: ze lezen

De NUTS-nomenclatuur van Statbel is gecodeerd in **Windows-1252** (`cp1252`), de historische codering van Windows, erg dicht bij latin-1. pandas gaat standaard uit van **UTF-8** en stopt bij het eerste teken met een accent (hier de « ü » van *Brüssel*).

**Bewuste fout**: lees de laatste regel van de melding, die noemt het probleem.

```python erreur
ref = pd.read_csv("referenties/nuts_lau_2027.txt", sep="|",
                  dtype_backend="pyarrow")
```

# … en ze dan verbeteren

Oplossing: `encoding="cp1252"` opgeven. Het scheidingsteken van dit bestand is de verticale streep `|`.

```python
ref = pd.read_csv("referenties/nuts_lau_2027.txt", sep="|",
                  encoding="cp1252", dtype_backend="pyarrow")
print(ref.shape)
ref.head(4)
```

**Interpretatie:** 919 rijen. Elk gebied heeft een NUTS-code (`CD_LAU`), een NIS-code (`CD_MUNTY_REFNIS`), een naam in vier talen, geldigheidsdatums en een niveau (`CD_LVL`: 1 = gewest, 2 = provincie, 3 = arrondissement, 4 = gemeente). De verdwenen gemeenten (fusies van 2019 en 2025) staan er nog in, met hun einddatum.

::: piege
**Latin-1 of Windows-1252?** Met `encoding="latin-1"` lukt het inlezen ook… maar « Province d’Anvers » wordt « Province d\x92Anvers »: de typografische apostrof ’ (byte 0x92) bestaat niet in latin-1 en wordt een onzichtbaar teken. Geen foutmelding: alleen een controle van de labels brengt het aan het licht.
:::

Vergelijk de twee inlezingen op de rij van de provincie Antwerpen (Franse naam):

```python
for enc in ["latin-1", "cp1252"]:
    proef = pd.read_csv("referenties/nuts_lau_2027.txt", sep="|",
                        encoding=enc, dtype_backend="pyarrow")
    print(enc, repr(proef.loc[4, "TX_DESCR_FR"]))
```

::: note
`CD_MUNTY_REFNIS` wordt als tekst gelezen (`"04000"` houdt zijn nul) omdat de kolom ook `-` bevat: pandas kan er geen getallen van maken.
:::

# Een tekstbestand met tabs: het oorspronkelijke bestand van Statbel

Een TXT-bestand met tabs lees je met `pd.read_csv()` en `sep="\t"` (de tab). We lezen het zonder verdere voorzorgen in, en bekijken dan de types met `.dtypes`:

```python
ruw = pd.read_csv("gegevens/bevolking_2026.txt", sep="\t",
                  dtype_backend="pyarrow")
print(ruw.shape)
print(ruw.dtypes)
ruw.head(5)
```

Vier problemen springen in het oog:

1. twee lege regels (`<NA>`) onder de kopregels;
2. de NIS-code is als getal gelezen: `01000` is `1000` geworden;
3. de bevolkingscijfers zijn **tekst** (`string`), door de punten van de duizendtallen;
4. de naam van de eerste kolom bevat een spatie: `"NIS code"`.

# De inlezing verbeteren met de juiste instellingen

- `skiprows=[1, 2]` slaat de regels 1 en 2 van het bestand over (regel 0 is die van de kopregels);
- `thousands="."` geeft aan dat het punt de duizendtallen scheidt;
- `dtype={"NIS code": str}` houdt de code als tekst, met de exacte naam van de kolom.

```python
ruw = pd.read_csv("gegevens/bevolking_2026.txt", sep="\t",
                  skiprows=[1, 2], thousands=".",
                  dtype={"NIS code": str},
                  dtype_backend="pyarrow")
print(ruw.shape)
print(ruw.dtypes)
ruw.head(4)
```

**Interpretatie:** 622 rijen, de bevolkingscijfers zijn gehele getallen en `01000` heeft zijn nul gehouden. Maar het bestand mengt de niveaus: België, 3 gewesten, 10 provincies, 43 arrondissementen en 565 gemeenten. In halve dag 4 leer je er maar één te behouden.

::: piege
De naam `"NIS code"` bevat een spatie: je moet hem exact overnemen, en `ruw["NIS-code"]` of `ruw["NIS Code"]` zou een fout `KeyError` geven. Toon `ruw.columns` om de exacte namen te zien.
:::

# Een Excel-bestand inlezen

`pd.read_excel()` leest een Excel-werkblad. Twee titelregels gaan aan de kopregels vooraf: `header=2` duidt de derde regel aan, want we tellen vanaf 0.

Ook hier beschermt `dtype={"nis_code": str}` de nul van de code van Brussel (`04000`).

```python
prov = pd.read_excel("gegevens/bevolking_provincies_2026.xlsx",
                     header=2, dtype={"nis_code": str},
                     dtype_backend="pyarrow")
print(prov.shape)
prov.head(3)
```

**Interpretatie:** 11 rijen: de 10 provincies en het Brussels Hoofdstedelijk Gewest, dat tot geen enkele provincie behoort.

# Een tabel wegschrijven: CSV, TXT met tabs en Excel

Een DataFrame schrijf je weg met `.to_csv()` of `.to_excel()`. Een TXT-bestand met tabs schrijf je ook met `.to_csv()`: alleen het scheidingsteken verandert, `sep="\t"`.

`index=False` voorkomt dat er een extra kolom met rijnummers wordt weggeschreven.

Schrijf altijd in `uitvoer/`: de bronbestanden wijzig je nooit.

```python
uittreksel = bev.head(10)            # 10 eerste rijen
uittreksel.to_csv("uitvoer/uittreksel_2026.csv", sep=";",
                  index=False, encoding="utf-8")
uittreksel.to_csv("uitvoer/uittreksel_2026.txt", sep="\t",
                  index=False, encoding="utf-8")     # TXT met tabs
uittreksel.to_excel("uitvoer/uittreksel_2026.xlsx", index=False)

herlezen = pd.read_csv("uitvoer/uittreksel_2026.txt", sep="\t",
                       dtype_backend="pyarrow")
print(herlezen.shape)                 # controle
print(os.listdir("uitvoer"))
```

::: sas
`PROC EXPORT` speelt dezelfde rol. De reflex om in beide talen te houden: het weggeschreven bestand opnieuw inlezen om het te controleren.
:::

# Om te onthouden

- **Variabelen en types**: een naam verwijst naar een waarde: `int`, `float`, `str`, `bool`, `date`. Controleer met `type()`.
- **Omzettingen**: `int()`, `float()`, `str()`. Een waarde uit een bestand is vaak tekst; let op het punt van de duizendtallen.
- **Operatoren**: `=` kent toe, `==` vergelijkt. `and`, `or`, `not` en `in` combineren voorwaarden.
- **Structuren**: lijst `[ ]`, tuple `( )`, verzameling `{ }`, woordenboek `{sleutel: waarde}`.
- **Posities**: we tellen vanaf 0. In `[begin:einde]` is het einde niet inbegrepen. `-1` duidt het laatste element aan.
- **Bestanden**: stel `sep`, `encoding`, `header` of `skiprows`, `thousands` of `decimal`, `dtype` in; controleer daarna altijd `.shape` en `.dtypes`.

Tijd voor de **oefeningen**: de « Aan jou » van de sessie en **atelier 1**.
