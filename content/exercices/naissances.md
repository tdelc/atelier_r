---
base: naissances
---

# Âge moyen des mères dans le Nord
niveau: 1
theme: filter + summarise

## Énoncé
Calculez l'âge moyen des mères pour les naissances ayant eu lieu dans le Nord (département `59`).

## Indice
Deux verbes : d'abord `filter()` pour garder le Nord, puis `summarise()` avec `mean()`. Attention : `DEPNAIS` est du texte.

## Code de départ
```r
BDD_NAIS |>
  filter(...) |>
  summarise(...)
```

## Correction
```r
BDD_NAIS |>
  filter(DEPNAIS == "59") |>
  summarise(AGE_MOYEN_MERE = mean(AGEMERE))
```

## Commentaire
Les mères du Nord ont en moyenne 30,5 ans, contre 31,2 ans pour la France entière. Le guillemet autour de `"59"` est indispensable : `DEPNAIS` est une colonne de texte.

# Nombre de naissances à Paris
niveau: 1
theme: filter + count

## Énoncé
Combien de naissances ont eu lieu à Paris (département `75`) en 2021 ?

## Indice
`filter()` puis `count()`.

## Correction
```r
BDD_NAIS |>
  filter(DEPNAIS == "75") |>
  count()
```

## Commentaire
41 880 naissances. On aurait aussi pu écrire `summarise(NB = n())` à la place de `count()`.

# Les pères de 46 ans ou plus
niveau: 1
theme: filter + count

## Énoncé
Combien de naissances ont un père âgé de 46 ans ou plus ?

## Indice
L'opérateur « supérieur ou égal » s'écrit `>=`. Et rappelez-vous ce que signifie la valeur 46 dans cette base (voir le Dictionnaire).

## Correction
```r
BDD_NAIS |>
  filter(AGEPERE >= 46) |>
  count()
```

## Commentaire
Comme la valeur 46 regroupe tous les pères de « 46 ans ou plus », `AGEPERE >= 46` et `AGEPERE == 46` donnent ici le même résultat. Impossible, avec cette base, de compter les pères de plus de 50 ans.

# Une sous-base pour le Rhône
niveau: 1
theme: filter + select + <-

## Énoncé
Créez une base `BDD_NAIS_RHONE` contenant les enfants nés dans le Rhône (`69`), en ne gardant que les colonnes `DEPNAIS`, `SEXE` et `AGEMERE`. Affichez-la ensuite.

## Indice
`NOM <- BDD |> filter(...) |> select(...)`, puis tapez le nom de la nouvelle base pour l'afficher.

## Correction
```r
BDD_NAIS_RHONE <- BDD_NAIS |>
  filter(DEPNAIS == "69") |>
  select(DEPNAIS, SEXE, AGEMERE)

BDD_NAIS_RHONE
```

## Commentaire
27 198 lignes et 3 colonnes. On a choisi un **nouveau nom** : écrire `BDD_NAIS <- ...` aurait écrasé la base complète.

# Âge médian des pères
niveau: 1
theme: summarise / R base

## Énoncé
Quel est l'âge médian des pères ? Donnez deux écritures : une avec `summarise()`, une avec une fonction de R base et `$`.

## Indice
`median()` dans un `summarise()`, ou `median(BDD_NAIS$...)`.

## Correction
```r
BDD_NAIS |> summarise(AGE_MEDIAN_PERE = median(AGEPERE))

median(BDD_NAIS$AGEPERE)
```

## Commentaire
33 ans dans les deux cas. La première écriture renvoie un **tableau** (une ligne, une colonne), la seconde un simple **nombre**. Pour la vérification automatique, c'est le résultat de la dernière ligne qui compte.

# Médiane de l'âge des mères en Loire-Atlantique
niveau: 1
theme: filter + summarise

## Énoncé
Calculez l'âge médian des mères pour les naissances en Loire-Atlantique (`44`).

## Indice
`summary()` ou `median(BDD_NAIS$AGEMERE)` portent sur **toute** la colonne : il faut d'abord filtrer, donc passer par les verbes.

## Correction
```r
BDD_NAIS |>
  filter(DEPNAIS == "44") |>
  summarise(AGE_MEDIAN_MERE = median(AGEMERE))
```

## Commentaire
32 ans, un an de plus que la médiane nationale.

