---
base: communes_be
---

# Het aandeel vrouwen in Namen berekenen
niveau: 1
groupe: Halve dag 1 · Aan jou
theme: operatoren, round()

## Opgave
Op 1 januari 2026 telt Namen 56 248 mannen en 59 209 vrouwen.

1. Maak de variabelen `mannen` en `vrouwen`.
2. Bereken de totale bevolking.
3. Toon `True` als er meer vrouwen dan mannen zijn.
4. Bereken het aandeel vrouwen in %, afgerond op 2 decimalen, en schrijf het **alleen op de laatste regel**: dat wordt gecontroleerd.

## Hint
`round(waarde, 2)` rondt af op 2 decimalen. Het aandeel in %: `vrouwen / totaal * 100`.

## Startcode
```python
mannen = 56248
vrouwen = 59209
```

## Oplossing
```python
mannen = 56248
vrouwen = 59209
totaal = mannen + vrouwen
print(totaal)
print(vrouwen > mannen)
aandeel_vrouwen = round(vrouwen / totaal * 100, 2)
aandeel_vrouwen
```

## Commentaar
Namen telt 115 457 inwoners, waarvan 51,28 % vrouwen. `round(100 * vrouwen / totaal, 2)` schrijven geeft hetzelfde resultaat: de volgorde van de vermenigvuldigingen verandert niets.

# De grote steden in een woordenboek
niveau: 1
groupe: Halve dag 1 · Aan jou
theme: woordenboek

## Opgave
1. Maak `bev = {"Brussel": 198674, "Antwerpen": 565615, "Gent": 274042}` (bevolking op 1 januari 2026).
2. Toon de bevolking van Gent.
3. Voeg Charleroi toe, met 206 900 inwoners.
4. Bereken op de laatste regel het totaal van de vier steden met `sum(bev.values())`.

## Hint
Je voegt een sleutel toe zoals je een waarde wijzigt: `bev["Charleroi"] = 206900`.

## Startcode
```python
bev = {"Brussel": 198674, "Antwerpen": 565615, "Gent": 274042}
```

## Oplossing
```python
bev = {"Brussel": 198674, "Antwerpen": 565615, "Gent": 274042}
print(bev["Gent"])
bev["Charleroi"] = 206900
sum(bev.values())
```

## Commentaar
De vier steden tellen 1 245 231 inwoners. « Brussel » duidt hier de **gemeente** Brussel aan (198 674 inwoners), niet het Brussels Hoofdstedelijk Gewest, dat er 1 255 834 telt: een label volstaat niet, het is de NIS-code die een gebied identificeert (21004 voor de gemeente, 04000 voor het gewest).

# Een NIS-code en een datum knippen
niveau: 1
groupe: Halve dag 1 · Aan jou
theme: slicing

## Opgave
De NIS-code van Bastenaken is `"82039"`: het eerste cijfer duidt de provincie aan, de eerste twee het arrondissement.

1. Haal met slicing de code van de provincie en dan die van het arrondissement eruit, en toon ze.
2. Haal op de laatste regel het jaar uit de tekst `"2026-01-01"`.

## Hint
`tekst[:2]` geeft de eerste twee tekens.

## Oplossing
```python
nis_code = "82039"
print(nis_code[:1], nis_code[:2])
datum_tekst = "2026-01-01"
datum_tekst[:4]
```

## Commentaar
Bastenaken ligt in provincie 8 (Luxemburg, code 80000) en arrondissement 82 (Bastenaken, code 82000). Het verkregen jaar is **tekst**, `"2026"`: `int(datum_tekst[:4])` zou het in een getal omzetten.

# Een verkeerd scheidingsteken, en dan het juiste
niveau: 2
groupe: Halve dag 1 · Aan jou
theme: read_csv, sep

## Opgave
1. Lees `gegevens/bevolking_gemeenten_2026.csv` met `sep=","` (opzettelijk fout) en toon `.shape`. Wat stel je vast?
2. Verbeter het scheidingsteken.
3. Toon op de laatste regel `.shape` van de goed ingelezen tabel: je moet 565 rijen en 5 kolommen krijgen.

## Hint
Open het bestand in gedachten: `nis_code;gemeente;mannen;vrouwen;totaal`. Welk teken scheidt de kolommen?

## Startcode
```python
import pandas as pd

fout = pd.read_csv("gegevens/bevolking_gemeenten_2026.csv", sep=",",
                   dtype_backend="pyarrow")
print(fout.shape)
```

## Oplossing
```python
import pandas as pd

fout = pd.read_csv("gegevens/bevolking_gemeenten_2026.csv", sep=",",
                   dtype_backend="pyarrow")
print(fout.shape)
bev = pd.read_csv("gegevens/bevolking_gemeenten_2026.csv", sep=";",
                  dtype_backend="pyarrow")
bev.shape
```

## Commentaar
Met `sep=","` vindt pandas maar één kolom: `(565, 1)`. Een onverwachte dimensie is het eerste signaal van een verkeerd ingestelde parameter.

# Het type van de kolommen van het Statbel-bestand
niveau: 2
groupe: Halve dag 1 · Aan jou
theme: read_csv, dtypes, thousands

## Opgave
1. Lees `gegevens/bevolking_2026.txt` (met tabs) **zonder** `thousands="."` en toon `.dtypes`: wat is het type van de kolom `Totaal`?
2. Lees het opnieuw met `thousands="."` en `skiprows=[1, 2]`.
3. Schrijf op de laatste regel de totale bevolking van België: de waarde van de kolom `Totaal` op de eerste rij, `ruw["Totaal"][0]`.

## Hint
Het scheidingsteken is de tab, `sep="\t"`. Met `skiprows=[1, 2]` wordt de rij van België rij 0.

## Oplossing
```python
import pandas as pd

ruw = pd.read_csv("gegevens/bevolking_2026.txt", sep="\t",
                  dtype_backend="pyarrow")
print(ruw.dtypes)
ruw = pd.read_csv("gegevens/bevolking_2026.txt", sep="\t",
                  skiprows=[1, 2], thousands=".",
                  dtype_backend="pyarrow")
print(ruw.dtypes)
ruw["Totaal"][0]
```

## Commentaar
Zonder `thousands="."` is `Totaal` tekst (`string[pyarrow]`): `"11.867.634"` bevat twee punten, het is geen getal. Met de parameter wordt de kolom een geheel getal (`int64[pyarrow]`) en telt België 11 867 634 inwoners.

# Atelier 1 · Stap 1: de vier bestanden importeren
niveau: 3
groupe: Atelier 1 · Eerste kennismaking met de gegevens
theme: read_csv, read_excel

## Opgave
**Doel van het atelier**: de bestanden van Statbel importeren, hun structuur controleren, eerste berekeningen maken en een uittreksel wegschrijven.

Importeer de vier bestanden met de juiste instellingen:

- `bev`: `gegevens/bevolking_gemeenten_2026.csv`, met `nis_code` als tekst;
- `ruw`: `gegevens/bevolking_2026.txt`;
- `prov`: `gegevens/bevolking_provincies_2026.xlsx`;
- `ref`: `referenties/nuts_lau_2027.txt`.

Controleer de structuur van elke tabel (`.shape`, `.columns`, `.dtypes`). Schrijf op de laatste regel de lijst van hun dimensies: `[bev.shape, ruw.shape, prov.shape, ref.shape]`.

