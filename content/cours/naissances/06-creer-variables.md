---
titre: Créer des variables
resume: mutate(), les variables VRAI / FAUX, if_else(), case_when(), cut() et les calculs par groupe.
partie: Les bases
---

# mutate() : créer une colonne

::: usage
**À quoi ça sert ?** Ajouter une nouvelle colonne calculée à partir des autres. **Le nombre de lignes ne change pas.**

**Écriture :** `BDD <- BDD |> mutate(NOUVELLE_COLONNE = calcul)`
:::

```r
# Un calcul : l'écart d'âge entre les parents
BDD_NAIS <- BDD_NAIS |>
  mutate(DIFF_AGE = AGEPERE - AGEMERE)

BDD_NAIS |>
  filter(DIFF_AGE > 20) |>
  select(AGEMERE, AGEPERE, DIFF_AGE)
```

::: piege
N'oubliez pas le `BDD_NAIS <-` au début : sans lui, la colonne est calculée, affichée… et perdue.
:::

# Toujours vérifier une variable créée

```r
summary(BDD_NAIS$DIFF_AGE)
hist(BDD_NAIS$DIFF_AGE)
```

::: note
**Lecture :** le père est en moyenne 2,7 ans plus âgé que la mère, et dans la moitié des cas l'écart est compris entre 0 et 5 ans. Les écarts extrêmes sont rares — et un peu sous-estimés, puisque les âges sont plafonnés à 46 ans.
:::

# Une variable VRAI / FAUX

Le résultat d'une comparaison est déjà `TRUE` ou `FALSE` : pas besoin de fonction particulière.

```r
# Les parents sont-ils mariés ?
BDD_NAIS <- BDD_NAIS |>
  mutate(MARIAGE = AMAR != "0000")

# Les parents ont-ils la même situation professionnelle ?
BDD_NAIS <- BDD_NAIS |>
  mutate(MEME_PROF = SITUATMR == SITUATPR)

# Plusieurs tests combinés : l'enfant a-t-il été reconnu par le père ?
BDD_NAIS <- BDD_NAIS |>
  mutate(RECON_PERE = AMAR != "0000" | JRECC != "00" | JRECP != "00")

table(BDD_NAIS$MARIAGE)
table(BDD_NAIS$MEME_PROF, useNA = "ifany")
```

::: piege
`MEME_PROF` contient des `NA` : quand la situation d'un des parents est manquante, R ne peut pas dire si elle est identique à celle de l'autre.
:::

# La moyenne d'une variable VRAI / FAUX

```r
BDD_NAIS |>
  group_by(AGEMERE) |>
  summarise(PART_RECON_PERE = mean(RECON_PERE))
```

::: usage
**Astuce :** `TRUE` compte 1 et `FALSE` compte 0. La **moyenne** d'une variable VRAI / FAUX donne donc la **proportion** de VRAI ; sa **somme** donne le **nombre** de VRAI.
:::

::: note
**Lecture :** chez les mères de 17 ans ou moins, 40 % des enfants sont reconnus par le père (mariage ou reconnaissance) ; la part dépasse 80 % à partir de 25 ans, puis redescend légèrement chez les mères les plus âgées.
:::

# if_else() : deux cas possibles

::: usage
**Écriture :** `if_else(condition, valeur_si_vrai, valeur_si_faux)`
:::

```r
BDD_NAIS <- BDD_NAIS |>
  mutate(PERE_PLUS_AGE = if_else(AGEPERE > AGEMERE, "Oui", "Non"))

BDD_NAIS |> group_by(PERE_PLUS_AGE) |> count()
```

# case_when() : plusieurs cas possibles

::: usage
**À quoi ça sert ?** Créer une variable avec **plus de deux** modalités, selon une série de conditions **testées dans l'ordre**.

```
case_when(
  condition_1 ~ "valeur 1",
  condition_2 ~ "valeur 2",
  .default = "valeur pour tous les autres cas"
)
```
:::

```r
# Qui est le parent le plus âgé ?
BDD_NAIS <- BDD_NAIS |>
  mutate(DIFF_AGE_DETAIL = case_when(
    DIFF_AGE > 0 ~ "Père plus âgé",
    DIFF_AGE < 0 ~ "Mère plus âgée",
    .default = "Parents du même âge"
  ))

# Vérification
BDD_NAIS |>
  group_by(DIFF_AGE_DETAIL) |>
  summarise(MIN = min(DIFF_AGE), MAX = max(DIFF_AGE))
```

# case_when() : la saison de naissance

```r
BDD_NAIS <- BDD_NAIS |>
  mutate(SNAIS = case_when(
    MNAIS %in% c("01", "02", "03") ~ "Hiver",
    MNAIS %in% c("04", "05", "06") ~ "Printemps",
    MNAIS %in% c("07", "08", "09") ~ "Été",
    MNAIS %in% c("10", "11", "12") ~ "Automne",
    .default = "Erreur"
  ))

# Vérification : chaque mois tombe dans une seule saison
BDD_NAIS |> group_by(MNAIS, SNAIS) |> count()
```

::: note
**Astuce :** mettre `.default = "Erreur"` permet de repérer immédiatement les cas qu'on a oublié de prévoir.
:::

# cut() : découper un nombre en classes

::: usage
**Écriture :** `cut(COLONNE, breaks = c(bornes), labels = c(noms des classes))`

- Il faut **une étiquette de moins que de bornes**.
- Par défaut, chaque classe inclut sa borne **droite** : `(20, 30]` va de 21 à 30 ans.
- Une valeur en dehors des bornes devient `NA`.
:::

```r
BDD_NAIS <- BDD_NAIS |>
  mutate(AGEMERE_CAT = cut(AGEMERE,
                           breaks = c(0, 20, 30, 40, 50),
                           labels = c("20 ans ou moins", "21-30", "31-40", "41-50")))

table(BDD_NAIS$AGEMERE_CAT)

# Utilisation : part des enfants reconnus par le père, par tranche d'âge de la mère
BDD_NAIS |>
  group_by(AGEMERE_CAT) |>
  summarise(PART_RECON_PERE = mean(RECON_PERE))
```

# group_by() + mutate() : un calcul dans chaque groupe

Après un `group_by()`, `mutate()` calcule **dans chaque groupe**, mais garde **toutes les lignes** (contrairement à `summarise()`).

```r
BDD_NAIS <- BDD_NAIS |>
  group_by(ORIGINOM) |>
  mutate(N_ORIGINOM = n(),
         AGE_MEDIAN_ORIGINOM = median(AGEMERE)) |>
  ungroup()

# distinct() : ne garder que les lignes uniques
BDD_NAIS |>
  select(ORIGINOM, N_ORIGINOM, AGE_MEDIAN_ORIGINOM) |>
  distinct()
```

::: piege
Ajoutez toujours `ungroup()` après un calcul groupé : sinon, les calculs suivants resteront découpés par groupe, sans que vous le voyiez.
:::
