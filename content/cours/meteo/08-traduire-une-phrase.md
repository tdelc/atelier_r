---
titre: Traduire une phrase en R
resume: Repérer les mots-clés d'une question et les remplacer par le bon verbe.
partie: Les bases
---

# Le dictionnaire français → R

| Dans la phrase… | Idée | Verbe R |
|---|---|---|
| « **à** Lille », « **en** été », « **parmi** les jours de pluie », « **seulement** 2025 » | je restreins la population | `filter()` |
| « **par** ville », « **selon** la saison », « **pour chaque** année », « **en fonction du** mois » | je compare des groupes | `group_by()` |
| « température **moyenne** », « **médiane** », « **maximum** », « **record** » | je calcule un indicateur | `summarise(mean())`, `max()`… |
| « **nombre de** jours », « **combien** » | je compte des lignes | `count()`, `sum(condition)` |
| « **part** de », « **proportion** de » | je fais la moyenne d'un VRAI / FAUX | `summarise(mean(condition))` |
| « **créer** une variable », « **indiquer si** » | je fabrique une colonne | `mutate()` + `if_else()`, `case_when()`, `cut()` |
| « **en colonnes** », « **tableau croisé** » | je mets en forme | `pivot_wider()` |
| « **le plus** », « **le moins** », « **classer** » | j'ordonne les lignes | `arrange()`, `arrange(desc())` |

# L'ordre des verbes

::: etape
0. `mutate()` — si la question demande une variable qui n'existe pas encore
1. `filter()` — de qui parle-t-on ? (la population)
2. `group_by()` — comparé selon quoi ? (les groupes)
3. `summarise()` ou `count()` — quel calcul ? (l'indicateur)
4. `pivot_wider()` puis `arrange()` — comment le présenter ? (la mise en forme)
:::

# Exemple 1

**« À Lille, température maximale moyenne selon le mois »**

| Morceau de phrase | Verbe |
|---|---|
| le mois *(n'existe pas encore)* | `mutate(mois = month(date))` |
| À Lille | `filter(name == "Lille")` |
| selon le mois | `group_by(mois)` |
| température maximale moyenne | `summarise(mean(tmax, na.rm = TRUE))` |

```r
BDD_METEO |>
  mutate(mois = month(date)) |>
  filter(name == "Lille") |>
  group_by(mois) |>
  summarise(TMAX_MOY = mean(tmax, na.rm = TRUE))
```

# Exemple 2

**« Nombre de jours à plus de 30 °C par ville en 2025, de la plus chaude à la moins chaude »**

| Morceau de phrase | Verbe |
|---|---|
| en 2025 | `filter(year(date) == 2025)` |
| par ville | `group_by(name)` |
| nombre de jours à plus de 30 °C | `summarise(sum(tmax > 30, na.rm = TRUE))` |
| de la plus chaude à la moins chaude | `arrange(desc(...))` |

```r
BDD_METEO |>
  filter(year(date) == 2025) |>
  group_by(name) |>
  summarise(NB_JOURS_30 = sum(tmax > 30, na.rm = TRUE)) |>
  arrange(desc(NB_JOURS_30))
```

# Exemple 3

**« Part des jours de pluie selon la saison, avec une colonne par ville, pour Rennes et Nice »**

| Morceau de phrase | Verbe |
|---|---|
| la saison *(n'existe pas encore)* | `mutate(saison = case_when(...))` |
| pour Rennes et Nice | `filter(name %in% c("Rennes", "Nice"))` |
| selon la saison, par ville | `group_by(saison, name)` |
| part des jours de pluie | `summarise(mean(prcp > 0, na.rm = TRUE))` |
| une colonne par ville | `pivot_wider(names_from = name, ...)` |

```r
BDD_METEO |>
  mutate(saison = case_when(
    month(date) %in% c(12, 1, 2)  ~ "1_Hiver",
    month(date) %in% c(3, 4, 5)   ~ "2_Printemps",
    month(date) %in% c(6, 7, 8)   ~ "3_Eté",
    month(date) %in% c(9, 10, 11) ~ "4_Automne"
  )) |>
  filter(name %in% c("Rennes", "Nice")) |>
  group_by(saison, name) |>
  summarise(PART_PLUIE = mean(prcp > 0, na.rm = TRUE)) |>
  pivot_wider(names_from = name, values_from = PART_PLUIE)
```

::: note
**Lecture :** à Rennes, il pleut de 4 à 6 jours sur 10 selon la saison. À Nice, il pleut environ un jour sur quatre en dehors de l'été, et à peine un jour sur huit en été.
:::
