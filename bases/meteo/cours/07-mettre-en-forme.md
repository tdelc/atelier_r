---
titre: Mettre en forme un tableau
resume: pivot_wider() pour mettre une variable en colonnes, values_fill, et la technique du double pivot.
partie: Les bases
---

# Le problème : un tableau trop long

```r
vec_villes <- c("Rennes", "Perpignan", "Dijon", "Bastia", "Paris-Orly")

BDD_METEO |>
  filter(name %in% vec_villes) |>
  group_by(name, annee = year(date)) |>
  summarise(prop_pluie = mean(prcp > 0, na.rm = TRUE))
```

Une ligne par ville × année : impossible de comparer les villes d'un coup d'œil.

::: piege
Avez-vous remarqué ? `"Dijon"` est dans la liste… mais n'apparaît pas dans le résultat : il n'y a **pas** de station à Dijon dans la base. `filter()` ne signale rien, il ne garde simplement aucune ligne. Vérifiez toujours que toutes les modalités attendues sont bien là.
:::

# pivot_wider() : une variable en colonnes

::: usage
**Écriture :** `pivot_wider(names_from = COLONNE_A_PIVOTER, values_from = VALEURS_CENTRALES)`
:::

```r
BDD_METEO |>
  filter(name %in% vec_villes) |>
  group_by(name, annee = year(date)) |>
  summarise(prop_pluie = mean(prcp > 0, na.rm = TRUE)) |>
  pivot_wider(names_from = name, values_from = prop_pluie)
```

::: usage
Mettre la **ville en colonne** et l'**année en ligne** permet de lire une tendance de haut en bas et une comparaison de gauche à droite.

- Le tableau doit contenir **trois colonnes** : celle qui reste en lignes, celle qui passe en colonnes, et celle des valeurs.
- Pour choisir la colonne à pivoter, prenez celle qui a **le moins de modalités**.
:::

# values_fill : les cases vides d'un comptage

```r
BDD_METEO |>
  filter(name == "Lille", !is.na(cldc)) |>
  group_by(annee = year(date), cldc) |>
  count() |>
  pivot_wider(names_from = cldc, values_from = n, values_fill = 0)
```

::: usage
**`values_fill = 0`** : après un pivot, une case vide signifie « cette combinaison n'existe pas dans la base ». Pour un comptage, c'est bien un **zéro**. Sans cet argument, vous obtenez des `NA`.

**`!is.na(cldc)`** : on retire explicitement les jours sans mesure, pour ne pas obtenir une colonne `NA` dans le tableau. Et on le signale en note de lecture.
:::

# Des effectifs aux pourcentages

Ces effectifs ne sont pas comparables d'une année à l'autre (toutes les années n'ont pas le même nombre de mesures). On les passe en **pourcentage de l'année** :

```r
BDD_METEO |>
  filter(name == "Lille", !is.na(cldc)) |>
  group_by(annee = year(date), cldc) |>
  count() |>
  group_by(annee) |>                     # dénominateur = l'année
  mutate(prop = round(100 * n / sum(n), 1)) |>
  ungroup() |>
  select(annee, cldc, prop) |>
  pivot_wider(names_from = cldc, values_from = prop, values_fill = 0)
```

::: note
Le choix du **dénominateur** (total général, total de la ligne, total de la colonne) change complètement la lecture du tableau. Ici, chaque ligne fait 100 % : on lit la répartition du ciel **au sein de chaque année**.
:::

# La technique du double pivot

Un tableau avec deux lignes et beaucoup de colonnes se lit mal. On le **transpose** : un indicateur par ligne, une période par colonne.

```r
BDD_METEO |>
  filter(name == "Lille") |>
  mutate(periode = if_else(year(date) <= 2016, "2010_2016", "2017_2026")) |>
  group_by(periode) |>
  summarise(moy_temp   = mean(temp, na.rm = TRUE),
            moy_pluie  = mean(prcp, na.rm = TRUE),
            prop_pluie = mean(prcp > 0, na.rm = TRUE)) |>
  pivot_longer(-periode, names_to = "indicateur") |>
  pivot_wider(names_from = periode, values_from = value)
```

::: usage
1. `pivot_longer(-periode, names_to = "indicateur")` empile toutes les colonnes sauf `periode` : on obtient trois colonnes (`periode`, `indicateur`, `value`) ;
2. `pivot_wider(names_from = periode, values_from = value)` remet les périodes en colonnes.

Sans `names_to`, la colonne des noms s'appellerait `name` — ce qui entre en conflit avec la colonne des villes !
:::
