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

La part de naissances hors mariage, selon la taille de la commune de la mère (en lignes) et sa nationalité (en colonnes). C'est un pourcentage **par case** : parmi les naissances de chaque taille de commune × nationalité.

```r
EXPORT1 <- BDD_NAIS |>
  mutate(TAILLE = case_when(
           TUDOM == 0     ~ "1_Rural",
           TUDOM %in% 1:3 ~ "2_Moins de 20 000 hab.",
           TUDOM %in% 4:6 ~ "3_20 000 à 199 999 hab.",
           TUDOM == 7     ~ "4_200 000 hab. ou plus",
           TUDOM == 8     ~ "5_Agglomération parisienne",
           .default       = "6_Étranger ou COM"),
         NATIO = if_else(INDNATM == 1, "francaise", "etrangere")) |>
  filter(TAILLE != "6_Étranger ou COM") |>
  group_by(TAILLE, NATIO) |>
  summarise(PART_HORS_MARIAGE = mean(AMAR == "0000")) |>
  ungroup() |>
  mutate(TAILLE = str_sub(TAILLE, 3)) |>          # retire le préfixe "1_", "2_"…
  pivot_wider(names_from = NATIO, values_from = PART_HORS_MARIAGE) |>
  select(TAILLE, francaise, etrangere)

EXPORT1
```

::: usage
- Des noms de colonnes **sans espace ni accent** (`francaise`, `etrangere`) évitent les accents graves `` ` `` dans la suite du code : les beaux libellés viendront à l'étape 2.
- `str_sub(TAILLE, 3)` garde le texte à partir du 3e caractère : le préfixe qui servait à trier disparaît une fois l'ordre fixé.
- `select()` remet les colonnes dans l'ordre voulu.
:::

# Étape 2 : le tableau brut, puis le titre et les libellés

```r norun
library(gt)   # dans RStudio ; inutile dans l'atelier
```

```r
# Le tableau brut
gt(EXPORT1)

# Titre, libellés, pourcentages
TAB_GT <- gt(EXPORT1) |>
  tab_header(
    title = "Part des naissances hors mariage",
    subtitle = "Selon la taille de la commune et la nationalité de la mère, France, 2021"
  ) |>
  cols_label(
    TAILLE    = "Taille de la commune de la mère",
    francaise = "Mère française",
    etrangere = "Mère étrangère"
  ) |>
  fmt_percent(columns = c(francaise, etrangere), decimals = 1, locale = "fr")

TAB_GT
```

::: usage
| Fonction gt | Rôle |
|---|---|
| `gt()` | transforme un tibble en tableau gt |
| `tab_header(title, subtitle)` | titre et sous-titre |
| `cols_label(COLONNE = "Libellé")` | libellés des colonnes |
| `fmt_percent(columns, decimals, locale)` | affiche 0,679 en « 67,9 % » |
| `fmt_number(columns, decimals, pattern)` | format des nombres, ex. `pattern = "{x} ans"` |
:::

# Couleurs, notes et source

```r
TAB_GT |>
  data_color(
    columns = c(francaise, etrangere),
    palette = c("#f7fbff", "#08306b"), domain = c(0, 1)
  ) |>
  tab_footnote(footnote = "Parents non mariés à la naissance (AMAR = 0000).") |>
  tab_source_note(source_note = "Source : INSEE, état civil, naissances 2021.")
```

::: note
`data_color()` colore chaque case selon sa valeur, sur une échelle de couleurs (`palette`) qui va de 0 à 1 (`domain`), ici du bleu clair (0 %) au bleu foncé (100 %). Une **source** et une **note** de définition sont indispensables dans tout tableau de rapport.
:::

# Exporter le tableau

```r norun
# En image ou en page web
gtsave(TAB_GT, "tableau_hors_mariage.png")
gtsave(TAB_GT, "tableau_hors_mariage.html")

# En document Word
gtsave(TAB_GT, "tableau_hors_mariage.docx")
```

# Un second exemple : des âges, avec fmt_number()

```r
EXPORT2 <- BDD_NAIS |>
  filter(DEPNAIS %in% c("59", "62", "02", "60", "80")) |>
  group_by(DEPNAIS) |>
  summarise(NB = n(),
            AGE_MERE = mean(AGEXACTM),
            AGE_PERE = mean(AGEXACTP))

EXPORT2
```

```r
gt(EXPORT2) |>
  tab_header(title = "Naissances dans les Hauts-de-France, 2021") |>
  cols_label(DEPNAIS = "Département", NB = "Naissances",
             AGE_MERE = "Âge moyen de la mère", AGE_PERE = "Âge moyen du père") |>
  fmt_number(columns = NB, decimals = 0, sep_mark = " ") |>
  fmt_number(columns = c(AGE_MERE, AGE_PERE), decimals = 1, dec_mark = ",", sep_mark = " ",
             pattern = "{x} ans")
```

::: note
Pour afficher le **nom** des départements plutôt que leur code, il faut une autre table qui contient ces noms, et la **fusionner** avec la base : c'est l'objet de la leçon suivante.
:::
