---
titre: Ajouter et fusionner des bases
resume: Empiler des bases avec bind_rows(), associer les informations d'une autre table avec left_join().
partie: Compléments
---

# Deux opérations à ne pas confondre

| Opération | On veut… | Fonction | Image |
|---|---|---|---|
| **Ajouter** (empiler) | mettre des lignes **sous** d'autres lignes | `bind_rows()` | on allonge le tableau |
| **Fusionner** (joindre) | ajouter des **colonnes** venant d'une autre table | `left_join()`… | on élargit le tableau |

# Ajouter des bases l'une sous l'autre : bind_rows()

Sur meteostat.net, on télécharge souvent **un fichier par ville**. Pour les analyser ensemble, il faut les **empiler**. Les bases doivent représenter le même type d'observations (ici, une ville × un jour) et avoir **les mêmes colonnes** (même nom, même type).

On simule trois fichiers avec `filter()`, en ne gardant que quelques colonnes, et **sans** le nom de la ville, comme dans un vrai fichier d'export.

```r
METEO_LILLE     <- BDD_METEO |> filter(name == "Lille")     |> select(date, temp, prcp)
METEO_MARSEILLE <- BDD_METEO |> filter(name == "Marseille / Marignane") |> select(date, temp, prcp)
METEO_RENNES    <- BDD_METEO |> filter(name == "Rennes")    |> select(date, temp, prcp)

head(METEO_LILLE, 3)
```

# Ajouter la ville, puis empiler

Chaque fichier ne dit pas de quelle ville il s'agit : il faut **ajouter cette information avant d'empiler**, sinon on ne pourra plus distinguer les villes.

```r
METEO_LILLE     <- METEO_LILLE     |> mutate(VILLE = "Lille")
METEO_MARSEILLE <- METEO_MARSEILLE |> mutate(VILLE = "Marseille")
METEO_RENNES    <- METEO_RENNES    |> mutate(VILLE = "Rennes")

METEO_3VILLES <- bind_rows(METEO_LILLE, METEO_MARSEILLE, METEO_RENNES)

nrow(METEO_LILLE) + nrow(METEO_MARSEILLE) + nrow(METEO_RENNES)
nrow(METEO_3VILLES)
METEO_3VILLES |> count(VILLE)
```

::: usage
Le nombre de lignes de la base empilée est la **somme** des trois : c'est la vérification à faire après chaque `bind_rows()`. Variante sans `mutate()` : `bind_rows(Lille = METEO_LILLE, Rennes = METEO_RENNES, .id = "VILLE")`.
:::

::: piege
Si une colonne manque dans l'une des bases, `bind_rows()` la crée et la remplit de `NA`. Une colonne nommée `temp` dans un fichier et `TEMP` dans l'autre donnerait **deux** colonnes à moitié vides : vérifiez les noms avec `glimpse()` avant d'empiler.
:::

# Fusionner : une table d'informations sur les villes

