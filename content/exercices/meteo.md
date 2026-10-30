---
base: meteo
---

# Combien de villes ?
niveau: 1
theme: n_distinct

## Énoncé
Combien de villes (stations) différentes la base contient-elle ?

## Indice
`n_distinct()` compte le nombre de valeurs différentes d'une colonne. On peut l'utiliser avec `$` ou dans un `summarise()`.

## Correction
```r
n_distinct(BDD_METEO$name)
```

## Commentaire
13 villes. `BDD_METEO |> summarise(NB_VILLES = n_distinct(name))` donne le même résultat sous forme de tableau.

# Température moyenne à Lille
niveau: 1
theme: filter + summarise + na.rm

## Énoncé
Calculez la température moyenne (`temp`) à Lille sur toute la période.

## Indice
Si le résultat vaut `NA`, c'est qu'il manque des valeurs : ajoutez `na.rm = TRUE` dans `mean()`. Le nom de la ville s'écrit entre guillemets.

## Code de départ
```r
BDD_METEO |>
  filter(...) |>
  summarise(...)
```

## Correction
```r
BDD_METEO |>
  filter(name == "Lille") |>
  summarise(TEMP_MOY = mean(temp, na.rm = TRUE))
```

## Commentaire
11,7 °C. Lille n'a en fait aucune valeur manquante pour `temp` : `na.rm = TRUE` n'est pas nécessaire ici, mais c'est une bonne habitude avec cette base.

# Les jours à plus de 35 °C à Perpignan
niveau: 1
theme: filter + count

## Énoncé
Combien de jours la température maximale a-t-elle dépassé 35 °C à Perpignan ?

## Indice
Deux conditions dans `filter()`, reliées par `&` (ou par une virgule), puis `count()`.

## Correction
```r
BDD_METEO |>
  filter(name == "Perpignan" & tmax > 35) |>
  count()
```

## Commentaire
113 jours en un peu plus de 16 ans. Variante sans filtre : `summarise(sum(tmax > 35, na.rm = TRUE))`.

# Le record de chaleur
niveau: 1
theme: arrange + head

## Énoncé
Quelle est la température maximale la plus élevée de la base ? Affichez la ville, la date et la température correspondantes.

## Indice
Triez les lignes de la plus chaude à la moins chaude avec `arrange(desc())`, gardez la première avec `head(1)`, et choisissez les colonnes avec `select()`.

## Correction
```r
BDD_METEO |>
  arrange(desc(tmax)) |>
  head(1) |>
  select(name, date, tmax)
```

## Commentaire
43,5 °C à Montpellier le 28 juin 2019. `slice_max(tmax, n = 1)` fait la même chose en une seule commande.

# Les valeurs manquantes de la pluie
niveau: 1
theme: is.na

## Énoncé
Combien de relevés de précipitations (`prcp`) sont manquants dans la base ?

## Indice
`is.na()` renvoie `TRUE` pour chaque valeur manquante, et `sum()` compte les `TRUE`.

## Correction
```r
sum(is.na(BDD_METEO$prcp))
```

## Commentaire
1 681 relevés manquants. `colSums(is.na(BDD_METEO))` donne ce chiffre pour toutes les colonnes d'un coup.

# Classement des villes par température
niveau: 2
theme: group_by + summarise + arrange

## Énoncé
Calculez la température moyenne de chaque ville, et classez les villes de la plus chaude à la plus froide.

## Indice
`group_by(name)`, `summarise()` avec `na.rm = TRUE`, puis `arrange(desc(...))`.

## Correction
```r
BDD_METEO |>
  group_by(name) |>
  summarise(TEMP_MOY = mean(temp, na.rm = TRUE)) |>
  arrange(desc(TEMP_MOY))
```

## Commentaire
Nice (16,9 °C) en tête, Nancy et Lille (11,6-11,7 °C) en queue. Sans `na.rm = TRUE`, Montélimar, Paris-Orly et Strasbourg obtiendraient `NA`.

# Les jours de pluie en 2025
niveau: 2
theme: filter + group_by + summarise

