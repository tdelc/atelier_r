---
base: meteo
---

# Explorer une variable au choix

Les trois commandes de base pour découvrir une variable : un aperçu, un résumé, une distribution. Le code ci-dessous regarde la température maximale.

```r
head(BDD_METEO$tmax)
summary(BDD_METEO$tmax)
hist(BDD_METEO$tmax)
```

## À essayer

- Remplacez `tmax` par `rhum` (humidité), `wspd` (vent), `pres` (pression).
- Pour `prcp`, comparez la moyenne et la médiane : pourquoi sont-elles si différentes ?
- Essayez `hist(BDD_METEO$tmin, breaks = 50, col = "lightblue")`.
- Pour une variable catégorielle comme `cldc`, utilisez `table(BDD_METEO$cldc, useNA = "ifany")`.

# Filtrer une population

Les jours de forte chaleur dans une ville.

```r
BDD_METEO |>
  filter(name == "Lyon / Bron" & tmax > 35) |>
  select(name, date, tmin, tmax)
```

## À essayer

- Changez la ville : `"Strasbourg"`, `"Nantes"`, `"Bastia"`… (le nom doit être écrit exactement comme dans la base).
- Cherchez les jours de gel (`tmin < 0`) à Nice.
- Ajoutez une condition sur la date : `date >= as.Date("2022-01-01")`.
- Ajoutez `|> count()` à la fin pour compter au lieu d'afficher.

# Comparer les villes

Un indicateur par ville, du plus grand au plus petit.

```r
BDD_METEO |>
  group_by(name) |>
  summarise(TEMP_MOY = mean(temp, na.rm = TRUE),
            NB_JOURS_GEL = sum(tmin < 0, na.rm = TRUE)) |>
  arrange(desc(TEMP_MOY))
```

## À essayer

- Retirez `na.rm = TRUE` : que se passe-t-il pour certaines villes ? Pourquoi celles-là ?
- Ajoutez un indicateur de vent : `VENT_MOY = mean(wspd, na.rm = TRUE)`.
- Classez les villes selon la part des jours de pluie : `mean(prcp > 0, na.rm = TRUE)`.
- Ajoutez un `filter(year(date) == 2025)` au début.

# L'évolution année par année

Extraire l'année de la date, puis calculer un indicateur par année.

```r
BDD_METEO |>
  filter(name == "Paris-Orly") |>
  group_by(annee = year(date)) |>
  summarise(TEMP_MOY = mean(temp, na.rm = TRUE),
            NB_JOURS_30 = sum(tmax > 30, na.rm = TRUE)) |>
  print(n = 20)
```

## À essayer

- Changez de ville, ou de seuil (`tmax > 25`, `tmax > 35`).
- Remplacez `year(date)` par `month(date)` : vous obtenez le climat moyen par mois.
- Pourquoi la dernière année (2026) est-elle si chaude ? Indice : regardez `max(BDD_METEO$date)`.

# Des classes de température

Découper la température maximale en classes, puis compter. Les bornes sont un **choix** : modifiez-les.

```r
BDD_METEO |>
  filter(name == "Montpellier") |>
  mutate(classe = cut(tmax,
                      breaks = c(-20, 10, 20, 30, 50),
                      labels = c("Froid", "Doux", "Chaud", "Très chaud"))) |>
  count(classe)
```

## À essayer

- Ajoutez une classe « Canicule » au-delà de 35 °C (une borne **et** une étiquette).
- Comparez avec une ville du nord.
- Remplacez `count(classe)` par `group_by(classe) |> summarise(PLUIE = mean(prcp > 0, na.rm = TRUE))`.

# Construire un tableau croisé

Un indicateur par ville et par saison, avec une colonne par saison.

```r
BDD_METEO |>
  mutate(saison = case_when(
    month(date) %in% c(12, 1, 2)  ~ "1_Hiver",
    month(date) %in% c(3, 4, 5)   ~ "2_Printemps",
    month(date) %in% c(6, 7, 8)   ~ "3_Eté",
    month(date) %in% c(9, 10, 11) ~ "4_Automne"
  )) |>
  group_by(name, saison) |>
  summarise(TEMP_MOY = mean(temp, na.rm = TRUE)) |>
  pivot_wider(names_from = saison, values_from = TEMP_MOY)
```

## À essayer

- Remplacez la température par la part des jours de pluie.
- Faites l'inverse : une colonne par ville (`names_from = name`) — est-ce plus lisible ?
- Ajoutez `|> arrange(desc(`3_Eté`))` (avec les accents graves) pour classer les villes selon l'été.

# Un premier graphique

Un graphique ggplot2 : on calcule d'abord un tableau, puis on le dessine.

```r
TEMP_ANNEE <- BDD_METEO |>
  filter(name %in% c("Lille", "Nice"), year(date) < 2026) |>
  group_by(name, annee = year(date)) |>
  summarise(TEMP_MOY = mean(temp, na.rm = TRUE))

ggplot(TEMP_ANNEE, aes(x = annee, y = TEMP_MOY, colour = name)) +
  geom_line(linewidth = 1) +
  labs(title = "Température moyenne annuelle", x = NULL, y = "°C", colour = NULL) +
  theme_minimal()
```

## À essayer

- Ajoutez d'autres villes dans le `filter()`.
- Ajoutez `geom_point()` ou `geom_smooth(method = "lm", se = FALSE)`.
- Remplacez la température par le nombre de jours à plus de 30 °C.
- Changez le thème : `theme_classic()`, `theme_bw()`.

# Votre propre question

Un squelette à compléter. Choisissez une population (`filter`), des groupes (`group_by`) et un indicateur (`summarise`).

```r
BDD_METEO |>
  filter(name %in% c("Rennes", "Strasbourg")) |>
  group_by(name, mois = month(date)) |>
  summarise(TMAX_MOY = mean(tmax, na.rm = TRUE),
            PART_PLUIE = mean(prcp > 0, na.rm = TRUE)) |>
  print(n = 30)
```

## À essayer

- Écrivez d'abord votre question **en français**, puis traduisez-la avec le dictionnaire de la leçon « Traduire une phrase en R ».
- Ouvrez le **Dictionnaire** (en haut de l'écran) pour trouver d'autres variables.
- Pensez à `na.rm = TRUE` et à vérifier chaque variable créée.
