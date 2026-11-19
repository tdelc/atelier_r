---
base: communes_be
---

# Spelen met de types
Elke waarde heeft een type, dat bepaalt wat je ermee kunt doen. Verander de waarden en bekijk de types en de resultaten.

```python
bevolking = 198102
nis_code = "62063"
oppervlakte = 69.4
print(type(bevolking), type(nis_code), type(oppervlakte))
print(bevolking / oppervlakte)     # dichtheid, in inwoners per km²
print(nis_code * 2)                # een tekst vermenigvuldigd met 2?
```

## Om te proberen
- Vervang `bevolking / oppervlakte` door `round(bevolking / oppervlakte, 1)`.
- Wat geeft `nis_code + 1`? Lees de laatste regel van de foutmelding.
- Vergelijk `int("04000")` en `"04000"`: wat gebeurt er met de nul?
- Wat geeft `float("198.102")`? En `int("198.102".replace(".", ""))`?

# Een bestand inlezen met de verkeerde instellingen
De inleesinstellingen bepalen wat pandas van het bestand begrijpt. Verander ze een voor een en bekijk `.shape` en `.dtypes`.

```python
import pandas as pd

ruw = pd.read_csv("gegevens/bevolking_2026.txt", sep="\t",
                  dtype_backend="pyarrow")
print(ruw.shape)
print(ruw.dtypes)
ruw.head()
```

## Om te proberen
- Voeg `thousands="."` toe: wat is nu het type van `Totaal`?
- Voeg `skiprows=[1, 2]` toe, en dan `dtype={"NIS code": str}`.
- Vervang `sep="\t"` door `sep=";"`: hoeveel kolommen?
- Lees maar drie rijen met `nrows=3`.

# De NUTS-nomenclatuur verkennen
De referentie van Statbel beschrijft alle Belgische gebieden, van de gewesten tot de gemeenten, met hun geldigheidsdatums.

```python
import pandas as pd

ref = pd.read_csv("referenties/nuts_lau_2027.txt", sep="|",
                  encoding="cp1252", dtype_backend="pyarrow")
print(ref.shape)
print(list(ref.columns))
ref.head(10)
```

## Om te proberen
- Toon de laatste rijen met `ref.tail()`.
- De NUTS-code van (de provincie) Luik is `BE33`: wat geven `"BE332"[:3]` en `"BE332"[:4]`?
- Wat gebeurt er zonder `encoding="cp1252"`? En met `encoding="latin-1"`: bekijk rij 4, `ref.loc[4, "TX_DESCR_FR"]`.
- Tel de niveaus met `ref["CD_LVL"].value_counts()` (een functie van halve dag 4).