## Hint
Neem de instellingen van de les « Bestanden inlezen en wegschrijven » over: `sep`, `encoding`, `skiprows`, `thousands`, `header`, `dtype`.

## Startcode
```python
import pandas as pd

bev = pd.read_csv(...)
```

## Oplossing
```python
import pandas as pd

bev = pd.read_csv("gegevens/bevolking_gemeenten_2026.csv", sep=";",
                  dtype={"nis_code": str}, dtype_backend="pyarrow")
ruw = pd.read_csv("gegevens/bevolking_2026.txt", sep="\t",
                  skiprows=[1, 2], thousands=".",
                  dtype={"NIS code": str}, dtype_backend="pyarrow")
prov = pd.read_excel("gegevens/bevolking_provincies_2026.xlsx", header=2,
                     dtype={"nis_code": str}, dtype_backend="pyarrow")
ref = pd.read_csv("referenties/nuts_lau_2027.txt", sep="|",
                  encoding="cp1252", dtype_backend="pyarrow")
print(bev.dtypes)
[bev.shape, ruw.shape, prov.shape, ref.shape]
```

## Commentaar
Verwachte dimensies: 565 × 5, 622 × 5, 11 × 5 en 919 × 10. Vind je 624 rijen voor `ruw`, dan zijn de twee lege regels gebleven: voeg `skiprows=[1, 2]` toe.

# Atelier 1 · Stap 2: een gemeente in een woordenboek
niveau: 3
groupe: Atelier 1 · Eerste kennismaking met de gegevens
theme: woordenboek, berekening

## Opgave
Toon de rij van Aarlen (NIS-code 81001) met `bev[bev["nis_code"] == "81001"]` (filter gegeven: deze syntaxis wordt uitgelegd in halve dag 4).

1. Neem in een woordenboek `aarlen` de bevolkingscijfers over die je op het scherm leest, met de sleutels `"mannen"` en `"vrouwen"`.
2. Bereken de totale bevolking van Aarlen.
3. Bereken op de laatste regel het aandeel **mannen** in %, afgerond op 1 decimaal.

## Hint
Het aandeel: `aarlen["mannen"] / totaal * 100`, dan `round(..., 1)`.

## Voorbereiding
```python
import pandas as pd
bev = pd.read_csv("gegevens/bevolking_gemeenten_2026.csv", sep=";",
                  dtype={"nis_code": str}, dtype_backend="pyarrow")
```

## Startcode
```python
bev[bev["nis_code"] == "81001"]
```

## Oplossing
```python
print(bev[bev["nis_code"] == "81001"])
aarlen = {"mannen": 15647, "vrouwen": 15793}
totaal = aarlen["mannen"] + aarlen["vrouwen"]
print(totaal)
round(aarlen["mannen"] / totaal * 100, 1)
```

## Commentaar
Aarlen telt 31 440 inwoners, waarvan 49,8 % mannen. Cijfers overnemen die je op het scherm leest, is kwetsbaar: vanaf halve dag 4 reken je rechtstreeks op de kolom.

# Atelier 1 · Stap 3: de codes vergelijken met die van de referentie
niveau: 4
groupe: Atelier 1 · Eerste kennismaking met de gegevens
theme: set, verschil van verzamelingen

## Opgave
1. Neem de verzameling van de NIS-codes van de gemeenten van `bev` met `set(bev["nis_code"])`: hoeveel zijn er?
2. Neem de verzameling van de NIS-codes van de referentie: `set(ref["CD_MUNTY_REFNIS"])`.
3. Tel op de laatste regel de codes van de referentie die **niet** in `bev` staan, met een verschil van verzamelingen: `len(a - b)`.

## Hint
`a - b` geeft de elementen van `a` die niet in `b` zitten. De twee tabellen zijn al ingeladen: kijk bij « Code die vóór de jouwe uitgevoerd wordt ».

## Voorbereiding
```python
import pandas as pd
bev = pd.read_csv("gegevens/bevolking_gemeenten_2026.csv", sep=";",
                  dtype={"nis_code": str}, dtype_backend="pyarrow")
ref = pd.read_csv("referenties/nuts_lau_2027.txt", sep="|",
                  encoding="cp1252", dtype_backend="pyarrow")
```

## Oplossing
```python
codes_bev = set(bev["nis_code"])
codes_ref = set(ref["CD_MUNTY_REFNIS"])
print(len(codes_bev), len(codes_ref))
print(len(codes_bev - codes_ref))     # gemeenten die niet in de referentie staan
len(codes_ref - codes_bev)
```

## Commentaar
De 565 gemeenten van 2026 staan allemaal in de referentie. In de andere richting hebben 113 codes van de referentie geen bevolking: de gewesten, provincies en arrondissementen, het streepje `-` van de gebieden zonder NIS-code, en vooral de **oude gemeenten**, verdwenen bij de fusies van 2019 en 2025.

Probeer `bev` opnieuw in te lezen **zonder** `dtype={"nis_code": str}`: het verschil stijgt tot 678, want de codes zijn dan getallen (`11001`) en komen niet meer overeen met de teksten van de referentie (`"11001"`).

# Atelier 1 · Stap 4: een uittreksel wegschrijven en opnieuw inlezen
niveau: 4
groupe: Atelier 1 · Eerste kennismaking met de gegevens
theme: to_csv, controle

## Opgave
De filter hieronder (gegeven, uitgelegd in halve dag 4) houdt de gemeenten van het arrondissement Luik, waarvan de NIS-code begint met `62`:

```python
uittreksel = bev[bev["nis_code"].str.startswith("62")]
```

1. Schrijf `uittreksel` weg naar `uitvoer/uittreksel_arrondissement_luik.csv`, scheidingsteken `;`, zonder index.
2. Lees het weggeschreven bestand opnieuw in.
3. Toon op de laatste regel de dimensies van het herlezen bestand.

## Hint
`uittreksel.to_csv(pad, sep=";", index=False)`, dan `pd.read_csv(pad, sep=";")`.

## Voorbereiding
```python
import pandas as pd
bev = pd.read_csv("gegevens/bevolking_gemeenten_2026.csv", sep=";",
                  dtype={"nis_code": str}, dtype_backend="pyarrow")
```

## Startcode
```python
uittreksel = bev[bev["nis_code"].str.startswith("62")]
```

## Oplossing
```python
uittreksel = bev[bev["nis_code"].str.startswith("62")]
uittreksel.to_csv("uitvoer/uittreksel_arrondissement_luik.csv", sep=";",
                  index=False, encoding="utf-8")
herlezen = pd.read_csv("uitvoer/uittreksel_arrondissement_luik.csv", sep=";",
                       dtype_backend="pyarrow")
herlezen.shape
```

## Commentaar
Het arrondissement Luik telt 24 gemeenten: het herlezen bestand heeft 24 rijen en 5 kolommen. Een weggeschreven bestand opnieuw inlezen is een eenvoudige controle die voorkomt dat je een leeg of afgekapt bestand verstuurt.

**Om verder te gaan**: schrijf hetzelfde uittreksel weg in Excel-formaat (`.to_excel()`) en lees het opnieuw in; lees alleen twee kolommen met `usecols=["nis_code", "totaal"]`.

# Twee controleregels schrijven
niveau: 1
groupe: Halve dag 2 · Aan jou
theme: if, geketende voorwaarden