# Les naissances multiples
niveau: 1
theme: filter + count

## Énoncé
Combien d'enfants sont nés d'un accouchement multiple (jumeaux ou plus) ?

## Indice
La variable `NBENF` donne le nombre d'enfants issus de l'accouchement.

## Correction
```r
BDD_NAIS |>
  filter(NBENF >= 2) |>
  count()
```

## Commentaire
22 687 enfants. Attention : ce sont des **enfants**, pas des accouchements — des jumeaux comptent deux fois.

# Histogramme de l'âge du père
niveau: 1
theme: hist
verif: aucune

## Énoncé
Tracez l'histogramme de l'âge du père. Ajoutez un titre et un nom pour l'axe horizontal.

## Indice
`hist(BDD$COLONNE, main = "...", xlab = "...")`

## Correction
```r
hist(BDD_NAIS$AGEPERE,
     main = "Âge du père à la naissance (2021)",
     xlab = "Âge du père")
```

## Commentaire
La dernière barre est très haute : c'est l'effet du codage « 46 ans ou plus ». Pas de vérification automatique pour un graphique : comparez avec la correction.

# Naissances par sexe
niveau: 2
theme: group_by + count

## Énoncé
Calculez le nombre de naissances par sexe de l'enfant.

## Indice
`group_by()` puis `count()` — ou directement `count(SEXE)`.

## Correction
```r
BDD_NAIS |>
  group_by(SEXE) |>
  count()
```

## Commentaire
379 265 garçons (1) et 362 787 filles (2) : il naît environ 105 garçons pour 100 filles, un rapport très stable dans toutes les populations humaines.

# Âge des mères selon l'origine du nom
niveau: 2
theme: group_by + summarise

## Énoncé
Calculez l'âge moyen des mères selon l'origine du nom de famille donné à l'enfant (`ORIGINOM`).

## Indice
`group_by(ORIGINOM)` puis `summarise()`.

## Correction
```r
BDD_NAIS |>
  group_by(ORIGINOM) |>
  summarise(AGE_MOYEN_MERE = mean(AGEMERE))
```

## Commentaire
Les mères sont plus jeunes quand l'enfant porte leur nom seul (`ORIGINOM` = 2 : 29,5 ans) que dans les autres cas (environ 31,3 à 31,8 ans).

# Les départements des Hauts-de-France
niveau: 2
theme: filter + %in% + group_by

## Énoncé
Calculez le nombre de naissances par département de naissance, pour les départements de la région Hauts-de-France : Aisne (`02`), Nord (`59`), Oise (`60`), Pas-de-Calais (`62`) et Somme (`80`).

## Indice
`%in%` et `c()` pour la liste, puis `group_by()` et `count()`.

## Correction
```r
BDD_NAIS |>
  filter(DEPNAIS %in% c("02", "59", "60", "62", "80")) |>
  group_by(DEPNAIS) |>
  count()
```

## Commentaire
Le Nord à lui seul compte plus de naissances (32 220) que les quatre autres départements réunis.

# Âge des parents selon le sexe, dans le Nord
niveau: 2
theme: filter + group_by + summarise

## Énoncé
Dans le Nord, calculez l'âge moyen du père et de la mère selon le sexe de l'enfant.

## Indice
L'ordre des verbes : `filter()` (le Nord), `group_by()` (le sexe), `summarise()` (deux moyennes).

## Correction
```r
BDD_NAIS |>
  filter(DEPNAIS == "59") |>
  group_by(SEXE) |>
  summarise(AGE_PERE = mean(AGEPERE),
            AGE_MERE = mean(AGEMERE))
```

## Commentaire
Aucune différence notable : l'âge des parents ne dépend évidemment pas du sexe de l'enfant. Un résultat « nul » est aussi un résultat, et c'est un bon test de cohérence.

# Jumeaux et âge de la mère
niveau: 2
theme: réflexion

## Énoncé
Le nombre d'enfants issus de l'accouchement dépend-il de l'âge de la mère ? Calculez la **part** de naissances multiples (`NBENF` ≥ 2) pour chaque âge de la mère, et affichez toutes les lignes.

## Indice
La part d'une condition = la moyenne de cette condition : `mean(NBENF >= 2)`. Pour voir toutes les lignes : `print(n = 50)`.

## Correction
```r
BDD_NAIS |>
  group_by(AGEMERE) |>
  summarise(PART_MULTIPLES = mean(NBENF >= 2)) |>
  print(n = 50)
```

