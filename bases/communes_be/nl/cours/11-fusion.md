---
titre: Meerdere bronnen koppelen
resume: Stapelen met concat(), koppelen met merge(); het type koppeling kiezen; een koppeling controleren met indicator en validate.
partie: Halve dag 5 · Aggregaties, koppeling en consolidatie
---

# Tabellen stapelen: concat()

`pd.concat([t1, t2, t3])` stapelt tabellen die **dezelfde kolommen** hebben. `ignore_index=True` nummert de rijen opnieuw van 0 tot n-1.

Onmiddellijke controle: het aantal gestapelde rijen is de som van de rijen van elke tabel.

```python
import pandas as pd

bxl = pd.read_csv("gegevens/bevolking_brussel_2026.csv", sep=";",
                  dtype={"nis_code": str}, dtype_backend="pyarrow")
vla = pd.read_excel("gegevens/bevolking_vlaanderen_2026.xlsx", header=2,
                    dtype={"nis_code": str}, dtype_backend="pyarrow")
wal = pd.read_csv("gegevens/bevolking_wallonie_2026.txt", sep="\t",
                  dtype={"nis_code": str}, dtype_backend="pyarrow")

gestapeld = pd.concat([bxl, vla, wal], ignore_index=True)
print(len(bxl) + len(vla) + len(wal), len(gestapeld))
print(gestapeld["geslacht"].unique().tolist())
```

::: sas
`SET t1 t2 t3;` in een DATA-stap stapelt de tabellen op dezelfde manier.
:::

# De referentie: één rij per gemeente?

We willen aan elke bevolkingsrij haar arrondissement, provincie en gewest toevoegen, op basis van de NUTS-nomenclatuur. De bevolkingstabel is `schoon`, de opgeschoonde tabel van atelier 4.

```python
schoon = pd.read_parquet("gegevens/bevolking_opgeschoond.parquet",
                         dtype_backend="pyarrow")
ref = pd.read_csv("referenties/nuts_lau_2027.txt", sep="|",
                  encoding="cp1252", dtype_backend="pyarrow")

alle_gemeenten = ref[ref["CD_LVL"] == 4]
print(len(alle_gemeenten), alle_gemeenten["CD_MUNTY_REFNIS"].nunique())
alle_gemeenten[alle_gemeenten["CD_MUNTY_REFNIS"] == "11002"]
```

**Interpretatie:** 840 gemeenterijen, maar slechts 620 verschillende codes: eenzelfde gemeente kan meerdere rijen hebben. Antwerpen heeft er twee: zijn provincie kreeg in 2027 een andere NUTS-code (van `BE21` naar `BE26`), de rij met de oude code is afgesloten op 31/12/2026. Andere gemeenten zijn verdwenen bij de fusies van 2019 en 2025. **De sleutel is niet uniek**: dat is de belangrijkste valkuil van een koppeling.

# Twee tabellen koppelen: merge()

`merge()` koppelt de rijen van twee tabellen die een **sleutel** delen. Hier heet de sleutel `nis_code` aan de ene kant en `CD_MUNTY_REFNIS` aan de andere: we hernoemen de kolom van de referentie.

We koppelen eerst **alle** gemeenterijen van de referentie, zonder nadenken:

```python
sleutels = alle_gemeenten.rename(columns={"CD_MUNTY_REFNIS": "nis_code",
                                          "CD_LVL_SUP": "nuts3"})
sleutels = sleutels[["nis_code", "nuts3", "DT_VLDT_STOP"]]
gekoppeld = schoon.merge(sleutels, on="nis_code", how="left")
print(len(schoon), "->", len(gekoppeld))
```

**Interpretatie:** de tabel gaat van 1 129 naar 1 563 rijen, **zonder enige fout**: elke rij van Antwerpen (en van de andere gemeenten met meerdere rijen) is verdubbeld, één keer per rij van de referentie. De totalen die je daarna berekent, zouden fout zijn.

# Jezelf beschermen: validate

`validate="many_to_one"` controleert dat de sleutel uniek is in de rechtertabel (de referentie); anders een fout `MergeError`. **Bewuste fout**:

```python erreur
gekoppeld = schoon.merge(sleutels, on="nis_code", how="left",
                         validate="many_to_one")
```

De oplossing: alleen de **geldige** gemeenten houden, waarvan de einddatum van geldigheid `31/12/9999` is.

```python
geldig = sleutels[sleutels["DT_VLDT_STOP"] == "31/12/9999"]
geldig = geldig.drop(columns="DT_VLDT_STOP")
print(len(geldig), geldig["nis_code"].nunique())

verrijkt = schoon.merge(geldig, on="nis_code", how="left",
                        validate="many_to_one")
print(len(schoon), "->", len(verrijkt))
verrijkt[["nis_code", "gemeente", "geslacht", "bevolking", "nuts3"]].head(3)
```

