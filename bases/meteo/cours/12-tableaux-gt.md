---
titre: De beaux tableaux avec gt
resume: Préparer un tableau avec les verbes du cours, puis le mettre en forme pour un rapport avec le paquet gt.
partie: Compléments
---

# Deux étapes : calculer, puis présenter

Un tableau de rapport se construit en **deux temps** :

::: etape
1. **Calculer** le tableau avec les verbes que vous connaissez (`count`, `group_by`, `mutate`, `pivot_wider`…) : c'est un tibble.
2. **Présenter** ce tibble avec le paquet **gt** : titre, libellés de colonnes, format des pourcentages, couleurs, notes et source.
:::

::: note
Le paquet gt produit un tableau HTML, qui s'affiche dans le **Viewer** de RStudio (le panneau en bas à droite). Dans l'atelier, il s'affiche de la même façon, sous le code. Dans RStudio, installez le paquet une fois avec `install.packages("gt")`, puis chargez-le avec `library(gt)` ; dans l'atelier, il est déjà chargé.
:::

# Étape 1 : calculer le tableau

La répartition des jours selon le ciel, **pour chaque ville** : un pourcentage **en ligne** (chaque ville fait 100 %).

```r
EXPORT1 <- BDD_METEO |>
  filter(!is.na(cldc), year(date) < 2026) |>
  mutate(CIEL = case_when(cldc <= 2 ~ "degage",
                          cldc <= 5 ~ "partiel",
                          cldc <= 7 ~ "nuageux",
                          .default  = "couvert")) |>
  count(name, CIEL, name = "NB_JOURS") |>
  group_by(name) |>
  mutate(PC_JOURS = NB_JOURS / sum(NB_JOURS)) |>
  ungroup() |>
  select(name, CIEL, PC_JOURS) |>
  pivot_wider(names_from = CIEL, values_from = PC_JOURS) |>
  select(name, degage, partiel, nuageux, couvert) |>
  arrange(desc(degage))

EXPORT1
```

::: usage
- `count(…, name = "NB_JOURS")` nomme directement la colonne de comptage ;
- des noms de colonnes **sans espace ni accent** (`degage`, `partiel`…) évitent les accents graves `` ` `` dans la suite du code : les beaux libellés viendront à l'étape 2 ;
- le dernier `select()` remet les colonnes dans l'ordre logique, du ciel dégagé au ciel couvert.
:::

# Étape 2 : le tableau brut, puis le titre et les libellés

```r norun
library(gt)
```

```r
# Le tableau brut
gt(EXPORT1)

# Titre, libellés, pourcentages
TAB_GT <- gt(EXPORT1) |>
  tab_header(
    title = "Le ciel des villes françaises",
    subtitle = "Répartition des jours selon la couverture nuageuse, 2010-2025"
  ) |>
  cols_label(
    name    = "Ville",
    degage  = "Dégagé (0-2 octas)",
    partiel = "Partiel (3-5)",
    nuageux = "Nuageux (6-7)",
    couvert = "Couvert (8-9)"
  ) |>
  fmt_percent(columns = c(degage, partiel, nuageux, couvert), decimals = 1, locale = "fr")

TAB_GT
```

::: usage
| Fonction gt | Rôle |
|---|---|
| `gt()` | transforme un tibble en tableau gt |
| `tab_header(title, subtitle)` | titre et sous-titre |
| `cols_label(COLONNE = "Libellé")` | libellés des colonnes |
| `fmt_percent(columns, decimals, locale)` | affiche 0,215 en « 21,5 % » |
| `fmt_number(columns, decimals, pattern)` | format des nombres, ex. `pattern = "{x} °C"` |
:::

# Couleurs, notes et source

```r
TAB_GT |>
  data_color(
    columns = c(degage, partiel, nuageux, couvert),
    palette = c("#f7fbff", "#08306b"), domain = c(0, 1)
  ) |>
  tab_footnote(footnote = "Jours sans mesure de la couverture nuageuse exclus.") |>
  tab_source_note(source_note = "Source : meteostat.net.")
```

::: note
`data_color()` colore chaque case selon sa valeur, sur une échelle de couleurs (`palette`) qui va de 0 à 1 (`domain`). Une **source** et une **note** sur les données exclues sont indispensables : ici, plus de 40 % des jours n'ont pas de mesure du ciel.
:::

# Exporter le tableau

```r norun
gtsave(TAB_GT, "tableau_ciel.png")    # image
gtsave(TAB_GT, "tableau_ciel.html")   # page web
gtsave(TAB_GT, "tableau_ciel.docx")   # document Word
```

# Un second exemple : des températures, avec fmt_number()

```r
EXPORT2 <- BDD_METEO |>
  filter(year(date) == 2025) |>
  group_by(name) |>
  summarise(TMIN = mean(tmin, na.rm = TRUE),
            TMOY = mean(temp, na.rm = TRUE),
            TMAX = mean(tmax, na.rm = TRUE)) |>
  arrange(desc(TMOY))

EXPORT2
```

```r
gt(EXPORT2) |>
  tab_header(title = "Températures moyennes par ville en 2025") |>
  cols_label(name = "Ville", TMIN = "Minimale", TMOY = "Moyenne", TMAX = "Maximale") |>
  fmt_number(columns = c(TMIN, TMOY, TMAX), decimals = 1, dec_mark = ",", sep_mark = " ",
             pattern = "{x} °C")
```
