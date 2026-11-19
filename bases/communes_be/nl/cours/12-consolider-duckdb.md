---
titre: Consolideren en herlezen met DuckDB
resume: Een volledige consolidatieverwerking, indicatoren per provincie, een Parquet-bestand herlezen in SQL met DuckDB; DuckDB en pandas in de browser.
partie: Halve dag 5 · Aggregaties, koppeling en consolidatie
---

# Demonstratie: consolideren en de koppeling controleren

1. Vertrekken van de opgeschoonde tabel
2. Aggregeren op het niveau **gemeente**, met behoud van het aantal rijen
3. De nomenclatuur koppelen (geldige gemeenten, dan provincies) met `indicator=True`
4. Het aantal rijen en de totalen controleren

```python
import pandas as pd

schoon = pd.read_parquet("gegevens/bevolking_opgeschoond.parquet",
                         dtype_backend="pyarrow")
ref = pd.read_csv("referenties/nuts_lau_2027.txt", sep="|",
                  encoding="cp1252", dtype_backend="pyarrow")

geldig = (ref[(ref["CD_LVL"] == 4) & (ref["DT_VLDT_STOP"] == "31/12/9999")]
          .rename(columns={"CD_MUNTY_REFNIS": "nis_code", "CD_LVL_SUP": "nuts3"})
          [["nis_code", "nuts3"]])
provincies = (ref[(ref["CD_LVL"] == 2) & (ref["DT_VLDT_STOP"] == "31/12/9999")]
              .rename(columns={"CD_LAU": "nuts2", "TX_DESCR_NL": "provincie"})
              [["nuts2", "provincie"]])

# vrouwen: de bevolking als de rij die van de vrouwen is, anders 0
schoon["vrouwen"] = schoon["bevolking"].where(schoon["geslacht"] == "V", 0)
per_gemeente = (schoon
    .groupby(["nis_code", "gemeente"], as_index=False)
    .agg(bevolking=("bevolking", "sum"),
         vrouwen=("vrouwen", "sum"),
         rijen=("bevolking", "size")))
met_ref = per_gemeente.merge(geldig, on="nis_code", how="left",
                             indicator=True, validate="many_to_one")
# ontbrekende NUTS-sleutel (onbekende gemeente): vervangen door "-" vóór het koppelen
met_ref["nuts2"] = met_ref["nuts3"].fillna("-").str.slice(0, 4)
met_ref = met_ref.merge(provincies, on="nuts2", how="left", validate="many_to_one")
met_ref.loc[met_ref["nuts2"] == "BE10", "provincie"] = "Brussels Hoofdstedelijk Gewest"

print(len(per_gemeente), "->", len(met_ref), "rijen")
print(met_ref["_merge"].value_counts().to_dict())
print("Totaal:", per_gemeente["bevolking"].sum(), met_ref["bevolking"].sum())
```

**Te controleren:** hetzelfde aantal rijen en hetzelfde totaal voor en na de koppeling; de niet-gekoppelde gemeente (« 99999 ») is geïdentificeerd, niet verloren.

`reeks.where(voorwaarde, ander)` houdt de waarde waar de voorwaarde waar is en zet `ander` elders: met de kolom `vrouwen` kun je de vrouwen in dezelfde `agg()` optellen.

# Indicatoren per provincie berekenen

Per provincie: aantal gemeenten, bevolking, aandeel vrouwen. We houden alleen de gekoppelde gemeenten.

**Volledigheid**: elke gemeente moet 2 rijen hebben (mannen en vrouwen). De kolom `volledig` wijst de provincies aan die door het opschonen geraakt zijn.

```python
gekoppeld = met_ref[met_ref["_merge"] == "both"]
indic = (gekoppeld.groupby("provincie")
         .agg(gemeenten=("nis_code", "size"),
              rijen=("rijen", "sum"),
              bevolking=("bevolking", "sum"),
              vrouwen=("vrouwen", "sum")))
indic["aandeel_vrouwen"] = (indic["vrouwen"] / indic["bevolking"] * 100).round(1)
indic["volledig"] = indic["rijen"] == 2 * indic["gemeenten"]
indic.sort_values("bevolking", ascending=False)
```