## Opgave
1. Vertrek van `rij = {"jaar": 2021, "geslacht": "V"}`.
2. Maak een lege lijst `afwijkingen`.
3. Voeg `"jaar buiten periode"` toe aan de lijst als het jaar niet tussen 2024 en 2026 ligt.
4. Voeg `"geslacht onbekend"` toe als het geslacht noch `"M"` noch `"V"` is.
5. Toon op de laatste regel `afwijkingen`. Test ook met `{"jaar": 2026, "geslacht": "v"}`.

## Hint
Python aanvaardt geketende vergelijkingen: `2024 <= jaar <= 2026`. Voor « ligt niet tussen »: `not (...)`.

## Startcode
```python
rij = {"jaar": 2021, "geslacht": "V"}
afwijkingen = []
```

## Oplossing
```python
rij = {"jaar": 2021, "geslacht": "V"}
afwijkingen = []
if not 2024 <= rij["jaar"] <= 2026:
    afwijkingen.append("jaar buiten periode")
if rij["geslacht"] not in ("M", "V"):
    afwijkingen.append("geslacht onbekend")
afwijkingen
```

## Commentaar
Met 2021 wordt alleen de eerste regel geactiveerd. Met `{"jaar": 2026, "geslacht": "v"}` is het de tweede: Python maakt onderscheid tussen hoofdletters en kleine letters, `"v"` is niet `"V"`.

# De incoherente rijen van een bestand opsporen
niveau: 2
groupe: Halve dag 2 · Aan jou
theme: for, enumerate, teller

## Opgave
De rijen van het Waalse bestand zijn al ingeladen in `rijen`.

1. Doorloop `rijen` met `enumerate()`.
2. Toon de positie, de NIS-code, de gemeente en de bevolking van elke rij waarvan de bevolking **ontbreekt of negatief is**.
3. Tel die rijen in `n` en toon `n` op de laatste regel.

## Hint
Test eerst `is None`, dan `< 0`: `if bev is None or bev < 0:`.

## Voorbereiding
```python
from outils_cursus import laad_rijen
rijen = laad_rijen("gegevens/bevolking_wallonie_2026.txt")
```

## Oplossing
```python
n = 0
for positie, rij in enumerate(rijen):
    bev = rij["bevolking"]
    if bev is None or bev < 0:
        n += 1
        print(positie, rij["nis_code"], rij["gemeente"], bev)
n
```

## Commentaar
Twee rijen: Martelange (vrouwen, negatieve bevolking) en Daverdisse (mannen, ontbrekende bevolking). De volgorde van de test telt: met `bev < 0 or bev is None` zou Python `None < 0` vergelijken en stoppen met een fout `TypeError`.

# Atelier 2 · Stap 1: een overzicht per bestand
niveau: 3
groupe: Atelier 2 · Een eerste geautomatiseerde verwerking
theme: for, regels R1 tot R4

## Opgave
**Doel van het atelier**: de drie bestanden met eenzelfde lus controleren en een controleerbaar tussenresultaat maken.

Pas met één enkele lus over `bestanden` de regels R1 tot R4 toe op elke rij en tel de afwijkende rijen per bestand. Berg het resultaat op in een woordenboek `overzicht` (sleutel = pad van het bestand, waarde = aantal afwijkende rijen) en toon het op de laatste regel.

- **R1** `geslacht` is M of V; **R2** `bevolking` ingevuld; **R3** `bevolking` positief of nul; **R4** `nis_code` van 5 tekens.

## Hint
Initialiseer `overzicht = {}` vóór de lus over de bestanden, en `n = 0` aan het begin van elk bestand. Na de lus over de rijen: `overzicht[pad] = n`.

## Voorbereiding
```python
from outils_cursus import laad_rijen
bestanden = ["gegevens/bevolking_brussel_2026.csv",
             "gegevens/bevolking_vlaanderen_2026.xlsx",
             "gegevens/bevolking_wallonie_2026.txt"]
```

## Oplossing
```python
overzicht = {}
for pad in bestanden:
    n = 0
    for rij in laad_rijen(pad):
        bev = rij["bevolking"]
        if (rij["geslacht"] not in ("M", "V")
                or bev is None or bev < 0
                or len(rij["nis_code"]) != 5):
            n += 1
    overzicht[pad] = n
overzicht
```

## Commentaar
Geen enkele afwijking in Brussel of Vlaanderen, 4 afwijkende rijen in Wallonië. Een bestand toevoegen vraagt maar één regel meer in de lijst `bestanden`.

# Atelier 2 · Stap 2: de afwijkingen verzamelen
niveau: 3
groupe: Atelier 2 · Een eerste geautomatiseerde verwerking
theme: lijst van woordenboeken

## Opgave
Verzamel voor elke afwijking een woordenboek in de lijst `afwijkingen`: `bestand`, `positie`, `regel` (bijvoorbeeld `"R1 geslacht"`) en de gecontroleerde `waarde`. Een rij die twee regels overtreedt, geeft twee afwijkingen.

Toon op de laatste regel het aantal afwijkingen, `len(afwijkingen)`.

## Hint
Eén `if`-voorwaarde per regel (en niet één voorwaarde met `or`), elk gevolgd door een `afwijkingen.append({...})`. Gebruik `enumerate()` voor de positie.

## Voorbereiding
```python
from outils_cursus import laad_rijen
bestanden = ["gegevens/bevolking_brussel_2026.csv",
             "gegevens/bevolking_vlaanderen_2026.xlsx",
             "gegevens/bevolking_wallonie_2026.txt"]
```

## Oplossing
```python
afwijkingen = []
for pad in bestanden:
    for positie, rij in enumerate(laad_rijen(pad)):
        bev = rij["bevolking"]
        def noteer(regel, waarde):
            afwijkingen.append({"bestand": pad, "positie": positie,
                                "regel": regel, "waarde": waarde})
        if rij["geslacht"] not in ("M", "V"):
            noteer("R1 geslacht", rij["geslacht"])
        if bev is None:
            noteer("R2 ontbrekende bevolking", bev)
        elif bev < 0:
            noteer("R3 negatieve bevolking", bev)
        if len(rij["nis_code"]) != 5:
            noteer("R4 formaat van de code", rij["nis_code"])
for a in afwijkingen:
    print(a)
len(afwijkingen)
```

## Commentaar
Vier afwijkingen, allemaal in Wallonië, één per regel: Namen (`"v"`), Daverdisse (ontbrekende bevolking), Martelange (negatieve bevolking) en Luik (`" 62063"`, met een spatie). De oplossing definieert een kleine functie `noteer()` om niet vier keer dezelfde `append` te herhalen: dat is het onderwerp van halve dag 3.

# Atelier 2 · Stap 3: de geldige rijen, verrijkt
niveau: 4
groupe: Atelier 2 · Een eerste geautomatiseerde verwerking
theme: kopie van een woordenboek, verrijken

## Opgave
1. Selecteer de rijen **zonder afwijking** in een lijst `geldig`.
2. Voeg aan elk `bronbestand` (het pad) en `gewest` toe: `"Brussel"`, `"Vlaanderen"` of `"Wallonië"`, afgeleid uit de naam van het bestand.
3. Controleer dat voor elk bestand geldt: gelezen rijen = geldige rijen + afwijkende rijen.
4. Toon op de laatste regel het aantal geldige rijen.

## Hint
Een correspondentiewoordenboek vermijdt drie `if`'s: `gewesten = {"brussel": "Brussel", ...}`, en zoek dan met `in` welke sleutel in het pad staat.

