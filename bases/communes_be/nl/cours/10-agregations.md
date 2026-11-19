---
titre: Groeperingen en aggregaties
resume: groupby() en agg(); waarden of rijen tellen; de volledigheid van een opgeschoonde tabel controleren.
partie: Halve dag 5 · Aggregaties, koppeling en consolidatie
---

# Halve dag 5: aggregaties, koppeling en consolidatie

**Na deze sessie kun je**

- observaties groeperen en aggregaten berekenen met `groupby()` en `agg()`;
- tabellen stapelen met `concat()` en ze koppelen met `merge()`;
- de kwaliteit van een koppeling controleren: sleutels, niet-gekoppelde rijen, totalen;
- een geconsolideerd bestand in Parquet-formaat maken, herbruikbaar in DuckDB.

**Opsplitsen, berekenen, samenvoegen**

1. **Opsplitsen**: de rijen worden in groepen verdeeld volgens een of meer kolommen (`gewest`, `geslacht`…).
2. **Berekenen**: een functie wordt op elke groep toegepast: som, telling, gemiddelde.
3. **Samenvoegen**: de resultaten vormen een nieuwe tabel, één rij per groep.

`schoon.groupby("gewest")["bevolking"].sum()` lees je als: « voor elk gewest, de som van de bevolking ».

# Startcel van de sessie

`bevolking_opgeschoond.parquet` is de oplossing van atelier 4 (reservebestand); `ruw` is de oorspronkelijke tabel, afwijkingen inbegrepen.

```python
import pandas as pd
from outils_cursus import harmoniseer_code

schoon = pd.read_parquet("gegevens/bevolking_opgeschoond.parquet",
                         dtype_backend="pyarrow")
ruw = pd.read_parquet("gegevens/bevolking_ruw.parquet",
                      dtype_backend="pyarrow")
print(schoon.shape, ruw.shape)
```

# groupby() met één aggregatie

`groupby(kolommen)` bepaalt de groepen; daarna kies je de kolom om te aggregeren en de functie. Met meerdere groeperingskolommen krijg je één rij per combinatie. `reset_index()` zet het resultaat om in een gewone tabel.

```python
per_gewest = schoon.groupby("gewest")["bevolking"].sum()
print(per_gewest)
```

```python
per_gewest_geslacht = (schoon
                       .groupby(["gewest", "geslacht"])
                       ["bevolking"].sum()
                       .reset_index())
per_gewest_geslacht
```

**Interpretatie:** Wallonië telt 3 711 794 inwoners in de opgeschoonde tabel, en niet 3 713 450 zoals in het bestand van Statbel: de twee afgewezen rijen (Daverdisse, Martelange) ontbreken, en de gemeente « 99999 » voegt 120 inwoners toe die niet bestaan.

# Waarden tellen of rijen tellen

`sum()` telt op, `mean()` neemt het gemiddelde, `count()` telt de **ingevulde** waarden, `size()` telt de **rijen**.

Op de ruwe tabel brengt het vergelijken van `count()` en `size()` de ontbrekende waarden van een groep aan het licht.

```python
g = ruw.groupby("gewest")["bevolking"]
print(g.count())
print(g.size())
```

**Interpretatie:** 522 ingevulde waarden voor 523 rijen in Wallonië.

# Meerdere indicatoren met agg()

`agg()` berekent meerdere indicatoren in één keer: `nieuwe_kolom=("bronkolom", "functie")`.

```python
samenvatting = (schoon
    .groupby(["gewest", "geslacht"])
    .agg(bevolking=("bevolking", "sum"),
         rijen=("bevolking", "size"),
         gemiddelde=("bevolking", "mean"))
    .round(1)
    .reset_index())
samenvatting
```

**Interpretatie:** een Brusselse gemeente telt gemiddeld bijna 33 000 inwoners van elk geslacht, een Waalse gemeente ongeveer 7 000: de grootte van de gemeenten verschilt sterk van gewest tot gewest.

# Opgeschoond betekent niet volledig

Elke gemeente telt **2 rijen**: één voor de mannen, één voor de vrouwen. Het aantal rijen per gemeente tellen toont wat het opschonen verwijderd heeft.

Een som berekend op `schoon` is de **bevolking van de behouden observaties**, geen totale bevolking.

Beperkingen: deze telling veronderstelt unieke sleutels (dubbels verwijderd) en ziet geen gemeente die volledig ontbreekt; die spoor je op door te vergelijken met de referentie.

```python
rijen = schoon.groupby(["nis_code", "gemeente"]).size()
onvolledig = rijen[rijen != 2]
onvolledig
```

**Interpretatie:** Martelange en Daverdisse hebben nog maar één rij (de afgewezen rijen van atelier 4); « 99999 » heeft er van bij het begin maar één.

::: sas
Dezelfde controle in SAS: `PROC FREQ` met `TABLES nis_code / LIST;`, en dan de aantallen verschillend van 2 opsporen.
:::
