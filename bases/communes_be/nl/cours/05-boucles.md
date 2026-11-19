---
titre: Lussen en iteraties
resume: Een verwerking herhalen met for en while, range() en enumerate(); een lijst van woordenboeken en meerdere bestanden doorlopen.
partie: Halve dag 2 · Voorwaarden en lussen
---

# De for-lus: herhalen voor elk element

`for element in verzameling:` voert het blok één keer per element uit.

De lusvariabele neemt achtereenvolgens elke waarde aan.

Een **accumulator**, vóór de lus geïnitialiseerd, verzamelt het resultaat. Hier de bevolking van de vijf Waalse provincies:

```python
bevolkingen = [416947, 1368562, 1125300, 296370, 506271]
totaal = 0                        # accumulator
for waarde in bevolkingen:
    totaal = totaal + waarde
    print("toevoegen van", waarde, "->", totaal)
print("Totaal:", totaal)
```

# Een expliciete lus, waar SAS impliciet lust

| | DATA-stap in SAS | Python (sessies 2 en 3) | pandas (sessies 4 en 5) |
|---|---|---|---|
| De lus over de rijen | **impliciet**: de code geldt voor elke rij die `SET` leest | **expliciet**: `for rij in rijen:` | geen lus: een instructie geldt voor **een hele kolom** |
| Het rijnummer | `_N_` | `enumerate()` | de index |
| De rij wegschrijven | `OUTPUT` | `.append()` | `df["x"] = df["bevolking"] / 1000` |

Waarom lussen schrijven vóór pandas? Om te begrijpen wat een verwerking rij per rij doet, en om te automatiseren wat geen tabel is: een lijst van bestanden, periodes of regels.

# range() en enumerate()

`range(begin, einde)` maakt gehele getallen van `begin` tot `einde` **niet inbegrepen**, zoals bij slicing.

`enumerate()` geeft tegelijk de positie en het element: nuttig om aan te geven waar een afwijking zit.

```python
for jaar in range(2024, 2027):
    print("Verwerking van het jaar", jaar)

codes = ["62003", " 62063", "62006"]
for positie, code in enumerate(codes):
    if len(code) != 5:
        print("Positie", positie, ":", repr(code), "te controleren")
```

`repr()` toont de tekst met zijn aanhalingstekens: de spatie vooraan wordt zichtbaar.

# Een lijst van woordenboeken doorlopen

Een tabel kun je voorstellen als een **lijst van woordenboeken**: één rij = één woordenboek.

Je doorloopt de rijen met `for` en leest elk veld via zijn sleutel.

`.items()` doorloopt de sleutel-waardeparen van een woordenboek.

```python
rijen = [
    {"nis_code": "92094", "gemeente": "Namen", "geslacht": "M", "bevolking": 56248},
    {"nis_code": "92094", "gemeente": "Namen", "geslacht": "v", "bevolking": 59209},
    {"nis_code": "84016", "gemeente": "Daverdisse", "geslacht": "M", "bevolking": None},
]
for rij in rijen:
    if rij["geslacht"] not in ("M", "V"):
        print("Geslacht te controleren:", rij["gemeente"])
for sleutel, waarde in rijen[0].items():
    print(sleutel, "=", waarde)
```

# Tellen en verzamelen tijdens een lus

Een **teller** en een **verzamellijst** initialiseer je vóór de lus.

`n += 1` is een verkorte vorm van `n = n + 1`.

Woordenboeken verzamelen levert een uitvoertabel op die je kunt wegschrijven en controleren.

```python
n_afwijkingen = 0
te_controleren = []
for positie, rij in enumerate(rijen):
    if rij["geslacht"] not in ("M", "V"):
        n_afwijkingen += 1
        te_controleren.append({"positie": positie,
                               "regel": "R1 geslacht",
                               "waarde": rij["geslacht"]})
print(n_afwijkingen)
print(te_controleren)
```

# Meerdere bestanden doorlopen

*Recept om zo te hergebruiken.*

De meegeleverde functie `laad_rijen(pad)` (in `outils_cursus.py`) leest een CSV-, Excel- of TXT-bestand en geeft een lijst van woordenboeken terug; een ontbrekende waarde wordt `None`. In halve dag 3 leer je zo'n functie zelf te schrijven.

De lus past dezelfde verwerking toe op elk bestand.

```python
from outils_cursus import laad_rijen

bestanden = ["gegevens/bevolking_brussel_2026.csv",
             "gegevens/bevolking_vlaanderen_2026.xlsx",
             "gegevens/bevolking_wallonie_2026.txt"]
for pad in bestanden:
    rijen = laad_rijen(pad)
    print(pad, ":", len(rijen), "rijen")
print(rijen[0])
```

**Interpretatie:** 38 rijen voor Brussel (19 gemeenten × 2 geslachten), 571 voor Vlaanderen, 523 voor Wallonië.

# while: herhalen zolang een voorwaarde waar is

`while voorwaarde:` herhaalt het blok zolang de voorwaarde waar blijft. Nuttig wanneer het aantal herhalingen niet vooraf gekend is.

Een projectie: Namen telt 115 457 inwoners. Met 0,5 % meer per jaar (hypothese), wanneer zal de stad 120 000 inwoners overschrijden?

```python
bevolking = 115457
jaar = 2026
while bevolking < 120000:       # hypothese: +0,5 % per jaar
    bevolking = bevolking * 1.005
    jaar += 1
print(jaar, round(bevolking))
```

::: piege
**Als de voorwaarde nooit onwaar wordt, stopt de lus niet.** Hier verandert de bevolking niet: de lus zou eindeloos draaien. In JupyterLab onderbreek je ze met de knop ■; in het atelier blokkeert Python en moet je de pagina herladen. Deze code wordt hier dus **niet uitgevoerd**:
:::

```python norun
bevolking = 115457
while bevolking < 120000:
    print(bevolking)            # vergeten bevolking te wijzigen
```

# Demonstratie: de drie bestanden controleren

1. Elk bestand inlezen met `laad_rijen()`
2. R1 tot R4 toepassen op elke rij
3. De afwijkende rijen per bestand tellen
4. Het overzicht lezen

```python
for pad in bestanden:
    n = 0
    for rij in laad_rijen(pad):
        bev = rij["bevolking"]
        if (rij["geslacht"] not in ("M", "V")
                or bev is None or bev < 0
                or len(rij["nis_code"]) != 5):
            n += 1
    print(pad[9:], ":", n, "afwijkend")
```

**Om op te letten:** geen enkele afwijking in Vlaanderen, terwijl het bestand een dubbele rij bevat (Gent, vrouwen). Een dubbel zie je niet rij per rij: je moet de rijen met elkaar vergelijken (zie de uitbreidingen van atelier 2).

# Om te onthouden

- **Voorwaarden**: `if`, `elif`, `else`: het eerste ware blok wordt uitgevoerd. `:` op het einde van de regel, ingesprongen blok.
- **Booleans**: `and`, `or`, `not`, `in`. Test `is None` vóór je een waarde vergelijkt.
- **for-lus**: één doorgang per element. `range()` voor gehele getallen, `enumerate()` voor de positie.
- **while-lus**: zolang de voorwaarde waar is. Controleer dat ze ooit onwaar wordt.
- **Accumuleren**: tellers en verzamellijsten initialiseer je **vóór** de lus.
- **Controleren**: één regel per afwijking, één overzicht per bestand: gelezen rijen = geldige + afgewezen.
