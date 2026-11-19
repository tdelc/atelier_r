---
titre: Tabellen stapelen en koppelen
resume: Bestanden stapelen met pd.concat(), de informatie van een andere tabel koppelen met merge(); een koppeling controleren met indicator en validate.
partie: Je eigen bestanden
---

# Tabellen stapelen: pd.concat()

Statbel levert soms één bestand per gewest. De drie bestanden van `gegevens/` hebben **dezelfde kolommen**: we stapelen ze.

```python
bxl = pd.read_csv("gegevens/bevolking_brussel_2026.csv", sep=";",
                  dtype={"nis_code": str})
vla = pd.read_excel("gegevens/bevolking_vlaanderen_2026.xlsx", header=2,
                    dtype={"nis_code": str})
wal = pd.read_csv("gegevens/bevolking_wallonie_2026.txt", sep="\t",
                  dtype={"nis_code": str})

leveringen = pd.concat([bxl, vla, wal], ignore_index=True)
print(len(bxl), len(vla), len(wal), "->", len(leveringen))
leveringen.head(3)
```

::: usage
`pd.concat([t1, t2, t3])` krijgt een **lijst** van tabellen. `ignore_index=True` nummert de rijen opnieuw van 0 tot n-1. Onmiddellijke controle: het aantal gestapelde rijen is de som van de rijen van elke tabel.
:::

::: sas
`DATA leveringen; SET bxl vla wal; RUN;`
:::

# De herkomst bijhouden

Vóór het stapelen geeft een kolom aan waar elke rij vandaan komt.

```python
bxl["bron"] = "Brussel"
vla["bron"] = "Vlaanderen"
wal["bron"] = "Wallonië"
leveringen = pd.concat([bxl, vla, wal], ignore_index=True)
leveringen["bron"].value_counts()
```

::: note
Deze bestanden bevatten enkele **opzettelijke afwijkingen** (een geslacht in kleine letters, een ontbrekende bevolking…): we behandelen ze in de les « Een tabel opschonen ».
:::

# Koppelen: kolommen van een andere tabel toevoegen

De tabel `gemeenten` geeft de namen in het Nederlands. De NUTS-nomenclatuur geeft ook de namen in het **Frans** en in het **Duits**. We willen ze aan `gemeenten` toevoegen, door de rijen te koppelen via de **NIS-code**: dat is een koppeling, of **join**.

```python
nuts = pd.read_csv("referenties/nuts_lau_2027.txt", sep="|", encoding="cp1252",
                   dtype={"CD_MUNTY_REFNIS": str})
namen = nuts[["CD_MUNTY_REFNIS", "TX_DESCR_FR", "TX_DESCR_DE", "CD_LVL", "DT_VLDT_STOP"]]
namen = namen.rename(columns={"CD_MUNTY_REFNIS": "nis_code",
                              "TX_DESCR_FR": "naam_fr", "TX_DESCR_DE": "naam_de"})
namen.head(3)
```

# merge(): de koppeling

```python
met_namen = gemeenten.merge(namen, on="nis_code", how="left")
print(len(gemeenten), "->", len(met_namen))
```

**Interpretatie:** 565 gemeenten bij de start… en 782 rijen bij aankomst! Geen enkele fout, en toch is het resultaat fout.

# De valkuil: een dubbele sleutel

De nomenclatuur bevat **meerdere rijen voor eenzelfde code**: de gewesten, provincies en arrondissementen, maar vooral de geschiedenis van de gemeenten (één rij per geldigheidsperiode). Antwerpen bijvoorbeeld:

```python
namen.query("nis_code == '11002'")
```

Elke rij van Antwerpen in `gemeenten` is gekoppeld aan de twee rijen van Antwerpen in de nomenclatuur: ze is **verdubbeld**. De totalen die je daarna berekent, zouden fout zijn.

::: sas
In SAS koppelt `MERGE ... BY` rij per rij en meldt het log « MERGE statement has more than one data set with repeats of BY values ». pandas maakt **alle combinaties**, zonder iets te zeggen.
:::

# Jezelf beschermen: validate=

`validate="many_to_one"` eist dat elke code **maar één keer** voorkomt in de rechtertabel. Anders: een fout. **Bewuste fout**:

```python erreur
gemeenten.merge(namen, on="nis_code", how="left", validate="many_to_one")
```

De oplossing: in de nomenclatuur alleen de **gemeenten** (niveau 4) houden die **geldig** zijn (einde van geldigheid op 31/12/9999).

```python
namen_geldig = namen.query("CD_LVL == 4 and DT_VLDT_STOP == '31/12/9999'")
namen_geldig = namen_geldig.drop(columns=["CD_LVL", "DT_VLDT_STOP"])

met_namen = gemeenten.merge(namen_geldig, on="nis_code", how="left",
                            validate="many_to_one")
print(len(gemeenten), "->", len(met_namen))
met_namen.query("gemeente in ['Luik', 'Bergen', 'Leuven', 'Antwerpen', 'Mechelen', 'Brussel']")[["gemeente", "naam_fr", "naam_de"]]
```

# De behouden rijen kiezen: how=

| `how=` | Behouden rijen | In SAS (`MERGE a(in=a) b(in=b)`) |
|---|---|---|
| `"left"` | alle rijen van de linkertabel | `if a;` |
| `"inner"` | de rijen die aan beide kanten voorkomen | `if a and b;` |
| `"right"` | alle rijen van de rechtertabel | `if b;` |
| `"outer"` | alle, aan beide kanten | geen `if` |

`"left"` is de gebruikelijke keuze om een tabel te **verrijken** zonder er rijen van te verliezen.

# Een koppeling controleren: indicator=True

`indicator=True` voegt een kolom `_merge` toe die zegt waar elke rij vandaan komt: `both` (beide kanten), `left_only`, `right_only`.

```python
controle = gemeenten.merge(namen_geldig, on="nis_code", how="outer",
                           indicator=True, validate="one_to_one")
controle["_merge"].value_counts()
```

**Interpretatie:** de 565 gemeenten van de tabel staan allemaal in de nomenclatuur, en omgekeerd: de koppeling is volledig.

::: sas
Dat is het equivalent van de `IN=`-variabelen van de `MERGE`-stap.
:::

# De reflexen bij een koppeling

1. Vooraf: is de sleutel **uniek** in de rechtertabel? (`validate=`, of `namen["nis_code"].duplicated().sum()`)
2. Hebben de sleutels aan beide kanten **hetzelfde type**? Een code als tekst (`"11002"`) komt niet overeen met een code als getal (`11002`).
3. Achteraf: is het aantal rijen veranderd? Hoeveel rijen zijn niet gekoppeld? (`indicator=True`)
4. Zijn de totalen gelijk gebleven?

```python
gemeenten["totaal"].sum() == met_namen["totaal"].sum()
```