## Commentaire
La part passe d'environ 1 % chez les plus jeunes mères à plus de 7 % à 46 ans et plus. Les grossesses multiples augmentent avec l'âge de la mère, et avec le recours à l'assistance médicale à la procréation, lui-même plus fréquent après 35 ans.

# Situations professionnelles différentes
niveau: 3
theme: mutate + VRAI / FAUX

## Énoncé
Créez une variable `DIFF_SITU` qui vaut `TRUE` si les deux parents ont une situation professionnelle différente (`SITUATMR` et `SITUATPR`). Comptez ensuite ses modalités, **en faisant apparaître les valeurs manquantes**.

## Indice
`!=` donne directement `TRUE` / `FALSE`. Pour compter avec les `NA` : `count()` les affiche toujours, `table()` seulement avec `useNA = "ifany"`.

## Correction
```r
BDD_NAIS <- BDD_NAIS |>
  mutate(DIFF_SITU = SITUATMR != SITUATPR)

BDD_NAIS |> count(DIFF_SITU)
```

## Commentaire
Plus de 137 000 `NA` : dès qu'un des deux parents a une situation manquante (`NA` = sans activité, d'après la documentation), R ne peut pas comparer. Faut-il les compter comme « différents » ? C'est une décision à prendre — et à écrire dans le rapport.

# La saison de naissance
niveau: 3
theme: case_when

## Énoncé
Créez une variable `SAISON` à partir du mois de naissance : janvier-février-mars = « Hiver », avril-mai-juin = « Printemps », juillet-août-septembre = « Été », octobre-novembre-décembre = « Automne ». Vérifiez-la en comptant les naissances par `MNAIS` et `SAISON`.

## Indice
`case_when()` avec `%in%`. `MNAIS` est du texte : `"01"`, `"02"`… N'oubliez pas `.default = "Erreur"`.

## Correction
```r
BDD_NAIS <- BDD_NAIS |>
  mutate(SAISON = case_when(
    MNAIS %in% c("01", "02", "03") ~ "Hiver",
    MNAIS %in% c("04", "05", "06") ~ "Printemps",
    MNAIS %in% c("07", "08", "09") ~ "Été",
    MNAIS %in% c("10", "11", "12") ~ "Automne",
    .default = "Erreur"
  ))

BDD_NAIS |> count(MNAIS, SAISON)
```

## Commentaire
Douze lignes, chaque mois dans une seule saison, aucune « Erreur » : la variable est correcte.

# Âge moyen des pères, par sexe, sur chaque ligne
niveau: 3
theme: group_by + mutate

## Énoncé
Pour chaque sexe de l'enfant, ajoutez une colonne `AGE_MOY_PERE_SEXE` donnant l'âge moyen des pères **sur chaque ligne** de la base (la base doit garder toutes ses lignes). Vérifiez ensuite que la valeur est bien calculée séparément pour les garçons et les filles.

## Indice
`group_by()` + `mutate()` (et non `summarise()`), puis `ungroup()`. Pour vérifier : `select(SEXE, AGE_MOY_PERE_SEXE) |> distinct()`.

## Correction
```r
BDD_NAIS <- BDD_NAIS |>
  group_by(SEXE) |>
  mutate(AGE_MOY_PERE_SEXE = mean(AGEPERE)) |>
  ungroup()

BDD_NAIS |>
  select(SEXE, AGE_MOY_PERE_SEXE) |>
  distinct()
```

## Commentaire
Deux lignes, une par sexe, avec deux moyennes très proches. Avec `summarise()`, on aurait obtenu le même chiffre mais **une ligne par sexe** au lieu de 742 052 lignes.

# Reconnaissance par le père et âge de la mère
niveau: 3
theme: réflexion

## Énoncé
La reconnaissance de l'enfant par le père dépend-elle de l'âge de la mère ? Un enfant est reconnu par le père si les parents sont mariés (`AMAR` différent de `"0000"`), ou s'il y a une reconnaissance conjointe (`JRECC` différent de `"00"`), ou une reconnaissance par le père (`JRECP` différent de `"00"`). Calculez la part d'enfants reconnus par le père selon des tranches d'âge de la mère : 20 ans ou moins, 21-30, 31-40, 41-50.

