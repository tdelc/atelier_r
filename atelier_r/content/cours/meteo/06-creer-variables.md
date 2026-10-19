---
titre: Créer des variables
resume: mutate(), les dates avec year() et month(), les variables VRAI / FAUX, if_else(), case_when(), cut().
partie: Les bases
---

# mutate() : créer une colonne

::: usage
**À quoi ça sert ?** Ajouter une nouvelle colonne calculée à partir des autres. **Le nombre de lignes ne change pas.**

**Écriture :** `BDD <- BDD |> mutate(NOUVELLE_COLONNE = calcul)`
:::

```r
# L'amplitude thermique du jour
BDD_METEO <- BDD_METEO |>
  mutate(amplitude = tmax - tmin)

summary(BDD_METEO$amplitude)
```

::: piege
N'oubliez pas le `BDD_METEO <-` au début : sans lui, la colonne est calculée, affichée… et perdue.
:::

# Extraire les composantes d'une date

::: usage
Une date brute ne permet pas de regrouper. Pour analyser par année, par mois ou par jour, il faut d'abord extraire ces composantes avec `year()`, `month()`, `day()` (paquet **lubridate**, chargé avec le tidyverse).
:::

```r
BDD_METEO <- BDD_METEO |>
  mutate(annee = year(date),
         mois  = month(date),
         jour  = day(date))

# Vérification immédiate : quelques lignes au hasard
BDD_METEO |>
  slice_sample(n = 10) |>
  select(date, annee, mois, jour)
```

::: usage
**`slice_sample(n = 10)`** tire 10 lignes au hasard. Bien plus honnête que `head()` pour vérifier un calcul : les premières lignes d'une base sont rarement représentatives.
:::

# Des variables VRAI / FAUX construites sur un seuil

```r
BDD_METEO <- BDD_METEO |>
  mutate(pluie       = prcp > 0,    # a-t-il plu ce jour ?
         jour_chaud  = tmax > 35,   # journée très chaude
         nuit_chaude = tmin > 20)   # nuit chaude

BDD_METEO |> count(pluie)
```

::: piege
Le `NA` se propage : si `prcp` est manquant, `pluie` vaut `NA`, et non `FALSE`. C'est le comportement souhaité (on ne sait pas), mais il faudra écrire `na.rm = TRUE` dans tous les calculs qui suivent.
:::

# Utiliser une variable VRAI / FAUX

```r
BDD_METEO |>
  group_by(name) |>
  summarise(NB_JOURS_CHAUDS  = sum(jour_chaud, na.rm = TRUE),
            NB_NUITS_CHAUDES = sum(nuit_chaude, na.rm = TRUE),
            PART_PLUIE       = mean(pluie, na.rm = TRUE))
```

::: usage
- `sum(VARIABLE, na.rm = TRUE)` → le **nombre** de jours où c'est VRAI ;
- `mean(VARIABLE, na.rm = TRUE)` → la **proportion** de jours où c'est VRAI.
:::

# if_else() : deux cas possibles

```r
BDD_METEO <- BDD_METEO |>
  mutate(periode = if_else(annee <= 2016, "2010_2016", "2017_2026"))

BDD_METEO |> count(periode)
```

::: piege
Le point de coupure (ici 2017) est un **choix**. Coupez au milieu de la période observée, ou sur une date qui a du sens, mais ne cherchez pas la coupure qui donne le plus joli résultat : ce serait fabriquer la conclusion.
:::

# case_when() : la saison

```r
BDD_METEO <- BDD_METEO |>
  mutate(saison = case_when(
    mois %in% c(12, 1, 2)  ~ "1_Hiver",
    mois %in% c(3, 4, 5)   ~ "2_Printemps",
    mois %in% c(6, 7, 8)   ~ "3_Eté",
    mois %in% c(9, 10, 11) ~ "4_Automne"
  ))

# Vérification : chaque mois tombe dans une seule saison
BDD_METEO |> count(mois, saison)
```

::: usage
**Pourquoi `1_Hiver` et pas `Hiver` ?** R trie les modalités par ordre alphabétique : sans le préfixe numérique, l'automne arriverait en premier dans tous vos tableaux et graphiques.

**`case_when` teste dans l'ordre** : dès qu'une condition est vraie, les suivantes ne sont plus évaluées.
:::

# cut() : découper un nombre en classes

::: usage
**Écriture :** `cut(COLONNE, breaks = c(bornes), labels = c(noms des classes))`

- Il faut **une étiquette de moins que de bornes** ;
- chaque classe inclut sa borne **droite** : `(25, 30]` va de 25,1 à 30 °C ;
- une valeur en dehors des bornes devient `NA`.
:::

```r
BDD_METEO <- BDD_METEO |>
  mutate(classe_tmax = cut(tmax,
                           breaks = c(-50, 0, 10, 20, 25, 30, 35, 50),
                           labels = c("Gel", "Froid", "Doux", "Agréable",
                                      "Chaud", "Très chaud", "Canicule")))

BDD_METEO |>
  filter(name == "Lille") |>
  count(classe_tmax)
```

# group_by() + mutate() : comparer à la moyenne de sa ville

Après un `group_by()`, `mutate()` calcule **dans chaque groupe**, mais garde **toutes les lignes**.

```r
BDD_METEO <- BDD_METEO |>
  group_by(name) |>
  mutate(temp_moy_ville = mean(temp, na.rm = TRUE),
         ecart_moyenne  = temp - temp_moy_ville) |>
  ungroup()

BDD_METEO |>
  slice_max(ecart_moyenne, n = 5) |>
  select(name, date, temp, temp_moy_ville, ecart_moyenne)
```

::: piege
Ajoutez toujours `ungroup()` après un calcul groupé : sinon, les calculs suivants resteront découpés par ville, sans que vous le voyiez.
:::