# Het type koppeling kiezen

`how=` kiest de behouden rijen.

| how | Behouden rijen | Wanneer gebruiken |
|---|---|---|
| `inner` | sleutels die in beide tabellen voorkomen | alleen analyseren wat gekoppeld is |
| `left` | alle rijen van de linkertabel | een tabel verrijken zonder rijen te verliezen |
| `right` | alle rijen van de rechtertabel | vertrekken van de referentie, gemeenten zonder gegevens inbegrepen |

```python
for how in ["inner", "left", "right"]:
    gekoppeld = schoon.merge(geldig, on="nis_code", how=how)
    print(how, len(gekoppeld))
```

**Interpretatie:** de rij van de gemeente « 99999 », die niet in de referentie staat, verdwijnt met `inner` en `right`. Met `left` blijft ze behouden, met een ontbrekende `nuts3`. Met `right` blijven Daverdisse en Martelange aanwezig (elk één rij).

# Een koppeling controleren: indicator

`indicator=True` voegt een kolom `_merge` toe: `both`, `left_only` of `right_only`. `value_counts()` telt elke categorie.

Een `left`-koppeling op een unieke sleutel verandert noch het aantal rijen, noch het totaal.

```python
controle = schoon.merge(geldig, on="nis_code", how="left",
                        indicator=True, validate="many_to_one")
print(controle["_merge"].value_counts())
niet_gekoppeld = controle[controle["_merge"] == "left_only"]
print(niet_gekoppeld["nis_code"].unique().tolist())
totaal_voor = schoon["bevolking"].sum()
totaal_na = controle["bevolking"].sum()
print(len(schoon) == len(controle), totaal_voor == totaal_na)
```

# MERGE … BY in SAS, merge() in pandas

| | DATA-stap: MERGE … BY | pandas: merge() |
|---|---|---|
| Voorafgaand sorteren | verplicht: `PROC SORT` op de sleutel | overbodig |
| Behouden rijen | zonder filter: alle; `IF a;` of `IF a and b;` om te filteren | `how=`: `outer`, `left`, `inner` (standaard) |
| Herkomst van de rijen | `IN=`-variabelen | kolom `_merge` met `indicator=True` |
| Dubbele sleutel aan beide kanten | rij per rij koppelen binnen de groep, met een notitie in het log | alle combinaties (cartesisch product) |
| Controle van de sleutel | zelf te programmeren | `validate="many_to_one"` |

Het geval « dubbele sleutel » is de belangrijkste valkuil: een pandas-koppeling kan rijen vermenigvuldigen zonder fout, zoals we met Antwerpen gezien hebben. Vandaar de systematische controle van het aantal rijen en de optie `validate`.

# De hiërarchie opklimmen: de provincie

De NUTS 3-code van het arrondissement bevat die van de provincie: `BE332` (arrondissement Luik) begint met `BE33` (provincie Luik). We knippen dus de code, en koppelen dan de lijst van geldige provincies.

We klimmen de hiërarchie alleen op voor de **gekoppelde** rijen: de gemeente « 99999 » heeft geen NUTS-code, en een lege koppelingssleutel heeft geen zin.

```python
provincies = ref[(ref["CD_LVL"] == 2) & (ref["DT_VLDT_STOP"] == "31/12/9999")]
provincies = provincies.rename(columns={"CD_LAU": "nuts2", "TX_DESCR_NL": "provincie"})
provincies = provincies[["nuts2", "provincie"]]
print(provincies)

gekoppeld = controle[controle["_merge"] == "both"].drop(columns="_merge")
gekoppeld["nuts2"] = gekoppeld["nuts3"].str.slice(0, 4)
met_prov = gekoppeld.merge(provincies, on="nuts2", how="left",
                           validate="many_to_one")
met_prov["provincie"].value_counts(dropna=False)
```

::: piege
**Een gebrek in het oorspronkelijke bestand.** Het Brussels Hoofdstedelijk Gewest behoort tot geen enkele provincie: zijn niveau 2 (`BE10`) heeft als naam `NA`… wat pandas leest als een **ontbrekende waarde**. We behandelen dat expliciet, door alleen de rijen `BE10` te viseren in plaats van met een algemene `fillna()`, die ook elke andere ontbrekende provincie zou verbergen.
:::

```python
met_prov.loc[met_prov["nuts2"] == "BE10", "provincie"] = "Brussels Hoofdstedelijk Gewest"
met_prov["provincie"].value_counts(dropna=False)
```

::: note
**Een koppelingssleutel mag niet leeg zijn.** In het atelier (Python in de browser) geeft koppelen op een sleutel met ontbrekende waarden zelfs een fout `ValueError: putmask: output array is read-only`. Filter de gekoppelde rijen, of vervang de ontbrekende sleutel door een expliciete waarde (`.fillna("-")`), vóór je koppelt.
:::