## Voorbereiding
```python
from outils_cursus import laad_rijen
bestanden = ["gegevens/bevolking_brussel_2026.csv",
             "gegevens/bevolking_vlaanderen_2026.xlsx",
             "gegevens/bevolking_wallonie_2026.txt"]
```

## Oplossing
```python
gewesten = {"brussel": "Brussel", "vlaanderen": "Vlaanderen", "wallonie": "Wallonië"}
geldig = []
for pad in bestanden:
    gelezen = laad_rijen(pad)
    n_nok = 0
    for rij in gelezen:
        bev = rij["bevolking"]
        if (rij["geslacht"] not in ("M", "V") or bev is None or bev < 0
                or len(rij["nis_code"]) != 5):
            n_nok += 1
            continue
        nieuw = dict(rij)
        nieuw["bronbestand"] = pad
        for sleutel, naam in gewesten.items():
            if sleutel in pad:
                nieuw["gewest"] = naam
        geldig.append(nieuw)
    n_ok = sum(1 for g in geldig if g["bronbestand"] == pad)
    print(pad[9:], len(gelezen), "=", n_ok, "+", n_nok)
len(geldig)
```

## Commentaar
1 128 geldige rijen: 38 + 571 + 519. `continue` gaat meteen naar de volgende rij. `dict(rij)` maakt een **kopie**: de gelezen rij blijft intact.

# Atelier 2 · Stap 4: de twee tabellen wegschrijven
niveau: 4
groupe: Atelier 2 · Een eerste geautomatiseerde verwerking
theme: export, controle

## Opgave
De lijsten `geldig` (stap 3) en `afwijkingen` (stap 2) zijn al opgebouwd.

1. Schrijf ze weg naar `uitvoer/geldige_rijen.csv` en `uitvoer/afwijkingen.csv` (scheidingsteken `;`, zonder index) met `pd.DataFrame(lijst).to_csv(...)`.
2. Lees `uitvoer/geldige_rijen.csv` opnieuw in en toon op de laatste regel de dimensies.

## Hint
`import pandas as pd`, dan `pd.DataFrame(geldig).to_csv("uitvoer/geldige_rijen.csv", sep=";", index=False)`.

## Voorbereiding
```python
from outils_cursus import laad_rijen
bestanden = ["gegevens/bevolking_brussel_2026.csv",
             "gegevens/bevolking_vlaanderen_2026.xlsx",
             "gegevens/bevolking_wallonie_2026.txt"]
gewesten = {"brussel": "Brussel", "vlaanderen": "Vlaanderen", "wallonie": "Wallonië"}
geldig, afwijkingen = [], []
for pad in bestanden:
    for positie, rij in enumerate(laad_rijen(pad)):
        bev = rij["bevolking"]
        regels = []
        if rij["geslacht"] not in ("M", "V"):
            regels.append(("R1 geslacht", rij["geslacht"]))
        if bev is None:
            regels.append(("R2 ontbrekende bevolking", bev))
        elif bev < 0:
            regels.append(("R3 negatieve bevolking", bev))
        if len(rij["nis_code"]) != 5:
            regels.append(("R4 formaat van de code", rij["nis_code"]))
        for regel, waarde in regels:
            afwijkingen.append({"bestand": pad, "positie": positie,
                                "regel": regel, "waarde": waarde})
        if not regels:
            nieuw = dict(rij, bronbestand=pad)
            nieuw["gewest"] = [n for s, n in gewesten.items() if s in pad][0]
            geldig.append(nieuw)
```

## Oplossing
```python
import pandas as pd

pd.DataFrame(geldig).to_csv("uitvoer/geldige_rijen.csv", sep=";", index=False)
pd.DataFrame(afwijkingen).to_csv("uitvoer/afwijkingen.csv", sep=";", index=False)
herlezen = pd.read_csv("uitvoer/geldige_rijen.csv", sep=";")
herlezen.shape
```

## Commentaar
1 128 rijen en 7 kolommen: de 5 oorspronkelijke kolommen, plus `bronbestand` en `gewest`.

**Om verder te gaan**
- Tel de afwijkingen per regel in een woordenboek `{"R1 geslacht": 1, ...}`.
- Spoor de dubbel van Vlaanderen op: onthoud elke sleutel `(nis_code, geslacht)` in een verzameling van tuples en meld een sleutel die je al gezien hebt.
- Maak de lijst van bestanden automatisch: `sorted(str(p) for p in Path("gegevens").glob("bevolking_*_2026.*"))`, na `from pathlib import Path` (let op: dat patroon vindt ook de andere `bevolking_…`-bestanden; verfijn het).

# De functie harmoniseer_geslacht() schrijven
niveau: 2
groupe: Halve dag 3 · Aan jou
theme: def, return, None

## Opgave
1. Schrijf `harmoniseer_geslacht(waarde)` die `"M"` of `"V"` teruggeeft, ongeacht hoofdletters en spaties (`" v"`, `"m "`).
2. Ze geeft `None` terug voor een ontbrekende of niet-herkende waarde.
3. Test ze op de laatste regel op vier waarden: `[harmoniseer_geslacht(w) for w in ["v", " M ", "x", None]]`.

## Hint
Behandel eerst het geval `None` (met `return None`), en gebruik dan `.strip().upper()`.

## Startcode
```python
def harmoniseer_geslacht(waarde):
    ...

[harmoniseer_geslacht(w) for w in ["v", " M ", "x", None]]
```

## Oplossing
```python
def harmoniseer_geslacht(waarde):
    """Geeft 'M' of 'V' terug, of None als de waarde niet herkend wordt."""
    if waarde is None:
        return None
    waarde = waarde.strip().upper()
    if waarde in ("M", "V"):
        return waarde
    return None

[harmoniseer_geslacht(w) for w in ["v", " M ", "x", None]]
```

## Commentaar
Verwacht resultaat: `['V', 'M', None, None]`. De laatste regel is een *list comprehension*: ze past de functie toe op elke waarde, zoals een `for`-lus die een lijst zou vullen.

# De functie schrijf_resultaat() schrijven
niveau: 2
groupe: Halve dag 3 · Aan jou
theme: def, export

## Opgave
1. Schrijf `schrijf_resultaat(rijen, pad)` die een lijst van woordenboeken wegschrijft als CSV gescheiden door `;` en het **aantal weggeschreven rijen** teruggeeft.
2. Recept: `pd.DataFrame(rijen).to_csv(pad, sep=";", index=False)`.
3. Roep ze op de laatste regel op voor de geldige rijen van Wallonië (al berekend in `geldig`) met het pad `uitvoer/geldig_wallonie.csv`.

## Hint
`return len(rijen)` na de export.

## Voorbereiding
```python
import pandas as pd
from outils_cursus import laad_rijen, harmoniseer_code, harmoniseer_geslacht
geldig = []
for rij in laad_rijen("gegevens/bevolking_wallonie_2026.txt"):
    rij = dict(rij, nis_code=harmoniseer_code(rij["nis_code"]),
               geslacht=harmoniseer_geslacht(rij["geslacht"]))
    if rij["bevolking"] is not None and rij["bevolking"] >= 0:
        geldig.append(rij)
```

## Oplossing
```python
def schrijf_resultaat(rijen, pad):
    """Schrijft rijen weg als CSV (;) en geeft het aantal weggeschreven rijen terug."""
    pd.DataFrame(rijen).to_csv(pad, sep=";", index=False)
    return len(rijen)

schrijf_resultaat(geldig, "uitvoer/geldig_wallonie.csv")
```

