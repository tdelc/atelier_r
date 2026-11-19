---
titre: Je tabellen bevragen in SQL met DuckDB
resume: In SQL schrijven, zoals met PROC SQL, op pandas-tabellen of rechtstreeks op bestanden; van SQL naar pandas gaan en omgekeerd.
partie: Je eigen bestanden
---

# Waarom DuckDB?

Veel SAS-gebruikers kennen **PROC SQL**. Met **DuckDB** schrijf je dezelfde query's in Python, op een pandas-tabel of rechtstreeks op een bestand (CSV, Parquet), en krijg je het resultaat terug als pandas-tabel.

```python
import duckdb

duckdb.sql("SELECT gewest, COUNT(*) AS gemeenten, SUM(totaal) AS bevolking FROM gemeenten GROUP BY gewest").df()
```

::: usage
- `duckdb.sql("query")` voert de query uit; in de `FROM` volstaat de naam van een pandas-tabel (`gemeenten`);
- `.df()` zet het resultaat om in een pandas-tabel, om verder te werken met de werkwoorden van de cursus.
- `SUM()` geeft hier een decimaal getal terug (`1255834.0`): DuckDB berekent de som op een heel groot geheel getal, dat pandas omzet. Om een geheel getal te houden: `CAST(SUM(totaal) AS BIGINT)`.
:::

::: sas
```
PROC SQL;
  SELECT gewest, COUNT(*) AS gemeenten, SUM(totaal) AS bevolking
  FROM gemeenten GROUP BY gewest;
QUIT;
```
:::

# Een query over meerdere regels

Tussen drie aanhalingstekens schrijf je een query over meerdere regels, zoals in PROC SQL.

```python
duckdb.sql("""
    SELECT gemeente, provincie, totaal
    FROM gemeenten
    WHERE gewest = 'Wallonië' AND totaal > 50000
    ORDER BY totaal DESC
""").df()
```

# Dezelfde vragen, in pandas en in SQL

| Vraag | pandas | SQL |
|---|---|---|
| rijen behouden | `.query("totaal > 50000")` | `WHERE totaal > 50000` |
| kolommen behouden | `[["gemeente", "totaal"]]` | `SELECT gemeente, totaal` |
| per groep | `.groupby("provincie").agg(...)` | `GROUP BY provincie` |
| een berekend resultaat filteren | `.query(...)` na `agg` | `HAVING` |
| sorteren | `.sort_values("totaal", ascending=False)` | `ORDER BY totaal DESC` |
| koppelen | `.merge(t2, on="nis_code", how="left")` | `LEFT JOIN t2 USING (nis_code)` |

# GROUP BY en HAVING

De arrondissementen met meer dan 500 000 inwoners:

```python
duckdb.sql("""
    SELECT arrondissement, SUM(totaal) AS bevolking
    FROM gemeenten
    GROUP BY arrondissement
    HAVING SUM(totaal) > 500000
    ORDER BY bevolking DESC
""").df()
```

# Een join

De bevolking per geslacht en per gewest, door `bevolking_geslacht` aan `gemeenten` te koppelen via de NIS-code:

```python
duckdb.sql("""
    SELECT g.gewest, b.geslacht, SUM(b.bevolking) AS bevolking
    FROM bevolking_geslacht AS b
    LEFT JOIN gemeenten AS g USING (nis_code)
    GROUP BY g.gewest, b.geslacht
    ORDER BY g.gewest, b.geslacht
""").df()
```

# Een bestand rechtstreeks bevragen

DuckDB leest een bestand **zonder het eerst in te laden**: zijn naam, tussen enkele aanhalingstekens, vervangt de tabel in de `FROM`. Handig voor een groot bestand waarvan je maar een deel wilt.

```python
duckdb.sql("""
    SELECT provincie, COUNT(*) AS gemeenten
    FROM 'gegevens/gemeenten_2026.parquet'
    GROUP BY provincie
    ORDER BY gemeenten DESC
""").df()
```

Een CSV lees je op dezelfde manier, met zijn instellingen:

```python
duckdb.sql("""
    SELECT *
    FROM read_csv('gegevens/gemeenten_2026.csv', delim = ';')
    LIMIT 3
""").df()
```

# Eerst SQL, dan pandas

Je kunt mengen: de query bereidt de tabel voor, pandas gaat verder (grafiek, export…).

```python
per_provincie = duckdb.sql("""
    SELECT provincie, SUM(vrouwen) * 100.0 / SUM(totaal) AS aandeel_vrouwen
    FROM gemeenten GROUP BY provincie
""").df()

per_provincie.sort_values("aandeel_vrouwen", ascending=False).round(2).head(3)
```

# Is DuckDB sneller?

Op je eigen pc, met grote tabellen (miljoenen rijen), is DuckDB meestal **veel sneller** dan pandas: het gebruikt alle kernen van de processor en leest alleen de nuttige kolommen van een Parquet-bestand. Je opleider zal het je tonen.

**In het atelier is dat niet zo**: Python draait in je browser, op één enkele kern. We meten op 2 miljoen willekeurig gegenereerde rijen:

```python
import time

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

**Interpretatie:** hier is DuckDB niet sneller, vaak trager. Een snelheidsmeting hangt af van de machine: onthoud van DuckDB wat het overal brengt (SQL, het rechtstreeks lezen van bestanden), en meet zijn snelheid daar waar je zult werken.
