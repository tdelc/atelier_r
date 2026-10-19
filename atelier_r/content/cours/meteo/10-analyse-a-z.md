---
titre: Une analyse de A à Z
resume: Étude de cas complète - voit-on des impacts du réchauffement climatique à Lille ? De la question à la conclusion.
partie: Étude de cas
---

# La démarche : par où commencer ?

Face à une base de données inconnue, la tentation est de se jeter sur la question de recherche. C'est le meilleur moyen de produire des résultats faux : une colonne mal comprise, des valeurs manquantes non repérées, et toute l'analyse s'effondre.

**On avance toujours dans le même ordre.**

::: etape
**Étape 0 — La question de recherche.** Qu'est-ce que je cherche à savoir ? Quelles hypothèses puis-je tester avec cette base ?

**Étape 1 — Le tableau dans son ensemble.** Combien de lignes, de colonnes ? Que représente une ligne ? Où sont les valeurs manquantes ?

**Étape 2 — Chaque variable, une à une.** Que mesure cette colonne ? Quel est son type ? Ses valeurs sont-elles crédibles ? M'est-elle utile ?

**Étape 3 — Les variables supplémentaires.** De quoi ai-je besoin qui n'existe pas encore dans la base ? Je les crée, et je les vérifie.

**Étape 4 — La question de recherche, pour de bon.** Je produis les tableaux qui répondent à la question, du plus simple au plus fin, puis je conclus.
:::

Les étapes 2 et 3 s'alimentent l'une l'autre : en explorant une variable, vous verrez souvent qu'il faut en créer une autre. C'est normal, faites des allers-retours.

