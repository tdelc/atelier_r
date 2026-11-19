---
base: communes_py
---

# De gemeenten van de provincie Namen
niveau: 1
theme: query + len

## Opgave
Hoeveel gemeenten telt de provincie Namen?

## Hint
Filter met `query()` (de naam van de provincie tussen enkele aanhalingstekens), en tel dan de rijen met `len()`.

## Startcode
```python
len(gemeenten.query(...))
```

## Oplossing
```python
len(gemeenten.query("provincie == 'Namen'"))
```

## Commentaar
38 gemeenten. `gemeenten["provincie"].value_counts()` geeft het antwoord voor alle provincies tegelijk.

# De bevolking van het Waals Gewest
niveau: 1
theme: query + sum

## Opgave
Wat is de totale bevolking van Wallonië op 1 januari 2026?

## Hint
Filter het gewest, neem de kolom `totaal`, en maak dan de som.

## Oplossing
```python
gemeenten.query("gewest == 'Wallonië'")["totaal"].sum()
```

## Commentaar
3 713 450 inwoners. We vinden precies het cijfer terug dat Statbel voor het Waals Gewest publiceert: de tabel is volledig.

# De grote steden van Vlaanderen
niveau: 1
theme: query + kolommen

## Opgave
Toon de naam en de bevolking van de Vlaamse gemeenten met meer dan 100 000 inwoners.

## Hint
Twee voorwaarden met `and`, dan `[["gemeente", "totaal"]]`.

## Oplossing
```python
gemeenten.query("gewest == 'Vlaanderen' and totaal > 100000")[["gemeente", "totaal"]]
```

## Commentaar
Vier steden: Antwerpen (565 615 inwoners, de grootste gemeente van het land), Gent, Brugge en Leuven. Mechelen blijft met 90 355 inwoners onder de drempel.

# De kleinste gemeente van elk gewest
niveau: 1
theme: nsmallest

## Opgave
Wat is de kleinste gemeente van Wallonië? Toon haar naam en haar bevolking.

## Hint
Filter het gewest, dan `nsmallest(1, "totaal")`.

## Oplossing
```python
gemeenten.query("gewest == 'Wallonië'").nsmallest(1, "totaal")[["gemeente", "totaal"]]
```

## Commentaar
Daverdisse (provincie Luxemburg), 1 397 inwoners. In Vlaanderen is het Herstappe, de kleinste gemeente van België met 78 inwoners.

# Hoeveel gemeenten met minder dan 5 000 inwoners?
niveau: 1
theme: query + len

## Opgave
Hoeveel Belgische gemeenten tellen minder dan 5 000 inwoners?

## Oplossing
```python
len(gemeenten.query("totaal < 5000"))
```

## Commentaar
66 gemeenten. `gemeenten.query("totaal < 5000").shape[0]` geeft hetzelfde resultaat: `shape[0]` is het aantal rijen.

# De gemeenten met « Sint » in hun naam
niveau: 1
theme: query + str.contains

## Opgave
Hoeveel gemeenten hebben « Sint » in hun naam?

## Hint
`gemeente.str.contains('Sint')` in `query()`.

## Oplossing
```python
len(gemeenten.query("gemeente.str.contains('Sint')"))
```

## Commentaar
16 gemeenten. Let op de hoofdletters: `'sint'` in kleine letters zou niets vinden. Om hoofdletters te negeren: `gemeente.str.contains('sint', case=False)`.

# Het aantal gemeenten per provincie
niveau: 2
theme: groupby + size

## Opgave
Bereken het aantal gemeenten van elke provincie, als tabel (een kolom `provincie`, een kolom met het aantal).

## Hint
`groupby("provincie", as_index=False)` en dan `.size()`.

## Oplossing
```python
gemeenten.groupby("provincie", as_index=False).size()
```

## Commentaar
De provincie Luik heeft de meeste gemeenten (84), Waals-Brabant de minste (27), de 19 gemeenten van Brussel-Hoofdstad niet meegerekend. `gemeenten["provincie"].value_counts()` geeft dezelfde cijfers, gesorteerd.

# Bevolking en mediane grootte per gewest
niveau: 2
theme: groupby + agg

## Opgave
Bereken voor elk gewest de totale bevolking (`bevolking`) en de mediane bevolking van een gemeente (`mediaan`).

## Hint
`.agg(bevolking=("totaal", "sum"), mediaan=("totaal", "median"))`.