## Commentaar
521 rijen weggeschreven. Om te controleren, lees je het bestand opnieuw in: `pd.read_csv("uitvoer/geldig_wallonie.csv", sep=";").shape`.

# Atelier 3 · Stap 1: transformeer_rij()
niveau: 3
groupe: Atelier 3 · Een herbruikbare verwerking
theme: def, datum

## Opgave
**Doel van het atelier**: een verwerking bouwen waarvan dezelfde functies op de drie bestanden toegepast worden.

Schrijf `transformeer_rij(rij)`, die een **kopie** van de rij teruggeeft met twee velden extra:

- `referentiedatum`: 1 januari van het jaar (`date(jaar, 1, 1)`);
- `grootte`: `"klein"` als de bevolking (van dat geslacht) kleiner is dan 5 000, anders `"groot"`.

Pas ze op de laatste regel toe op `{"nis_code": "62063", "gemeente": "Luik", "jaar": 2026, "geslacht": "M", "bevolking": 98484}`.

## Hint
`nieuw = dict(rij)`, twee toekenningen, `return nieuw`. Voor `grootte`: een `if` of de korte schrijfwijze `"klein" if ... else "groot"`.

## Voorbereiding
```python
from datetime import date
```

## Startcode
```python
def transformeer_rij(rij):
    nieuw = dict(rij)
    nieuw["referentiedatum"] = ...
    nieuw["grootte"] = ...
    return nieuw
```

## Oplossing
```python
def transformeer_rij(rij):
    """Kopie van de rij met referentiedatum en grootte."""
    nieuw = dict(rij)
    nieuw["referentiedatum"] = date(rij["jaar"], 1, 1)
    if rij["bevolking"] < 5000:
        nieuw["grootte"] = "klein"
    else:
        nieuw["grootte"] = "groot"
    return nieuw

transformeer_rij({"nis_code": "62063", "gemeente": "Luik", "jaar": 2026,
                  "geslacht": "M", "bevolking": 98484})
```

## Commentaar
De oorspronkelijke rij wordt niet gewijzigd: `transformeer_rij()` werkt op een kopie. Je roept deze functie alleen op voor rijen die **al gecontroleerd** zijn: op een ontbrekende bevolking zou `None < 5000` een fout geven.

# Atelier 3 · Stap 2: verwerk_bestand() op de drie bestanden
niveau: 4
groupe: Atelier 3 · Een herbruikbare verwerking
theme: functies aaneenrijgen, assert

## Opgave
De functies `harmoniseer_rij()`, `controleer_rij()` en `transformeer_rij()` zijn al gedefinieerd.

1. Schrijf `verwerk_bestand(pad)`: elke rij inlezen, harmoniseren en dan controleren; de afgewezen rijen gaan naar `afgewezen`, de andere worden getransformeerd en gaan naar `geldig`. De functie geeft `geldig, afgewezen` terug.
2. Controleer met `assert`, voor elk bestand, dat er geen enkele rij verloren gaat.
3. Toon op de laatste regel de lijst van de overzichten `[(len(geldig), len(afgewezen)), ...]` voor de drie bestanden, in de volgorde van `bestanden`.

## Hint
Het plan: `geldig, afgewezen = [], []` initialiseren; `laad_rijen(pad)` doorlopen; harmoniseren; `if controleer_rij(rij):` → afwijzen; anders transformeren en toevoegen; `return geldig, afgewezen`.

## Voorbereiding
```python
from datetime import date
from outils_cursus import laad_rijen, harmoniseer_code, harmoniseer_geslacht
bestanden = ["gegevens/bevolking_brussel_2026.csv",
             "gegevens/bevolking_vlaanderen_2026.xlsx",
             "gegevens/bevolking_wallonie_2026.txt"]

def harmoniseer_rij(rij):
    nieuw = dict(rij)
    nieuw["nis_code"] = harmoniseer_code(rij["nis_code"])
    nieuw["geslacht"] = harmoniseer_geslacht(rij["geslacht"])
    return nieuw

def controleer_rij(rij):
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

def transformeer_rij(rij):
    nieuw = dict(rij)
    nieuw["referentiedatum"] = date(rij["jaar"], 1, 1)
    nieuw["grootte"] = "klein" if rij["bevolking"] < 5000 else "groot"
    return nieuw
```

## Startcode
```python
# Plan van verwerk_bestand(pad):
# 1. geldig en afgewezen initialiseren.
# 2. laad_rijen(pad) doorlopen.
# 3. Elke rij harmoniseren en dan controleren.
# 4. De afgewezen rijen toevoegen aan afgewezen.
# 5. De andere rijen transformeren en dan toevoegen aan geldig.
# 6. geldig, afgewezen teruggeven.
```

## Oplossing
```python
def verwerk_bestand(pad):
    """Leest, harmoniseert, controleert en transformeert een bestand."""
    geldig, afgewezen = [], []
    for rij in laad_rijen(pad):
        rij = harmoniseer_rij(rij)
        if controleer_rij(rij):
            afgewezen.append(rij)
        else:
            geldig.append(transformeer_rij(rij))
    return geldig, afgewezen

overzichten = []
for pad in bestanden:
    geldig, afgewezen = verwerk_bestand(pad)
    assert len(geldig) + len(afgewezen) == len(laad_rijen(pad)), "rijen verloren"
    overzichten.append((len(geldig), len(afgewezen)))
overzichten
```

## Commentaar
Verwacht overzicht: `[(38, 0), (571, 0), (521, 2)]`. De twee afgewezen rijen zijn Daverdisse (ontbrekende bevolking) en Martelange (negatieve bevolking); de code `" 62063"` en het geslacht `"v"` worden **verbeterd**, niet afgewezen.

**Om verder te gaan**
- Schrijf je eigen versie van `laad_rijen()` op basis van de recepten van halve dag 1.
- Voeg een parameter `drempel_min=0` toe aan `controleer_rij()` om regel R3 instelbaar te maken.
- Houd een logboek bij: een woordenboek dat de afgewezen rijen per regel en per bestand telt.
- Meld de dubbel van Vlaanderen met een verzameling van al geziene sleutels `(nis_code, geslacht)`.

# De ruwe tabel inspecteren
niveau: 2
groupe: Halve dag 4 · Aan jou
theme: info, describe, unique

## Opgave
De tabel `ruw` is al ingeladen.

1. Hoeveel rijen en kolommen telt `ruw`?
2. Welke kolom bevat ontbrekende waarden, en hoeveel?
3. Welke categorieën neemt `geslacht` aan?
4. Toon op de laatste regel de kleinste bevolking. Wat betekent ze?

## Hint
`.shape`, `.info()` (of `.isna().sum()`), `.unique()`, en dan `ruw["bevolking"].min()`.

## Voorbereiding
```python
import pandas as pd
ruw = pd.read_parquet("gegevens/bevolking_ruw.parquet", dtype_backend="pyarrow")
```

## Oplossing
```python
print(ruw.shape)
print(ruw.isna().sum())
print(ruw["geslacht"].unique().tolist())
ruw["bevolking"].min()
```

## Commentaar
1 132 rijen en 6 kolommen; één ontbrekende bevolking; drie categorieën voor `geslacht` (`"M"`, `"V"` en `"v"`). Het minimum, -1 059, is onmogelijk: het is een invoerfout (Martelange, vrouwen) die je moet verwijderen en melden.

