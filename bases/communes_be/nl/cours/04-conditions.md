---
titre: Voorwaardelijke structuren
resume: if, elif en else; het inspringen; voorwaarden combineren en een ontbrekende waarde behandelen; validatieregels.
partie: Halve dag 2 · Voorwaarden en lussen
---

# Halve dag 2: voorwaarden en lussen

**Na deze sessie kun je**

- voorwaarden schrijven met `if`, `elif` en `else` om een waarde te valideren of in te delen;
- booleaanse uitdrukkingen combineren en een ontbrekende waarde behandelen;
- een verwerking herhalen met `for` en `while`, `range()` en `enumerate()`;
- meerdere bestanden doorlopen en een overzicht van de afwijkingen maken.

**De rode draad van halve dag 2 tot 5**: Statbel levert de bevolking per gemeente en per geslacht in drie bestanden, één per gewest, in drie formaten.

| Bestand | Gewest | Formaat |
|---|---|---|
| `gegevens/bevolking_brussel_2026.csv` | Brussel | CSV, scheidingsteken `;` |
| `gegevens/bevolking_vlaanderen_2026.xlsx` | Vlaanderen | Excel, twee titelregels |
| `gegevens/bevolking_wallonie_2026.txt` | Wallonië | tekst met tabs |

De cijfers zijn die van Statbel. **Er zijn opzettelijk enkele afwijkingen toegevoegd**, om ze te leren opsporen: een geslacht in kleine letters, een code met een spatie, een ontbrekende bevolking, een negatieve bevolking, een dubbele rij en een onbekende gemeente.

# if, elif, else: handelen volgens een voorwaarde

`if` voert een blok uit als de voorwaarde waar is; `elif` test een andere voorwaarde; `else` dekt alle andere gevallen.

De regel eindigt op `:` en het blok **springt in** met 4 spaties.

De voorwaarden worden in volgorde getest: alleen het eerste ware blok wordt uitgevoerd.

```python
bevolking = 198102          # Luik

if bevolking < 5000:
    grootte = "klein"
elif bevolking < 50000:
    grootte = "middelgroot"
else:
    grootte = "groot"
print(grootte)
```

::: sas
De logica is die van `IF ... THEN ...; ELSE IF ...; ELSE ...;`. Python vervangt `THEN` door `:` en bakent de blokken af met inspringing in plaats van met `DO; ... END;`.
:::

# Inspringen hoort bij de syntaxis

In Python is inspringen geen opmaak: het **bakent de blokken af**.

Alles wat onder `if` inspringt, hangt af van de voorwaarde; terug naar de kantlijn beëindigt het blok.

```python
bevolking = -1059
if bevolking < 0:
    print("negatieve waarde")
print("controle beëindigd")      # buiten het blok: altijd uitgevoerd
```

**Bewuste fout**: het blok springt niet in.

```python erreur
if bevolking < 0:
print("negatieve waarde")
```

De editor van het atelier springt, net als JupyterLab, automatisch in na `:`. Houd 4 spaties per niveau.

# Voorwaarden combineren en een ontbrekende waarde behandelen

`and`, `or`, `not` combineren voorwaarden; `in` controleert een toegelaten categorie.

`None` betekent « geen waarde ». Je test het met `is None` of `is not None`.

Test de afwezigheid van een waarde **vóór** je vergelijkt: Python stopt zodra het resultaat van een `and` gekend is.

```python
geslacht = "v"
bevolking = None

geslacht_geldig = geslacht in ("M", "V")
bevolking_geldig = bevolking is not None and bevolking >= 0
print(geslacht_geldig, bevolking_geldig)

if not geslacht_geldig or not bevolking_geldig:
    print("rij te controleren")
```

::: sas
In SAS is een ontbrekende waarde (`.`) kleiner dan elk getal: `if bevolking < 0` houdt ze. In Python geeft het vergelijken van `None` met een getal een fout `TypeError`: test eerst de afwezigheid van een waarde.
:::

# Validatieregels toepassen op een rij

Vier regels, die we de hele dag zullen hergebruiken:

- **R1** · `geslacht` is M of V
- **R2** · `bevolking` is ingevuld
- **R3** · `bevolking` is positief of nul
- **R4** · `nis_code` telt 5 tekens

Elke regel die niet nageleefd wordt, voegt een label toe aan de lijst `afwijkingen`. De rij hieronder komt uit het Waalse bestand: haar code heeft een spatie vooraan.

```python
rij = {"nis_code": " 62063", "gemeente": "Luik", "jaar": 2026,
       "geslacht": "M", "bevolking": 98484}
afwijkingen = []
if rij["geslacht"] not in ("M", "V"):
    afwijkingen.append("R1 geslacht")
if rij["bevolking"] is None:
    afwijkingen.append("R2 ontbrekende bevolking")
elif rij["bevolking"] < 0:
    afwijkingen.append("R3 negatieve bevolking")
if len(rij["nis_code"]) != 5:
    afwijkingen.append("R4 formaat van de code")
print(afwijkingen)
```

`elif` voorkomt dat R3 getest wordt wanneer de bevolking ontbreekt: `None < 0` vergelijken zou een fout geven.