## Oplossing
```python
(gemeenten
 .groupby("gewest", as_index=False)
 .agg(bevolking=("totaal", "sum"),
      mediaan=("totaal", "median")))
```

## Commentaar
De mediaangemeente telt 8 719 inwoners in Wallonië, 16 742 in Vlaanderen en 49 638 in Brussel. De kolomnamen mogen van de jouwe verschillen: de controle vergelijkt de waarden.

# De dichtstbevolkte arrondissementen
niveau: 2
theme: groupby + sort_values + head

## Opgave
Welke zijn de 5 arrondissementen met de meeste inwoners? Toon hun naam en hun bevolking, van groot naar klein.

## Oplossing
```python
(gemeenten
 .groupby("arrondissement", as_index=False)
 .agg(bevolking=("totaal", "sum"))
 .sort_values("bevolking", ascending=False)
 .head(5))
```

## Commentaar
Brussel-Hoofdstad, Antwerpen, Halle-Vilvoorde, Luik en Gent. `.nlargest(5, "bevolking")` vervangt `sort_values` + `head`.

# De provincies met meer dan een miljoen inwoners
niveau: 2
theme: groupby + query erna

## Opgave
Welke provincies tellen meer dan een miljoen inwoners? (Brussel-Hoofdstad telt hier als een provincie.)

## Hint
De filter slaat op een **berekend** resultaat: hij komt na de groepering.

## Oplossing
```python
(gemeenten
 .groupby("provincie", as_index=False)
 .agg(bevolking=("totaal", "sum"))
 .query("bevolking > 1000000"))
```

## Commentaar
Zeven: Antwerpen, Brussel-Hoofdstad, Henegouwen, Luik, Oost-Vlaanderen, Vlaams-Brabant en West-Vlaanderen.

# De gemeenten met meer dan 20 000 inwoners per gewest
niveau: 2
theme: query en dan groupby

## Opgave
Hoeveel gemeenten tellen, voor elk gewest, meer dan 20 000 inwoners?

## Oplossing
```python
(gemeenten
 .query("totaal > 20000")
 .groupby("gewest", as_index=False)
 .size())
```

## Commentaar
Alle Brusselse gemeenten (19), 111 in Vlaanderen, 42 in Wallonië. Hier slaat de filter op de gemeenten: hij komt **vóór** de groepering.

# Het aandeel vrouwen in elke gemeente
niveau: 3
theme: nieuwe kolom

## Opgave
Maak de kolom `aandeel_vrouwen` (in %, afgerond op 1 decimaal), en toon dan de 3 gemeenten waar het aandeel het hoogst is, met hun naam en `aandeel_vrouwen`.

## Oplossing
```python
gemeenten["aandeel_vrouwen"] = (gemeenten["vrouwen"] / gemeenten["totaal"] * 100).round(1)
gemeenten.nlargest(3, "aandeel_vrouwen")[["gemeente", "aandeel_vrouwen"]]
```

## Commentaar
Drie Brusselse gemeenten: Watermaal-Bosvoorde (53,8 %), Ukkel (53,5 %) en Sint-Lambrechts-Woluwe (53,4 %). Vrouwen leven langer: gemeenten met een oudere bevolking tellen meer vrouwen.

# De gemeenten waar de mannen in de meerderheid zijn
niveau: 3
theme: variabele waar / onwaar

## Opgave
Maak een kolom `meer_mannen` (waar als de gemeente meer mannen dan vrouwen telt), en bereken dan **het aantal** van die gemeenten.

## Hint
Een vergelijking maakt een kolom `True` / `False`; `.sum()` telt de `True`.

## Oplossing
```python
gemeenten["meer_mannen"] = gemeenten["mannen"] > gemeenten["vrouwen"]
gemeenten["meer_mannen"].sum()
```

## Commentaar
113 van de 565 gemeenten tellen meer mannen dan vrouwen, ongeveer één op vijf. Twee gemeenten, Modave en Peer, hebben precies evenveel mannen als vrouwen.

# Grootteklassen
niveau: 3
theme: pd.cut + value_counts

## Opgave
Maak de kolom `grootte` met drie klassen: minder dan 10 000 inwoners, van 10 000 tot 50 000, meer dan 50 000. Tel de gemeenten van elke klasse, in de volgorde van de klassen.

## Hint
`pd.cut(gemeenten["totaal"], bins=[0, 10000, 50000, 600000], labels=[...])`, dan `.value_counts().sort_index()`.