## Indice
Deux `mutate()` : une variable VRAI / FAUX combinant trois conditions avec `|`, et une variable de tranches avec `cut()`. Puis `group_by()` et `summarise(mean())`.

## Correction
```r
BDD_NAIS |>
  mutate(RECON_PERE = AMAR != "0000" | JRECC != "00" | JRECP != "00",
         AGEMERE_CAT = cut(AGEMERE,
                           breaks = c(0, 20, 30, 40, 50),
                           labels = c("20 ans ou moins", "21-30", "31-40", "41-50"))) |>
  group_by(AGEMERE_CAT) |>
  summarise(PART_RECON_PERE = mean(RECON_PERE))
```

## Commentaire
56 % des enfants de mères de 20 ans ou moins sont reconnus par le père, contre plus de 80 % au-delà. Attention, ces tranches ne sont pas de même taille : la première ne contient que 4 âges (17 à 20 ans).

# Naissances par sexe et nationalité de la mère
niveau: 4
theme: pivot_wider

## Énoncé
Comptez le nombre de naissances par sexe (`SEXE`) et par nationalité de la mère (`INDNATM`), puis pivotez le tableau pour avoir une colonne par nationalité.

## Indice
`group_by(SEXE, INDNATM)`, `count()`, puis `pivot_wider(names_from = ..., values_from = n)`.

## Correction
```r
BDD_NAIS |>
  group_by(SEXE, INDNATM) |>
  count() |>
  pivot_wider(names_from = INDNATM, values_from = n, names_prefix = "NATIO_")
```

## Commentaire
Une ligne par sexe, une colonne par nationalité (1 = française, 2 = étrangère). `names_prefix` évite des noms de colonnes qui commencent par un chiffre.

# Âge des mères : origine du nom × sexe
niveau: 4
theme: pivot_wider

## Énoncé
Calculez l'âge moyen des mères selon le sexe de l'enfant et l'origine du nom (`ORIGINOM`). Présentez le résultat avec une ligne par `ORIGINOM` et une colonne par sexe.

## Indice
Pour choisir la colonne à pivoter, prenez celle qui doit passer en colonnes : ici `SEXE`.

## Correction
```r
BDD_NAIS |>
  group_by(ORIGINOM, SEXE) |>
  summarise(AGE_MERE = mean(AGEMERE)) |>
  pivot_wider(names_from = SEXE, values_from = AGE_MERE, names_prefix = "SEXE_")
```

## Commentaire
Les deux colonnes sont presque identiques : l'origine du nom est liée à l'âge de la mère, pas au sexe de l'enfant.

# Le pic de septembre
niveau: 4
theme: pivot_wider + arrange

## Énoncé
Comptez le nombre de naissances par département (`DEPNAIS`) et par mois (`MNAIS`). Faites un pivot pour avoir une ligne par département et une colonne par mois, puis triez pour trouver le département avec le plus de naissances en septembre.

## Indice
`names_prefix = "MOIS_"` donnera des colonnes `MOIS_01` à `MOIS_12`. Puis `arrange(desc(MOIS_09))`.

## Correction
```r
BDD_NAIS |>
  group_by(DEPNAIS, MNAIS) |>
  count() |>
  pivot_wider(names_from = MNAIS, values_from = n, names_prefix = "MOIS_") |>
  arrange(desc(MOIS_09))
```

## Commentaire
Paris arrive en tête… parce que c'est le département qui a le plus de naissances tout court. Pour parler d'un **pic**, il faudrait comparer septembre aux autres mois du même département (voir la leçon « Mettre en forme »).

# Hors mariage et taille de la commune
niveau: 5
theme: synthèse

## Énoncé
La part des naissances hors mariage varie-t-elle selon la taille de l'unité urbaine du domicile (`TUDOM`) ? Calculez, pour chaque valeur de `TUDOM`, le nombre de naissances et la part des naissances hors mariage (`AMAR` égal à `"0000"`).

## Indice
Pas besoin de créer une variable : `mean(AMAR == "0000")` donne directement la part. Consultez le Dictionnaire pour lire les codes de `TUDOM`.

## Correction
```r
BDD_NAIS |>
  group_by(TUDOM) |>
  summarise(NB = n(),
            PART_HORS_MARIAGE = mean(AMAR == "0000"))
```