::: note
**Tenez un journal de bord.** Dans votre script, écrivez en commentaire ce que vous apprenez sur chaque variable : sa définition, son unité, ses problèmes, votre décision (je la garde / je la corrige / je l'abandonne). C'est ce journal qui deviendra la partie « données et méthode » de votre rapport.
:::

# Étape 0 : la question de recherche

> **Voit-on des impacts du réchauffement climatique à Lille ? Si oui, quels sont les effets visibles entre 2010 et 2026 ?**

Une question de recherche est trop vague pour être calculée telle quelle. Il faut la traduire en **hypothèses**, et chaque hypothèse en **indicateur mesurable** :

| Hypothèse | Indicateur à calculer | Variables nécessaires |
|---|---|---|
| Il fait plus chaud en moyenne | Température moyenne par année | `temp` |
| Les extrêmes de chaleur sont plus fréquents | Nombre de jours > 35 °C par année | `tmax` |
| Les nuits sont plus chaudes | Part des jours où `tmin` > 15 °C | `tmin` |
| Les canicules sont plus fréquentes | Nombre de jours de canicule par année | `tmax`, `tmin`, `date` |
| Il pleut moins souvent | Part des jours de pluie par année | `prcp` |
| Les périodes sèches s'allongent | Nombre de jours de sécheresse par année | `prcp`, `date` |

::: note
**Trois questions à se poser dès le départ :**

1. **La base peut-elle y répondre ?** Ici, 16 ans de données : c'est court pour parler de climat (on raisonne normalement sur 30 ans), mais suffisant pour décrire une évolution.
2. **Quelle est ma population de comparaison ?** Lille contre les autres villes ? Lille d'hier contre Lille d'aujourd'hui ? Les deux ?
3. **Quels seuils vais-je retenir ?** 35 °C, 3 jours consécutifs… Ces choix doivent être justifiés et rappelés dans la conclusion.
:::

# Étape 1 : la taille et l'aperçu

```r
dim(BDD_METEO)
glimpse(BDD_METEO)
```

::: piege
Vérifiez tout de suite les **types** : une date importée en texte, ou une température importée en texte à cause d'une virgule décimale, se repère ici et pas plus tard.
:::

# Étape 1 : que représente une ligne ?

```r
# Combien de villes, et combien de relevés par ville ?
BDD_METEO |> count(name)

# Y a-t-il des doublons ville × jour ?
BDD_METEO |>
  count(name, date) |>
  filter(n > 1)
```

::: note
Un tableau vide (`0 lignes`) en réponse : il n'y a pas de doublon, l'unité statistique **une ville × un jour** est confirmée.
:::

# Étape 1 : les valeurs manquantes

```r
colSums(is.na(BDD_METEO))
```

C'est **la** commande qui oriente toute la suite : une variable remplie à moitié ne pourra pas servir d'indicateur central.

# Étape 1 : retirer les colonnes inutiles

```r
# Les colonnes *_source documentent l'origine de chaque mesure : inutiles ici
BDD_METEO <- BDD_METEO |>
  select(-ends_with("_source"), -`...1`, -X)

ncol(BDD_METEO)
colSums(is.na(BDD_METEO))
```

::: usage
`` `...1` `` s'écrit entre **accents graves** (backticks) : c'est obligatoire pour un nom de colonne qui ne commence pas par une lettre.
:::

::: piege
Retirer des colonnes, oui ; retirer des **lignes** à ce stade, non. On ne filtre la population qu'au moment de l'analyse, en sachant exactement ce qu'on exclut.
:::

# Étape 1 : la période couverte

```r
BDD_METEO |> summarise(MIN_DATE = min(date),
                       MAX_DATE = max(date),
                       NB_JOURS = n())
```

::: piege
La date de fin est le **8 septembre 2026** : la dernière année est **incomplète**. Une année qui s'arrête en septembre n'a pas connu son hiver : sa température moyenne sera artificiellement élevée. Il faudra soit l'exclure, soit la signaler systématiquement.
:::

::: note
**Bilan de l'étape 1 à noter dans votre journal :** nombre de lignes, période couverte, nombre de villes, unité statistique confirmée, colonnes supprimées, colonnes à problème (beaucoup de `NA`).
:::

# Étape 2 : les quatre questions à chaque variable

::: usage
1. **Que mesure-t-elle, dans quelle unité ?** (la documentation de la base, pas la devinette)
2. **Quel est son type ?** numérique continue, catégorielle, date, identifiant
3. **Ses valeurs sont-elles plausibles ?** minimum, maximum, distribution, valeurs aberrantes
4. **Quel est son statut dans mon étude ?** indispensable / utile pour créer une autre variable / inutilisable / à écarter
:::

```r
summary(BDD_METEO$temp)
hist(BDD_METEO$temp)
```

::: note
**Lecture :** température moyenne de l'air sur la journée, en °C. Distribution symétrique, valeurs extrêmes plausibles pour la France. Quelques `NA` : il faudra penser à `na.rm = TRUE`. **Décision : variable centrale de l'étude.**
:::

# Étape 2 : NA ou zéro ?

```r
summary(BDD_METEO$prcp)
sum(BDD_METEO$prcp == 0, na.rm = TRUE)

summary(BDD_METEO$snwd)
sum(BDD_METEO$snwd == 0, na.rm = TRUE)
```

::: note
**Lecture :** pour `prcp`, il existe de nombreux jours à `0` mm : les `NA` sont des **relevés manquants**, pas des jours secs. Pour `snwd`, aucun 0 et presque uniquement des `NA` : les jours sans neige ont probablement été codés `NA`. **Décision : `prcp` est gardée, `snwd` est écartée.**
:::

# Étape 2 : la fiche de synthèse des variables

À remplir au fil de l'exploration — c'est le livrable de l'étape 2 :

| Variable | Contenu | Type | État | Décision |
|---|---|---|---|---|
| `date` | Jour du relevé | Date | Complet | Indispensable → en dériver année, mois, jour |
| `temp` | Température moyenne | Numérique | Quelques `NA` | Indicateur central |
| `tmin`, `tmax` | Températures extrêmes | Numérique | Quelques `NA` | Canicules, nuits chaudes |
| `prcp` | Précipitations (mm) | Numérique | `NA` = manquant | Pluie et sécheresse |
| `rhum` | Humidité (%) | Numérique | Correct | Secondaire |
| `wspd` | Vent moyen (km/h) | Numérique | Correct | Épisodes venteux |
| `wpgt` | Rafales (km/h) | Numérique | Beaucoup de `NA` | À manier avec prudence |
| `pres` | Pression (hPa) | Numérique | Correct | Non utilisée |
| `tsun` | Ensoleillement (min) | Numérique | Beaucoup de `NA` | À manier avec prudence |
| `cldc` | Couverture nuageuse | Catégorielle | Beaucoup de `NA` | Descriptif seulement |
| `snwd` | Neige au sol (mm) | Numérique | `NA` ambigus | **Écartée** |
| `name` | Ville | Identifiant | Complet | Variable de groupe |
| `country`, `timezone`, `language` | Contexte station | Identifiant | Constantes | Écartées |

# Étape 3 : les variables simples

```r
BDD_METEO <- BDD_METEO |>
  mutate(annee       = year(date),
         mois        = month(date),
         jour        = day(date),
         pluie       = prcp > 0,    # a-t-il plu ce jour ?
         jour_chaud  = tmax > 35,   # journée très chaude
         nuit_chaude = tmin > 20)   # nuit chaude

# Vérification immédiate
BDD_METEO |>
  slice_sample(n = 10) |>
  select(date, annee, mois, jour, prcp, pluie)
```

::: note
**Justifiez vos seuils.** 35 °C, 20 °C la nuit : ces valeurs doivent venir de quelque part (définitions de Météo-France, littérature, ou choix assumé). Un seuil non justifié est une critique facile à faire à votre travail.
:::

# Étape 3 : regarder la veille avec lag()

Une canicule ne se définit pas sur une journée isolée : il faut **plusieurs jours chauds de suite**. Il faut donc, sur chaque ligne, pouvoir regarder la valeur de la veille et de l'avant-veille.

::: usage
**`lag(COLONNE, n)`** renvoie la valeur située `n` lignes plus haut.

**Trois précautions indispensables :**

1. **`arrange(name, date)`** — `lag()` suit l'ordre des lignes. Si les lignes ne sont pas triées, « la ligne précédente » n'est pas « la veille ».
2. **`group_by(name)`** — sans groupe, la première ligne de Lille irait chercher la dernière ligne de Bastia.
3. **`ungroup()`** — pour que les calculs suivants ne restent pas groupés.
:::

```r
BDD_METEO <- BDD_METEO |>
  arrange(name, date) |>
  group_by(name) |>
  mutate(tmax_l1 = lag(tmax, 1),
         tmax_l2 = lag(tmax, 2),
         tmin_l1 = lag(tmin, 1),
         tmin_l2 = lag(tmin, 2),
         canicule = tmax > 30 & tmax_l1 > 30 & tmax_l2 > 30 &   # 3 jours chauds
                    tmin > 15 & tmin_l1 > 15 & tmin_l2 > 15) |> # 3 nuits chaudes
  ungroup()
```

# Étape 3 : vérifier la canicule

```r
# On regarde les lignes concernées et on recompte à la main
BDD_METEO |>
  filter(name == "Lille", canicule) |>
  select(date, tmin, tmin_l1, tmin_l2, tmax, tmax_l1, tmax_l2)

# Le test du bon sens : plus de canicules à Marseille qu'à Lille
BDD_METEO |>
  filter(name %in% c("Lille", "Marseille / Marignane")) |>
  group_by(name, annee) |>
  summarise(nb_canicule = sum(canicule, na.rm = TRUE)) |>
  pivot_wider(names_from = name, values_from = nb_canicule)
```

::: usage
**`sum()` ou `mean()` sur une variable VRAI / FAUX :**

- `sum(canicule, na.rm = TRUE)` → le **nombre** de jours de canicule ;
- `mean(canicule, na.rm = TRUE)` → la **proportion** de jours de canicule.
:::

# Étape 3 : la sécheresse

Même logique pour la sécheresse : 5 jours consécutifs sans pluie.

```r
BDD_METEO <- BDD_METEO |>
  arrange(name, date) |>
  group_by(name) |>
  mutate(sans_pluie_l1 = lag(!pluie, 1, default = FALSE),
         sans_pluie_l2 = lag(!pluie, 2, default = FALSE),
         sans_pluie_l3 = lag(!pluie, 3, default = FALSE),
         sans_pluie_l4 = lag(!pluie, 4, default = FALSE),
         secheresse = !pluie & sans_pluie_l1 & sans_pluie_l2 &
                      sans_pluie_l3 & sans_pluie_l4) |>
  ungroup()

BDD_METEO |>
  filter(name == "Lille") |>
  group_by(annee) |>
  summarise(nb_secheresses = sum(secheresse, na.rm = TRUE))
```

::: usage
**`default = FALSE`** dans `lag()` indique quoi mettre pour les toutes premières lignes, qui n'ont pas de prédécesseur. Sans cela, elles valent `NA`.
:::

::: piege
Cette variable compte les **jours** appartenant à un épisode de sécheresse, pas le **nombre d'épisodes**. Dites clairement lequel des deux vous présentez.
:::

# Étape 3 : saisons et périodes

```r
# Saisons astronomiques : elles changent vers le 20-21 du mois
BDD_METEO <- BDD_METEO |>
  mutate(saison = case_when(
    mois < 3                ~ "1_Hiver",
    mois == 3 & jour < 21   ~ "1_Hiver",
    mois < 6                ~ "2_Printemps",
    mois == 6 & jour < 20   ~ "2_Printemps",
    mois < 9                ~ "3_Eté",
    mois == 9 & jour < 20   ~ "3_Eté",
    mois < 12               ~ "4_Automne",
    mois == 12 & jour < 21  ~ "4_Automne",
    .default = "1_Hiver"
  ),
  periode = if_else(annee <= 2016, "2010_2016", "2017_2026"))

BDD_METEO |> count(mois, saison) |> print(n = 30)
BDD_METEO |> count(periode)
```

::: usage
**Pourquoi `case_when` teste dans l'ordre ?** Dès qu'une condition est vraie, les suivantes ne sont plus évaluées. C'est ce qui permet d'écrire `mois < 6` sans répéter « et mois >= 3 ».
:::

::: note
**La règle d'or de l'étape 3 : toute variable créée est vérifiée dans la foulée**, avec un croisement `count(SOURCE, CREEE)`, quelques lignes tirées au hasard, ou le test du bon sens.
:::

# Étape 4 : l'évolution année par année

```r
BDD_METEO |>
  filter(name == "Lille") |>
  group_by(annee) |>
  summarise(nb_canicules   = sum(canicule, na.rm = TRUE),
            nb_secheresses = sum(secheresse, na.rm = TRUE),
            moy_temp       = mean(temp, na.rm = TRUE),
            prop_pluie     = mean(pluie, na.rm = TRUE)) |>
  print(n = 20)
```

::: note
**La structure de base de tous vos tableaux :** `filter()` (qui ?) → `group_by()` (comparé selon quoi ?) → `summarise()` (quoi ?).
:::

# Étape 4 : avant / après

C'est le tableau qui répond le plus directement à la question de recherche. On le **transpose** avec un double pivot : un indicateur par ligne, une période par colonne.

```r
BDD_METEO |>
  filter(name == "Lille") |>
  group_by(periode) |>
  summarise(nb_canicules      = sum(canicule, na.rm = TRUE),
            prop_jours_35     = mean(tmax > 35, na.rm = TRUE),
            prop_nuits_15     = mean(tmin > 15, na.rm = TRUE),
            moy_temp          = mean(temp, na.rm = TRUE),
            moy_pluie         = mean(prcp, na.rm = TRUE),
            prop_pluie        = mean(pluie, na.rm = TRUE),
            prop_secheresse   = mean(secheresse, na.rm = TRUE),
            prop_vent_fort    = mean(wspd > 40, na.rm = TRUE)) |>
  pivot_longer(-periode, names_to = "indicateur") |>
  pivot_wider(names_from = periode, values_from = value)
```

::: usage
**Astuce :** `mean(tmax > 35, na.rm = TRUE)` calcule directement une proportion sans passer par `mutate()`.
:::

# Étape 4 : et sans 2026 ?

La seconde période contient une année incomplète, qui s'arrête juste après l'été. Vérifions si elle pèse sur le résultat :

```r
BDD_METEO |>
  filter(name == "Lille", annee < 2026) |>
  group_by(periode) |>
  summarise(moy_temp     = mean(temp, na.rm = TRUE),
            nb_canicules = sum(canicule, na.rm = TRUE))
```

::: note
**Lecture :** sans 2026, l'écart de température entre les deux périodes passe d'environ +1,2 °C à environ +1,0 °C, et le nombre de jours de canicule de la seconde période tombe de 33 à 23. Le constat tient, mais il est **moins spectaculaire** : c'est exactement le genre de vérification à faire avant de conclure.
:::

# Étape 4 : le détail par saison

Une moyenne annuelle peut masquer deux évolutions opposées. Le même tableau, restreint à l'été :

```r
BDD_METEO |>
  filter(name == "Lille", saison == "3_Eté") |>
  group_by(periode) |>
  summarise(nb_canicules    = sum(canicule, na.rm = TRUE),
            moy_temp        = mean(temp, na.rm = TRUE),
            prop_pluie      = mean(pluie, na.rm = TRUE),
            prop_secheresse = mean(secheresse, na.rm = TRUE)) |>
  pivot_longer(-periode, names_to = "indicateur") |>
  pivot_wider(names_from = periode, values_from = value)
```

Et un indicateur différent, qui parle souvent plus qu'une moyenne : **la date du premier jour chaud de l'année**.

```r
BDD_METEO |>
  filter(name == "Lille", tmax >= 30) |>
  group_by(annee) |>
  summarise(premier_jour_chaud = min(date))
```

# Étape 4 : conclure

::: usage
Une conclusion se construit en trois temps :

1. **Les faits** — les chiffres, avec leur unité et leur période ;
2. **L'interprétation** — ce qu'ils signifient ensemble, et ce qu'ils ne disent pas ;
3. **Les limites** — ce qui pourrait fragiliser le résultat.
:::

> La température moyenne passe de 11,0 °C à 12,2 °C entre 2010-2016 et 2017-2026, soit **+1,2 °C** (+1,0 °C sans l'année 2026, incomplète). Les jours de canicule sont **3,7 fois plus nombreux** (9 jours contre 33), et la part des jours dépassant 35 °C est multipliée par 7,5. Les nuits chaudes (`tmin` > 15 °C) passent de 6,9 % à 12,0 % des jours.
>
> Côté précipitations, le cumul moyen baisse légèrement (2,07 mm à 1,84 mm par jour) et la part des jours de pluie passe de 53,5 % à 50,8 %. L'évolution est beaucoup plus marquée en été : la part des jours de pluie passe de 54 % à 39 %, et celle des jours de sécheresse de 10 % à 26 %.
>
> **Interprétation :** le réchauffement est net et porté avant tout par les **extrêmes** — canicules, jours très chauds, nuits chaudes — davantage que par un glissement uniforme des températures. Les étés deviennent nettement plus secs, sans effondrement des précipitations sur l'ensemble de l'année.

::: piege
**Les précautions à écrire noir sur blanc :**

- **Une station unique** par ville : on décrit un point de mesure, pas une région.
- **16 ans**, c'est court. Une seule année exceptionnelle pèse lourd (2026 apporte à elle seule 10 jours de canicule).
- **La dernière année est incomplète**, elle n'est pas comparable aux autres.
- **Les données manquantes** ne sont pas réparties au hasard : si les relevés de pluie manquent plus souvent certaines années, la comparaison est biaisée.
- **Les seuils** (30 °C, 35 °C, 3 jours) sont des conventions ; un autre choix donnerait d'autres chiffres.
- Une évolution observée **n'établit pas une cause**. On décrit ce qu'on voit à Lille, on ne démontre pas le réchauffement climatique global.
:::
