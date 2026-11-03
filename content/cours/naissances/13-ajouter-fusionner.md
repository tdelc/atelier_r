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

Dans l'atelier, une seconde table est disponible : `INFO_DEPARTEMENTS`, une ligne par département avec son nom et sa région.

```r
INFO_DEPARTEMENTS
```

# Ajouter des bases l'une sous l'autre : bind_rows()

Pour empiler, les bases doivent **représenter le même type d'observations** (ici, des naissances) et avoir **les mêmes colonnes** (même nom, même type).

Imaginons que l'INSEE nous ait livré un fichier par département. On les simule avec `filter()`, puis on les empile.

```r
NAIS_NORD   <- BDD_NAIS |> filter(DEPNAIS == "59")
NAIS_PAS_DE_CALAIS <- BDD_NAIS |> filter(DEPNAIS == "62")
NAIS_SOMME  <- BDD_NAIS |> filter(DEPNAIS == "80")

nrow(NAIS_NORD); nrow(NAIS_PAS_DE_CALAIS); nrow(NAIS_SOMME)

NAIS_3DEP <- bind_rows(NAIS_NORD, NAIS_PAS_DE_CALAIS, NAIS_SOMME)
nrow(NAIS_3DEP)
```

::: note
Le nombre de lignes de la base empilée est la **somme** des trois : c'est la vérification à faire après chaque `bind_rows()`.
:::

# Garder la trace de l'origine : .id

Quand les fichiers ne contiennent pas de colonne qui dit d'où vient chaque ligne, on l'ajoute avant d'empiler, ou avec l'argument `.id`.

```r
NAIS_3DEP <- bind_rows(Nord = NAIS_NORD,
                       `Pas-de-Calais` = NAIS_PAS_DE_CALAIS,
                       Somme = NAIS_SOMME,
                       .id = "FICHIER")

NAIS_3DEP |> count(FICHIER, DEPNAIS)
```

::: usage
Si une colonne manque dans l'une des bases, `bind_rows()` la crée et la remplit de `NA`. Vérifiez donc toujours les colonnes avec `glimpse()` avant d'empiler : une colonne mal orthographiée dans un fichier donnerait **deux** colonnes à moitié vides.
:::

# Fusionner : la clé de jointure

Pour ajouter le nom du département et la région à chaque naissance, il faut une **clé de jointure** : une variable présente dans les deux tables, avec **le même format**.

```r
# A-t-on les mêmes codes de départements dans les deux bases ?
sort(unique(BDD_NAIS$DEPNAIS))
sort(unique(INFO_DEPARTEMENTS$code_departement))
```

::: piege
La clé doit avoir **le même type** dans les deux tables : `"01"` (texte) et `1` (nombre) ne se rejoignent pas. Ici, les deux sont du texte avec le zéro initial, et les deux contiennent `"2A"`, `"2B"` et les départements d'outre-mer.
:::

# Une seule ligne par clé dans la table de droite

```r
# La table de droite ne doit avoir qu'une ligne par département
INFO_DEPARTEMENTS |>
  count(code_departement) |>
  filter(n > 1)
```

::: note
Un tableau vide : chaque code n'apparaît qu'une fois. La base « de gauche » (`BDD_NAIS`) répète la clé des milliers de fois, c'est normal ; la base « de droite » doit, elle, n'avoir **qu'une information par clé**. Sinon, chaque naissance serait dupliquée.
:::

# left_join() : la fusion

Le plus simple est de **renommer** la clé pour qu'elle porte le même nom dans les deux tables.

```r
INFO_DEPARTEMENTS <- INFO_DEPARTEMENTS |>
  rename(DEPNAIS = code_departement)

BDD_NAIS <- BDD_NAIS |>
  left_join(INFO_DEPARTEMENTS, by = "DEPNAIS")

# Vérifications : même nombre de lignes, nouvelles colonnes remplies
nrow(BDD_NAIS)
BDD_NAIS |> count(is.na(nom_region))
```

::: usage
Sans renommer, on peut aussi écrire `by = c("DEPNAIS" = "code_departement")` : la clé de gauche, puis celle de droite.
:::

# Les trois jointures

| Fonction | Garde… |
|---|---|
| `left_join(A, B)` | toutes les lignes de **A**, complétées par **B** quand c'est possible (`NA` sinon) |
| `inner_join(A, B)` | seulement les lignes présentes **dans les deux** tables |
| `full_join(A, B)` | toutes les lignes **des deux** tables |

```r
# anti_join() : les lignes de A SANS correspondance dans B (très utile pour vérifier)
BDD_NAIS |>
  select(DEPNAIS) |>
  distinct() |>
  anti_join(INFO_DEPARTEMENTS, by = "DEPNAIS")
```

::: note
`anti_join()` renvoie un tableau vide : tous les départements de `BDD_NAIS` ont trouvé leur nom. Ici, les trois jointures donnent donc le même résultat. Avec des tables incomplètes, le choix de la jointure change la population étudiée : c'est une décision à justifier.
:::

# Utiliser les nouvelles variables

```r
BDD_NAIS |>
  group_by(nom_region) |>
  summarise(NB_NAIS = n(),
            AGE_MERE = mean(AGEMERE)) |>
  arrange(desc(NB_NAIS))

BDD_NAIS |>
  group_by(nom_region, SEXE) |>
  summarise(NB_NAIS = n()) |>
  pivot_wider(names_from = SEXE, values_from = NB_NAIS, names_prefix = "SEXE_")
```

::: note
Grâce à la jointure, on peut maintenant raisonner par **région**, une information absente de la base d'origine. C'est l'usage le plus courant des fusions : enrichir une base avec une **nomenclature** (noms, regroupements géographiques, catégories).
:::

# Fusionner avec un tableau de synthèse

On peut aussi joindre un tableau **calculé** : par exemple, comparer chaque naissance à la moyenne de sa région.

```r
MOY_REGION <- BDD_NAIS |>
  group_by(nom_region) |>
  summarise(AGE_MERE_REGION = mean(AGEMERE))

BDD_NAIS |>
  left_join(MOY_REGION, by = "nom_region") |>
  mutate(ECART = AGEMERE - AGE_MERE_REGION) |>
  select(DEPNAIS, nom_region, AGEMERE, AGE_MERE_REGION, ECART) |>
  slice_sample(n = 8)
```

::: usage
Le même résultat s'obtient avec `group_by(nom_region) |> mutate(AGE_MERE_REGION = mean(AGEMERE))` (leçon « Créer des variables »). La jointure devient indispensable quand l'information vient d'**une autre source**.
:::
