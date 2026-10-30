---
titre: Faire une carte
resume: Une carte par département - calculer un indicateur, le fusionner avec un fond de carte, le dessiner.
partie: Compléments
---

# Une carte, c'est une fusion

Une carte thématique (une couleur par département) se fabrique toujours en trois temps :

::: etape
1. **Calculer** l'indicateur par département (`group_by` + `summarise`).
2. **Fusionner** ce tableau avec un **fond de carte** : une table qui contient la forme de chaque département, et le même code département.
3. **Dessiner** en coloriant chaque forme selon l'indicateur.
:::

Dans l'atelier, le fond de carte est la table `CARTE_DEP` : chaque ligne est un **point du contour** d'un département (longitude, latitude), avec son code INSEE.

```r
CARTE_DEP

CARTE_DEP |> count(code_insee, nom)
```

::: note
Une seule ligne par département ne suffit pas à décrire une forme : il en faut des centaines de points. La colonne `groupe` distingue les morceaux d'un même département (les îles, par exemple).
:::

# Le fond de carte seul

```r
ggplot(CARTE_DEP, aes(x = long, y = lat, group = groupe)) +
  geom_polygon(fill = "white", colour = "grey40") +
  coord_quickmap() +
  theme_void()
```

::: usage
- `geom_polygon()` relie les points d'un même `groupe` pour former une surface ;
- `coord_quickmap()` respecte les proportions d'une carte (sinon la France paraît écrasée) ;
- `theme_void()` retire les axes et la grille, inutiles sur une carte.
:::

# 1. Calculer l'indicateur

```r
SYN_NAIS <- BDD_NAIS |>
  group_by(DEPNAIS) |>
  summarise(AGEMERE = mean(AGEMERE))

SYN_NAIS
```

# 2. Fusionner avec le fond de carte

La clé est le code département : `code_insee` dans le fond de carte, `DEPNAIS` dans notre tableau. Le fond de carte est la base **de gauche** (on garde toutes ses lignes), l'indicateur la base **de droite** (une ligne par département).

```r
CARTE <- CARTE_DEP |>
  left_join(SYN_NAIS, by = c("code_insee" = "DEPNAIS"))

CARTE
```

::: piege
Les départements d'outre-mer ne sont pas dans ce fond de carte métropolitain : ils sont présents dans `SYN_NAIS` mais disparaissent de la carte. Signalez-le sous la carte.
:::

# 3. Dessiner

```r
ggplot(CARTE, aes(x = long, y = lat, group = groupe, fill = AGEMERE)) +
  geom_polygon(colour = "white", linewidth = 0.2) +
  coord_quickmap() +
  scale_fill_distiller(palette = "YlOrBr", direction = 1) +
  labs(title = "Âge moyen des mères à la naissance, par département (2021)",
       fill = "Âge moyen", caption = "Source : INSEE. France métropolitaine.") +
  theme_void()
```

::: note
**Lecture :** les mères sont plus âgées à Paris et dans l'ouest de l'Île-de-France (plus de 32 ans), ainsi que dans quelques départements de grandes villes ou du littoral (Rhône, Alpes-Maritimes, Pyrénées-Atlantiques) ; elles sont plus jeunes dans le nord et le nord-est (Ardennes, Meuse, Pas-de-Calais : moins de 30 ans). `scale_fill_distiller()` applique une palette continue ; `direction = 1` met les couleurs foncées sur les valeurs élevées.
:::

# Une carte en classes

Une palette continue rend les petites différences difficiles à lire. On peut découper l'indicateur en **classes** avec `cut()`, puis utiliser une palette de couleurs distinctes.

```r
CARTE <- CARTE |>
  mutate(CLASSE = cut(AGEMERE, breaks = c(28, 30, 31, 32, 34),
                      labels = c("Moins de 30 ans", "30 à 31 ans", "31 à 32 ans", "32 ans et plus")))

ggplot(CARTE, aes(x = long, y = lat, group = groupe, fill = CLASSE)) +
  geom_polygon(colour = "white", linewidth = 0.2) +
  coord_quickmap() +
  scale_fill_brewer(palette = "YlOrBr") +
  labs(title = "Âge moyen des mères à la naissance (2021)", fill = NULL) +
  theme_void()
```

::: piege
Le choix des bornes change **beaucoup** l'image d'une carte. Vérifiez la distribution de l'indicateur (`summary(SYN_NAIS$AGEMERE)`) avant de fixer les classes, et ne cherchez pas les bornes qui « font joli ».
:::

# Une autre carte, même méthode

La part des naissances dont l'enfant porte le nom de la mère seule (`ORIGINOM == 2`) :

```r
SYN_NOM <- BDD_NAIS |>
  filter(!is.na(ORIGINOM)) |>
  group_by(DEPNAIS) |>
  summarise(PART_NOM_MERE = mean(ORIGINOM == 2))

CARTE_DEP |>
  left_join(SYN_NOM, by = c("code_insee" = "DEPNAIS")) |>
  ggplot(aes(x = long, y = lat, group = groupe, fill = PART_NOM_MERE)) +
  geom_polygon(colour = "white", linewidth = 0.2) +
  coord_quickmap() +
  scale_fill_distiller(palette = "Purples", direction = 1, labels = percent) +
  labs(title = "Part des enfants portant le nom de leur mère (2021)", fill = NULL) +
  theme_void()
```

# Dans RStudio : une carte interactive avec terra et leaflet

Avec les fichiers de contours (`.shp`, `.shx`, `.dbf`, `.prj`, tous dans le même dossier), les paquets **terra** et **leaflet** produisent une carte zoomable sur un fond OpenStreetMap. **Ce code ne s'exécute pas dans l'atelier.**

```r norun
library(terra)
library(leaflet)

FR_SHP <- vect("contours-des-departements-francais-issus-dopenstreetmap.shp")

SYN_NAIS <- BDD_NAIS |>
  group_by(DEPNAIS) |>
  summarise(AGEMERE = mean(AGEMERE))

# La fusion géographique : même principe que left_join()
CARTE <- terra::merge(FR_SHP, SYN_NAIS, by.x = "code_insee", by.y = "DEPNAIS")

mypalette <- colorBin(palette = "YlOrBr", domain = CARTE$AGEMERE,
                      na.color = "transparent", bins = 5)

m <- leaflet(CARTE) |>
  addTiles() |>
  setView(lat = 47.5, lng = 3, zoom = 5.5) |>
  addPolygons(stroke = TRUE, color = "black", weight = 1,
              fillColor = ~mypalette(AGEMERE), fillOpacity = 0.5) |>
  addLegend(pal = mypalette, values = ~AGEMERE, opacity = 0.9,
            title = "Âge", position = "bottomleft")
m

htmlwidgets::saveWidget(m, file = "CARTE_NAIS.html")   # une page web à partager
```

::: note
La logique est **exactement la même** : un indicateur par département, une fusion par le code département (`terra::merge` joue le rôle de `left_join`), puis une couleur par département. `terra::aggregate(FR_SHP, by = "nom")` permet de regrouper des contours (par exemple les départements en régions, si la table contient la région).
:::
