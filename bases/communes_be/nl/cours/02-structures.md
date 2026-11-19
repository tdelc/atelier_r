---
titre: Structuren, indexering en slicing
resume: Lijsten, tuples, verzamelingen en woordenboeken; een element op zijn positie of een stuk eruit halen.
partie: Halve dag 1 · Basis en bestanden
---

# Vier structuren om waarden te groeperen

| Structuur | Schrijfwijze | Geordend | Wijzigbaar | Dubbels | Typisch gebruik |
|---|---|---|---|---|---|
| lijst | `[416947, 1368562]` | ja | ja | ja | een reeks waarden |
| tuple | `("gewest", "provincie")` | ja | nee | ja | een vaste nomenclatuur |
| verzameling (set) | `{"62063", "92094"}` | nee | ja | nee | unieke codes |
| woordenboek | `{"nis_code": "62063", "bevolking": 198102}` | ja | ja | unieke sleutels | een rij van een tabel |

Een rij van een tabel kun je voorstellen als een **woordenboek**, en een tabel als een **lijst van woordenboeken**: dat is de vorm die we in halve dag 2 en 3 gebruiken, vóór we naar pandas overstappen.

# Lijsten: een geordende en wijzigbare reeks

Een lijst schrijf je tussen vierkante haken, met de elementen gescheiden door komma's.

`len()` telt de elementen; `sum()`, `min()`, `max()` rekenen op getallen.

`.append()` voegt toe aan het einde; `lijst[i] = ...` vervangt het element op positie `i`.

De vijf Waalse provincies en hun bevolking op 1 januari 2026:

```python
provincies = ["Waals Brabant", "Henegouwen", "Luik", "Luxemburg"]
bevolkingen = [416947, 1368562, 1125300, 296370]
print(len(provincies))
provincies.append("Namen")             # voegt toe aan het einde
bevolkingen.append(506271)
provincies[0] = "Waals-Brabant"        # verbetert de tikfout
print(provincies)
print(sum(bevolkingen), max(bevolkingen))
```

**Interpretatie:** de som, 3 713 450, is precies de bevolking van het Waals Gewest in het bestand van Statbel. Henegouwen is de provincie met de meeste inwoners.

# Indexering: de eerste positie is 0

Je bereikt een element via zijn positie tussen vierkante haken.

De posities beginnen bij **0**. Negatieve posities tellen vanaf het einde: `-1` is het laatste.

| Element | Brussel | Vlaanderen | Wallonië |
|---|---|---|---|
| Positie | 0 | 1 | 2 |
| Vanaf het einde | -3 | -2 | -1 |

Een positie die niet bestaat, geeft een fout `IndexError`. **Bewuste fout** op de laatste regel:

```python erreur
gewesten = ["Brussel", "Vlaanderen", "Wallonië"]
print(gewesten[0])      # eerste element
print(gewesten[2])      # derde element
print(gewesten[-1])     # laatste element
gewesten[3]             # er zijn maar 3 elementen
```

::: sas
SAS nummert de observaties vanaf 1 (`_N_` is 1 op de eerste). Python telt de posities vanaf 0.
:::

# Slicing: een stuk eruit halen met [begin:einde]

`lijst[begin:einde]` geeft de elementen van `begin` **inbegrepen** tot `einde` **niet inbegrepen**.

Zonder `begin`: vanaf het eerste element. Zonder `einde`: tot het laatste.

Slicing werkt ook op tekst. Dat is heel nuttig met de **NIS-code**: het eerste cijfer duidt de provincie aan, de eerste twee het arrondissement.

```python
codes = ["62003", "62006", "62009", "62011", "62015", "62022"]
print(codes[1:4])     # posities 1, 2 en 3
print(codes[:2])      # de eerste twee
print(codes[-3:])     # de laatste drie

nis_code = "62063"    # Luik
print(nis_code[:1], nis_code[:2])
```

**Interpretatie:** `"6"` is de code van de provincie Luik (60000) en `"62"` die van het arrondissement Luik (62000).

# Tuples en verzamelingen

Een **tuple** schrijf je tussen ronde haken en kun je niet wijzigen: geschikt voor een vaste nomenclatuur.

Een **verzameling** (`set`) houdt maar één exemplaar van elke waarde, zonder volgorde: ideaal om unieke codes te krijgen of te testen of iets erin zit.

`sorted()` geeft een gesorteerde lijst terug.

```python
niveaus = ("gewest", "provincie", "arrondissement", "gemeente")   # tuple
print(niveaus[1])

gelezen_provincies = ["Luik", "Namen", "Luik", "Henegouwen", "Namen"]
unieke_provincies = set(gelezen_provincies)          # zonder dubbels
print(len(gelezen_provincies), len(unieke_provincies))
print(sorted(unieke_provincies))
print("Luxemburg" in unieke_provincies)
```

# Woordenboeken: een sleutel aan een waarde koppelen

Een woordenboek (*dictionary*) koppelt unieke **sleutels** aan **waarden**.

Je leest een waarde via haar sleutel: `gemeente["bevolking"]`.

`.get(sleutel, standaard)` geeft een standaardwaarde terug als de sleutel niet bestaat, in plaats van een fout `KeyError`.

```python
gemeente = {"nis_code": "62063", "naam": "Luik", "bevolking": 198102}
print(gemeente["bevolking"])
gemeente["bevolking"] = 198112       # een waarde wijzigen
gemeente["provincie"] = "Luik"       # een sleutel toevoegen
print(list(gemeente.keys()))
print(gemeente.get("oppervlakte", "onbekend"))
```
