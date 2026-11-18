---
titre: Faire une carte
resume: Placer les stations sur un fond de carte et les colorer selon un indicateur - calculer, fusionner, dessiner.
partie: Compléments
---

# Une carte = un fond + des données

Une carte se construit en **couches**, comme tout graphique ggplot2 :

::: etape
1. **Un fond de carte** : les contours des départements.
2. **Un indicateur** calculé par station (`group_by` + `summarise`), avec ses coordonnées.
3. **Le dessin** : le fond en gris, puis un point par station, coloré selon l'indicateur.
:::

Dans l'atelier, le fond de carte est la table `CARTE_DEP` : chaque ligne est un **point du contour** d'un département (longitude `long`, latitude `lat`), avec son code INSEE.

```r
CARTE_DEP
```

# Le fond de carte seul

```r
ggplot(CARTE_DEP, aes(x = long, y = lat, group = groupe)) +
  geom_polygon(fill = "white", colour = "grey40") +
  coord_quickmap() +
  theme_void()
```

::: usage
- `geom_polygon()` relie les points d'un même `groupe` pour former une surface (la colonne `groupe` distingue les morceaux d'un département, les îles par exemple) ;
- `coord_quickmap()` respecte les proportions d'une carte (sinon la France paraît écrasée) ;
- `theme_void()` retire les axes et la grille, inutiles sur une carte.
:::

# 1. L'indicateur par station

La base contient la latitude et la longitude de chaque station. On calcule un indicateur par station en gardant ces coordonnées dans le `group_by()`.

```r
STATIONS <- BDD_METEO |>
  filter(year(date) < 2026) |>
  group_by(name, latitude, longitude) |>
  summarise(TEMP_MOY = mean(temp, na.rm = TRUE),
            JOURS_30 = sum(tmax >= 30, na.rm = TRUE) / n_distinct(year(date))) |>
  ungroup()

STATIONS
```

::: note
Les coordonnées sont constantes pour une station : les mettre dans le `group_by()` ne change pas les groupes, et permet de les garder dans le résultat.
:::

# 2. Superposer les stations au fond de carte

Deux tables, deux couches : chaque `geom_` reçoit ses propres données avec l'argument `data =`.

```r
ggplot() +
  geom_polygon(data = CARTE_DEP, aes(x = long, y = lat, group = groupe),
               fill = "grey95", colour = "grey70", linewidth = 0.2) +
  geom_point(data = STATIONS, aes(x = longitude, y = latitude, colour = TEMP_MOY),
             size = 5) +
  geom_text(data = STATIONS, aes(x = longitude, y = latitude, label = name),
            size = 3, vjust = -1.3) +
  scale_colour_distiller(palette = "RdYlBu") +
  coord_quickmap() +
  labs(title = "Température moyenne des stations, 2010-2025", colour = "°C") +
  theme_void()
```

::: usage
- `ggplot()` vide, puis `data =` dans chaque couche : c'est ainsi qu'on combine plusieurs tables dans un même graphique ;
- `geom_text()` écrit le nom de chaque station, `vjust` le décale verticalement ;
- `scale_colour_distiller(palette = "RdYlBu")` : du rouge (chaud) au bleu (froid).
:::

# Un indicateur d'évolution

La même carte, avec le **réchauffement** de chaque station entre 2010-2016 et 2017-2025 (on exclut 2026, incomplète).

```r
RECHAUFFEMENT <- BDD_METEO |>
  filter(year(date) < 2026) |>
  mutate(periode = if_else(year(date) <= 2016, "avant", "apres")) |>
  group_by(name, latitude, longitude, periode) |>
  summarise(TEMP = mean(temp, na.rm = TRUE)) |>
  ungroup() |>
  pivot_wider(names_from = periode, values_from = TEMP) |>
  mutate(ECART = apres - avant)

ggplot() +
  geom_polygon(data = CARTE_DEP, aes(x = long, y = lat, group = groupe),
               fill = "grey95", colour = "grey70", linewidth = 0.2) +
  geom_point(data = RECHAUFFEMENT, aes(x = longitude, y = latitude, colour = ECART),
             size = 6) +
  geom_text(data = RECHAUFFEMENT, aes(x = longitude, y = latitude,
                                      label = round(ECART, 1)),
            size = 3, vjust = -1.6) +
  scale_colour_distiller(palette = "OrRd", direction = 1) +
  coord_quickmap() +
  labs(title = "Écart de température moyenne : 2017-2025 contre 2010-2016",
       colour = "°C") +
  theme_void()
```

::: note
**Lecture :** toutes les stations se sont réchauffées. L'écart est plus marqué dans le nord et le nord-est (Lille, Nancy, Strasbourg) que sur le pourtour méditerranéen.
:::

# Colorier les départements des stations

Pour colorier des **surfaces** plutôt que des points, il faut **fusionner** l'indicateur avec le fond de carte. On rattache chaque station à son département avec une petite table de correspondance.

```r
DEP_STATIONS <- tibble(
  name = c("Bastia", "Lille", "Lyon / Bron", "Marseille / Marignane", "Montelimar",
           "Montpellier", "Nancy / Essey", "Nantes", "Nice", "Paris-Orly",
           "Perpignan", "Rennes", "Strasbourg"),
  code_insee = c("2B", "59", "69", "13", "26", "34", "54", "44", "06", "94", "66", "35", "67")
)

CARTE <- CARTE_DEP |>
  left_join(DEP_STATIONS, by = "code_insee") |>
  left_join(RECHAUFFEMENT, by = "name")

ggplot(CARTE, aes(x = long, y = lat, group = groupe, fill = ECART)) +
  geom_polygon(colour = "white", linewidth = 0.2) +
  scale_fill_distiller(palette = "OrRd", direction = 1, na.value = "grey90") +
  coord_quickmap() +
  labs(title = "Réchauffement mesuré par la station du département", fill = "°C") +
  theme_void()
```

::: piege
Seuls 13 départements ont une station : tous les autres restent en gris (`na.value`). Une carte en surfaces donne l'**illusion** de couvrir tout un département, alors qu'on ne dispose que d'un point de mesure : pour des stations, la carte en points est plus honnête.
:::

# Dans RStudio : une carte interactive avec leaflet

Le paquet **leaflet** place les stations sur un fond OpenStreetMap zoomable. **Ce code ne s'exécute pas dans l'atelier.**

```r norun
library(leaflet)

palette <- colorNumeric(palette = "OrRd", domain = RECHAUFFEMENT$ECART)

m <- leaflet(RECHAUFFEMENT) |>
  addTiles() |>
  setView(lat = 46.5, lng = 2.5, zoom = 5.5) |>
  addCircleMarkers(lng = ~longitude, lat = ~latitude, radius = 10,
                   color = "black", weight = 1,
                   fillColor = ~palette(ECART), fillOpacity = 0.9,
                   label = ~paste0(name, " : +", round(ECART, 2), " °C")) |>
  addLegend(pal = palette, values = ~ECART, title = "°C", position = "bottomleft")
m

htmlwidgets::saveWidget(m, file = "CARTE_METEO.html")   # une page web à partager
```

::: note
Pour colorier des départements dans leaflet, on lit les contours avec le paquet **terra** (`vect("contours-des-departements….shp")`), puis on les fusionne avec l'indicateur par `terra::merge()` : la même logique que `left_join()`.
:::
