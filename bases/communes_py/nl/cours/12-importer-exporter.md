---
titre: Je bestanden inlezen en wegschrijven
resume: Een CSV-, TXT-, Excel- en Parquet-bestand inlezen met het juiste scheidingsteken, de juiste codering, kopregels en types; de inlezing controleren; een resultaat wegschrijven.
partie: Je eigen bestanden
---

# De bestanden in je map

Tot nu toe stond de tabel `gemeenten` klaar. In je werk zul je **je bestanden moeten inlezen**: het equivalent van `PROC IMPORT` of van een `DATA`-stap met `INFILE`.

De bestanden van Statbel staan in de map `gegevens/` van het atelier, zoals ze gepubliceerd worden:

```python
import os
os.listdir("gegevens")
```

::: note
In je scripts vertrekt het pad vanuit de werkmap. Schrijf onder Windows de paden met `/` (`"G:/Statistieken/gegevens/bestand.csv"`) of zet er een `r` voor (`r"G:\Statistieken\gegevens\bestand.csv"`).
:::

# Een eenvoudig CSV-bestand: pd.read_csv()

```python
gem = pd.read_csv("gegevens/gemeenten_2026.csv", sep=";")
gem.shape
```

::: usage
`sep=` geeft het scheidingsteken tussen de kolommen: `";"` (het meest gebruikelijke in België, omdat de komma voor decimalen dient), `","`, `"\t"` (tab) of `"|"`.
:::

::: sas
`PROC IMPORT DATAFILE="gemeenten_2026.csv" OUT=gem DBMS=DLM REPLACE; DELIMITER=';'; RUN;`
:::

# Altijd controleren: shape en info()

```python
gem.info()
```

::: piege
De NIS-code wordt als een **getal** (`int64`) gelezen: pandas leidt het af uit de waarden. Voor een code is dat fout: `04000` (Brussels Hoofdstedelijk Gewest) zou `4000` worden. Je legt het teksttype op met `dtype=`:
:::

```python
gem = pd.read_csv("gegevens/gemeenten_2026.csv", sep=";", dtype={"nis_code": str})
gem["nis_code"].head(3)
```

# Het oorspronkelijke bestand van Statbel

Het bestand « Bevolking per gemeente » van Statbel is een tekstbestand met tabs. We lezen het zonder voorzorgen in:

```python
ruw = pd.read_csv("gegevens/bevolking_2026.txt", sep="\t")
print(ruw.shape)
ruw.head(5)
```

Drie problemen:

1. twee lege regels onder de kopregel;
2. de NIS-code is als getal gelezen: `01000` is `1000.0` geworden (decimaal, door de lege regels);
3. de bevolkingscijfers zijn **tekst**, door de punten van de duizendtallen (`11.867.634`).

# De juiste instellingen

```python
ruw = pd.read_csv("gegevens/bevolking_2026.txt", sep="\t",
                  skiprows=[1, 2],               # de lege regels
                  thousands=".",                 # het punt van de duizendtallen
                  dtype={"NIS code": str})       # de code als tekst
ruw.columns = ["nis_code", "plaats", "mannen", "vrouwen", "totaal"]   # handige namen
print(ruw.dtypes)
ruw.head(4)
```

| Instelling | Rol | Symptoom als ze verkeerd staat |
|---|---|---|
| `sep` | scheidingsteken tussen kolommen | maar één kolom ingelezen |
| `encoding` | codering van de tekens | fout `UnicodeDecodeError`, of onleesbare accenten |
| `skiprows`, `header` | over te slaan regels, kopregel | lege regels of titels als gegevens gelezen |
| `thousands`, `decimal` | scheidingsteken duizendtallen, decimalen | getallen als tekst gelezen |
| `dtype` | type opgelegd aan een kolom | voorloopnullen verloren |

::: note
`ruw.columns = [...]` vervangt alle kolomnamen in één keer, in volgorde. Dat is eenvoudiger dan `rename()` wanneer de oorspronkelijke namen onhandig zijn (hier bevat `"NIS code"` een spatie).
:::

# De codering: de NUTS-nomenclatuur

De nomenclatuur van de gebieden van Statbel is gecodeerd in **Windows-1252** (`cp1252`), de historische codering van Windows. pandas gaat standaard uit van UTF-8 en stopt bij het eerste teken met een accent (de « ü » van *Brüssel*). **Bewuste fout**:

```python erreur
nuts = pd.read_csv("referenties/nuts_lau_2027.txt", sep="|")
```

```python
nuts = pd.read_csv("referenties/nuts_lau_2027.txt", sep="|", encoding="cp1252")
print(nuts.shape)
nuts[["CD_MUNTY_REFNIS", "TX_DESCR_NL", "TX_DESCR_FR", "CD_LVL"]].head(4)
```

::: piege
`encoding="latin-1"` leest dit bestand ook zonder fout… maar in de Franse kolom wordt de apostrof van « Province d’Anvers » een onzichtbaar teken. Bestanden die onder Windows aangemaakt zijn, staan bijna altijd in `cp1252`; recente bestanden in `utf-8`.
:::

::: sas
`FILENAME f "nuts_lau_2027.txt" ENCODING="wlatin1";`
:::

# Een Excel-bestand: pd.read_excel()

Twee titelregels gaan aan de kopregel vooraf: `header=2` duidt de derde regel aan (we tellen vanaf 0).

```python
prov = pd.read_excel("gegevens/bevolking_provincies_2026.xlsx", header=2,
                     dtype={"nis_code": str})
prov.head(3)
```

::: usage
`sheet_name="Blad2"` kiest een ander werkblad; `sheet_name=None` leest ze allemaal.
:::

# Een Parquet-bestand: pd.read_parquet()

Het **Parquet**-formaat bewaart de types samen met de gegevens: niets te preciseren, alles klopt. Het is het aanbevolen formaat voor tabellen die je tussen programma's uitwisselt (Python, R, DuckDB…).

```python
t = pd.read_parquet("gegevens/gemeenten_2026.parquet")
t.dtypes
```

# Een resultaat wegschrijven

We berekenen een tabel en bewaren ze dan in de map `uitvoer/`.

```python
per_provincie = (gemeenten
                 .groupby("provincie", as_index=False)
                 .agg(gemeenten=("gemeente", "count"), bevolking=("totaal", "sum")))

per_provincie.to_csv("uitvoer/provincies.csv", sep=";", index=False, encoding="utf-8")
per_provincie.to_excel("uitvoer/provincies.xlsx", index=False)
per_provincie.to_parquet("uitvoer/provincies.parquet", index=False)
os.listdir("uitvoer")
```

::: usage
`index=False` voorkomt dat er een extra kolom met rijnummers wordt weggeschreven. Voor een bestand dat bedoeld is voor een Nederlandstalige of Franstalige Excel geven `sep=";"` en `decimal=","` meteen leesbare getallen.
:::

::: sas
`PROC EXPORT DATA=per_provincie OUTFILE="provincies.csv" DBMS=DLM REPLACE; DELIMITER=';'; RUN;`
:::

# Opnieuw inlezen wat je geschreven hebt

De reflex, in Python zoals in SAS: het weggeschreven bestand opnieuw inlezen om het te controleren.

```python
pd.read_csv("uitvoer/provincies.csv", sep=";").shape
```