## Énoncé
Pour l'année 2025, calculez pour chaque ville le nombre de jours de pluie (`prcp` > 0).

## Indice
Pour filtrer sur l'année : `year(date) == 2025`. Pour compter les jours de pluie sans filtre supplémentaire : `sum(prcp > 0, na.rm = TRUE)`.

## Correction
```r
BDD_METEO |>
  filter(year(date) == 2025) |>
  group_by(name) |>
  summarise(NB_JOURS_PLUIE = sum(prcp > 0, na.rm = TRUE))
```

## Commentaire
Environ 95 à 130 jours à Marseille, Perpignan, Nice et Montpellier, contre 140 à 185 dans le nord, l'est et l'ouest. Bastia fait exception sur le pourtour méditerranéen (172 jours). Attention aux villes qui ont des relevés manquants : leur nombre de jours de pluie est sous-estimé.

# La couverture nuageuse à Lille
niveau: 2
theme: table + useNA

## Énoncé
À Lille, comptez le nombre de jours pour chaque valeur de la couverture nuageuse (`cldc`), **en faisant apparaître les valeurs manquantes**.

## Indice
`table()` sur une colonne, avec l'argument `useNA = "ifany"`. Vous devez d'abord créer une sous-base de Lille, ou utiliser `count()`.

## Correction
```r
BDD_METEO |>
  filter(name == "Lille") |>
  count(cldc)
```

## Commentaire
`count()` affiche toujours les `NA`. Plus d'un tiers des jours de Lille n'ont pas de mesure de couverture nuageuse : la variable ne peut servir qu'à titre descriptif.

# Le climat de Strasbourg mois par mois
niveau: 3
theme: mutate + group_by

## Énoncé
Créez une variable `mois` à partir de la date, puis calculez la température moyenne de Strasbourg pour chaque mois de l'année.

## Indice
`month(date)` extrait le mois. Puis `filter()`, `group_by(mois)` et `summarise()`.

## Correction
```r
BDD_METEO |>
  mutate(mois = month(date)) |>
  filter(name == "Strasbourg") |>
  group_by(mois) |>
  summarise(TEMP_MOY = mean(temp, na.rm = TRUE))
```

## Commentaire
D'environ 3 °C en janvier à 21 °C en juillet : un climat semi-continental, avec une forte amplitude entre l'hiver et l'été.

# Les jours chauds à Lyon, année par année
niveau: 3
theme: mutate + VRAI / FAUX

## Énoncé
Créez une variable `jour_chaud` (VRAI si `tmax` dépasse 30 °C) et une variable `annee`. Calculez ensuite le nombre de jours chauds par année à Lyon (`"Lyon / Bron"`).

## Indice
La somme d'une variable VRAI / FAUX donne le nombre de VRAI : `sum(jour_chaud, na.rm = TRUE)`. Attention au nom exact de la ville.

## Correction
```r
BDD_METEO <- BDD_METEO |>
  mutate(jour_chaud = tmax > 30,
         annee = year(date))

BDD_METEO |>
  filter(name == "Lyon / Bron") |>
  group_by(annee) |>
  summarise(NB_JOURS_CHAUDS = sum(jour_chaud, na.rm = TRUE))
```

## Commentaire
Une forte variabilité d'une année à l'autre : de 10 jours (2014) à plus de 50 (2022), et 2026 bat tous les records alors qu'elle n'est pas terminée. C'est pour cela qu'on compare des **périodes** plutôt que deux années isolées.

# La température par saison à Nice
niveau: 3
theme: case_when

## Énoncé
Créez une variable `saison` (« 1_Hiver » pour décembre-janvier-février, « 2_Printemps » pour mars-avril-mai, « 3_Eté » pour juin-juillet-août, « 4_Automne » pour septembre-octobre-novembre). Calculez la température moyenne de Nice par saison.

## Indice
`case_when()` avec `month(date) %in% c(...)`. Les préfixes numériques imposent l'ordre chronologique dans le résultat.

