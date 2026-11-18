---
titre: Mettre en forme un tableau
resume: Passer des modalités en colonnes avec pivot_wider(), trier avec arrange(), dédoublonner avec distinct().
partie: Les bases
---

# Le problème : un tableau trop long

Après un `group_by()` sur deux variables, on obtient une ligne par croisement. Difficile à lire !

```r
# 1 ligne par croisement ORIGINOM × INDLNM
BDD_NAIS |>
  group_by(ORIGINOM, INDLNM) |>
  count()
```

# pivot_wider() : passer une variable en colonnes

::: usage
**À quoi ça sert ?** Rendre lisible un tableau croisé : les modalités d'une des deux variables passent **en colonnes**.

**Écriture :** `pivot_wider(names_from = COLONNE_A_PIVOTER, values_from = VALEURS_CENTRALES)`
:::

```r
# 1 ligne par ORIGINOM, 1 colonne par INDLNM
BDD_NAIS |>
  group_by(ORIGINOM, INDLNM) |>
  count() |>
  pivot_wider(names_from = INDLNM, values_from = n)
```

::: note
- Le tableau doit contenir **trois colonnes** : celle qui reste en lignes, celle qui passe en colonnes, et celle des valeurs.
- Pour choisir la colonne à pivoter, prenez celle qui a **le moins de modalités**.
- Après un `count()`, la colonne des valeurs s'appelle `n`.
:::

# names_prefix : des noms de colonnes lisibles

```r
BDD_NAIS |>
  group_by(SEXE, ORIGINOM) |>
  summarise(AGE_MERE = mean(AGEMERE)) |>
  pivot_wider(names_from = SEXE,
              values_from = AGE_MERE,
              names_prefix = "SEXE_")
```

::: usage
`names_prefix = "SEXE_"` ajoute un préfixe aux nouveaux noms de colonnes : `SEXE_1`, `SEXE_2` au lieu de `1`, `2` (des noms qui commencent par un chiffre sont pénibles à manipuler).
:::

# arrange() et desc() : trier les lignes

::: usage
**Écriture :** `BDD |> arrange(COLONNE)` (croissant) ou `BDD |> arrange(desc(COLONNE))` (décroissant)
:::

```r
# Les départements avec le plus de naissances
BDD_NAIS |>
  count(DEPNAIS) |>
  arrange(desc(n))
```

::: note
`count(DEPNAIS)` est un raccourci pour `group_by(DEPNAIS) |> count()`.
:::

# Tout combiner : le pic de septembre

« Nombre de naissances par département et par mois, avec une colonne par mois. Quel département a le plus fort pic en septembre ? »

```r
BDD_NAIS |>
  group_by(DEPNAIS, MNAIS) |>
  count() |>
  pivot_wider(names_from = MNAIS, names_prefix = "MOIS_", values_from = n) |>
  arrange(desc(MOIS_09))
```

::: piege
Ce tableau répond à « quel département a le **plus de naissances** en septembre » : Paris arrive en tête… parce que c'est le département qui a le plus de naissances tout court ! Pour parler d'un **pic**, il faudrait comparer septembre aux autres mois du même département, par exemple avec la **part** de septembre dans le total annuel.
:::

# Pour aller plus loin : la part de septembre

On remplace le **nombre** par une **part** : la proportion des naissances de l'année qui ont lieu en septembre, dans chaque département.

```r
BDD_NAIS |>
  group_by(DEPNAIS) |>
  summarise(NB_NAISSANCES = n(),
            PART_SEPTEMBRE = mean(MNAIS == "09")) |>
  arrange(desc(PART_SEPTEMBRE))
```

::: note
`mean(MNAIS == "09")` : la condition donne `TRUE` / `FALSE` pour chaque naissance, et la moyenne en donne la proportion. Si les naissances étaient réparties uniformément, la part de septembre serait d'environ 30 / 365 = 8,2 %. Le classement n'a plus rien à voir avec le précédent : comparer des **effectifs** ou des **proportions** ne répond pas à la même question.
:::

# distinct() : supprimer les doublons

```r
BDD_NAIS |>
  select(SEXE, NBENF) |>
  distinct()
```

::: usage
`distinct()` ne garde que les **lignes uniques**. Souvent utilisé après un `select()` pour voir les combinaisons de valeurs qui existent.
:::
