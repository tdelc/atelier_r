---
titre: Een verwerking structureren
resume: Een verwerking opdelen in eenvoudige functies, ze na elkaar uitvoeren, ze op meerdere bestanden toepassen en de resultaten controleren met assert.
partie: Halve dag 3 · Functies en herbruikbare verwerkingen
---

# Startcel: de hulpmiddelen

*Recept om zo te hergebruiken.*

De verwerkingen van dit deel lezen de drie gewestelijke bestanden, zoals in halve dag 2. We importeren `date` (voor het atelier), pandas, de functies uit `outils_cursus.py`, en definiëren opnieuw de lijst van bestanden.

```python
from datetime import date
import pandas as pd
from outils_cursus import laad_rijen, harmoniseer_code, harmoniseer_geslacht

bestanden = ["gegevens/bevolking_brussel_2026.csv",
             "gegevens/bevolking_vlaanderen_2026.xlsx",
             "gegevens/bevolking_wallonie_2026.txt"]
print(len(bestanden), "bestanden")
```

# Een verwerking opdelen in eenvoudige bewerkingen

| Stap | Functie | Invoer → uitvoer |
|---|---|---|
| 1 · Inlezen | `laad_rijen(pad)` | een bestand → een lijst van rijen (meegeleverd) |
| 2 · Harmoniseren | `harmoniseer_rij(rij)` | een rij → een kopie in de verwachte formaten |
| 3 · Controleren | `controleer_rij(rij)` | een rij → de lijst van haar afwijkingen |
| 4 · Transformeren | `transformeer_rij(rij)` | een rij → een verrijkte rij |
| 5 · Wegschrijven | `schrijf_resultaat(rijen, pad)` | rijen → een bestand, aantal weggeschreven rijen |

Elke functie doet **één enkel ding** en wordt apart getest. De volledige verwerking wordt een opeenvolging van oproepen, samengebracht in `verwerk_bestand(pad)`.

# Een controlefunctie die een lijst teruggeeft

De regels van halve dag 2 worden een functie: een rij als invoer, een lijst als uitvoer. Lege lijst: de rij is in orde.

```python
def controleer_rij(rij):
    """Afwijkingen van een rij ([] als ze in orde is)."""
    afwijkingen = []
    if rij["geslacht"] not in ("M", "V"):
        afwijkingen.append("R1 geslacht")
    if rij["bevolking"] is None:
        afwijkingen.append("R2 ontbrekende bevolking")
    elif rij["bevolking"] < 0:
        afwijkingen.append("R3 negatieve bevolking")
    if len(rij["nis_code"]) != 5:
        afwijkingen.append("R4 formaat van de code")
    return afwijkingen

ok = {"nis_code": "62063", "geslacht": "V", "bevolking": 99618}
nok = {"nis_code": " 62063", "geslacht": "x", "bevolking": None}
print(controleer_rij(ok))
print(controleer_rij(nok))
```

# Functies na elkaar uitvoeren

`harmoniseer_rij()` roept de reeds geschreven functies op: elk blijft eenvoudig.

`dict(rij)` maakt een **kopie**: de oorspronkelijke rij blijft intact, zodat je voor en na kunt vergelijken.

```python
def harmoniseer_rij(rij):
    """Geharmoniseerde kopie van een rij."""
    nieuw = dict(rij)          # kopie
    nieuw["nis_code"] = harmoniseer_code(rij["nis_code"])
    nieuw["geslacht"] = harmoniseer_geslacht(rij["geslacht"])
    return nieuw

ruw = {"nis_code": " 62063", "gemeente": "Luik", "geslacht": "m", "bevolking": 98484}
schoon = harmoniseer_rij(ruw)
print(repr(ruw["nis_code"]), ruw["geslacht"])
print(repr(schoon["nis_code"]), schoon["geslacht"])
print(controleer_rij(schoon))
```

# De functies hergebruiken op meerdere bestanden

Een lege lijst is `False` in een voorwaarde: `if controleer_rij(rij):` betekent « als er minstens één afwijking is ».

`return geldig, afgewezen` geeft twee lijsten terug, opgevangen in één toekenning.

