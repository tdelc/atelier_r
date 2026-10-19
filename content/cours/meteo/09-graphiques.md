---
titre: Premiers graphiques avec ggplot2
resume: Construire un graphique couche par couche - données, axes, géométrie, habillage.
partie: Pour aller plus loin
---

# La grammaire de ggplot2

`hist()` donne un graphique rapide pour **vous**. Pour un graphique destiné à **un rapport**, on utilise `ggplot2` (chargé avec le tidyverse). Un graphique se construit par **couches**, reliées par des `+` :

::: etape
1. `ggplot(DONNEES, aes(x = ..., y = ...))` — quelles données, quelle variable sur quel axe ?
2. `geom_...()` — quelle forme : courbe (`geom_line`), barres (`geom_col`), points (`geom_point`), histogramme (`geom_histogram`)…
3. `labs()`, `theme_...()` — l'habillage : titres, style.
:::

::: piege
Entre les couches, c'est `+` et non `|>`. Le pipe sert à enchaîner des **calculs** ; le `+` assemble les **couches** d'un graphique.
:::

# Une courbe : la température moyenne par année

La méthode la plus sûre : **calculer d'abord** le tableau, **dessiner ensuite**.

```r
TEMP_LILLE <- BDD_METEO |>
  filter(name == "Lille", year(date) < 2026) |>     # 2026 est incomplète
  group_by(annee = year(date)) |>
  summarise(temp_moy = mean(temp, na.rm = TRUE))

ggplot(TEMP_LILLE, aes(x = annee, y = temp_moy)) +
  geom_line(colour = "#3b6ea5", linewidth = 1) +
  geom_point(colour = "#3b6ea5") +
  labs(title = "Température moyenne annuelle à Lille",
       x = NULL, y = "°C") +
  theme_minimal()
```

# Ajouter une tendance

```r
ggplot(TEMP_LILLE, aes(x = annee, y = temp_moy)) +
  geom_line(colour = "#3b6ea5", linewidth = 1) +
  geom_point(colour = "#3b6ea5") +
  geom_smooth(method = "lm", se = FALSE, colour = "#d9822b", linetype = "dashed") +
  labs(title = "Température moyenne annuelle à Lille, avec tendance linéaire",
       x = NULL, y = "°C") +
  theme_minimal()
```

::: note
`geom_smooth(method = "lm")` ajoute une **droite de régression**. Sur 16 ans, elle donne un ordre de grandeur de la tendance — à manier avec prudence : une ou deux années exceptionnelles suffisent à la faire pencher.
:::

# Comparer des villes avec la couleur

```r
TEMP_VILLES <- BDD_METEO |>
  filter(name %in% c("Lille", "Strasbourg", "Nice", "Nantes"), year(date) < 2026) |>
  group_by(name, annee = year(date)) |>
  summarise(temp_moy = mean(temp, na.rm = TRUE))

ggplot(TEMP_VILLES, aes(x = annee, y = temp_moy, colour = name)) +
  geom_line(linewidth = 1) +
  labs(title = "Température moyenne annuelle", x = NULL, y = "°C", colour = NULL) +
  theme_minimal() +
  theme(legend.position = "bottom")
```

::: usage
`colour = VARIABLE` dans `aes()` dessine une courbe par modalité, avec une légende.
:::

# Un diagramme en barres : le climat moyen

```r
CLIMAT_LILLE <- BDD_METEO |>
  filter(name == "Lille") |>
  group_by(mois = month(date)) |>
  summarise(pluie_moy = mean(prcp, na.rm = TRUE) * 30)   # cumul mensuel approximatif

ggplot(CLIMAT_LILLE, aes(x = factor(mois), y = pluie_moy)) +
  geom_col(fill = "#3b6ea5") +
  labs(title = "Lille : précipitations mensuelles moyennes (approximation)",
       x = "Mois", y = "mm") +
  theme_minimal()
```

::: note
`factor(mois)` traite le mois comme une **catégorie** : une barre par mois, avec une étiquette pour chacun.
:::

# Une distribution par groupe : boîtes à moustaches

```r
BDD_METEO |>
  filter(month(date) %in% c(7, 8)) |>
  ggplot(aes(x = reorder(name, tmax, median, na.rm = TRUE), y = tmax)) +
  geom_boxplot(fill = "#eef3fb", outlier.size = 0.5) +
  coord_flip() +
  labs(title = "Températures maximales en juillet-août", x = NULL, y = "°C") +
  theme_minimal()
```

::: note
`coord_flip()` couche le graphique pour que les noms de villes soient lisibles. L'onglet **Dashboard** montre ce que l'on peut construire avec ces mêmes outils.
:::
