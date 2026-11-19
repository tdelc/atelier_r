---
titre: Types en operatoren
resume: Variabelen, basistypes (getallen, tekst, booleans, datums), conversies, berekeningen en vergelijkingen.
partie: Halve dag 1 · Basis en bestanden
---

# Halve dag 1: basis en gegevensbestanden

**Na deze sessie kun je**

- variabelen aanmaken en hun type herkennen: getallen, tekst, booleans, datums;
- rekenen met rekenkundige, vergelijkings- en logische operatoren;
- lijsten, tuples, verzamelingen en woordenboeken gebruiken en er elementen uit halen;
- CSV-, Excel- en TXT-bestanden inlezen en wegschrijven met het juiste scheidingsteken, de juiste codering en kopregels.

De gegevens zijn **echt**: de bevolking van de 565 Belgische gemeenten op 1 januari 2026 en de nomenclatuur van de gebieden (NUTS-codes), gepubliceerd door Statbel.

::: note
**Python draait in je browser.** De eerste keer duurt het een tiental seconden om Python en zijn pakketten te laden. De kaarten worden in volgorde uitgevoerd, zoals de cellen van een notebook: een variabele die in een kaart is aangemaakt, is beschikbaar in de volgende. Om een voorbeeld aan te passen, klik je op **Deze code aanpassen in Ontdekken**.
:::

# Een variabele is een naam die naar een waarde verwijst

Het teken `=` **kent** een waarde toe aan een naam: het test geen gelijkheid.

Een variabelenaam schrijf je in kleine letters, cijfers en `_`, zonder spatie en liefst zonder accent (`bev_2026`).

`print()` toont waarden. Zoals in een notebook wordt de **laatste regel** van een cel ook getoond, zonder `print()`.

```python
jaar = 2026
gemeente = "Luik"
nis_code = "62063"
bevolking = 198102
print(gemeente, nis_code, jaar, bevolking)

bevolking = bevolking + 10    # we kennen opnieuw toe
bevolking
```

::: sas
In SAS is een variabele een kolom van een tabel. In Python is een variabele een naam die naar een getal, een tekst, een lijst of een hele tabel kan verwijzen.
:::

# Vier basistypes: int, float, str en bool

`type()` geeft het type van een waarde. Het type bepaalt welke bewerkingen mogelijk zijn.

| Type | Betekenis | Voorbeeld | Gebruik |
|---|---|---|---|
| `int` | geheel getal | `198102` | aantallen, jaren |
| `float` | decimaal getal | `69.4` | oppervlaktes, percentages |
| `str` | tekst | `"62063"` | codes, labels |
| `bool` | waar of onwaar | `True` | resultaat van een controle |

```python
bevolking = 198102      # int
oppervlakte = 69.4      # float: decimale punt (km², afgeronde waarde)
nis_code = "62063"      # str: tussen aanhalingstekens
is_stad = True          # bool
print(type(bevolking), type(oppervlakte))
print(type(nis_code), type(is_stad))
```

::: piege
**Een code is geen getal.** De NIS-code van de gemeente staat tussen aanhalingstekens: je rekent er niet mee, en sommige codes beginnen met een nul (`"04000"` voor het Brussels Hoofdstedelijk Gewest). Als getal geschreven zou `04000` zijn nul verliezen.
:::

# Datums: het type date van de module datetime

We importeren het type `date` uit de module `datetime`.

Een datum kent zijn jaar, maand en dag; je kunt het verschil tussen twee datums berekenen.

In een bestand wordt een datum vaak als tekst gelezen: dat is het geval voor de geldigheidsdatums van de NUTS-nomenclatuur (`"01/01/2019"`). Je zult ze moeten omzetten (halve dag 4).

```python
from datetime import date
referentie = date(2026, 1, 1)     # datum van de bevolkingscijfers
print(referentie)
print(referentie.year, referentie.month)
einde = date(2026, 12, 31)
print(einde - referentie)          # verschil in dagen
```

::: sas
In SAS is een datum een aantal dagen sinds 1 januari 1960, leesbaar dankzij een formaat. In Python is een datum een object dat rechtstreeks in het formaat JJJJ-MM-DD verschijnt.
:::

# Een waarde van het ene type naar het andere omzetten

Een waarde die uit een bestand gelezen wordt, is vaak **tekst**, ook al lijkt ze op een getal. In het bestand van Statbel staat de bevolking van Luik als `198.102`, met een punt om de duizendtallen te scheiden.

`int()`, `float()` en `str()` zetten een waarde om. Een onmogelijke omzetting geeft een fout `ValueError`: dat is een nuttig signaal, geen mislukking.

**Bewuste fout**: de laatste regel kan niet omgezet worden. Lees de laatste regel van de melding.

```python erreur
tekst = "198.102"                 # zoals in het bestand van Statbel
print(tekst + "0")                # teksten worden aan elkaar geplakt
print(float(tekst))               # valkuil: het punt wordt als decimaalteken gelezen
getal = int(tekst.replace(".", ""))
print(getal + 10)
print(str(2026) + "-K1")
int("198 102")                    # spatie: omzetting onmogelijk
```

::: piege
`float("198.102")` geeft **geen** fout: Python leest `198,102`, dus iets minder dan 200. Een stille fout is gevaarlijker dan een foutmelding: bij het inlezen van het bestand zul je zien hoe je pandas vertelt dat het punt de duizendtallen scheidt.
:::

# Rekenen: de rekenkundige operatoren

| Operator | Rol | Voorbeeld → resultaat |
|---|---|---|
| `+` | optelling | `98484 + 99618` → `198102` |
| `-` | aftrekking | `99618 - 98484` → `1134` |
| `*` | vermenigvuldiging | `2.5 * 4` → `10.0` |
| `/` | deling | `7 / 2` → `3.5` |
| `//` | gehele deling | `7 // 2` → `3` |
| `%` | rest van de deling | `7 % 2` → `1` |
| `**` | macht | `1.02 ** 2` → `1.0404` |

De bevolking van Luik op 1 januari 2026:

```python
mannen = 98484
vrouwen = 99618
totaal = mannen + vrouwen
aandeel_vrouwen = vrouwen / totaal * 100
print(totaal)
print(round(aandeel_vrouwen, 1))
print(totaal // 1000, "duizend en", totaal % 1000)
```

**Interpretatie:** Luik telt 198 102 inwoners, waarvan 50,3 % vrouwen.

# Vergelijken en voorwaarden combineren

Vergelijking: `==` gelijk, `!=` verschillend, `<`, `<=`, `>`, `>=`. Het resultaat is een boolean (`True` of `False`).

Combinatie: `and` (allebei), `or` (minstens één), `not` (het omgekeerde).

`in` test of iets tot een lijst of een tekst behoort.

```python
bevolking = 198102
print(bevolking >= 0 and bevolking < 1_000_000)
gewest = "Wallonië"
print(gewest == "Wallonië" or gewest == "Vlaanderen")
print(gewest in ["Brussel", "Vlaanderen", "Wallonië"])
print(not bevolking > 100000)
print("Luik" in "Arrondissement Luik")
```

`1_000_000` schrijf je met `_` om het leesbaar te maken: Python negeert ze.

::: sas
SAS aanvaardt `=` of `EQ` om te vergelijken. Python maakt het onderscheid tussen `=` (toekennen) en `==` (vergelijken): ze verwarren is in het begin de meest voorkomende fout.
:::