```python
def verwerk_bestand(pad):
    """Leest, harmoniseert en controleert een bestand."""
    geldig, afgewezen = [], []
    for rij in laad_rijen(pad):
        rij = harmoniseer_rij(rij)
        if controleer_rij(rij):     # niet-lege lijst
            afgewezen.append(rij)
        else:
            geldig.append(rij)
    return geldig, afgewezen

for pad in bestanden:
    geldig, afgewezen = verwerk_bestand(pad)
    print(pad[9:], len(geldig), len(afgewezen))
```

**Interpretatie:** dankzij het harmoniseren worden Luik (`" 62063"`) en Namen (`"v"`) niet meer afgewezen. Er blijven 2 afgewezen rijen in Wallonië: de ontbrekende bevolking van Daverdisse en de negatieve bevolking van Martelange, die geen enkele functie kan raden.

# De invoer en de resultaten controleren

`assert voorwaarde, melding` zegt niets als de voorwaarde waar is, en stopt met `AssertionError` als ze onwaar is.

Controleer een functie op gekende gevallen vóór je ze op een heel bestand toepast. Controleer het globale resultaat: er mag geen enkele rij verloren gaan.

```python
assert harmoniseer_code(" 62063") == "62063"
assert harmoniseer_geslacht(" v") == "V"
assert controleer_rij({"nis_code": "62063", "geslacht": "M",
                       "bevolking": 10}) == []

pad = "gegevens/bevolking_wallonie_2026.txt"
n_gelezen = len(laad_rijen(pad))
geldig, afgewezen = verwerk_bestand(pad)
assert len(geldig) + len(afgewezen) == n_gelezen, "rijen verloren"
print("Controles OK:", n_gelezen, "rijen gelezen")
```

# Demonstratie: de aanwezigheid van de verwachte waarden controleren

- een variabele harmoniseren: `harmoniseer_code()`;
- de verwachte waarden controleren: `controleer_verwacht()`;
- het geheel op de drie bestanden toepassen.

`verzameling.add(x)` voegt een waarde toe; `a - b` geeft de elementen van `a` die niet in `b` zitten. De verwachte codes zijn die van de **geldige** gemeenten in de NUTS-nomenclatuur.

```python
def controleer_verwacht(rijen, verwacht, veld):
    """Waarden die in de rijen staan maar niet bij de verwachte."""
    aanwezig = set()
    for rij in rijen:
        aanwezig.add(rij[veld])
    return aanwezig - verwacht

ref = pd.read_csv("referenties/nuts_lau_2027.txt", sep="|", encoding="cp1252")
gemeentecodes = set()
for code, niveau, einde in zip(ref["CD_MUNTY_REFNIS"], ref["CD_LVL"], ref["DT_VLDT_STOP"]):
    if niveau == 4 and einde == "31/12/9999":
        gemeentecodes.add(code)
print(len(gemeentecodes), "geldige gemeenten")

for pad in bestanden:
    onverwacht = controleer_verwacht(laad_rijen(pad), gemeentecodes, "nis_code")
    print(pad[9:], sorted(onverwacht))
```

**Interpretatie:** in Wallonië zijn twee codes geen geldige gemeenten: `" 62063"`, die `harmoniseer_code()` verbetert, en `"99999"`, een onbekende gemeente die gemeld moet worden (je komt ze terug tegen bij de koppeling van halve dag 5).

# Om te onthouden

- **Ingebouwde functies**: `len`, `sum`, `min`, `max`, `round`, `sorted`, en de tekstmethodes `.strip()`, `.upper()`, `.zfill()`.
- **Definiëren**: `def naam(parameters):`, een docstring, een ingesprongen blok, `return`.
- **Parameters**: standaardwaarden voor de opties; benoemde argumenten bij de oproep voor de leesbaarheid.
- **Teruggeven**: `return` geeft een resultaat door; `print` toont alleen. Zonder `return`: `None`.
- **Structureren**: één functie = één bewerking: inlezen, harmoniseren, controleren, transformeren, wegschrijven.
- **Controleren**: `assert` op gekende gevallen; gelezen rijen = geldige rijen + afgewezen.