## Correction
```r
BDD_METEO |>
  mutate(saison = case_when(
    month(date) %in% c(12, 1, 2)  ~ "1_Hiver",
    month(date) %in% c(3, 4, 5)   ~ "2_Printemps",
    month(date) %in% c(6, 7, 8)   ~ "3_Eté",
    month(date) %in% c(9, 10, 11) ~ "4_Automne"
  )) |>
  filter(name == "Nice") |>
  group_by(saison) |>
  summarise(TEMP_MOY = mean(temp, na.rm = TRUE))
```

## Commentaire
L'hiver niçois est doux (environ 10 °C en moyenne) et l'été chaud (environ 24-25 °C) : l'effet modérateur de la mer.

# Des classes de température à Orly
niveau: 3
theme: cut

## Énoncé
À Paris-Orly, découpez la température maximale en classes : « Gel » (0 °C ou moins), « Froid » (0 à 10), « Doux » (10 à 20), « Chaud » (20 à 30), « Très chaud » (plus de 30). Comptez le nombre de jours dans chaque classe.

## Indice
`cut()` avec `breaks = c(-50, 0, 10, 20, 30, 50)` (une borne de plus que d'étiquettes), puis `count()`.

## Correction
```r
BDD_METEO |>
  filter(name == "Paris-Orly") |>
  mutate(classe = cut(tmax,
                      breaks = c(-50, 0, 10, 20, 30, 50),
                      labels = c("Gel", "Froid", "Doux", "Chaud", "Très chaud"))) |>
  count(classe)
```

## Commentaire
Si `tmax` avait des valeurs manquantes, une ligne `NA` apparaîtrait (ce n'est pas le cas à Orly). Remarquez que les classes incluent leur borne **droite** : un jour à exactement 10 °C est classé « Froid ».

# Un tableau ville × année
niveau: 4
theme: pivot_wider

## Énoncé
Pour Lille, Lyon (`"Lyon / Bron"`) et Marseille (`"Marseille / Marignane"`), calculez la température moyenne par année, et présentez le résultat avec une ligne par année et une colonne par ville.

## Indice
`group_by(name, annee = year(date))`, `summarise()`, puis `pivot_wider(names_from = name, values_from = ...)`.

## Correction
```r
BDD_METEO |>
  filter(name %in% c("Lille", "Lyon / Bron", "Marseille / Marignane")) |>
  group_by(name, annee = year(date)) |>
  summarise(TEMP_MOY = mean(temp, na.rm = TRUE)) |>
  pivot_wider(names_from = name, values_from = TEMP_MOY)
```

## Commentaire
On lit la tendance de haut en bas, la comparaison entre villes de gauche à droite. La dernière ligne (2026) est plus chaude partout : l'année s'arrête en septembre, elle n'a pas eu d'automne ni d'hiver complets.

# La pluie selon la ville et la saison
niveau: 4
theme: pivot_wider + proportion

## Énoncé
Calculez la part des jours de pluie (`prcp` > 0) pour chaque ville et chaque saison (même définition des saisons que l'exercice sur Nice), avec une ligne par ville et une colonne par saison.

## Indice
La part : `mean(prcp > 0, na.rm = TRUE)`. Pivotez la saison (4 modalités) plutôt que la ville (13 modalités).

## Correction
```r
BDD_METEO |>
  mutate(saison = case_when(
    month(date) %in% c(12, 1, 2)  ~ "1_Hiver",
    month(date) %in% c(3, 4, 5)   ~ "2_Printemps",
    month(date) %in% c(6, 7, 8)   ~ "3_Eté",
    month(date) %in% c(9, 10, 11) ~ "4_Automne"
  )) |>
  group_by(name, saison) |>
  summarise(PART_PLUIE = mean(prcp > 0, na.rm = TRUE)) |>
  pivot_wider(names_from = saison, values_from = PART_PLUIE)
```

## Commentaire
Dans les villes méditerranéennes, l'été est la saison la plus sèche de loin ; dans l'ouest et le nord, la pluie est mieux répartie sur l'année.

# Avant / après à Marseille
niveau: 4
theme: double pivot

## Énoncé
À Marseille (`"Marseille / Marignane"`), comparez les périodes 2010-2016 et 2017-2026 : température moyenne, part des jours à plus de 30 °C et part des jours de pluie. Présentez le résultat avec **une ligne par indicateur** et **une colonne par période**.

## Indice
Créez la période avec `if_else(year(date) <= 2016, ...)`. Puis la technique du double pivot : `pivot_longer(-periode, names_to = "indicateur")` puis `pivot_wider(names_from = periode, values_from = value)`.

## Correction
```r
BDD_METEO |>
  filter(name == "Marseille / Marignane") |>
  mutate(periode = if_else(year(date) <= 2016, "2010_2016", "2017_2026")) |>
  group_by(periode) |>
  summarise(moy_temp   = mean(temp, na.rm = TRUE),
            prop_30    = mean(tmax > 30, na.rm = TRUE),
            prop_pluie = mean(prcp > 0, na.rm = TRUE)) |>
  pivot_longer(-periode, names_to = "indicateur") |>
  pivot_wider(names_from = periode, values_from = value)
```

## Commentaire
Comme à Lille, la température moyenne et la part des jours chauds augmentent entre les deux périodes. N'oubliez pas que la seconde contient l'année 2026, incomplète et estivale.

# Les canicules : Lille contre Marseille
niveau: 5
theme: lag

## Énoncé
Créez une variable `canicule` : VRAI si, ce jour-là **et** les deux jours précédents, `tmax` dépasse 30 °C **et** `tmin` dépasse 15 °C. Calculez ensuite le nombre de jours de canicule par année, avec une colonne pour Lille et une pour Marseille.

## Indice
`lag(tmax, 1)` donne la valeur de la veille. Trois précautions : `arrange(name, date)`, `group_by(name)` avant le `mutate()`, `ungroup()` après.

## Correction
```r
BDD_METEO <- BDD_METEO |>
  arrange(name, date) |>
  group_by(name) |>
  mutate(canicule = tmax > 30 & lag(tmax, 1) > 30 & lag(tmax, 2) > 30 &
                    tmin > 15 & lag(tmin, 1) > 15 & lag(tmin, 2) > 15) |>
  ungroup()

BDD_METEO |>
  filter(name %in% c("Lille", "Marseille / Marignane")) |>
  group_by(name, annee = year(date)) |>
  summarise(NB_CANICULE = sum(canicule, na.rm = TRUE)) |>
  pivot_wider(names_from = name, values_from = NB_CANICULE)
```

## Commentaire
Sans `group_by(name)`, le premier jour de Lille irait chercher la veille… dans les données de Bastia (la ville précédente dans l'ordre alphabétique). Marseille compte des dizaines de jours de canicule chaque année, Lille quelques-uns.

# Le premier jour chaud de l'année
niveau: 5
theme: filter + min

## Énoncé
Pour chaque année, trouvez la date du premier jour où la température maximale a atteint au moins 30 °C à Lille.

## Indice
Gardez seulement les jours à 30 °C ou plus, puis, pour chaque année, prenez la plus petite date avec `min()`.

## Correction
```r
BDD_METEO |>
  filter(name == "Lille", tmax >= 30) |>
  group_by(annee = year(date)) |>
  summarise(PREMIER_JOUR_CHAUD = min(date))
```

## Commentaire
Avant 2017, le premier jour à 30 °C arrive le plus souvent en juillet ; depuis, plutôt en juin, voire fin mai (2017, 2026). Un indicateur simple et parlant, mais sensible à une seule journée exceptionnelle.

# Les jours de sécheresse à Perpignan
niveau: 5
theme: lag + synthèse

## Énoncé
Un jour est « de sécheresse » s'il n'a pas plu ce jour-là ni les 4 jours précédents. Calculez le nombre de jours de sécheresse par année à Perpignan.

## Indice
Créez d'abord `pluie = prcp > 0`. Puis `lag(!pluie, 1, default = FALSE)` … jusqu'à 4, dans un `mutate()` encadré par `arrange()`, `group_by()` et `ungroup()`.

## Correction
```r
BDD_METEO |>
  mutate(pluie = prcp > 0) |>
  arrange(name, date) |>
  group_by(name) |>
  mutate(secheresse = !pluie &
           lag(!pluie, 1, default = FALSE) & lag(!pluie, 2, default = FALSE) &
           lag(!pluie, 3, default = FALSE) & lag(!pluie, 4, default = FALSE)) |>
  ungroup() |>
  filter(name == "Perpignan") |>
  group_by(annee = year(date)) |>
  summarise(NB_JOURS_SECHERESSE = sum(secheresse, na.rm = TRUE))
```

## Commentaire
Ce sont des **jours** appartenant à une période sèche, pas un nombre d'épisodes. À Perpignan, jusqu'à 40 % des jours de l'année sont concernés : la définition (5 jours) est sans doute trop courte pour un climat méditerranéen. Le choix d'un seuil doit s'adapter au terrain étudié.

# Synthèse : l'été à Lille
niveau: 5
theme: synthèse

## Énoncé
Pour les seuls mois de juin, juillet et août à Lille, comparez les périodes 2010-2016 et 2017-2025 (on **exclut 2026**, incomplète) : température maximale moyenne, part des jours à plus de 30 °C, part des jours de pluie. Une ligne par indicateur, une colonne par période.

## Indice
Plusieurs conditions dans `filter()` : la ville, `month(date) %in% c(6, 7, 8)`, `year(date) < 2026`. Puis la période, le `summarise()` et le double pivot.

## Correction
```r
BDD_METEO |>
  filter(name == "Lille", month(date) %in% c(6, 7, 8), year(date) < 2026) |>
  mutate(periode = if_else(year(date) <= 2016, "2010_2016", "2017_2025")) |>
  group_by(periode) |>
  summarise(tmax_moy   = mean(tmax, na.rm = TRUE),
            prop_30    = mean(tmax > 30, na.rm = TRUE),
            prop_pluie = mean(prcp > 0, na.rm = TRUE)) |>
  pivot_longer(-periode, names_to = "indicateur") |>
  pivot_wider(names_from = periode, values_from = value)
```

## Commentaire
Même sans 2026, les étés récents sont plus chauds et plus secs. C'est la vérification qui rend une conclusion solide : le résultat ne dépend pas d'une seule année exceptionnelle.

# Les classes de température par ville (en %)
niveau: 4
theme: pourcentage en ligne

## Énoncé
Pour Lille, Nancy (`"Nancy / Essey"`) et Nice, découpez la température maximale en classes : « Froid » (10 °C ou moins), « Doux » (10 à 20), « Chaud » (20 à 30), « Très chaud » (plus de 30). Calculez, **pour chaque ville**, la répartition de ses jours entre ces classes, en pourcentage : chaque ville doit faire 100 %. Une ligne par ville, une colonne par classe. Retirez les jours sans `tmax`.

## Indice
`cut(tmax, breaks = c(-50, 10, 20, 30, 50), labels = ...)`, puis `count(name, classe)`, `group_by(name)` et `mutate(PCT = 100 * n / sum(n))`.

## Correction
```r
BDD_METEO |>
  filter(name %in% c("Lille", "Nancy / Essey", "Nice"), !is.na(tmax)) |>
  mutate(classe = cut(tmax, breaks = c(-50, 10, 20, 30, 50),
                      labels = c("Froid", "Doux", "Chaud", "Très chaud"))) |>
  count(name, classe) |>
  group_by(name) |>
  mutate(PCT = 100 * n / sum(n)) |>
  ungroup() |>
  select(-n) |>
  pivot_wider(names_from = classe, values_from = PCT)
```

## Commentaire
Chaque **ligne** fait 100 %. À Nice, les jours « froids » sont rares, alors qu'ils représentent une part importante des jours à Lille et à Nancy. Si une classe n'existe pas pour une ville, ajoutez `values_fill = 0` dans le `pivot_wider()`.

# D'où viennent les jours de très forte chaleur ? (en %)
niveau: 4
theme: pourcentage en colonne

## Énoncé
Parmi **tous** les relevés à plus de 35 °C de la base (toutes villes confondues), quelle est la part de chaque ville ? Triez de la plus grande part à la plus petite.

## Indice
On garde d'abord les jours à plus de 35 °C, puis on compte par ville, et on divise par le **total** de ces jours : pas de `group_by()` avant la division.

## Correction
```r
BDD_METEO |>
  filter(tmax > 35) |>
  count(name) |>
  mutate(PCT = 100 * n / sum(n)) |>
  arrange(desc(PCT))
```

## Commentaire
Montélimar et Marseille concentrent à elles seules une grande partie des journées à plus de 35 °C. C'est une question de **composition** (« parmi les jours très chauds… »), à ne pas confondre avec « quelle part des jours de Montélimar est très chaude ? », qui demanderait un dénominateur par ville.

# Littoral ou intérieur ?
niveau: 4
theme: left_join

## Énoncé
La table `INFO_VILLES` (déjà créée, voir le code exécuté avant le vôtre) indique pour chaque ville si elle est sur le littoral (`LITTORAL`). Fusionnez-la avec `BDD_METEO`, puis calculez, selon `LITTORAL`, la part des jours de gel (`tmin < 0`) et la température moyenne, en excluant l'année 2026.

## Indice
`left_join(INFO_VILLES, by = "name")`, puis `filter(year(date) < 2026)`, `group_by(LITTORAL)` et `summarise()`. Pensez à `na.rm = TRUE`.

## Préparation
```r
INFO_VILLES <- tibble(
  name = c("Bastia", "Lille", "Lyon / Bron", "Marseille / Marignane", "Montelimar",
           "Montpellier", "Nancy / Essey", "Nantes", "Nice", "Paris-Orly",
           "Perpignan", "Rennes", "Strasbourg"),
  LITTORAL = c(TRUE, FALSE, FALSE, TRUE, FALSE, TRUE, FALSE, FALSE, TRUE, FALSE, TRUE, FALSE, FALSE)
)
```

## Correction
```r
BDD_METEO |>
  left_join(INFO_VILLES, by = "name") |>
  filter(year(date) < 2026) |>
  group_by(LITTORAL) |>
  summarise(PART_GEL = mean(tmin < 0, na.rm = TRUE),
            TEMP_MOY = mean(temp, na.rm = TRUE))
```

## Commentaire
Environ 2 % de jours de gel sur le littoral contre 9 % à l'intérieur. Attention : les villes du littoral de cette base sont toutes méditerranéennes : aucune n'est sur l'Atlantique (Nantes et Rennes sont à l'intérieur des terres). La comparaison « littoral / intérieur » se confond donc ici avec « sud / nord ».

# Les stations sur une carte
niveau: 5
theme: carte
verif: aucune

## Énoncé
Dessinez une carte des 13 stations, colorées selon leur nombre moyen de jours à 30 °C ou plus par an (de 2010 à 2025). Le fond de carte est la table `CARTE_DEP` (colonnes `groupe`, `long`, `lat`) ; les coordonnées des stations sont dans `latitude` et `longitude`.

## Indice
Un indicateur par station (`group_by(name, latitude, longitude)`), puis `ggplot()` vide avec deux couches : `geom_polygon(data = CARTE_DEP, ...)` et `geom_point(data = STATIONS, ...)`. Finissez par `coord_quickmap()`.

## Correction
```r
STATIONS <- BDD_METEO |>
  filter(year(date) < 2026) |>
  group_by(name, latitude, longitude) |>
  summarise(JOURS_30 = sum(tmax >= 30, na.rm = TRUE) / 16) |>
  ungroup()

ggplot() +
  geom_polygon(data = CARTE_DEP, aes(x = long, y = lat, group = groupe),
               fill = "grey95", colour = "grey70", linewidth = 0.2) +
  geom_point(data = STATIONS, aes(x = longitude, y = latitude, colour = JOURS_30), size = 6) +
  scale_colour_distiller(palette = "YlOrRd", direction = 1) +
  coord_quickmap() +
  labs(title = "Jours à 30 °C ou plus par an, 2010-2025", colour = "Jours / an") +
  theme_void()
```

## Commentaire
On divise par 16, le nombre d'années de 2010 à 2025. La vallée du Rhône (Montélimar) et le pourtour méditerranéen ressortent nettement. Sur une carte de points, ajoutez le nom des stations avec `geom_text()` pour que le lecteur s'y retrouve.

# Une fonction pour décrire une ville
niveau: 5
theme: function

## Énoncé
Écrivez une fonction `bilan_annee` qui prend un nom de ville et une année, et renvoie un tableau d'une ligne avec la température moyenne, le nombre de jours à 30 °C ou plus et le nombre de jours de pluie (`prcp > 0`) de cette ville cette année-là. Appelez-la pour Lyon (`"Lyon / Bron"`) en 2025.

## Indice
`bilan_annee <- function(ville, an) { ... }`, avec à l'intérieur `filter(name == ville, year(date) == an)` puis `summarise()`. La dernière ligne de votre code doit être l'appel de la fonction.

## Correction
```r
bilan_annee <- function(ville, an) {
  BDD_METEO |>
    filter(name == ville, year(date) == an) |>
    summarise(VILLE = ville,
              ANNEE = an,
              TEMP_MOY = mean(temp, na.rm = TRUE),
              JOURS_30 = sum(tmax >= 30, na.rm = TRUE),
              JOURS_PLUIE = sum(prcp > 0, na.rm = TRUE))
}

bilan_annee("Lyon / Bron", 2025)
```

## Commentaire
Testez-la sur d'autres villes et d'autres années. Pour comparer plusieurs années d'un coup, une boucle `for (an in 2020:2025)` et `bind_rows()` empilent les bilans… mais `group_by(year(date))` le ferait en une ligne. Une fonction devient vraiment utile quand le même traitement s'applique à des objets **différents**, par exemple plusieurs bases.

# Un tableau de rapport avec gt
niveau: 3
theme: gt

## Énoncé
Pour l'année 2025, calculez par ville (`name`) la température moyenne (`temp`) et le cumul de précipitations (`prcp`), en ignorant les valeurs manquantes. Présentez le résultat dans un tableau **gt**, trié de la ville la plus chaude à la plus froide, avec un titre, des libellés en français et une décimale. Le tableau s'affiche dans le Viewer, sous votre code.

## Indice
D'abord le tableau : `filter(year(date) == 2025)`, `group_by(name)`, `summarise(…, na.rm = TRUE)`, `arrange(desc(…))`. Puis la présentation : `gt()`, `tab_header()`, `cols_label()` et `fmt_number(decimals = 1)`.

## Code de départ
```r
BDD_METEO |>
  filter(year(date) == 2025) |>
  group_by(name) |>
  summarise(...) |>
  gt()
```

## Correction
```r
BDD_METEO |>
  filter(year(date) == 2025) |>
  group_by(name) |>
  summarise(TEMP = mean(temp, na.rm = TRUE),
            PLUIE = sum(prcp, na.rm = TRUE)) |>
  arrange(desc(TEMP)) |>
  gt() |>
  tab_header(title = "Température et précipitations par ville en 2025") |>
  cols_label(name = "Ville", TEMP = "Température moyenne (°C)",
             PLUIE = "Précipitations (mm)") |>
  fmt_number(columns = c(TEMP, PLUIE), decimals = 1, dec_mark = ",", sep_mark = " ")
```

## Commentaire
La vérification porte sur les **données** du tableau, pas sur sa mise en forme : vos titres et libellés peuvent différer de la correction. Le cumul de précipitations ignore les jours sans relevé : comparez les villes avec prudence si certaines ont beaucoup de valeurs manquantes.
