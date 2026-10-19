---
titre: Premiers graphiques avec ggplot2
resume: Construire un graphique couche par couche - données, axes, géométrie, habillage.
partie: Pour aller plus loin
---

# La grammaire de ggplot2

`hist()` ou `barplot()` donnent un graphique rapide pour **vous**. Pour un graphique destiné à **un rapport**, on utilise `ggplot2` (chargé avec le tidyverse). Un graphique se construit par **couches**, reliées par des `+` :

::: etape
1. `ggplot(DONNEES, aes(x = ..., y = ...))` — quelles données, quelle variable sur quel axe ?
2. `geom_...()` — quelle forme : barres (`geom_col`, `geom_bar`), courbe (`geom_line`), points (`geom_point`), histogramme (`geom_histogram`)…
3. `labs()`, `theme_...()` — l'habillage : titres, style.
:::

::: piege
Entre les couches, c'est `+` et non `|>`. Le pipe sert à enchaîner des **calculs** ; le `+` assemble les **couches** d'un graphique.
:::

# Un histogramme

```r
ggplot(BDD_NAIS, aes(x = AGEMERE)) +
  geom_histogram(binwidth = 1, fill = "#3b6ea5", colour = "white") +
  labs(title = "Âge des mères à la naissance, France, 2021",
       x = "Âge de la mère (17 = 17 ans ou moins, 46 = 46 ans ou plus)",
       y = "Nombre de naissances") +
  theme_minimal()
```

# Un diagramme en barres à partir d'un tableau

La méthode la plus sûre : **calculer d'abord** le tableau avec les verbes que vous connaissez, **dessiner ensuite**.

```r
NAIS_MOIS <- BDD_NAIS |>
  count(MNAIS)

ggplot(NAIS_MOIS, aes(x = MNAIS, y = n)) +
  geom_col(fill = "#3b6ea5") +
  labs(title = "Naissances par mois, 2021", x = "Mois", y = "Naissances") +
  theme_minimal()
```

::: note
**Lecture :** les naissances sont plus nombreuses de juillet à octobre. Mais attention : les mois n'ont pas tous le même nombre de jours ! Février (28 jours) est mécaniquement désavantagé.
:::

# Corriger : des naissances par jour

```r
NAIS_MOIS <- BDD_NAIS |>
  count(MNAIS) |>
  mutate(NB_JOURS = c(31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31),
         NAIS_PAR_JOUR = n / NB_JOURS)

ggplot(NAIS_MOIS, aes(x = MNAIS, y = NAIS_PAR_JOUR)) +
  geom_col(fill = "#3b6ea5") +
  geom_hline(yintercept = mean(NAIS_MOIS$NAIS_PAR_JOUR), linetype = "dashed") +
  labs(title = "Naissances par jour, selon le mois (2021)",
       x = "Mois", y = "Naissances par jour") +
  theme_minimal()
```

::: note
Rapporté au nombre de jours, février dépasse janvier : le creux est en **janvier**, et le pic en septembre-octobre ressort encore plus nettement. Un même phénomène peut donner deux images différentes selon l'indicateur : c'est un **choix** à expliciter dans votre rapport.
:::

# Comparer des groupes avec la couleur

```r
PART_MARIES <- BDD_NAIS |>
  mutate(MARIAGE = AMAR != "0000",
         NATIONALITE = if_else(INDNATM == 1, "Mère française", "Mère étrangère")) |>
  group_by(AGEMERE, NATIONALITE) |>
  summarise(PART = mean(MARIAGE))

ggplot(PART_MARIES, aes(x = AGEMERE, y = PART, colour = NATIONALITE)) +
  geom_line(linewidth = 1) +
  scale_y_continuous(labels = percent) +
  labs(title = "Part des naissances de parents mariés, selon l'âge de la mère",
       x = "Âge de la mère", y = NULL, colour = NULL) +
  theme_minimal() +
  theme(legend.position = "bottom")
```

::: usage
`colour = VARIABLE` dans `aes()` dessine une courbe par modalité, avec une légende. `scale_y_continuous(labels = percent)` affiche l'axe en pourcentages.
:::

# Un graphique par groupe : facet_wrap()

```r
BDD_NAIS |>
  filter(DEPNAIS %in% c("59", "75", "13", "69")) |>
  ggplot(aes(x = AGEMERE)) +
  geom_histogram(binwidth = 2, fill = "#3b6ea5", colour = "white") +
  facet_wrap(~ DEPNAIS) +
  labs(title = "Âge des mères dans quatre départements",
       x = "Âge de la mère", y = "Naissances") +
  theme_minimal()
```

::: note
`facet_wrap(~ VARIABLE)` répète le graphique pour chaque modalité. Pour aller plus loin, l'onglet **Dashboard** montre ce que l'on peut construire avec ces mêmes outils.
:::