## Oplossing
```python
gemeenten["grootte"] = pd.cut(gemeenten["totaal"], bins=[0, 10000, 50000, 600000],
                              labels=["< 10 000", "10 000 tot 50 000", "50 000 en +"])
gemeenten["grootte"].value_counts().sort_index()
```

## Commentaar
203 gemeenten met minder dan 10 000 inwoners, 330 tussen 10 000 en 50 000, 32 daarboven. Een gemeente met precies 10 000 inwoners zou in de eerste klasse vallen: de rechtergrens is inbegrepen.

# Het gewicht van elke gemeente in haar provincie
niveau: 3
theme: groupby + transform

## Opgave
Bereken voor elke gemeente haar aandeel in de bevolking van haar provincie (in %, 1 decimaal), in een kolom `aandeel_provincie`. Toon daarna de gemeente die het zwaarst weegt in de provincie Luxemburg.

## Hint
`gemeenten.groupby("provincie")["totaal"].transform("sum")` geeft de bevolking van de provincie op elke rij.

## Oplossing
```python
gemeenten["aandeel_provincie"] = (gemeenten["totaal"]
                                  / gemeenten.groupby("provincie")["totaal"].transform("sum")
                                  * 100).round(1)
gemeenten.query("provincie == 'Luxemburg'").nlargest(1, "aandeel_provincie")[["gemeente", "aandeel_provincie"]]
```

## Commentaar
Aarlen, met 10,6 % van de bevolking van de provincie. Geen enkele gemeente domineert Luxemburg: vergelijk met Antwerpen, dat 29,3 % van zijn provincie weegt.

# Mannen en vrouwen per gewest, in kolommen
niveau: 4
theme: pivot_table

## Opgave
Bereken met de tabel `bevolking_geslacht` de bevolking per gewest (in rijen) en per geslacht (in kolommen).

## Hint
`pivot_table(index=..., columns=..., values="bevolking", aggfunc="sum")`.

## Oplossing
```python
bevolking_geslacht.pivot_table(index="gewest", columns="geslacht", values="bevolking", aggfunc="sum")
```

## Commentaar
In de drie gewesten zijn er meer vrouwen dan mannen. Met `margins=True` voeg je de totalen toe.

# Naar het lange formaat
niveau: 4
theme: melt

## Opgave
Bouw met `gemeenten` een lange tabel met één rij per gemeente en per geslacht: kolommen `nis_code`, `gemeente`, `geslacht` (`mannen` of `vrouwen`) en `bevolking`. Toon haar grootte.

## Oplossing
```python
lang = gemeenten.melt(id_vars=["nis_code", "gemeente"], value_vars=["mannen", "vrouwen"],
                      var_name="geslacht", value_name="bevolking")
lang.shape
```

## Commentaar
1 130 rijen (565 gemeenten × 2 geslachten) en 4 kolommen. Dat is de vorm van de tabel `bevolking_geslacht`.

# Gewest en grootte: rijpercentages
niveau: 4
theme: crosstab normalize

## Opgave
Bereken met de klassen « minder dan 10 000 » en « 10 000 en meer » voor elk gewest het **percentage van zijn gemeenten** in elke klasse (1 decimaal).

## Hint
De noemer is het gewest (de rij): `normalize="index"`.

## Startcode
```python
gemeenten["grootte"] = pd.cut(gemeenten["totaal"], bins=[0, 10000, 600000],
                              labels=["< 10 000", "10 000 en +"])
```

## Oplossing
```python
gemeenten["grootte"] = pd.cut(gemeenten["totaal"], bins=[0, 10000, 600000],
                              labels=["< 10 000", "10 000 en +"])
(pd.crosstab(gemeenten["gewest"], gemeenten["grootte"], normalize="index") * 100).round(1)
```

## Commentaar
56,7 % van de Waalse gemeenten telt minder dan 10 000 inwoners, tegenover 19,3 % van de Vlaamse gemeenten en geen enkele Brusselse gemeente. Elke rij is 100 %.

# Gewest en grootte: aandeel van de inwoners
niveau: 4
theme: crosstab values + aggfunc

## Opgave
Dezelfde tabel, maar met het aandeel van de **inwoners** van elk gewest (en niet van de gemeenten) dat in elke klasse woont.

## Oplossing
```python
gemeenten["grootte"] = pd.cut(gemeenten["totaal"], bins=[0, 10000, 600000],
                              labels=["< 10 000", "10 000 en +"])
(pd.crosstab(gemeenten["gewest"], gemeenten["grootte"], values=gemeenten["totaal"],
             aggfunc="sum", normalize="index") * 100).round(1)
```

