---
titre: Een tabel opschonen
resume: Dubbels, ontbrekende waarden, slecht geschreven categorieën en onmogelijke waarden opsporen en behandelen; bijhouden wat je verwijdert.
partie: Je eigen bestanden
---

# De drie gewestelijke leveringen

We nemen de drie gestapelde bestanden van de vorige les: één rij per gemeente **en per geslacht**. Ze bevatten enkele **opzettelijk toegevoegde afwijkingen**, zoals je ze in echte leveringen tegenkomt.

```python
bxl = pd.read_csv("gegevens/bevolking_brussel_2026.csv", sep=";", dtype={"nis_code": str})
vla = pd.read_excel("gegevens/bevolking_vlaanderen_2026.xlsx", header=2, dtype={"nis_code": str})
wal = pd.read_csv("gegevens/bevolking_wallonie_2026.txt", sep="\t", dtype={"nis_code": str})
bxl["gewest"], vla["gewest"], wal["gewest"] = "Brussel", "Vlaanderen", "Wallonië"
leveringen = pd.concat([bxl, vla, wal], ignore_index=True)
leveringen.shape
```

::: etape
**De werkwijze**: eerst **opsporen** (zonder iets te wijzigen), dan een regel **beslissen**, dan **toepassen** en **bijhouden** wat verwijderd wordt. Elke verwijderde rij moet je kunnen verklaren.
:::

# Opsporen: de categorieën

```python
leveringen["geslacht"].value_counts()
```

**Interpretatie:** een kleine `v`, naast `M` en `V`.

# Opsporen: ontbrekende en onmogelijke waarden

```python
print(leveringen.isna().sum())
leveringen["bevolking"].describe()
```

**Interpretatie:** één ontbrekende bevolking, en een negatief minimum (-1 059): onmogelijk voor een bevolking.

```python
leveringen.query("bevolking.isna() or bevolking < 0")
```

# Opsporen: de dubbels

`duplicated()` markeert de rijen die identiek zijn aan een vorige rij.

```python
print(leveringen.duplicated().sum())
leveringen[leveringen.duplicated(keep=False)]
```

::: usage
`keep=False` markeert **alle** dubbele rijen (het origineel en de kopie), om ze naast elkaar te zien. `subset=["nis_code", "geslacht"]` beperkt de vergelijking tot een sleutel: twee rijen met dezelfde sleutel maar andere cijfers zijn een nog verontrustender dubbel.
:::

# Opsporen: slecht gevormde codes

Een NIS-code telt 5 tekens.

```python
leveringen.query("nis_code.str.len() != 5")
```

**Interpretatie:** de code van Luik wordt voorafgegaan door een spatie. Onzichtbaar voor het oog, maar ze zou elke koppeling met de nomenclatuur verhinderen.

# Verbeteren wat kan

Schrijffouten verbeter je: overbodige spaties, kleine letters.

```python
schoon = leveringen.drop_duplicates().copy()
schoon["nis_code"] = schoon["nis_code"].str.strip()
schoon["geslacht"] = schoon["geslacht"].str.strip().str.upper()
print(schoon["geslacht"].value_counts())
print(schoon.query("nis_code.str.len() != 5").shape)
```

::: usage
- `.str.strip()` verwijdert de spaties aan het begin en het einde; `.str.upper()` zet in hoofdletters;
- `.copy()` maakt een onafhankelijke tabel: `schoon` wijzigen raakt `leveringen` niet.
:::

::: sas
`nis_code = strip(nis_code); geslacht = upcase(strip(geslacht));` en `PROC SORT NODUPKEY` voor de dubbels.
:::

# Verwijderen wat niet kan, en het bijhouden

Een ontbrekende of negatieve bevolking kun je niet raden. Regel: de rij wordt **verwijderd** en opgeborgen in een tabel van **afgewezen rijen**, met de reden.

```python
af_te_wijzen = schoon["bevolking"].isna() | (schoon["bevolking"] < 0)
afgewezen = schoon[af_te_wijzen].copy()
afgewezen["reden"] = np.where(afgewezen["bevolking"].isna(),
                              "ontbrekende bevolking", "negatieve bevolking")
schoon = schoon[~af_te_wijzen].copy()
schoon["bevolking"] = schoon["bevolking"].astype(int)

print(len(leveringen), "gelezen;", len(schoon), "behouden;", len(afgewezen), "afgewezen")
afgewezen
```

::: usage
`|` betekent « of », `~` betekent « niet »: `schoon[~af_te_wijzen]` houdt de rijen die **niet** afgewezen moeten worden. `.astype(int)` zet de bevolking terug als geheel getal (ze was decimaal door de ontbrekende waarde).
:::

# Een becijferd overzicht: het auditspoor

```python
overzicht = pd.DataFrame({
    "stap": ["gelezen rijen", "verwijderde dubbels", "afgewezen rijen", "behouden rijen"],
    "rijen": [len(leveringen), leveringen.duplicated().sum(), len(afgewezen), len(schoon)]})
overzicht
```

# Controleren met een referentiebron

De tabel `gemeenten` is de officiële bevolking. We vergelijken ze met de opgeschoonde leveringen, gemeente per gemeente.

```python
per_gemeente = schoon.groupby("nis_code", as_index=False).agg(geleverd=("bevolking", "sum"))
vergelijking = gemeenten.merge(per_gemeente, on="nis_code", how="outer",
                               indicator=True, validate="one_to_one")
vergelijking["verschil"] = vergelijking["geleverd"] - vergelijking["totaal"]
vergelijking.query("verschil != 0 or _merge != 'both'")[
    ["nis_code", "gemeente", "totaal", "geleverd", "verschil", "_merge"]]
```

**Interpretatie:** drie verschillen, allemaal verklaard: Daverdisse en Martelange hebben een rij verloren (afgewezen), en de code « 99999 » bestaat niet in de officiële tabel. Alle andere gemeenten kloppen tot op de eenheid.

::: piege
**Opgeschoond betekent niet volledig.** Na het opschonen telt de bevolking van Daverdisse alleen nog de vrouwen. Elke som die de gemeente bevat, is onderschat: meld het, of vraag een nieuwe levering.
:::