# Een gewest opschonen
niveau: 2
groupe: Halve dag 4 · Aan jou
theme: filteren, isna, str

## Opgave
1. Houd vanuit `ruw` alleen Wallonië in `wal`.
2. Tel de rijen waarvan de bevolking ontbreekt, en dan die waarvan ze negatief is.
3. Maak `schoon_wal` zonder die rijen, en harmoniseer `geslacht` met `.str.strip().str.upper()`.
4. Controleer dat `geslacht` alleen nog de waarden M en V aanneemt. Toon op de laatste regel het aantal rijen van `schoon_wal`.

## Hint
`wal["bevolking"].isna().sum()`; `(wal["bevolking"] < 0).sum()`. Om de ingevulde en positieve bevolkingscijfers te houden: `wal[wal["bevolking"].notna() & (wal["bevolking"] >= 0)]`.

## Voorbereiding
```python
import pandas as pd
ruw = pd.read_parquet("gegevens/bevolking_ruw.parquet", dtype_backend="pyarrow")
```

## Oplossing
```python
wal = ruw[ruw["gewest"] == "Wallonië"]
print(wal["bevolking"].isna().sum(), (wal["bevolking"] < 0).sum())
schoon_wal = wal[wal["bevolking"].notna() & (wal["bevolking"] >= 0)].copy()
schoon_wal["geslacht"] = schoon_wal["geslacht"].str.strip().str.upper()
print(schoon_wal["geslacht"].unique().tolist())
len(schoon_wal)
```

## Commentaar
Eén ontbrekende en één negatieve bevolking: er blijven 521 rijen van de 523. `.copy()` voorkomt de waarschuwing van pandas wanneer je een tabel wijzigt die uit een andere gehaald is.

# Atelier 4 · Stap 1: inspecteren en filteren
niveau: 3
groupe: Atelier 4 · Een opgeschoonde tabel maken
theme: inspectie, filter

## Opgave
**Doel van het atelier**: een opgeschoonde tabel maken, gedocumenteerd met een becijferd overzicht, vanuit `gegevens/bevolking_ruw.parquet`.

1. Importeer het bestand in `ruw` en inspecteer het: `shape`, `info()`, `describe()`, `unique()`.
2. Haal in `namen_arr` de rijen van het arrondissement Namen eruit: NIS-code die begint met `92`.
3. Toon op de laatste regel de dimensies van `namen_arr`.

## Hint
`ruw["nis_code"].str.startswith("92")` geeft een Series van booleans, die je tussen vierkante haken zet.

## Startcode
```python
import pandas as pd

ruw = pd.read_parquet(...)
```

## Oplossing
```python
import pandas as pd

ruw = pd.read_parquet("gegevens/bevolking_ruw.parquet", dtype_backend="pyarrow")
print(ruw.shape)
ruw.info()
print(ruw["geslacht"].unique().tolist())
namen_arr = ruw[ruw["nis_code"].str.startswith("92")]
namen_arr.shape
```

## Commentaar
Het arrondissement Namen telt 16 gemeenten, dus 32 rijen (mannen en vrouwen). De rij van Namen geschreven als `"v"` staat er wel in: de filter slaat op de code, niet op het geslacht.

# Atelier 4 · Stap 2: dubbels, harmonisatie en afwijzingen
niveau: 4
groupe: Atelier 4 · Een opgeschoonde tabel maken
theme: drop_duplicates, map, afwijzingen

## Opgave
1. Verwijder de dubbels van `ruw` in een nieuwe tabel `df` (houd het eerste exemplaar).
2. Harmoniseer `nis_code` met `.map(harmoniseer_code)` en `geslacht` met `.str`.
3. Gegeven regel: een ontbrekende of negatieve bevolking doet de rij **verwijderen**, die naar een tabel `afgewezen` gaat.
4. Toon op de laatste regel `(len(df), len(afgewezen))`.

## Hint
Bereken eerst het masker van de af te wijzen rijen: `af_te_wijzen = df["bevolking"].isna() | (df["bevolking"] < 0)`. Dan `afgewezen = df[af_te_wijzen]` en `df = df[~af_te_wijzen]`.

## Voorbereiding
```python
import pandas as pd
from outils_cursus import harmoniseer_code
ruw = pd.read_parquet("gegevens/bevolking_ruw.parquet", dtype_backend="pyarrow")
```

## Oplossing
```python
df = ruw.drop_duplicates().copy()
df["nis_code"] = df["nis_code"].map(harmoniseer_code)
df["geslacht"] = df["geslacht"].str.strip().str.upper()
af_te_wijzen = df["bevolking"].isna() | (df["bevolking"] < 0)
afgewezen = df[af_te_wijzen]
df = df[~af_te_wijzen].copy()
print(afgewezen[["nis_code", "gemeente", "geslacht", "bevolking"]])
(len(df), len(afgewezen))
```

## Commentaar
1 132 rijen gelezen, 1 dubbel verwijderd, 2 rijen afgewezen: er blijven er 1 129. Let op: `isna() | (... < 0)` werkt omdat een vergelijking met een ontbrekende waarde `<NA>` geeft, dat `|` correct combineert met `True`.

# Atelier 4 · Stap 3: types, variabelen en export
niveau: 4
groupe: Atelier 4 · Een opgeschoonde tabel maken
theme: astype, to_datetime, to_parquet

## Opgave
De opgeschoonde tabel `df` (stap 2) is klaar.

1. Zet `bevolking` om naar `int64[pyarrow]` en maak `referentiedatum` (1 januari van `jaar`) met `pd.to_datetime()`.
2. Maak `bevolking_duizend`, de bevolking in duizenden afgerond op 2 decimalen.
3. Schrijf de tabel weg naar `uitvoer/bevolking_opgeschoond.parquet` (zonder index), en lees ze opnieuw in.
4. Toon op de laatste regel de dimensies van het herlezen bestand.

## Hint
`df["jaar"].astype(str) + "-01-01"` bouwt de tekst van de datum; `df.to_parquet(pad, index=False)`; `pd.read_parquet(pad)`.

## Voorbereiding
```python
import pandas as pd
from outils_cursus import harmoniseer_code
ruw = pd.read_parquet("gegevens/bevolking_ruw.parquet", dtype_backend="pyarrow")
df = ruw.drop_duplicates().copy()
df["nis_code"] = df["nis_code"].map(harmoniseer_code)
df["geslacht"] = df["geslacht"].str.strip().str.upper()
af_te_wijzen = df["bevolking"].isna() | (df["bevolking"] < 0)
afgewezen = df[af_te_wijzen]
df = df[~af_te_wijzen].copy()
```

## Oplossing
```python
df["bevolking"] = df["bevolking"].astype("int64[pyarrow]")
df["referentiedatum"] = pd.to_datetime(df["jaar"].astype(str) + "-01-01")
df["bevolking_duizend"] = (df["bevolking"] / 1000).round(2)
df.to_parquet("uitvoer/bevolking_opgeschoond.parquet", index=False)
afgewezen.to_csv("uitvoer/afgewezen.csv", sep=";", index=False)
herlezen = pd.read_parquet("uitvoer/bevolking_opgeschoond.parquet", dtype_backend="pyarrow")
print(herlezen.dtypes)
herlezen.shape
```

