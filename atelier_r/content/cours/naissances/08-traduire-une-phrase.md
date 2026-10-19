---
titre: Traduire une phrase en R
resume: Repérer les mots-clés d'une question et les remplacer par le bon verbe.
partie: Les bases
---

# Le dictionnaire français → R

Une question statistique posée en français contient souvent les mêmes éléments. Il suffit de **repérer les mots-clés** et de les remplacer par le verbe correspondant.

| Dans la phrase… | Idée | Verbe R |
|---|---|---|
| « **dans** le Nord », « **à** Paris », « **parmi** les mères de moins de 25 ans », « **seulement** les garçons », « **dont** le père a plus de 46 ans » | je restreins la population | `filter()` |
| « **par** région », « **selon** le sexe », « **pour chaque** département », « **en fonction de** l'âge » | je compare des groupes | `group_by()` |
| « **moyenne** de », « âge **moyen** », « **médiane** », « **minimum** », « **écart-type** » | je calcule un indicateur | `summarise(mean())`, `median()`… |
| « **nombre de** naissances », « **combien** », « **effectif** » | je compte des lignes | `count()` ou `summarise(n())` |
| « **part** de », « **proportion** de » | je fais la moyenne d'un VRAI / FAUX | `summarise(mean(condition))` |
| « **créer** une variable », « **indiquer si** » | je fabrique une colonne | `mutate()` + `if_else()`, `case_when()`, `cut()` |
| « ne garder que les colonnes », « **afficher** l'âge et le sexe » | je choisis des colonnes | `select()` |
| « **en colonnes** », « **tableau croisé** » | je mets en forme | `pivot_wider()` |
| « **le plus** », « **le moins** », « **classer** », « **trier** » | j'ordonne les lignes | `arrange()`, `arrange(desc())` |
| « **créer une base** », « **conserver** » | j'enregistre le résultat | `NOM <- …` |

# L'ordre des verbes

Une fois les mots-clés repérés, on écrit les verbes **dans cet ordre** :

::: etape
1. `filter()` — de qui parle-t-on ? (la population)
2. `group_by()` — comparé selon quoi ? (les groupes)
3. `summarise()` ou `count()` — quel calcul ? (l'indicateur)
4. `pivot_wider()` puis `arrange()` — comment le présenter ? (la mise en forme)
:::

Si la question demande une variable qui n'existe pas encore, on commence par un `mutate()` pour la créer.

# Exemple 1

**« Dans le Nord, âge moyen du père et de la mère selon le sexe de l'enfant »**

| Morceau de phrase | Verbe |
|---|---|
| Dans le Nord | `filter(DEPNAIS == "59")` |
| selon le sexe de l'enfant | `group_by(SEXE)` |
| âge moyen du père et de la mère | `summarise(mean(AGEPERE), mean(AGEMERE))` |

```r
BDD_NAIS |>
  filter(DEPNAIS == "59") |>
  group_by(SEXE) |>
  summarise(AGE_PERE = mean(AGEPERE),
            AGE_MERE = mean(AGEMERE))
```

# Exemple 2

**« Nombre de naissances par département, en région Hauts-de-France »**

| Morceau de phrase | Verbe |
|---|---|
| en région Hauts-de-France | `filter(DEPNAIS %in% c("59", "62", "02", "60", "80"))` |
| par département | `group_by(DEPNAIS)` |
| nombre de naissances | `count()` |

```r
BDD_NAIS |>
  filter(DEPNAIS %in% c("59", "62", "02", "60", "80")) |>
  group_by(DEPNAIS) |>
  count()
```

# Exemple 3

**« Part des parents mariés, par saison de naissance »**

| Morceau de phrase | Verbe |
|---|---|
| saison de naissance *(n'existe pas encore)* | `mutate(SNAIS = case_when(...))` |
| par saison de naissance | `group_by(SNAIS)` |
| part des parents mariés | `summarise(mean(AMAR != "0000"))` |

```r
BDD_NAIS |>
  mutate(SNAIS = case_when(
    MNAIS %in% c("01", "02", "03") ~ "Hiver",
    MNAIS %in% c("04", "05", "06") ~ "Printemps",
    MNAIS %in% c("07", "08", "09") ~ "Été",
    MNAIS %in% c("10", "11", "12") ~ "Automne",
    .default = "Erreur"
  )) |>
  group_by(SNAIS) |>
  summarise(PART_MARIES = mean(AMAR != "0000"))
```

::: note
**Lecture :** la part des parents mariés est quasiment identique d'une saison à l'autre (environ 36 à 37 %). Une absence de différence est aussi un résultat !
:::

# Récapitulatif

| Je veux… | Tidyverse | R base |
|---|---|---|
| garder des lignes | `filter()` | |
| garder des colonnes | `select()` | |
| calculer un indicateur | `summarise()` | `mean()`, `median()`, `sd()`… sur `BDD$COL` |
| compter | `count()`, `summarise(n())` | `table(BDD$COL)` |
| calculer par groupe | `group_by()` + `summarise()` / `count()` | |
| créer une colonne | `mutate()` + `if_else()`, `case_when()` | `cut()` |
| mettre en colonnes | `pivot_wider()` | |
| trier | `arrange()`, `desc()` | |
| enlever les doublons | `distinct()` | |
| résumer une variable numérique | | `summary(BDD$COL)` |
| voir une distribution | | `hist(BDD$COL)` |
| tester l'appartenance à une liste | | `%in%`, `c()` |
| repérer les manquants | | `is.na()` |