## Commentaire
Un gradient très net : environ 74 % en commune rurale (`TUDOM` = 0), et globalement de moins en moins à mesure que l'unité urbaine grandit, jusqu'à 48 % dans l'agglomération parisienne (8). La leçon « Une analyse de A à Z » approfondit cette question.

# Écart d'âge et nationalité de la mère
niveau: 5
theme: synthèse

## Énoncé
L'écart d'âge entre le père et la mère dépend-il de la nationalité de la mère ? Créez une variable `NATIO_MERE` (« Française » si `INDNATM` vaut 1, « Étrangère » sinon), puis calculez, pour chaque nationalité, l'écart d'âge moyen (père moins mère) et la part des naissances où le père a au moins 10 ans de plus que la mère.

## Indice
Un `mutate()` avec `if_else()`, puis un `group_by()` et un `summarise()` avec deux indicateurs. La part d'une condition : `mean(AGEPERE - AGEMERE >= 10)`.

## Correction
```r
BDD_NAIS |>
  mutate(NATIO_MERE = if_else(INDNATM == 1, "Française", "Étrangère")) |>
  group_by(NATIO_MERE) |>
  summarise(ECART_MOYEN = mean(AGEPERE - AGEMERE),
            PART_ECART_10 = mean(AGEPERE - AGEMERE >= 10))
```

## Commentaire
L'écart moyen est plus grand lorsque la mère est de nationalité étrangère, et la part des écarts d'au moins 10 ans y est nettement plus élevée. Pensez aux limites : les âges sont plafonnés à 46 ans, ce qui réduit artificiellement les grands écarts.

# Naissances multiples selon la nationalité de la mère (en %)
niveau: 4
theme: pourcentage en ligne

## Énoncé
Pour chaque nationalité de la mère (`INDNATM`), calculez la répartition des naissances selon `NBENF` (1, 2 ou 3 enfants), **en pourcentage**. Chaque nationalité doit faire 100 %. Présentez le résultat avec une ligne par nationalité et une colonne par valeur de `NBENF`.

## Indice
C'est un pourcentage **en ligne** : `count(INDNATM, NBENF)`, puis `group_by(INDNATM)` avant `mutate(PCT = 100 * n / sum(n))`. N'oubliez pas de retirer la colonne `n` avant le `pivot_wider()`.

## Correction
```r
BDD_NAIS |>
  count(INDNATM, NBENF) |>
  group_by(INDNATM) |>
  mutate(PCT = 100 * n / sum(n)) |>
  ungroup() |>
  select(-n) |>
  pivot_wider(names_from = NBENF, values_from = PCT, names_prefix = "NBENF_")
```

## Commentaire
Chaque **ligne** fait 100 %. Si vous avez écrit `group_by(NBENF)`, vous avez calculé un pourcentage **en colonne** : « parmi les jumeaux, quelle part de mères françaises ? », une autre question. Avec `prop.table(table(BDD_NAIS$INDNATM, BDD_NAIS$NBENF), margin = 1)`, on obtient le même résultat en R base.

# Qui sont les mères des naissances hors mariage ? (en %)
niveau: 4
theme: pourcentage en colonne

## Énoncé
On découpe l'âge de la mère en trois tranches : 24 ans ou moins, 25-34 ans, 35 ans ou plus. **Parmi les naissances hors mariage d'une part, et parmi celles de parents mariés d'autre part**, quelle est la part de chaque tranche d'âge ? Présentez une ligne par tranche d'âge et une colonne par statut (mariés / non mariés) : chaque **colonne** doit faire 100 %.

## Indice
Créez `TRANCHE` avec `cut()` et `MARIES` avec `if_else(AMAR != "0000", "Mariés", "Non_mariés")`. Le dénominateur est le statut : c'est lui qui va dans le `group_by()`.

## Correction
```r
BDD_NAIS |>
  mutate(TRANCHE = cut(AGEMERE, breaks = c(0, 24, 34, 50),
                       labels = c("24 ans ou moins", "25-34 ans", "35 ans ou plus")),
         MARIES = if_else(AMAR != "0000", "Mariés", "Non_mariés")) |>
  count(TRANCHE, MARIES) |>
  group_by(MARIES) |>
  mutate(PCT = 100 * n / sum(n)) |>
  ungroup() |>
  select(-n) |>
  pivot_wider(names_from = MARIES, values_from = PCT)
```

