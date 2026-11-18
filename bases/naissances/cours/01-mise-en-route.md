---
titre: Mise en route
resume: Charger les données, afficher la base, comprendre ce qu'est une ligne et une colonne.
partie: Les bases
---

# La base des naissances : BDD_NAIS

Chaque ligne de `BDD_NAIS` est **une naissance** en France en 2021 (source : INSEE, fichier détail de l'état civil). Il y en a un peu plus de 740 000.

Les colonnes que nous utiliserons le plus :

| Colonne | Contenu |
|---|---|
| `DEPNAIS` | Département de naissance (texte : `"59"`, `"75"`, `"02"`…) |
| `DEPDOM` | Département de domicile de la mère |
| `SEXE` | Sexe de l'enfant (1 = garçon, 2 = fille) |
| `AGEMERE`, `AGEPERE` | Âge de la mère, âge du père |
| `MNAIS` | Mois de naissance (texte : `"01"` à `"12"`) |
| `NBENF` | Nombre d'enfants issus de l'accouchement (2 ou plus = naissance multiple) |
| `AMAR` | Année du mariage des parents (`"0000"` si non mariés) |
| `ORIGINOM` | Origine du nom de famille donné à l'enfant |
| `SITUATMR`, `SITUATPR` | Situation professionnelle de la mère, du père |
| `INDNATM` | Nationalité de la mère (1 = française, 2 = étrangère) |

Le bouton **Dictionnaire** (en haut de l'écran) donne la liste complète des colonnes et de leurs codes.

::: piege
**Attention aux guillemets.** Les codes comme `DEPNAIS`, `MNAIS` ou `AMAR` sont du **texte** : on écrit `DEPNAIS == "59"` et non `DEPNAIS == 59`. Les guillemets gardent aussi le zéro initial (`"02"` pour l'Aisne).
:::

# Charger le tidyverse et la base

Dans RStudio, ces commandes se placent **en haut de chaque script**.

```r norun
install.packages("tidyverse")   # une seule fois sur votre ordinateur
library(tidyverse)              # à chaque ouverture de RStudio

setwd("G:/Mon Drive/Cours/Initiation R/M1 2026")   # votre dossier de travail
BDD_NAIS <- read_csv2("FD_NAIS_2021.csv")
```

::: usage
- `install.packages()` télécharge un paquet **une seule fois** ; `library()` le charge **à chaque nouvelle session**.
- `setwd()` indique à R le dossier où lire et enregistrer les fichiers. Remplacez le chemin par le vôtre, et les antislashs `\` par des slashs `/`.
- `read_csv2()` lit un fichier dont le séparateur est le **point-virgule** ; `read_csv()` un fichier séparé par des **virgules**.
:::

::: note
**Dans cet atelier, tout est déjà fait** : le tidyverse est chargé et la base `BDD_NAIS` est prête. Ces lignes ne sont pas exécutées ici, mais vous devrez les écrire dans vos propres scripts.
:::

# Afficher la base

Taper le nom d'un objet l'affiche. Pour un grand tableau, R n'affiche que les 10 premières lignes et les colonnes qui tiennent dans la largeur.

```r
BDD_NAIS
```

L'en-tête `# A tibble: 742,052 × 32` donne déjà l'essentiel : **742 052 lignes** (naissances) et **32 colonnes** (variables). Sous chaque nom de colonne, son **type** : `<dbl>` pour un nombre, `<chr>` pour du texte.

# head() : les premières lignes

```r
head(BDD_NAIS)       # les 6 premières lignes
```

::: usage
`head()` affiche le début d'un objet. On peut choisir le nombre de lignes : `head(BDD_NAIS, 3)`.
:::

# dim(), nrow(), ncol() : la taille du tableau

```r
dim(BDD_NAIS)    # lignes, colonnes
nrow(BDD_NAIS)   # nombre de naissances
ncol(BDD_NAIS)   # nombre de variables
```

Un ordre de grandeur permet de détecter une importation ratée : environ 740 000 naissances en France par an, c'est cohérent.

# glimpse() : aperçu de toutes les colonnes

```r
glimpse(BDD_NAIS)
```

::: usage
`glimpse()` affiche, pour **chaque** colonne, son nom, son type et ses premières valeurs. C'est la première commande à lancer sur une base inconnue.
:::

::: piege
Regardez les types : `DEPNAIS`, `MNAIS`, `AMAR` sont en `<chr>` (texte), alors que `SEXE` ou `AGEMERE` sont en `<dbl>` (nombre). C'est ce qui décide si l'on écrit des guillemets ou non dans les conditions.
:::

# $ : désigner une colonne

```r
BDD_NAIS$AGEMERE |> head()   # les 6 premières valeurs de la colonne
```

::: usage
`BDD$COLONNE` extrait **une colonne** du tableau, sous forme de vecteur. On s'en sert pour donner une colonne à une fonction de R base : `summary()`, `hist()`, `table()`, `mean()`…
:::

# <- : conserver un résultat

Sans `<-`, le résultat s'affiche puis disparaît. Avec `<-`, on lui donne un nom pour le réutiliser.

```r
BDD_NAIS_NORD <- BDD_NAIS |> filter(DEPNAIS == "59")

nrow(BDD_NAIS_NORD)
```

::: piege
Écrire `BDD_NAIS <- BDD_NAIS |> filter(...)` **écrase** la base d'origine : vous perdez toutes les autres lignes. Pour une sous-base, choisissez un **nouveau nom**.
:::

# |> : le pipe

Le pipe prend le résultat de gauche et l'envoie dans la fonction de droite. Il se lit « **puis** ».

```r
BDD_NAIS |>                     # je prends la base des naissances,
  filter(DEPNAIS == "59") |>    # puis je garde le Nord,
  count()                       # puis je compte les lignes
```

::: note
On passe à la ligne après chaque `|>` pour que le code reste lisible : RStudio décale automatiquement la ligne suivante.

Dans du code trouvé en ligne, vous verrez souvent `%>%` : c'est l'ancien pipe, qui fait la même chose dans presque tous les cas.
:::
