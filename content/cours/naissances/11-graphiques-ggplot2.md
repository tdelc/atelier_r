---
titre: Graphiques avec ggplot2 - la suite
resume: Barres, facettes, boîtes à moustaches, densités, nuages de points, aires à 100 % - et l'export.
partie: Compléments
---

# Le diagramme en barres d'une variable catégorielle

`geom_bar()` **compte** lui-même les lignes : pas besoin de `count()` avant. Référence utile pour trouver des idées : [r-graph-gallery.com](https://www.r-graph-gallery.com/).

```r
ggplot(BDD_NAIS, aes(x = factor(ORIGINOM))) +
  geom_bar()
```

::: piege
`ORIGINOM` est codée en chiffres : sans `factor()`, ggplot2 la traiterait comme un nombre continu. Et les codes 1 à 5 ne disent rien au lecteur : il faut des **libellés**.
:::

# Des libellés et un ordre avec factor()

```r
BDD_NAIS <- BDD_NAIS |>
  mutate(ORIGINE_NOM = factor(ORIGINOM,
                              levels = c(1, 2, 3, 4, 5),
                              labels = c("Nom du père", "Nom de la mère",
                                         "Père-Mère", "Mère-Père", "Autre")))

ggplot(BDD_NAIS, aes(x = ORIGINE_NOM)) +
  geom_bar() +
  coord_flip()
```

::: usage
`factor(VARIABLE, levels = …, labels = …)` : `levels` donne les valeurs d'origine **dans l'ordre voulu**, `labels` les libellés à afficher. Les valeurs absentes de `levels` deviennent `NA`.

Avec des libellés longs, **pivotez** le graphique avec `coord_flip()`.
:::

# Couleurs, titres, thème

```r
BDD_NAIS |>
  filter(!is.na(ORIGINE_NOM)) |>
  ggplot(aes(x = ORIGINE_NOM, fill = ORIGINE_NOM)) +
  geom_bar() +
  coord_flip() +
  scale_fill_brewer(palette = "Set2") +
  labs(title = "Origine du nom de famille de l'enfant",
       subtitle = "Naissances en France, 2021",
       x = NULL, y = "Nombre de naissances") +
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
BDD_NAIS <- BDD_NAIS |>
  mutate(MARIES = if_else(AMAR != "0000", "Mariés", "Non mariés"))

# Effectifs empilés
BDD_NAIS |>
  filter(!is.na(ORIGINE_NOM)) |>
  ggplot(aes(x = MARIES, fill = ORIGINE_NOM)) +
  geom_bar() +
  theme_minimal()

# Chaque barre ramenée à 100 %
BDD_NAIS |>
  filter(!is.na(ORIGINE_NOM)) |>
  ggplot(aes(x = MARIES, fill = ORIGINE_NOM)) +
  geom_bar(position = "fill") +
  scale_y_continuous(labels = percent) +
  theme_minimal()
```

::: note
Le premier graphique montre surtout qu'il y a plus de naissances hors mariage ; le second permet de **comparer la répartition** des noms dans les deux groupes : l'enfant porte beaucoup plus souvent un nom autre que celui du père quand les parents ne sont pas mariés. Voir la leçon « Les pourcentages d'un tableau croisé ».
:::

# Une distribution par groupe : la boîte à moustaches

```r
BDD_NAIS |>
  mutate(SIT_MERE = case_when(SITUATMR == "S"  ~ "Salariée",
                              SITUATMR == "NS" ~ "Non salariée",
                              SITUATMR == "ND" ~ "Non déclarée",
                              .default = "Sans activité")) |>
  ggplot(aes(x = SIT_MERE, y = AGEXACTM, fill = SIT_MERE)) +
  geom_boxplot() +
  labs(title = "Âge de la mère selon sa situation professionnelle",
       x = NULL, y = "Âge exact de la mère") +
  theme_minimal() +
  theme(legend.position = "none")
```

::: usage
La boîte va du 1er au 3e quartile, le trait central est la **médiane**, les moustaches s'étendent jusqu'aux valeurs non extrêmes. Idéal pour comparer **une variable numérique** entre **plusieurs groupes**.
:::

# Histogramme et densité

```r
ggplot(BDD_NAIS, aes(x = AGEXACTP)) +
  geom_histogram(binwidth = 1, fill = "grey", colour = "black") +
  labs(title = "Âge exact du père", x = "Âge", y = "Naissances")

# Variante : la courbe de densité, pour superposer plusieurs groupes
BDD_NAIS |>
  ggplot(aes(x = AGEXACTM, fill = MARIES)) +
  geom_density(alpha = 0.4, bw = 0.8) +
  labs(title = "Âge de la mère selon que les parents sont mariés ou non",
       x = "Âge exact de la mère", y = "Densité", fill = NULL) +
  theme_minimal()
```

::: note
`alpha = 0.4` rend les couleurs transparentes, pour voir les deux courbes superposées. `bw = 0.8` définit le lissage de la courbe de densité, pour éviter les à-coups de la variable entière. La densité compare des **formes** de distribution, indépendamment de la taille des groupes.
:::

# Le nuage de points (et ses pièges)

Avec 742 000 naissances, un nuage de points serait illisible (et lent). On tire un **échantillon**, et on « secoue » les points avec `jitter`, car les âges sont des nombres entiers : sans cela, des milliers de points se superposent exactement.

```r
set.seed(2021)
BDD_NAIS |>
  slice_sample(n = 3000) |>
  ggplot(aes(x = AGEMERE, y = AGEPERE)) +
  geom_point(position = "jitter", alpha = 0.3) +
  geom_abline(slope = 1, intercept = 0, linetype = 2, colour = "red") +
  labs(title = "Âge du père selon l'âge de la mère (échantillon de 3 000 naissances)",
       x = "Âge de la mère", y = "Âge du père") +
  theme_minimal()
```

::: note
La droite rouge (`geom_abline`) marque l'égalité des âges : la plupart des points sont **au-dessus**, le père est en général plus âgé. Pour tracer une ligne horizontale ou verticale : `geom_hline(yintercept = …)`, `geom_vline(xintercept = …)`, avec `linetype` (pointillés), `linewidth` (épaisseur) et `colour`.
:::

# Des graphiques par groupe : facet_wrap() et facet_grid()

Pour comparer plusieurs groupes, plutôt que superposer les graphiques, il est possible de répliquer le graphique pour chaque groupe. `facet_wrap()` et `facet_grid()` réalisent cela facilement à partir d'un graphique existant.

```r
BDD_NAIS |>
  filter(DEPNAIS %in% c("59", "75", "13", "69")) |>
  ggplot(aes(x = AGEXACTM)) +
  geom_histogram(binwidth = 1) +
  facet_grid(MARIES ~ DEPNAIS) +
  labs(x = "Âge de la mère", y = "Naissances") +
  theme_minimal()
```

::: usage
`facet_wrap(~ A)` répète le graphique pour chaque modalité de `A` ; `facet_grid(A ~ B)` croise deux variables : `A` en lignes, `B` en colonnes.
:::

Ici, les axes sont "fixés" en abscisse et en ordonnée pour tous les graphiques. Avec l'argument `scales = "free_y"`, on rend libre l'axe des ordonnées sur les deux lignes :

```r
BDD_NAIS |>
  filter(DEPNAIS %in% c("59", "75", "13", "69")) |>
  ggplot(aes(x = AGEXACTM)) +
  geom_histogram(binwidth = 1) +
  facet_grid(MARIES ~ DEPNAIS, scales = "free_y") +
  labs(x = "Âge de la mère", y = "Naissances") +
  theme_minimal()
```

# Calculer avant de dessiner : l'aire à 100 %

Pour suivre une **répartition** (ici, celle des naissances selon le statut des parents au fil des mois), on calcule d'abord le tableau, puis on le dessine avec `geom_area(position = "fill")`.

```r
BDD_NAIS |>
  count(MOIS = as.numeric(MNAIS), MARIES) |>
  ggplot(aes(x = MOIS, y = n, fill = MARIES)) +
  geom_area(position = "fill") +
  scale_x_continuous(breaks = 1:12) +
  scale_y_continuous(labels = percent) +
  labs(title = "Part des naissances selon le statut des parents, mois par mois",
       x = "Mois", y = NULL, fill = NULL) +
  theme_minimal()
```

::: note
Les deux aires sont presque horizontales : la part des naissances hors mariage ne varie pas selon le mois. Un graphique « plat » est aussi un résultat.
:::

# Exporter un graphique

Dans RStudio, deux façons d'enregistrer un graphique en image. **Ces commandes écrivent des fichiers : elles ne fonctionnent pas dans l'atelier.**

```r norun
# 1. Avec ggsave() : enregistre le dernier graphique ggplot affiché
ggsave("graphique_noms.png", width = 8, height = 5, dpi = 300)

# 2. Avec png() ... dev.off() : pour tout type de graphique
png(filename = "graphique.png", width = 800, height = 500)
ggplot(BDD_NAIS, aes(x = AGEXACTM)) + geom_histogram(binwidth = 1)
dev.off()
```

::: piege
Avec `png()`, n'oubliez pas `dev.off()` : c'est lui qui ferme et écrit le fichier. Sans lui, le fichier reste vide.
:::
