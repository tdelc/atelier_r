---
titre: Graphiques avec ggplot2 - la suite
resume: Barres, facettes, boîtes à moustaches, densités, nuages de points, aires à 100 % - et l'export.
partie: Compléments
---

# Préparer des variables catégorielles

Pour les graphiques de cette leçon, on crée trois variables : la saison, le type de ciel (à partir de la couverture nuageuse `cldc`, en octas) et la classe de pluie. Référence utile pour trouver des idées : [r-graph-gallery.com](https://www.r-graph-gallery.com/).

```r
BDD_METEO <- BDD_METEO |>
  filter(year(date) < 2026) |>                   # on écarte l'année incomplète
  mutate(annee = year(date),
         mois  = month(date),
         saison = case_when(mois %in% c(12, 1, 2) ~ "1_Hiver",
                            mois %in% 3:5         ~ "2_Printemps",
                            mois %in% 6:8         ~ "3_Eté",
                            .default              = "4_Automne"),
         CIEL = cut(cldc, breaks = c(-1, 2, 5, 7, 9),
                    labels = c("Dégagé", "Partiellement nuageux", "Très nuageux", "Couvert")),
         CD_PLUIE = cut(prcp, breaks = c(-1, 0, 1, 5, 10, 1000),
                        labels = c("Sec", "Infime", "Faible", "Moyenne", "Forte")))

BDD_METEO |> count(CIEL)
```

::: note
`cut()` produit un **facteur** dont l'ordre est celui des classes : les graphiques respecteront cet ordre, du ciel dégagé au ciel couvert.
:::

# Le diagramme en barres d'une variable catégorielle

`geom_bar()` **compte** lui-même les lignes : pas besoin de `count()` avant.

```r
BDD_METEO |>
  filter(name == "Lille", !is.na(CIEL)) |>
  ggplot(aes(x = CIEL)) +
  geom_bar() +
  coord_flip()
```

::: usage
Avec des libellés longs, **pivotez** le graphique avec `coord_flip()`. On retire les jours sans mesure (`!is.na(CIEL)`) pour ne pas obtenir une barre `NA`, et on le signale sous le graphique.
:::

# Couleurs, titres, thème

```r
BDD_METEO |>
  filter(name == "Lille", !is.na(CIEL)) |>
  ggplot(aes(x = CIEL, fill = CIEL)) +
  geom_bar() +
  coord_flip() +
  scale_fill_brewer(palette = "Blues") +
  labs(title = "Le ciel à Lille",
       subtitle = "Jours selon la couverture nuageuse, 2010-2025 (jours mesurés)",
       x = NULL, y = "Nombre de jours") +
  theme_minimal() +
  theme(legend.position = "none")
```

::: usage
- `fill = VARIABLE` colore les barres ; `scale_fill_brewer(palette = …)` choisit une palette (`"Set2"`, `"Set3"`, `"Blues"`…) ;
- `labs()` regroupe titre, sous-titre et noms des axes ;
- `theme(legend.position = "none")` supprime une légende inutile (la couleur répète ici l'axe).
:::

# Deux variables catégorielles : empilé ou à 100 %

```r
VILLES <- c("Lille", "Rennes", "Strasbourg", "Nice", "Perpignan")

# Effectifs empilés
BDD_METEO |>
  filter(name %in% VILLES, !is.na(CD_PLUIE)) |>
  ggplot(aes(x = name, fill = CD_PLUIE)) +
  geom_bar() +
  coord_flip() +
  theme_minimal()

# Chaque barre ramenée à 100 %
BDD_METEO |>
  filter(name %in% VILLES, !is.na(CD_PLUIE)) |>
  ggplot(aes(x = name, fill = CD_PLUIE)) +
  geom_bar(position = "fill") +
  coord_flip() +
  scale_y_continuous(labels = percent) +
  scale_fill_brewer(palette = "Blues") +
  theme_minimal()
```

::: note
Le premier graphique dépend du nombre de jours mesurés dans chaque ville ; le second **compare la répartition** : la part des jours secs est bien plus grande à Nice et Perpignan. Voir la leçon « Les pourcentages d'un tableau croisé ».
:::

# Une distribution par groupe : la boîte à moustaches

```r
BDD_METEO |>
  filter(name %in% VILLES) |>
  ggplot(aes(x = name, y = tmin, fill = name)) +
  geom_boxplot() +
  labs(title = "Températures minimales selon la ville", x = NULL, y = "°C") +
  theme_minimal() +
  theme(legend.position = "none")
```

::: usage
La boîte va du 1er au 3e quartile, le trait central est la **médiane**, les moustaches s'étendent jusqu'aux valeurs non extrêmes. Idéal pour comparer **une variable numérique** entre **plusieurs groupes**.
:::

# Histogramme et densité

```r
BDD_METEO |>
  filter(name == "Lyon / Bron") |>
  ggplot(aes(x = tmax)) +
  geom_histogram(binwidth = 1, fill = "grey", colour = "black") +
  labs(title = "Températures maximales à Lyon", x = "°C", y = "Jours")

# Variante : la courbe de densité, pour superposer les saisons
BDD_METEO |>
  filter(name == "Lyon / Bron") |>
  ggplot(aes(x = tmax, fill = saison)) +
  geom_density(alpha = 0.4) +
  labs(title = "Températures maximales à Lyon, selon la saison",
       x = "°C", y = "Densité", fill = NULL) +
  theme_minimal()
```

::: note
`alpha = 0.4` rend les couleurs transparentes, pour voir les courbes superposées. Le printemps et l'automne se chevauchent largement : deux saisons « intermédiaires » aux températures proches.
:::

# Le nuage de points et les lignes de repère

```r
BDD_METEO |>
  filter(name %in% c("Lille", "Nice")) |>
  ggplot(aes(x = tmin, y = tmax, colour = saison)) +
  geom_point(alpha = 0.3, size = 0.8) +
  geom_vline(xintercept = 20, linetype = 2, linewidth = 1, colour = "red") +
  geom_hline(yintercept = 30, linetype = 2, linewidth = 1, colour = "red") +
  facet_wrap(~ name) +
  labs(title = "Température minimale et maximale du jour",
       x = "Minimale (°C)", y = "Maximale (°C)", colour = NULL) +
  theme_minimal()
```

::: usage
`geom_vline(xintercept = …)` et `geom_hline(yintercept = …)` tracent des repères : ici, les nuits à plus de 20 °C (à droite de la ligne verticale) et les journées à plus de 30 °C (au-dessus de la ligne horizontale). `linetype` règle le style du trait, `linewidth` son épaisseur, `colour` sa couleur.
:::

# Des graphiques par groupe : facet_grid()

```r
BDD_METEO |>
  filter(name %in% c("Lille", "Strasbourg", "Nice", "Rennes")) |>
  ggplot(aes(x = rhum)) +
  geom_histogram(binwidth = 2) +
  facet_grid(saison ~ name) +
  labs(title = "Humidité de l'air selon la ville et la saison", x = "%", y = "Jours") +
  theme_minimal()
```

::: usage
`facet_wrap(~ A)` répète le graphique pour chaque modalité de `A` ; `facet_grid(A ~ B)` croise deux variables : `A` en lignes, `B` en colonnes.
:::

# Calculer avant de dessiner : l'évolution d'une moyenne

```r
BDD_METEO |>
  filter(name %in% c("Lille", "Nice", "Rennes", "Strasbourg")) |>
  group_by(annee, name) |>
  summarise(PLUIE_MOY = mean(prcp, na.rm = TRUE)) |>
  ggplot(aes(x = annee, y = PLUIE_MOY, colour = name)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  labs(title = "Précipitations moyennes par jour, selon l'année",
       x = NULL, y = "mm par jour", colour = NULL) +
  theme_minimal()
```

# L'évolution d'une variable catégorielle : l'aire à 100 %

```r
BDD_METEO |>
  filter(name == "Lille", !is.na(CD_PLUIE)) |>
  count(annee, CD_PLUIE) |>
  ggplot(aes(x = annee, y = n, fill = CD_PLUIE)) +
  geom_area(position = "fill") +
  scale_y_continuous(labels = percent) +
  scale_fill_brewer(palette = "Blues") +
  labs(title = "Lille : répartition des jours selon la pluie",
       x = NULL, y = NULL, fill = NULL) +
  theme_minimal()
```

::: note
Chaque année fait 100 % : on suit la **répartition** des jours, indépendamment du nombre de relevés manquants. Quand l'année est en abscisse, on ne pivote pas le graphique.
:::

# Exporter un graphique

Dans RStudio, deux façons d'enregistrer un graphique en image. **Ces commandes écrivent des fichiers : elles ne fonctionnent pas dans l'atelier.**

```r norun
# 1. Avec ggsave() : enregistre le dernier graphique ggplot affiché
ggsave("graphique_pluie.png", width = 8, height = 5, dpi = 300)

# 2. Avec png() ... dev.off() : pour tout type de graphique
png(filename = "graphique.png", width = 800, height = 500)
ggplot(BDD_METEO, aes(x = tmax)) + geom_histogram(binwidth = 1)
dev.off()
```

::: piege
Avec `png()`, n'oubliez pas `dev.off()` : c'est lui qui ferme et écrit le fichier. Sans lui, le fichier reste vide.
:::
