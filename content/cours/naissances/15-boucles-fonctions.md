---
titre: Boucles et fonctions - simuler un échantillonnage
resume: Répéter un calcul avec for, stocker les résultats, puis l'automatiser avec une fonction. Application - la variabilité d'échantillonnage.
partie: Compléments
---

# La question : un échantillon dit-il la vérité ?

La base des naissances est **exhaustive** : elle contient toute la population de 2021. Cela permet une expérience impossible en temps normal : **tirer un échantillon**, calculer une statistique, et la comparer à la **vraie valeur** dans la population.

```r
# La vraie valeur, dans la population
AGEMERE_POP <- mean(BDD_NAIS$AGEMERE)   # âge moyen des mères
GARCON_POP  <- mean(BDD_NAIS$SEXE == 1) # proportion de garçons

AGEMERE_POP
GARCON_POP
```

::: note
C'est le principe des **enquêtes** : on n'interroge qu'un échantillon, et on espère que le résultat est proche de celui qu'on aurait obtenu sur toute la population. À quel point ?
:::

# Un échantillon

```r
set.seed(1)
SAMPLE_NAIS <- BDD_NAIS |> slice_sample(n = 10000)

AGEMERE_SAMPLE <- mean(SAMPLE_NAIS$AGEMERE)
GARCON_SAMPLE  <- mean(SAMPLE_NAIS$SEXE == 1)

# Écart avec la population
AGEMERE_SAMPLE - AGEMERE_POP
GARCON_SAMPLE - GARCON_POP
```

::: usage
`slice_sample(n = 10000)` tire 10 000 lignes au hasard (`sample_n()` est l'ancienne écriture). `set.seed()` fixe le hasard : avec la même graine, on retrouve le même échantillon, ce qui rend le résultat **reproductible**.
:::

Il y a un écart. Avons-nous eu de la (mal)chance ? Pour le savoir, il faut **recommencer** de nombreuses fois.

# for : répéter un calcul

::: usage
**Écriture :**

```
for (i in 1:100) {
  # code répété 100 fois ; i vaut 1, puis 2, …, puis 100
}
```
:::

```r
for (i in 1:5) {
  SAMPLE_NAIS <- BDD_NAIS |> slice_sample(n = 10000)
  print(mean(SAMPLE_NAIS$AGEMERE) - AGEMERE_POP)
}
```

::: piege
Dans une boucle, un résultat **ne s'affiche pas tout seul** : il faut `print()`. Et afficher n'est pas conserver : pour analyser les résultats, il faut les **stocker**.
:::

# Stocker les résultats dans un vecteur

On part d'un vecteur vide (`NULL`), et on lui ajoute un élément à chaque tour avec `c()`.

```r
VEC_AGEMERE <- NULL
VEC_GARCON  <- NULL

for (i in 1:100) {
  SAMPLE_NAIS <- BDD_NAIS |> slice_sample(n = 10000)
  VEC_AGEMERE <- c(VEC_AGEMERE, mean(SAMPLE_NAIS$AGEMERE))
  VEC_GARCON  <- c(VEC_GARCON, mean(SAMPLE_NAIS$SEXE == 1))
}

length(VEC_AGEMERE)
head(VEC_AGEMERE)
```

::: note
Après la boucle, `VEC_AGEMERE` contient **100** moyennes, une par échantillon. Le calcul prend quelques secondes : 100 tirages dans 742 000 lignes.
:::

# Analyser la simulation

```r
# Écart de chaque échantillon avec la population
hist(VEC_AGEMERE - AGEMERE_POP,
     main = "Écart entre l'âge moyen de l'échantillon et la vraie valeur",
     xlab = "Écart (années)")

# Écart moyen : proche de 0 ?
mean(VEC_AGEMERE) - AGEMERE_POP

# Dispersion : de combien un échantillon se trompe-t-il typiquement ?
sd(VEC_AGEMERE)
sd(VEC_GARCON)
```

::: note
**Lecture :** les écarts sont centrés sur 0 : en moyenne, l'échantillon ne se trompe pas (il est **sans biais**). Mais chaque échantillon s'écarte un peu de la vérité : l'écart-type des moyennes, autour de 0,06 an pour l'âge de la mère avec 10 000 naissances, mesure cette **erreur d'échantillonnage**. C'est elle que l'on résume par une marge d'erreur dans les sondages.
:::

# Une fonction : réutiliser le calcul

Pour faire varier la **taille de l'échantillon** et le **nombre de répétitions**, on transforme le code en **fonction**.

::: usage
**Écriture :**

```
NOM_FONCTION <- function(argument1, argument2) {
  # code qui utilise argument1 et argument2
  return(résultat)
}
```

On l'appelle ensuite comme n'importe quelle fonction : `NOM_FONCTION(10, 20)`.
:::

```r
simulation_echantillon <- function(n_sample, n_repli) {
  VEC_AGEMERE <- NULL
  for (i in 1:n_repli) {
    SAMPLE_NAIS <- BDD_NAIS |> slice_sample(n = n_sample)
    VEC_AGEMERE <- c(VEC_AGEMERE, mean(SAMPLE_NAIS$AGEMERE))
  }
  return(tibble(TAILLE = n_sample,
                ECART_MOYEN = mean(VEC_AGEMERE) - AGEMERE_POP,
                ECART_TYPE = sd(VEC_AGEMERE)))
}

simulation_echantillon(1000, 50)
```

::: note
Les objets créés **à l'intérieur** d'une fonction (`VEC_AGEMERE`, `SAMPLE_NAIS`) n'existent que pendant son exécution : seul le résultat renvoyé par `return()` en sort. C'est ce qui permet de l'appeler plusieurs fois sans mélanger les résultats.
:::

# Utiliser la fonction : l'effet de la taille de l'échantillon

```r
RESULTATS <- bind_rows(
  simulation_echantillon(100, 50),
  simulation_echantillon(1000, 50),
  simulation_echantillon(10000, 50)
)

RESULTATS
```

::: note
**Lecture :** l'écart-type est divisé par environ 3 chaque fois que la taille est multipliée par 10 : la précision progresse comme la **racine carrée** de la taille de l'échantillon (√10 ≈ 3,2). Pour diviser l'erreur par deux, il faut un échantillon **quatre fois** plus grand.
:::

# Une boucle sur une liste de valeurs

`for` peut parcourir n'importe quel vecteur, pas seulement `1:n`.

```r
RESULTATS <- NULL
for (taille in c(100, 500, 1000, 5000)) {
  RESULTATS <- bind_rows(RESULTATS, simulation_echantillon(taille, 30))
}

ggplot(RESULTATS, aes(x = TAILLE, y = ECART_TYPE)) +
  geom_line() +
  geom_point(size = 3) +
  labs(title = "Erreur d'échantillonnage selon la taille de l'échantillon",
       x = "Taille de l'échantillon", y = "Écart-type de l'âge moyen (années)") +
  theme_minimal()
```

::: piege
Dans l'atelier, le calcul est interrompu au-delà de 15 secondes : gardez des nombres de répétitions modestes. Dans RStudio, vous pouvez monter à 500 ou 1 000 répétitions pour des résultats plus stables.
:::