## Commentaar
1 129 rijen en 8 kolommen, dezelfde types na het herlezen: dat is het voordeel van Parquet. De tabel is **opgeschoond, niet volledig**: Daverdisse en Martelange hebben nog maar één rij op twee. Dat controleer je in halve dag 5.

**Om verder te gaan**
- Schrijf `opschonen(df)` die de opgeschoonde tabel, de afgewezen rijen en het overzicht teruggeeft.
- Voeg aan de afgewezen rijen een kolom `reden` toe: « ontbrekende bevolking » of « negatieve bevolking ».
- Vergelijk met de uitvoer van atelier 3: welk verschil, en waarom? (hint: de dubbel van Gent).

# Aggregaten per gewest en per geslacht
niveau: 2
groupe: Halve dag 5 · Aan jou
theme: groupby, agg

## Opgave
De opgeschoonde tabel `schoon` is ingeladen.

1. Bereken de totale bevolking per gewest, in dalende volgorde gesorteerd.
2. Bereken voor elk gewest de bevolking van de vrouwen en de totale bevolking.
3. Toon op de laatste regel het aandeel vrouwen per gewest, in %, afgerond op 1 decimaal.

## Hint
Filter de vrouwen **vóór** het groeperen: `schoon[schoon["geslacht"] == "V"].groupby("gewest")["bevolking"].sum()`. Twee Series met dezelfde index (de gewesten) kun je rechtstreeks delen.

## Voorbereiding
```python
import pandas as pd
schoon = pd.read_parquet("gegevens/bevolking_opgeschoond.parquet", dtype_backend="pyarrow")
```

## Oplossing
```python
totaal = schoon.groupby("gewest")["bevolking"].sum()
print(totaal.sort_values(ascending=False))
vrouwen = schoon[schoon["geslacht"] == "V"].groupby("gewest")["bevolking"].sum()
(vrouwen / totaal * 100).round(1)
```

## Commentaar
51,0 % vrouwen in Brussel en in Wallonië, 50,5 % in Vlaanderen. Vlaanderen is veruit het gewest met de meeste inwoners: 6,9 miljoen.

# Opsporen wat niet gekoppeld is
niveau: 3
groupe: Halve dag 5 · Aan jou
theme: merge, indicator

## Opgave
De tabel `schoon` en de tabel `geldig` (de geldige gemeenten van de nomenclatuur, met `nis_code` en `nuts3`) zijn ingeladen.

1. Koppel `schoon` aan `geldig` met `how="inner"`, en dan met `how="left"`: vergelijk het aantal rijen.
2. Toon met `indicator=True` op de laatste regel de lijst van de niet-gekoppelde NIS-codes.

## Hint
`controle["_merge"] == "left_only"`, dan `.unique().tolist()` op de kolom `nis_code`.

## Voorbereiding
```python
import pandas as pd
schoon = pd.read_parquet("gegevens/bevolking_opgeschoond.parquet", dtype_backend="pyarrow")
ref = pd.read_csv("referenties/nuts_lau_2027.txt", sep="|", encoding="cp1252",
                  dtype_backend="pyarrow")
geldig = (ref[(ref["CD_LVL"] == 4) & (ref["DT_VLDT_STOP"] == "31/12/9999")]
          .rename(columns={"CD_MUNTY_REFNIS": "nis_code", "CD_LVL_SUP": "nuts3"})
          [["nis_code", "nuts3"]])
```

## Oplossing
```python
print(len(schoon.merge(geldig, on="nis_code", how="inner")),
      len(schoon.merge(geldig, on="nis_code", how="left")))
controle = schoon.merge(geldig, on="nis_code", how="left",
                        indicator=True, validate="many_to_one")
controle.loc[controle["_merge"] == "left_only", "nis_code"].unique().tolist()
```

## Commentaar
1 128 rijen met `inner`, 1 129 met `left`: de rij van de gemeente « 99999 » bestaat niet in de nomenclatuur. Ze moet gemeld worden aan de bron van de gegevens, niet stilletjes verwijderd.

# Syntheseatelier · Stap 1: importeren en stapelen
niveau: 3
groupe: Syntheseatelier · Volledige consolidatie
theme: read_*, concat

## Opgave
**Doel van het atelier**: alle stappen van de opleiding na elkaar uitvoeren, van de ruwe bestanden tot het geconsolideerde bestand.

1. Importeer de drie gewestelijke bestanden met de juiste instellingen (`nis_code` als tekst), en voeg aan elk een kolom `gewest` toe.
2. Stapel ze in `gestapeld` en controleer de structuur: kolommen, types, aantal rijen.
3. Toon op de laatste regel `(len(gestapeld), gestapeld["gewest"].nunique())`.

## Hint
`bxl["gewest"] = "Brussel"` voegt een constante kolom toe. `pd.concat([bxl, vla, wal], ignore_index=True)`.

## Oplossing
```python
import pandas as pd

bxl = pd.read_csv("gegevens/bevolking_brussel_2026.csv", sep=";",
                  dtype={"nis_code": str}, dtype_backend="pyarrow")
vla = pd.read_excel("gegevens/bevolking_vlaanderen_2026.xlsx", header=2,
                    dtype={"nis_code": str}, dtype_backend="pyarrow")
wal = pd.read_csv("gegevens/bevolking_wallonie_2026.txt", sep="\t",
                  dtype={"nis_code": str}, dtype_backend="pyarrow")
bxl["gewest"] = "Brussel"
vla["gewest"] = "Vlaanderen"
wal["gewest"] = "Wallonië"
gestapeld = pd.concat([bxl, vla, wal], ignore_index=True)
print(gestapeld.dtypes)
(len(gestapeld), gestapeld["gewest"].nunique())
```

## Commentaar
1 132 rijen (38 + 571 + 523) en 3 gewesten: dat is precies de inhoud van `bevolking_ruw.parquet`.

# Syntheseatelier · Stap 2: opschonen en koppelen
niveau: 4
groupe: Syntheseatelier · Volledige consolidatie
theme: opschoning, merge, controles

## Opgave
`gestapeld` is klaar (stap 1), net als `geldig` (de geldige gemeenten van de nomenclatuur).

1. Schoon op met de regels van atelier 3 en 4: dubbels, `nis_code` en `geslacht` geharmoniseerd, ontbrekende of negatieve bevolkingscijfers verwijderd.
2. Koppel `geldig` (`how="left"`, `indicator=True`, `validate="many_to_one"`).
3. Controleer dat de koppeling noch het aantal rijen, noch het totaal van de bevolking verandert.
4. Toon op de laatste regel `(len(geconsolideerd), n_niet_gekoppeld)`, waarbij `n_niet_gekoppeld` het aantal rijen `left_only` is.

## Hint
Neem stap 2 van atelier 4 over voor het opschonen. Om te tellen: `(geconsolideerd["_merge"] == "left_only").sum()`.

## Voorbereiding
```python
import pandas as pd
from outils_cursus import harmoniseer_code
gestapeld = pd.read_parquet("gegevens/bevolking_ruw.parquet", dtype_backend="pyarrow")
ref = pd.read_csv("referenties/nuts_lau_2027.txt", sep="|", encoding="cp1252",
                  dtype_backend="pyarrow")
geldig = (ref[(ref["CD_LVL"] == 4) & (ref["DT_VLDT_STOP"] == "31/12/9999")]
          .rename(columns={"CD_MUNTY_REFNIS": "nis_code", "CD_LVL_SUP": "nuts3"})
          [["nis_code", "nuts3"]])
```