## Commentaar
In Wallonië woont 23,1 % van de inwoners in een gemeente met minder dan 10 000 inwoners, terwijl die gemeenten 56,7 % van de Waalse gemeenten uitmaken.

# Een grafiek van de bevolking per gewest
niveau: 4
theme: seaborn
verif: aucune

## Opgave
Teken een staafdiagram van de bevolking van elk gewest, met een titel.

## Hint
Bereken eerst de tabel (`groupby` + `agg`), dan `sns.barplot(data=..., x=..., y=...)` en `plt.title(...)`. Vergeet de `import`-regels niet.

## Oplossing
```python
import seaborn as sns
import matplotlib.pyplot as plt

per_gewest = gemeenten.groupby("gewest", as_index=False).agg(bevolking=("totaal", "sum"))
per_gewest["miljoenen"] = per_gewest["bevolking"] / 1e6
sns.barplot(data=per_gewest, x="gewest", y="miljoenen")
plt.title("Bevolking per gewest, 1 januari 2026 (miljoenen)")
plt.xlabel("")
plt.ylabel("Miljoenen inwoners")
```

## Commentaar
Geen automatische controle voor een grafiek: vergelijk met de oplossing. Delen door een miljoen voorkomt een schaal in wetenschappelijke notatie.

# Een fiche per provincie
niveau: 5
theme: groupby + agg + nieuwe kolom + sorteren

## Opgave
Bouw een tabel met één rij per provincie: aantal gemeenten, bevolking, bevolking van de grootste gemeente, en het **aandeel** van die grootste gemeente in de provincie (in %, 1 decimaal). Sorteer op dalend aandeel.

## Hint
`agg(gemeenten=("gemeente", "count"), bevolking=("totaal", "sum"), grootste=("totaal", "max"))`, en dan een nieuwe kolom.

## Oplossing
```python
fiche = (gemeenten
         .groupby("provincie", as_index=False)
         .agg(gemeenten=("gemeente", "count"),
              bevolking=("totaal", "sum"),
              grootste=("totaal", "max")))
fiche["aandeel_grootste"] = (fiche["grootste"] / fiche["bevolking"] * 100).round(1)
fiche.sort_values("aandeel_grootste", ascending=False)
```

## Commentaar
Antwerpen (29,3 %) en Namen (22,8 %) zijn de provincies die het sterkst door hun grootste gemeente gedomineerd worden; Vlaams-Brabant (8,7 %, Leuven) en West-Vlaanderen (9,7 %, Brugge) het minst. Let op: de grootste gemeente is niet altijd de hoofdplaats (Eigenbrakel, en niet Waver, in Waals-Brabant).

# Welk deel van de Belgen woont in een gemeente met meer dan 100 000 inwoners?
niveau: 5
theme: twee sommen, een aandeel

## Opgave
Bereken het percentage van de Belgische bevolking dat in een gemeente met meer dan 100 000 inwoners woont (1 decimaal).

## Oplossing
```python
grote = gemeenten.query("totaal > 100000")["totaal"].sum()
round(grote / gemeenten["totaal"].sum() * 100, 1)
```

## Commentaar
17,2 % van de Belgen woont in een van de 10 gemeenten met meer dan 100 000 inwoners.

# Het oorspronkelijke bestand van Statbel inlezen
niveau: 3
groupe: Je eigen bestanden
theme: read_csv, instellingen

## Opgave
Lees `gegevens/bevolking_2026.txt` (tekstbestand met tabs van Statbel) in met de juiste instellingen: lege regels overgeslagen, punt van de duizendtallen, NIS-code als tekst. Toon op de laatste regel de totale bevolking van België: de kolom `Totaal` van de eerste rij, `ruw["Totaal"][0]`.

## Hint
`sep="\t"`, `skiprows=[1, 2]`, `thousands="."`, `dtype={"NIS code": str}` (let op de spatie in de naam).

## Oplossing
```python
ruw = pd.read_csv("gegevens/bevolking_2026.txt", sep="\t", skiprows=[1, 2],
                  thousands=".", dtype={"NIS code": str})
ruw["Totaal"][0]
```

## Commentaar
11 867 634 inwoners. Zonder `thousands="."` zou de kolom `Totaal` tekst zijn, en `"11.867.634"` tel je niet op.

# De Franse namen toevoegen
niveau: 4
groupe: Je eigen bestanden
theme: merge, validate

