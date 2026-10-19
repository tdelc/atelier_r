---
titre: Une analyse de A à Z
resume: Étude de cas complète - qu'est-ce qui distingue les naissances hors mariage ? De la question à la conclusion.
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

::: note
**Tenez un journal de bord.** Dans votre script, écrivez en commentaire ce que vous apprenez sur chaque variable : sa définition, ses problèmes, votre décision (je la garde / je la corrige / je l'abandonne). C'est ce journal qui deviendra la partie « données et méthode » de votre rapport.
:::

# Étape 0 : la question de recherche

> **Les naissances hors mariage sont aujourd'hui majoritaires en France. Qu'est-ce qui les distingue des naissances de parents mariés ?**

Une question de recherche est trop vague pour être calculée telle quelle. Il faut la traduire en **hypothèses**, et chaque hypothèse en **indicateur mesurable** :

| Hypothèse | Indicateur à calculer | Variables nécessaires |
|---|---|---|
| Les parents non mariés sont plus jeunes | Âge moyen des parents selon le mariage | `AGEMERE`, `AGEPERE`, `AMAR` |
| Les naissances hors mariage sont plus fréquentes chez les jeunes mères | Part hors mariage par tranche d'âge | `AGEMERE`, `AMAR` |
| Elles sont plus fréquentes en milieu rural | Part hors mariage selon la taille de la commune | `TUDOM`, `AMAR` |
| Elles dépendent de la nationalité de la mère | Part hors mariage selon la nationalité | `INDNATM`, `AMAR` |
| Elles dépendent de l'activité de la mère | Part hors mariage selon la situation professionnelle | `SITUATMR`, `AMAR` |

::: note
**Trois questions à se poser dès le départ :**

1. **La base peut-elle y répondre ?** Elle décrit les naissances d'une seule année (2021) : on peut **comparer des groupes**, pas suivre une évolution dans le temps.
2. **Quelle est ma population ?** Toutes les naissances de 2021, y compris les départements d'outre-mer.
3. **Quels choix vais-je faire ?** Les bornes des tranches d'âge, le regroupement des tailles de commune… Ils devront être justifiés.
:::

# Étape 1 : la taille et l'aperçu

```r
dim(BDD_NAIS)
glimpse(BDD_NAIS)
```

::: note
**Unité statistique :** une ligne = **une naissance** (un enfant né vivant). La base ne contient pas d'identifiant : on ne peut pas vérifier les doublons comme on le ferait avec un identifiant de personne. On le note dans le journal.
:::

# Étape 1 : où sont les valeurs manquantes ?

```r
colSums(is.na(BDD_NAIS))
```

::: usage
**À quoi ça sert ?** Compter les `NA` colonne par colonne, en une seule commande. `is.na()` renvoie un tableau de `TRUE` / `FALSE`, et `colSums()` additionne chaque colonne (`TRUE` compte 1).
:::

::: piege
**Un `NA` n'a pas le même sens partout.** Avant de conclure qu'une variable est « mal remplie », lisez la documentation :

- `DMARNAIS` : 471 267 `NA`… c'est-à-dire les **parents non mariés**, pour qui la question n'a pas de sens ;
- `SITUATMR` : `NA` = mère **sans activité ou retraitée**, une vraie modalité ;
- `ACCOUCHR` et `ORIGINOM` : 761 `NA`, les **jugements déclaratifs** de naissance.
:::

# Étape 1 : vérifier la cohérence des NA

Si les `NA` de `ACCOUCHR` et de `ORIGINOM` correspondent tous deux aux jugements déclaratifs, ce sont **les mêmes lignes**. Vérifions-le en croisant les deux :

```r
BDD_NAIS |>
  count(NA_ACCOUCHR = is.na(ACCOUCHR),
        NA_ORIGINOM = is.na(ORIGINOM))
```

::: note
**Lecture :** les 761 lignes sont bien les mêmes. Ce type de vérification croisée rassure sur la compréhension de la base — et se fait en une ligne.
:::

# Étape 2 : la variable clé, AMAR

```r
BDD_NAIS |>
  count(AMAR) |>
  arrange(desc(n)) |>
  head(10)
```

::: note
**Lecture :** `AMAR` est l'année du mariage des parents, en **texte**. La valeur `"0000"` signifie « parents non mariés » (ou jugement déclaratif). Les années suivantes montrent que beaucoup de parents se sont mariés peu avant la naissance. **Décision :** on en tirera une variable VRAI / FAUX, `MARIAGE`.
:::

# Étape 2 : les âges et leurs bornes

```r
summary(BDD_NAIS$AGEMERE)
hist(BDD_NAIS$AGEMERE, breaks = 30)
```

::: piege
Les âges sont **plafonnés** : 17 = « 17 ans ou moins », 46 = « 46 ans ou plus ». Une moyenne d'âge reste utilisable (peu de naissances aux extrêmes), mais on ne peut pas parler des mères de 50 ans. **Décision :** variable centrale, découpée en tranches à l'étape 3.
:::

# Étape 2 : les variables catégorielles

```r
table(BDD_NAIS$SITUATMR, useNA = "ifany")
table(BDD_NAIS$INDNATM)
table(BDD_NAIS$TUDOM)
```

::: note
**Lecture des codes (dictionnaire) :**

- `SITUATMR` : S = salariée, NS = non salariée, ND = non déclarée, `NA` = sans activité ;
- `INDNATM` : 1 = française, 2 = étrangère ;
- `TUDOM` : 0 = commune rurale, 1 à 7 = unités urbaines de plus en plus grandes, 8 = agglomération parisienne, 9 = étranger ou collectivité d'outre-mer.

Ce sont des **codes** : on ne calcule pas une moyenne de `TUDOM`. **Décision :** on les recode en libellés lisibles, et on regroupe les 10 tranches de `TUDOM` en 6 catégories.
:::

# La fiche de synthèse des variables

À remplir au fil de l'exploration — c'est le livrable de l'étape 2 :

| Variable | Contenu | Type | État | Décision |
|---|---|---|---|---|
| `AMAR` | Année du mariage | Texte | `"0000"` = non mariés | → `MARIAGE` (VRAI / FAUX) |
| `AGEMERE`, `AGEPERE` | Âges des parents | Numérique | Complet, plafonné 17-46 | Centrale → tranches d'âge |
| `SITUATMR` | Situation pro. de la mère | Catégorielle | `NA` = sans activité | → libellés |
| `INDNATM` | Nationalité de la mère | Catégorielle (codée 1/2) | Complet | → libellés |
| `TUDOM` | Taille de l'unité urbaine | Catégorielle (codée 0-9) | Complet | → 6 catégories |
| `DMARNAIS` | Naissance / anniversaire de mariage | Catégorielle | `NA` = non mariés | Sert à vérifier `MARIAGE` |
| `DEPNAIS` | Département | Texte | Complet | Variable de groupe |
| `JREC*`, `MREC*` | Dates de reconnaissance | Texte | `"00"` = sans objet | Non utilisées |

# Étape 3 : créer la variable MARIAGE

```r
BDD_NAIS <- BDD_NAIS |>
  mutate(MARIAGE = AMAR != "0000")

# Vérification croisée : DMARNAIS est NA pour les parents non mariés
BDD_NAIS |>
  count(MARIAGE, NA_DMARNAIS = is.na(DMARNAIS))
```

::: note
**Lecture :** les parents mariés ont tous un `DMARNAIS` renseigné. Côté non mariés, 106 naissances ont pourtant un `DMARNAIS` : ce sont des cas où la date de mariage est absente (code 9, jugements déclaratifs). L'écart est minime et **expliqué** : on peut continuer.
:::

# Étape 3 : recoder en libellés

```r
BDD_NAIS <- BDD_NAIS |>
  mutate(
    NATIO_MERE = if_else(INDNATM == 1, "Française", "Étrangère"),
    SIT_MERE = case_when(
      SITUATMR == "S"  ~ "Salariée",
      SITUATMR == "NS" ~ "Non salariée",
      SITUATMR == "ND" ~ "Non déclarée",
      is.na(SITUATMR)  ~ "Sans activité"
    ),
    AGEMERE_CAT = cut(AGEMERE,
                      breaks = c(0, 24, 29, 34, 39, 50),
                      labels = c("24 ans ou moins", "25-29", "30-34", "35-39", "40 ans ou plus"))
  )

# Vérifications immédiates
BDD_NAIS |> count(SITUATMR, SIT_MERE)
BDD_NAIS |> group_by(AGEMERE_CAT) |> summarise(MIN = min(AGEMERE), MAX = max(AGEMERE))
```

# Étape 3 : regrouper la taille des communes

```r
BDD_NAIS <- BDD_NAIS |>
  mutate(TAILLE_UU = case_when(
    TUDOM == 0       ~ "1_Rural",
    TUDOM %in% 1:3   ~ "2_Moins de 20 000 hab.",
    TUDOM %in% 4:6   ~ "3_20 000 à 199 999 hab.",
    TUDOM == 7       ~ "4_200 000 hab. ou plus",
    TUDOM == 8       ~ "5_Agglomération parisienne",
    .default         = "6_Étranger ou COM"
  ))

BDD_NAIS |> count(TUDOM, TAILLE_UU)
```

::: usage
**Pourquoi `1_Rural` et pas `Rural` ?** R trie les modalités par ordre alphabétique : sans le préfixe numérique, l'agglomération parisienne arriverait en premier. Le chiffre impose l'ordre voulu.

**`1:3`** est un raccourci pour `c(1, 2, 3)`.
:::

# Étape 4 : le chiffre de départ

```r
BDD_NAIS |>
  summarise(NB_NAISSANCES = n(),
            PART_HORS_MARIAGE = mean(!MARIAGE))
```

::: note
`!MARIAGE` inverse VRAI et FAUX : la moyenne donne directement la **part de naissances hors mariage**. En 2021, près de **deux naissances sur trois** (63,5 %) ont lieu hors mariage.
:::

# Étape 4 : l'âge des parents

```r
BDD_NAIS |>
  group_by(MARIAGE) |>
  summarise(NB = n(),
            AGE_MERE = mean(AGEMERE),
            AGE_PERE = mean(AGEPERE))
```

::: note
**Lecture :** les parents non mariés sont en moyenne plus jeunes : environ 2 ans de moins pour la mère, près de 3 ans de moins pour le père. Première hypothèse confirmée.
:::

# Étape 4 : une variable à la fois

```r
# Selon l'âge de la mère
BDD_NAIS |>
  group_by(AGEMERE_CAT) |>
  summarise(NB = n(), PART_HORS_MARIAGE = mean(!MARIAGE))

# Selon la taille de l'unité urbaine
BDD_NAIS |>
  group_by(TAILLE_UU) |>
  summarise(NB = n(), PART_HORS_MARIAGE = mean(!MARIAGE))

# Selon la nationalité de la mère
BDD_NAIS |>
  group_by(NATIO_MERE) |>
  summarise(NB = n(), PART_HORS_MARIAGE = mean(!MARIAGE))
```

::: note
**Lecture :** trois gradients nets. La part hors mariage passe de 85 % chez les mères de 24 ans ou moins à 55 % après 35 ans ; de 74 % en commune rurale à 48 % dans l'agglomération parisienne ; et de 68 % pour les mères françaises à 44 % pour les mères étrangères.
:::

# Étape 4 : et la situation professionnelle ?

```r
BDD_NAIS |>
  group_by(SIT_MERE) |>
  summarise(NB = n(), PART_HORS_MARIAGE = mean(!MARIAGE))
```

::: note
**Lecture :** les écarts sont faibles (de 60 % à 65 %). L'hypothèse d'un lien fort avec l'activité de la mère n'est **pas** confirmée par ce tableau. C'est un résultat à part entière, à écrire dans le rapport.
:::

# Étape 4 : croiser deux variables

Les mères étrangères sont-elles moins souvent hors mariage **parce qu'elles sont plus âgées** ? Pour le savoir, on compare les nationalités **à âge égal**.

```r
BDD_NAIS |>
  group_by(AGEMERE_CAT, NATIO_MERE) |>
  summarise(PART_HORS_MARIAGE = mean(!MARIAGE)) |>
  pivot_wider(names_from = NATIO_MERE, values_from = PART_HORS_MARIAGE)
```

::: note
**Lecture :** dans **chaque** tranche d'âge, l'écart entre mères françaises et étrangères reste de 20 à 28 points. L'effet de la nationalité ne s'explique donc pas par l'âge. C'est le principe du **raisonnement « toutes choses égales par ailleurs »**, que les modèles de régression généralisent.
:::

# Étape 4 : le détail géographique

```r
BDD_NAIS |>
  group_by(DEPNAIS) |>
  summarise(NB = n(), PART_HORS_MARIAGE = mean(!MARIAGE)) |>
  arrange(PART_HORS_MARIAGE)
```

::: note
**Lecture :** les parts les plus faibles sont en Île-de-France (Hauts-de-Seine, Seine-Saint-Denis, Paris : 43 à 48 %). En triant dans l'autre sens (`arrange(desc(...))`), on trouverait les départements d'outre-mer, puis des départements ruraux comme la Creuse ou le Lot (près de 80 %). Cohérent avec le gradient urbain.
:::

# Étape 4 : conclure

::: usage
Une conclusion se construit en trois temps :

1. **Les faits** — les chiffres, avec leur unité et leur population ;
2. **L'interprétation** — ce qu'ils signifient ensemble, et ce qu'ils ne disent pas ;
3. **Les limites** — ce qui pourrait fragiliser le résultat.
:::

> En 2021, **63,5 %** des naissances en France ont lieu hors mariage. Ces naissances concernent des parents plus jeunes (mère : 30,0 ans contre 32,0 ans). La part hors mariage diminue avec l'âge de la mère (de 85 % avant 25 ans à 55 % après 35 ans), avec la taille de l'agglomération (de 74 % en commune rurale à 48 % dans l'agglomération parisienne), et elle est nettement plus faible lorsque la mère est de nationalité étrangère (44 % contre 68 %), y compris à âge égal. La situation professionnelle de la mère n'introduit en revanche que de faibles écarts.
>
> **Interprétation :** le mariage avant la naissance reste plus fréquent dans les grandes agglomérations, chez les mères plus âgées et chez les mères étrangères, ce qui renvoie à des normes familiales différentes selon les milieux.

::: piege
**Les précautions à écrire noir sur blanc :**

- **Une seule année** : on compare des groupes, on ne décrit pas une évolution.
- **Le mariage est observé à la naissance** : des parents peuvent s'être pacsés (information absente de la base) ou se marier après.
- **Les âges sont plafonnés** à 17 et 46 ans.
- **Les regroupements** (tranches d'âge, tailles de commune) sont des choix ; d'autres bornes donneraient d'autres chiffres.
- Les variables sont **liées entre elles** (âge, nationalité, territoire) : un tableau croisé ne contrôle qu'une variable à la fois.
- Une association n'établit pas une **cause**.
:::
