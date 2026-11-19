---
titre: Lussen en functies
resume: Een stap herhalen voor elke provincie of elk bestand met for, en dan je eigen functie schrijven om geen code meer te kopiëren.
partie: Verder gaan
---

# Wanneer heb je een lus nodig?

Met pandas gebeuren de meeste berekeningen **zonder lus**: een instructie geldt voor een hele kolom, `groupby` behandelt alle groepen in één keer. Je schrijft een lus wanneer je een **actie moet herhalen** die geen berekening op een tabel is:

- **één bestand per** provincie wegschrijven;
- **meerdere bestanden** inlezen en ze stapelen;
- **één grafiek per** gewest maken.

Dat is de rol van de `%DO`-macro's in SAS.

# De for-lus

`for waarde in lijst:` herhaalt de **ingesprongen** regels (4 spaties naar rechts) één keer voor elk element van de lijst.

```python
for gewest in ["Brussel", "Vlaanderen", "Wallonië"]:
    n = len(gemeenten.query("gewest == @gewest"))
    print(gewest, ":", n, "gemeenten")
```

::: usage
- De `for`-regel eindigt op `:`; het herhaalde blok **springt in**. Terug naar de kantlijn beëindigt de lus.
- In `query()` duidt `@gewest` de Python-**variabele** `gewest` aan (en niet een kolom): zo stop je een veranderende waarde in een voorwaarde.
:::

::: sas
`%DO i = 1 %TO 3; ... %END;` in een macro.
:::

# Eén bestand per provincie

We lussen over de waarden van de kolom `provincie`: elke ronde schrijft de gemeenten van één provincie weg.

```python
import os

for provincie in gemeenten["provincie"].unique():
    een = gemeenten.query("provincie == @provincie")
    een.to_csv(f"uitvoer/gemeenten_{provincie}.csv", sep=";", index=False)

sorted(os.listdir("uitvoer"))
```

::: usage
`f"uitvoer/gemeenten_{provincie}.csv"` is een tekst **met gaten** (een *f-string*): wat tussen accolades staat, wordt vervangen door de waarde van de variabele. Dat is het equivalent van `&provincie` in een SAS-macro.
:::

# Meerdere bestanden inlezen in een lus

We lezen elk bestand in, bergen de tabellen op in een **lijst**, en stapelen ze dan.

```python
bestanden = {"Brussel": "gegevens/bevolking_brussel_2026.csv",
             "Wallonië": "gegevens/bevolking_wallonie_2026.txt"}

tabellen = []
for gewest, pad in bestanden.items():
    sep = "\t" if pad.endswith(".txt") else ";"
    t = pd.read_csv(pad, sep=sep, dtype={"nis_code": str})
    t["gewest"] = gewest
    tabellen.append(t)

gestapeld = pd.concat(tabellen, ignore_index=True)
gestapeld["gewest"].value_counts()
```

::: usage
- `bestanden.items()` doorloopt de paren « sleutel: waarde » van een woordenboek (*dictionary*);
- `tabellen = []` maakt een lege lijst, die `tabellen.append(t)` bij elke ronde aanvult;
- `"\t" if ... else ";"` kiest een waarde volgens een voorwaarde, op één regel.
:::

# Je eigen functie schrijven

Wanneer je hetzelfde codeblok meermaals kopieert en telkens één waarde verandert, maak je er een **functie** van. De samenvattende fiche van een provincie:

```python
def fiche(provincie):
    """Gemeenten, bevolking en aandeel vrouwen van een provincie."""
    t = gemeenten.query("provincie == @provincie")
    return {"provincie": provincie,
            "gemeenten": len(t),
            "bevolking": int(t["totaal"].sum()),
            "aandeel_vrouwen": round(float(t["vrouwen"].sum() / t["totaal"].sum() * 100), 1)}

fiche("Namen")
```

::: usage
- `def naam(parameter):` declareert de functie; het ingesprongen blok is haar inhoud;
- de tekst tussen drie aanhalingstekens beschrijft de functie (je leest hem met `help(fiche)`);
- `return` geeft het resultaat terug; hier een **woordenboek** `{naam: waarde}`.
- `int()` en `float()` geven gewone Python-getallen: zonder hen zou het woordenboek `np.int64(506271)` tonen, de manier waarop pandas zijn eigen getallen noteert.
:::

::: sas
Een macro `%MACRO fiche(provincie); ... %MEND;`. Verschil: een Python-functie **geeft een waarde terug**, die je kunt opbergen, hergebruiken, stapelen.
:::

# De functie toepassen op elke provincie

Een lus roept de functie op voor elke provincie; `pd.DataFrame()` zet de lijst van fiches om in een tabel.

```python
fiches = []
for provincie in sorted(gemeenten["provincie"].unique()):
    fiches.append(fiche(provincie))

pd.DataFrame(fiches)
```

::: note
Voor deze precieze berekening had een `groupby` volstaan (les « Berekenen per groep »). De functie wordt pas echt nuttig wanneer de verwerking **lang** is (inlezen, opschonen, controleren, wegschrijven) en je ze, identiek, wilt toepassen op elke nieuwe levering.
:::

# Een functie controleren: assert

`assert voorwaarde` zegt niets als de voorwaarde waar is, en stopt alles als ze onwaar is. Controleer een functie op een geval waarvan je het antwoord kent.

```python
assert fiche("Brussel-Hoofdstad")["gemeenten"] == 19
assert fiche("Luxemburg")["bevolking"] == 296370
print("Controles OK")
```

# Opgelet voor eindeloze lussen

De `while`-lus herhaalt een blok **zolang een voorwaarde waar is**. Wordt de voorwaarde nooit onwaar, dan stopt de lus niet: in Jupyter onderbreek je ze met de knop ■; in het atelier zou je de pagina moeten herladen. Deze code wordt hier dus **niet uitgevoerd**:

```python norun
bevolking = 115457
while bevolking < 120000:
    print(bevolking)        # vergeten bevolking te laten veranderen
```

::: piege
Met pandas heb je zelden `while` nodig. Een `for`-lus over een gekende lijst stopt altijd.
:::