## Commentaire
Chaque **colonne** fait 100 % : on décrit la **composition** de chaque groupe de parents. Les mères de 24 ans ou moins sont environ trois fois plus représentées parmi les naissances hors mariage que parmi celles de parents mariés.

# Les naissances par région
niveau: 4
theme: left_join

## Énoncé
La table `INFO_DEPARTEMENTS` donne la région de chaque département (`code_departement`, `nom_region`). Fusionnez-la avec `BDD_NAIS`, puis calculez pour chaque région le nombre de naissances et l'âge moyen de la mère, de la région qui a le plus de naissances à celle qui en a le moins.

## Indice
`left_join(INFO_DEPARTEMENTS, by = c("DEPNAIS" = "code_departement"))`, puis `group_by(nom_region)`, `summarise()` et `arrange(desc(...))`.

## Correction
```r
BDD_NAIS |>
  left_join(INFO_DEPARTEMENTS, by = c("DEPNAIS" = "code_departement")) |>
  group_by(nom_region) |>
  summarise(NB_NAIS = n(),
            AGE_MERE = mean(AGEMERE)) |>
  arrange(desc(NB_NAIS))
```

## Commentaire
L'Île-de-France compte près d'une naissance sur quatre, avec les mères les plus âgées. Vérifiez toujours qu'aucune ligne n'a perdu sa région : `BDD_NAIS |> anti_join(INFO_DEPARTEMENTS, by = c("DEPNAIS" = "code_departement"))` doit être vide.

# Carte des naissances multiples
niveau: 5
theme: carte
verif: aucune

## Énoncé
Dessinez une carte de la part des naissances multiples (`NBENF >= 2`) par département. Le fond de carte est la table `CARTE_DEP` (colonnes `code_insee`, `groupe`, `long`, `lat`).

## Indice
Trois étapes : un indicateur par département (`group_by(DEPNAIS)` + `summarise(mean(NBENF >= 2))`), une fusion avec `CARTE_DEP` (`by = c("code_insee" = "DEPNAIS")`), puis `ggplot()` avec `geom_polygon()` et `coord_quickmap()`.

## Correction
```r
SYN <- BDD_NAIS |>
  group_by(DEPNAIS) |>
  summarise(PART_MULTIPLES = mean(NBENF >= 2))

CARTE_DEP |>
  left_join(SYN, by = c("code_insee" = "DEPNAIS")) |>
  ggplot(aes(x = long, y = lat, group = groupe, fill = PART_MULTIPLES)) +
  geom_polygon(colour = "white", linewidth = 0.2) +
  coord_quickmap() +
  scale_fill_distiller(palette = "Greens", direction = 1, labels = percent) +
  labs(title = "Part des naissances multiples par département (2021)", fill = NULL) +
  theme_void()
```

## Commentaire
Les écarts entre départements sont faibles, de l'ordre de quelques points de pourcentage : une palette continue les fait paraître importants. Pensez à regarder `summary(SYN$PART_MULTIPLES)` avant d'interpréter une carte.

# Une fonction pour décrire un département
niveau: 5
theme: function

## Énoncé
Écrivez une fonction `fiche_dep` qui prend un code de département (texte) et renvoie un tableau d'une ligne avec le nombre de naissances, l'âge moyen de la mère et la part des naissances hors mariage dans ce département. Appelez-la ensuite pour le Nord (`"59"`).

## Indice
`fiche_dep <- function(code) { ... }`. À l'intérieur : `BDD_NAIS |> filter(DEPNAIS == code) |> summarise(...)`. La dernière ligne de votre code doit être l'appel `fiche_dep("59")`.

## Correction
```r
fiche_dep <- function(code) {
  BDD_NAIS |>
    filter(DEPNAIS == code) |>
    summarise(DEP = code,
              NB_NAIS = n(),
              AGE_MERE = mean(AGEMERE),
              PART_HORS_MARIAGE = mean(AMAR == "0000"))
}

fiche_dep("59")
```

## Commentaire
Une fois la fonction écrite, `fiche_dep("75")` ou `fiche_dep("2A")` donnent la fiche d'un autre département sans recopier le code. Pour plusieurs départements à la fois, une boucle `for` et `bind_rows()` empilent les fiches… mais `group_by(DEPNAIS)` reste plus simple : les fonctions servent surtout quand un même traitement doit être répété sur des **objets différents**.