On veut ajouter à chaque relevé des informations sur la **ville** : sa région, et si elle est sur le littoral. On crée cette petite table avec `tibble()` (dans la réalité, elle viendrait d'un autre fichier).

```r
INFO_VILLES <- tibble(
  name = c("Bastia", "Lille", "Lyon / Bron", "Marseille / Marignane", "Montelimar",
           "Montpellier", "Nancy / Essey", "Nantes", "Nice", "Paris-Orly",
           "Perpignan", "Rennes", "Strasbourg"),
  REGION = c("Corse", "Hauts-de-France", "Auvergne-Rhône-Alpes", "Provence-Alpes-Côte d'Azur",
             "Auvergne-Rhône-Alpes", "Occitanie", "Grand Est", "Pays de la Loire",
             "Provence-Alpes-Côte d'Azur", "Île-de-France", "Occitanie", "Bretagne", "Grand Est"),
  LITTORAL = c(TRUE, FALSE, FALSE, TRUE, FALSE, TRUE, FALSE, FALSE, TRUE, FALSE, TRUE, FALSE, FALSE)
)

INFO_VILLES
```

::: usage
`tibble(colonne = c(...), ...)` crée un petit tableau à la main. Toutes les colonnes doivent avoir la même longueur.
:::

# La clé de jointure

Pour fusionner, il faut une **clé** : une variable présente dans les deux tables, avec **exactement** les mêmes valeurs. Ici, le nom de la station.

```r
# Toutes les villes de la base sont-elles dans la table d'informations ?
setdiff(unique(BDD_METEO$name), INFO_VILLES$name)

# La table de droite a-t-elle une seule ligne par ville ?
INFO_VILLES |> count(name) |> filter(n > 1)
```

::: note
Deux résultats vides : toutes les villes ont une correspondance, et chaque ville n'apparaît qu'une fois dans `INFO_VILLES`. La base « de gauche » (`BDD_METEO`) répète la clé des milliers de fois, c'est normal ; la base « de droite » doit n'avoir **qu'une ligne par clé**, sinon chaque relevé serait dupliqué.
:::

::: piege
`"Lyon"` ne rejoint pas `"Lyon / Bron"`, et `"lille"` ne rejoint pas `"Lille"` : la clé doit être **identique** au caractère près. C'est la première chose à vérifier quand une jointure laisse des `NA`.
:::

# left_join() : la fusion

```r
BDD_METEO <- BDD_METEO |>
  left_join(INFO_VILLES, by = "name")

# Vérifications : même nombre de lignes, nouvelles colonnes remplies
nrow(BDD_METEO)
BDD_METEO |> count(REGION, is.na(LITTORAL))
```

::: usage
Si la clé n'a pas le même nom dans les deux tables : `by = c("name" = "VILLE")`, la clé de gauche puis celle de droite.
:::

# Les trois jointures

| Fonction | Garde… |
|---|---|
| `left_join(A, B)` | toutes les lignes de **A**, complétées par **B** quand c'est possible (`NA` sinon) |
| `inner_join(A, B)` | seulement les lignes présentes **dans les deux** tables |
| `full_join(A, B)` | toutes les lignes **des deux** tables |

```r
# Une table d'informations incomplète : seulement 3 villes
INFO_3 <- INFO_VILLES |> filter(name %in% c("Lille", "Nice", "Rennes"))

BDD_METEO |> select(name, date, temp) |> left_join(INFO_3, by = "name") |> nrow()
BDD_METEO |> select(name, date, temp) |> inner_join(INFO_3, by = "name") |> nrow()

# anti_join() : les lignes de A SANS correspondance dans B
BDD_METEO |> select(name) |> distinct() |> anti_join(INFO_3, by = "name")
```

::: note
`left_join()` garde les 13 villes (avec des `NA` pour les dix sans information), `inner_join()` ne garde que les 3 villes renseignées : **le choix de la jointure change la population étudiée**. `anti_join()` est l'outil idéal pour repérer les clés qui n'ont pas trouvé leur correspondance.
:::

# Utiliser les nouvelles variables

```r
BDD_METEO |>
  filter(year(date) < 2026) |>
  group_by(LITTORAL) |>
  summarise(NB_VILLES = n_distinct(name),
            AMPLITUDE_MOY = mean(tmax - tmin, na.rm = TRUE),
            PART_GEL = mean(tmin < 0, na.rm = TRUE))
```

::: note
**Lecture :** l'amplitude thermique journalière est presque la même, mais les jours de gel sont environ quatre fois moins fréquents dans les villes du littoral (2 % contre 9 % des jours) : l'effet modérateur de la mer. Une information absente de la base d'origine, apportée par la jointure.
:::

# Fusionner avec un tableau de synthèse

On peut aussi joindre un tableau **calculé** : par exemple, comparer chaque année à la moyenne de sa ville sur toute la période.

```r
NORMALE <- BDD_METEO |>
  filter(year(date) < 2026) |>
  group_by(name) |>
  summarise(TEMP_NORMALE = mean(temp, na.rm = TRUE))

BDD_METEO |>
  filter(year(date) < 2026) |>
  group_by(name, annee = year(date)) |>
  summarise(TEMP_ANNEE = mean(temp, na.rm = TRUE)) |>
  ungroup() |>
  left_join(NORMALE, by = "name") |>
  mutate(ECART = TEMP_ANNEE - TEMP_NORMALE) |>
  filter(name == "Lille")
```
