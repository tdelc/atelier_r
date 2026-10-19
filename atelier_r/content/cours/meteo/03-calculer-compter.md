---
titre: Calculer et compter
resume: Résumer une base en un indicateur avec summarise(), compter les lignes avec count(), gérer les NA.
partie: Les bases
---

# summarise() : calculer un indicateur

::: usage
**À quoi ça sert ?** Résumer tout le tableau (ou chaque groupe, voir la leçon suivante) en **une valeur** : moyenne, médiane, effectif…

**Écriture :** `BDD |> summarise(NOM = fonction(COLONNE))`
:::

```r
# Température moyenne
BDD_METEO |> summarise(mean(temp))
```

Le résultat est `NA` ! Il suffit d'**une seule** valeur manquante dans la colonne pour que la moyenne soit inconnue.

# na.rm = TRUE : ignorer les valeurs manquantes

```r
BDD_METEO |> summarise(TEMP_MOY = mean(temp, na.rm = TRUE))
```

::: usage
`na.rm = TRUE` (*NA remove*) demande à la fonction d'ignorer les valeurs manquantes. Il fonctionne avec `mean()`, `median()`, `min()`, `max()`, `sum()`, `sd()`, `quantile()`.
:::

::: piege
Ignorer les `NA`, c'est faire l'hypothèse qu'ils sont **répartis au hasard**. Si les relevés manquent surtout en hiver, la moyenne sera artificiellement élevée. Gardez toujours un œil sur le nombre de `NA`.
:::

# Plusieurs indicateurs d'un coup

| Fonction | Calcule |
|---|---|
| `mean()` | la moyenne |
| `median()` | la médiane |
| `min()`, `max()` | le minimum, le maximum |
| `sd()` | l'écart-type |
| `quantile(x, 0.9)` | un quantile (ici le 9e décile) |
| `n()` | le nombre de lignes |

```r
# À Lille
BDD_METEO |>
  filter(name == "Lille") |>
  summarise(TMAX_MOY  = mean(tmax, na.rm = TRUE),
            TMAX_MED  = median(tmax, na.rm = TRUE),
            TMAX_MIN  = min(tmax, na.rm = TRUE),
            TMAX_MAX  = max(tmax, na.rm = TRUE),
            TMAX_SD   = sd(tmax, na.rm = TRUE),
            TMAX_D9   = quantile(tmax, 0.9, na.rm = TRUE),
            NB_JOURS  = n())
```

# count() : compter les lignes

::: usage
**À quoi ça sert ?** Compter le nombre de lignes, donc ici le nombre de **jours × villes**. Le résultat est une colonne appelée `n`.
:::

```r
# Nombre de jours de relevés à Nice
BDD_METEO |>
  filter(name == "Nice") |>
  count()

# Nombre de jours à plus de 35 °C, toutes villes confondues
BDD_METEO |>
  filter(tmax > 35) |>
  count()
```

# Compter avec sum() : le nombre de VRAI

Une condition donne `TRUE` ou `FALSE` pour chaque ligne, et `TRUE` compte 1. La **somme** d'une condition donne le **nombre** de lignes qui la vérifient, sa **moyenne** la **proportion**.

```r
BDD_METEO |>
  filter(name == "Lille") |>
  summarise(NB_JOURS_GEL   = sum(tmin < 0, na.rm = TRUE),
            PART_JOURS_GEL = mean(tmin < 0, na.rm = TRUE))
```

::: note
**Lecture :** sur toute la période, 537 jours à Lille ont connu une température minimale négative, soit près de 9 % des jours.
:::
