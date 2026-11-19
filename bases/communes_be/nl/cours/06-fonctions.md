---
titre: Python-functies
resume: Ingebouwde functies en tekstmethodes; een functie definiëren met def; parameters, standaardwaarden, return; lokale variabelen.
partie: Halve dag 3 · Functies en herbruikbare verwerkingen
---

# Halve dag 3: functies en herbruikbare verwerkingen

**Na deze sessie kun je**

- de ingebouwde functies gebruiken en nieuwe definiëren met `def`;
- parameters, standaardwaarden en terugkeerwaarden kiezen;
- een verwerking opdelen in eenvoudige functies en ze na elkaar uitvoeren;
- de invoer en de resultaten van een verwerking controleren.

**Waarom functies schrijven?**

- **Niet herhalen**: de regels van halve dag 2 werden voor elk geval gekopieerd. Een functie schrijf je één keer en roep je zo vaak op als nodig.
- **Een bedoeling benoemen**: `harmoniseer_code(code)` leest als een zin: je begrijpt de verwerking zonder de details te lezen.
- **Apart testen**: een functie controleer je op enkele gekende gevallen vóór je ze op duizenden rijen toepast.

Een functie krijgt **invoerwaarden** (haar parameters), voert een blok uit en **geeft een resultaat terug** met `return`.

# De ingebouwde functies, altijd beschikbaar

| Functie | Rol |
|---|---|
| `len()` | aantal elementen |
| `sum()` | som |
| `min()`, `max()` | minimum, maximum |
| `round(x, n)` | afronden op n decimalen |
| `sorted()` | gesorteerde lijst |
| `abs()` | absolute waarde |
| `type()` | type van een waarde |

```python
waarden = [198102, 115457, 206900, 97745]   # Luik, Namen, Charleroi, Bergen
print(len(waarden), sum(waarden))
print(min(waarden), max(waarden))
print(round(sum(waarden) / len(waarden), 1))
print(sorted(["Namen", "Luik", "Charleroi", "Bergen"]))
print(abs(-1059))
```

# De tekstmethodes: een tekenreeks opschonen

Een **methode** is een functie die aan een waarde vastzit: `waarde.methode()`.

De tekstmethodes geven een **nieuwe** tekst terug: het origineel wordt niet gewijzigd. Je kunt ze aan elkaar rijgen: `code.strip().upper()`.

| Methode | Effect |
|---|---|
| `.strip()` | verwijdert de spaties aan de uiteinden |
| `.upper()`, `.lower()` | hoofdletters, kleine letters |
| `.replace(a, b)` | vervangt a door b |
| `.zfill(n)` | vult links aan met nullen |
| `.startswith(x)` | begint met x? |

```python
code = " 62063 "
print(repr(code.strip()))
print(" v ".strip().upper())
print("1000".zfill(5))                 # de code van België, 01000
print("198.102".replace(".", ""))
print("62063".startswith("6"))         # een gemeente van de provincie Luik?
```

# Een functie definiëren met def

`def naam(parameters):` en dan een ingesprongen blok; `return` geeft het resultaat terug.

De tekst tussen drie aanhalingstekens (*docstring*) beschrijft de functie: pas de documentatieafspraken van je dienst toe.

Een gedefinieerde functie wordt pas uitgevoerd wanneer je ze **oproept**.

```python
def aandeel(deel, totaal):
    """Aandeel van deel in totaal, in %, afgerond op 2 decimalen."""
    return round(deel / totaal * 100, 2)

print(aandeel(99618, 198102))      # vrouwen in Luik
print(aandeel(59209, 115457))      # vrouwen in Namen
```

# Parameters, argumenten en standaardwaarden

De **parameters** zijn de namen die in `def` gedeclareerd worden; de **argumenten** zijn de waarden die je bij de oproep meegeeft.

Een parameter met een standaardwaarde wordt optioneel. De argumenten bij de oproep benoemen maakt de code leesbaar: `lengte=5`.

```python
def harmoniseer_code(code, lengte=5):
    """' 62063 ' -> '62063' ; '1000' -> '01000'."""
    return str(code).strip().zfill(lengte)

print(harmoniseer_code(" 62063"))
print(harmoniseer_code("1000"))
print(harmoniseer_code("3", lengte=2))
```

# return geeft een resultaat terug, print toont het alleen

Zonder `return` geeft een functie `None` terug.

Een **teruggegeven** resultaat kun je bewaren, hergebruiken en testen. Een **getoond** resultaat is verloren voor de rest.

Een functie kan meerdere waarden teruggeven: `return geldig, afgewezen`.

```python
def toon_totaal(waarden):
    print(sum(waarden))          # toont alleen

def bereken_totaal(waarden):
    return sum(waarden)          # geeft het resultaat terug

resultaat = toon_totaal([1, 2, 3])
print(resultaat)
print(bereken_totaal([1, 2, 3]) * 10)
```

# De variabelen van een functie blijven in de functie

Variabelen die in een functie aangemaakt worden, zijn **lokaal**: ze verdwijnen aan het einde van de oproep. Om een waarde terug te krijgen, moet de functie ze teruggeven.

Een functie die alleen haar parameters gebruikt, blijft voorspelbaar en makkelijk te testen.

**Bewuste fout**: `n` bestaat alleen in de functie.

```python erreur
def tel_ontbrekende(rijen):
    n = 0
    for rij in rijen:
        if rij["bevolking"] is None:
            n += 1
    return n

rijen = [{"bevolking": 120}, {"bevolking": None}]
print(tel_ontbrekende(rijen))
print(n)
```

# SAS-macro of Python-functie?

| | SAS-macro | Python-functie |
|---|---|---|
| Wat ze maakt | SAS-code, gegenereerd vóór de uitvoering | een waarde, berekend bij de uitvoering |
| Parameters | vervangen tekst (`&code`) | waarden: getal, tekst, lijst, tabel |
| Resultaat | de gegenereerde DATA- of PROC-stappen | wat `return` teruggeeft |
| Debuggen | `OPTIONS MPRINT` om de gegenereerde code te zien | een rechtstreekse oproep op een voorbeeld, `assert` |
| Typisch gebruik | een stap herhalen voor meerdere tabellen | harmoniseren, controleren, transformeren |

Een Python-functie staat dichter bij een functie die met `PROC FCMP` gedefinieerd is dan bij een macro: ze berekent een waarde. Om een verwerking op meerdere tabellen te herhalen, roep je ze op in een lus.

# De functie harmoniseer_geslacht()

Dit is de oefening « Aan jou » van dit deel: probeer ze eerst in het tabblad **Oefeningen**. De oplossing hieronder dient voor de rest van de sessie.

```python
def harmoniseer_geslacht(waarde):
    """Geeft 'M' of 'V' terug, of None als de waarde niet herkend wordt."""
    if waarde is None:
        return None
    waarde = waarde.strip().upper()
    if waarde in ("M", "V"):
        return waarde
    return None

for w in ["v", " M ", "x", None]:
    print(repr(w), "->", harmoniseer_geslacht(w))
```

`harmoniseer_code()` en `harmoniseer_geslacht()` worden ook meegeleverd in `outils_cursus.py`, voor de rest.