## Oplossing
```python
df = gestapeld.drop_duplicates().copy()
df["nis_code"] = df["nis_code"].map(harmoniseer_code)
df["geslacht"] = df["geslacht"].str.strip().str.upper()
df = df[df["bevolking"].notna() & (df["bevolking"] >= 0)].copy()
df["bevolking"] = df["bevolking"].astype("int64[pyarrow]")

geconsolideerd = df.merge(geldig, on="nis_code", how="left",
                          indicator=True, validate="many_to_one")
assert len(geconsolideerd) == len(df), "rijen toegevoegd door de koppeling"
assert geconsolideerd["bevolking"].sum() == df["bevolking"].sum(), "totaal gewijzigd"
n_niet_gekoppeld = int((geconsolideerd["_merge"] == "left_only").sum())
(len(geconsolideerd), n_niet_gekoppeld)
```

## Commentaar
1 129 rijen, waarvan 1 niet gekoppeld (« 99999 »). De twee `assert`'s zijn **automatische** controles: als een volgende levering een dubbele sleutel bevat, stopt de verwerking in plaats van foute totalen te maken.

# Syntheseatelier · Stap 3: de volledigheid controleren
niveau: 4
groupe: Syntheseatelier · Volledige consolidatie
theme: groupby, size

## Opgave
Elke gemeente moet **2 rijen** tellen (mannen en vrouwen). Toon voor de tabel `geconsolideerd` (stap 2) op de laatste regel de gesorteerde lijst van de NIS-codes van de gemeenten die geen 2 rijen hebben.

## Hint
`geconsolideerd.groupby("nis_code").size()` geeft het aantal rijen per gemeente; houd die met `!= 2`, dan `sorted(... .index)`.

## Voorbereiding
```python
import pandas as pd
from outils_cursus import harmoniseer_code
df = pd.read_parquet("gegevens/bevolking_opgeschoond.parquet", dtype_backend="pyarrow")
ref = pd.read_csv("referenties/nuts_lau_2027.txt", sep="|", encoding="cp1252",
                  dtype_backend="pyarrow")
geldig = (ref[(ref["CD_LVL"] == 4) & (ref["DT_VLDT_STOP"] == "31/12/9999")]
          .rename(columns={"CD_MUNTY_REFNIS": "nis_code", "CD_LVL_SUP": "nuts3"})
          [["nis_code", "nuts3"]])
geconsolideerd = df.merge(geldig, on="nis_code", how="left",
                          indicator=True, validate="many_to_one")
```

## Oplossing
```python
rijen = geconsolideerd.groupby("nis_code").size()
onvolledig = rijen[rijen != 2]
print(geconsolideerd[geconsolideerd["nis_code"].isin(onvolledig.index)][["nis_code", "gemeente", "geslacht"]])
sorted(onvolledig.index)
```

## Commentaar
Drie gemeenten: Martelange (`81013`) en Daverdisse (`84016`), waarvan één rij afgewezen is, en « 99999 », onbekend. De indicatoren van de provincies van die gemeenten slaan op onvolledige observaties: dat moet je in elke publicatie vermelden.

# Syntheseatelier · Stap 4: indicatoren per provincie en export
niveau: 5
groupe: Syntheseatelier · Volledige consolidatie
theme: agg, merge, to_parquet, DuckDB

## Opgave
1. Voeg de provincie toe aan `geconsolideerd`: `nuts2` = de eerste 4 tekens van `nuts3` (vervang eerst de ontbrekende `nuts3` van de onbekende gemeente door `"-"` met `.fillna("-")`), dan een koppeling met `provincies`; geef de rijen `BE10` de naam « Brussels Hoofdstedelijk Gewest ».
2. Bereken voor de gekoppelde rijen per provincie: `gemeenten` (aantal verschillende gemeenten), `bevolking` en `aandeel_vrouwen` (in %, 1 decimaal).
3. Schrijf `geconsolideerd` (zonder `_merge`) weg in Parquet naar `uitvoer/bevolking_geconsolideerd.parquet` en controleer met DuckDB dat de som van de bevolking dezelfde is.
4. Toon op de laatste regel de tabel van de indicatoren.

## Hint
`.str.slice(0, 4)`; `agg(gemeenten=("nis_code", "nunique"), bevolking=("bevolking", "sum"))`; voor de vrouwen filter je `geslacht == "V"` en groepeer je daarna. In SQL: `SELECT SUM(bevolking) FROM 'uitvoer/bevolking_geconsolideerd.parquet'`.

## Voorbereiding
```python
import pandas as pd
import duckdb
df = pd.read_parquet("gegevens/bevolking_opgeschoond.parquet", dtype_backend="pyarrow")
ref = pd.read_csv("referenties/nuts_lau_2027.txt", sep="|", encoding="cp1252",
                  dtype_backend="pyarrow")
geldig = (ref[(ref["CD_LVL"] == 4) & (ref["DT_VLDT_STOP"] == "31/12/9999")]
          .rename(columns={"CD_MUNTY_REFNIS": "nis_code", "CD_LVL_SUP": "nuts3"})
          [["nis_code", "nuts3"]])
provincies = (ref[(ref["CD_LVL"] == 2) & (ref["DT_VLDT_STOP"] == "31/12/9999")]
              .rename(columns={"CD_LAU": "nuts2", "TX_DESCR_NL": "provincie"})
              [["nuts2", "provincie"]])
geconsolideerd = df.merge(geldig, on="nis_code", how="left",
                          indicator=True, validate="many_to_one")
```

## Oplossing
```python
geconsolideerd["nuts2"] = geconsolideerd["nuts3"].fillna("-").str.slice(0, 4)
geconsolideerd = geconsolideerd.merge(provincies, on="nuts2", how="left", validate="many_to_one")
geconsolideerd.loc[geconsolideerd["nuts2"] == "BE10", "provincie"] = "Brussels Hoofdstedelijk Gewest"

ok = geconsolideerd[geconsolideerd["_merge"] == "both"]
indic = ok.groupby("provincie").agg(gemeenten=("nis_code", "nunique"),
                                    bevolking=("bevolking", "sum"))
vrouwen = ok[ok["geslacht"] == "V"].groupby("provincie")["bevolking"].sum()
indic["aandeel_vrouwen"] = (vrouwen / indic["bevolking"] * 100).round(1)

geconsolideerd.drop(columns="_merge").to_parquet("uitvoer/bevolking_geconsolideerd.parquet", index=False)
totaal_sql = duckdb.sql("SELECT SUM(bevolking) AS b FROM 'uitvoer/bevolking_geconsolideerd.parquet'").fetchone()[0]
assert totaal_sql == geconsolideerd["bevolking"].sum()
indic
```

## Commentaar
Elf rijen: de tien provincies en het Brussels Hoofdstedelijk Gewest. Het aandeel vrouwen gaat van 50,2 % (Limburg, Luxemburg) tot 51,5 % (Waals-Brabant). Luxemburg, onvolledig, moet je voorzichtig interpreteren.

**Om verder te gaan**
- Schrijf `consolideer(bestanden, pad_ref)` die de stappen na elkaar uitvoert en de tabel, de indicatoren en het overzicht teruggeeft.
- Bereken de indicatoren opnieuw met een DuckDB-query en vergelijk met de pandas-`groupby()`.
- Voeg het gewest toe op basis van de NUTS-code: de eerste 3 tekens van `nuts3` (`BE1`, `BE2`, `BE3`).