**Interpretatie:** Luxemburg is niet volledig: 294 594 inwoners in de opgeschoonde tabel, tegenover 296 370 in het bestand van Statbel. Dat zijn de twee afgewezen rijen (Daverdisse, Martelange): een bevolking berekend op een opgeschoonde tabel is die van de **behouden observaties**.

# Een Parquet-bestand herlezen met DuckDB

Een gemaakt bestand moet **herbruikbaar** zijn: je herleest het met een ander hulpmiddel. **DuckDB** bevraagt een Parquet-bestand in SQL, zonder het eerst in pandas te laden. De query moet de totalen van de vorige kaart terugvinden; « 99999 », niet gekoppeld, blijft zichtbaar, met een ontbrekende provincie.

```python
import duckdb

met_ref.drop(columns="_merge").to_parquet("uitvoer/gemeenten_geconsolideerd.parquet",
                                          index=False)

duckdb.sql("""
    SELECT provincie,
           COUNT(*)                       AS gemeenten,
           CAST(SUM(bevolking) AS BIGINT) AS bevolking
    FROM 'uitvoer/gemeenten_geconsolideerd.parquet'
    GROUP BY provincie
    ORDER BY bevolking DESC
""").df()
```

DuckDB leest ook rechtstreeks een pandas-**DataFrame**, aangeduid met zijn naam in de query:

```python
duckdb.sql("SELECT COUNT(*) AS rijen, SUM(bevolking) AS bevolking FROM schoon").df()
```

# Is DuckDB hier sneller?

Op je eigen pc is DuckDB meestal **veel sneller** dan pandas op grote tabellen: het gebruikt alle kernen van de processor, leest alleen de nuttige kolommen van een Parquet-bestand en kan bestanden verwerken die groter zijn dan het geheugen. Je opleider zal het je tonen.

**In het atelier is dat niet zo**: Python draait in je browser, op **één enkele kern** en zonder schijf. We meten op een tabel van 2 miljoen rijen, gemaakt met NumPy:

```python
import time
import numpy as np

rng = np.random.default_rng(1)
n = 2_000_000
groot = pd.DataFrame({"gemeente": rng.integers(0, 565, n),
                      "geslacht": rng.choice(["M", "V"], n),
                      "waarde": rng.random(n)})

begin = time.time()
a = groot.groupby(["gemeente", "geslacht"])["waarde"].sum()
t_pandas = time.time() - begin

begin = time.time()
b = duckdb.sql("SELECT gemeente, geslacht, SUM(waarde) FROM groot GROUP BY ALL").df()
t_duckdb = time.time() - begin

print(f"pandas: {t_pandas:.2f} s   DuckDB: {t_duckdb:.2f} s")
```

**Interpretatie:** hier is DuckDB niet sneller, vaak zelfs trager. Een prestatiemeting hangt af van de omgeving: onthoud van DuckDB wat het overal brengt (SQL, het rechtstreeks lezen van Parquet-bestanden), en meet zijn snelheid daar waar je zult werken.

# Een gegevensverwerking in zeven stappen

- **1 · Importeren**: `read_csv`, `read_excel`, `read_parquet`: scheidingsteken, codering, kopregels, types.
- **2 · Controleren**: `shape`, `info()`, `describe()`, validatieregels, `assert`.
- **3 · Opschonen**: dubbels, ontbrekende waarden, types, harmonisatie van de categorieën.
- **4 · Automatiseren**: lussen over de bestanden, herbruikbare functies.
- **5 · Koppelen**: `concat()` om te stapelen, `merge()` om te koppelen, `indicator` en `validate` om te controleren.
- **6 · Aggregeren**: `groupby()` en `agg()` per gebied, geslacht, categorie.
- **7 · Wegschrijven**: `to_csv`, `to_parquet`; het gemaakte bestand herlezen om het te controleren.

**Om verder te gaan**: neem een eenvoudige SAS-verwerking van je dienst en herschrijf ze stap voor stap in Python. Tijd voor het **syntheseatelier**, in het tabblad Oefeningen.