## Opgave
Lees de nomenclatuur `referenties/nuts_lau_2027.txt` in (scheidingsteken `|`, codering `cp1252`), houd de geldige gemeenten (`CD_LVL == 4` en `DT_VLDT_STOP == '31/12/9999'`), en voeg aan `gemeenten` hun Franse naam (`TX_DESCR_FR`) toe, met `validate="many_to_one"`. Toon op de laatste regel de Franse naam van Bergen.

## Hint
Hernoem `CD_MUNTY_REFNIS` tot `nis_code` (en lees de kolom als tekst: `dtype={"CD_MUNTY_REFNIS": str}`) om te kunnen koppelen met `on="nis_code"`.

## Oplossing
```python
nuts = pd.read_csv("referenties/nuts_lau_2027.txt", sep="|", encoding="cp1252",
                   dtype={"CD_MUNTY_REFNIS": str})
namen = (nuts.query("CD_LVL == 4 and DT_VLDT_STOP == '31/12/9999'")
         .rename(columns={"CD_MUNTY_REFNIS": "nis_code", "TX_DESCR_FR": "naam_fr"})
         [["nis_code", "naam_fr"]])
met_fr = gemeenten.merge(namen, on="nis_code", how="left", validate="many_to_one")
met_fr.query("gemeente == 'Bergen'")["naam_fr"].iloc[0]
```

## Commentaar
Bergen heet « Mons » in het Frans. `.iloc[0]` neemt de eerste (en enige) waarde van de gefilterde kolom. Zonder de filter op de geldige gemeenten zou `validate` de koppeling stoppen: de nomenclatuur bevat meerdere rijen voor sommige codes.

# De gewestelijke leveringen opschonen
niveau: 5
groupe: Je eigen bestanden
theme: drop_duplicates, str, isna

## Opgave
De tabel `leveringen` (de drie gestapelde gewestelijke bestanden) staat klaar. Verwijder de dubbels, harmoniseer `nis_code` (spaties) en `geslacht` (hoofdletters), verwijder de ontbrekende of negatieve bevolkingscijfers. Toon op de laatste regel het aantal behouden rijen.

## Hint
`drop_duplicates()`, `.str.strip()`, `.str.upper()`, dan `query("bevolking >= 0")` (een ontbrekende bevolking voldoet niet aan de voorwaarde).

## Voorbereiding
```python
bxl = pd.read_csv("gegevens/bevolking_brussel_2026.csv", sep=";", dtype={"nis_code": str})
vla = pd.read_excel("gegevens/bevolking_vlaanderen_2026.xlsx", header=2, dtype={"nis_code": str})
wal = pd.read_csv("gegevens/bevolking_wallonie_2026.txt", sep="\t", dtype={"nis_code": str})
leveringen = pd.concat([bxl, vla, wal], ignore_index=True)
```

## Oplossing
```python
schoon = leveringen.drop_duplicates().copy()
schoon["nis_code"] = schoon["nis_code"].str.strip()
schoon["geslacht"] = schoon["geslacht"].str.strip().str.upper()
schoon = schoon.query("bevolking >= 0")
len(schoon)
```

## Commentaar
1 129 van de 1 132 rijen behouden: een dubbel (Gent) en twee onmogelijke bevolkingscijfers (Daverdisse, Martelange). Een ontbrekende waarde (`NaN`) maakt elke vergelijking onwaar: `query("bevolking >= 0")` verwijdert ze samen met de negatieve.

# Dezelfde vraag in SQL
niveau: 4
groupe: Je eigen bestanden
theme: DuckDB, GROUP BY

## Opgave
Bereken met DuckDB voor elke provincie het aantal gemeenten met minder dan 5 000 inwoners, gesorteerd van de provincie met de meeste naar die met de minste. Haal het resultaat op als pandas-tabel.

## Hint
`duckdb.sql("""SELECT ... FROM gemeenten WHERE ... GROUP BY ... ORDER BY ... DESC""").df()`, na `import duckdb`.

## Oplossing
```python
import duckdb

duckdb.sql("""
    SELECT provincie, COUNT(*) AS kleine
    FROM gemeenten
    WHERE totaal < 5000
    GROUP BY provincie
    ORDER BY kleine DESC
""").df()
```

## Commentaar
Luik (23) en Luxemburg (17) aan de top. Hetzelfde in pandas: `gemeenten.query("totaal < 5000").groupby("provincie").size().sort_values(ascending=False)`.
