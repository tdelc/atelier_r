---
titre: Boucles et fonctions - simuler un échantillonnage
resume: Répéter un calcul avec for, stocker les résultats, puis l'automatiser avec une fonction. Application - estimer un climat à partir de quelques jours.
partie: Compléments
---

# La question : quelques jours suffisent-ils ?

Pour Lille, la base contient **tous** les jours de 2010 à 2025 : on connaît la vraie température moyenne de la période. Imaginons qu'un observateur n'ait relevé la température que certains jours, **tirés au hasard**. Son estimation serait-elle fiable ?

```r
LILLE <- BDD_METEO |>
  filter(name == "Lille", year(date) < 2026)

# La vraie valeur, sur tous les jours
TEMP_POP  <- mean(LILLE$temp, na.rm = TRUE)
CHAUD_POP <- mean(LILLE$tmax > 25, na.rm = TRUE)   # part des jours à plus de 25 °C

TEMP_POP
CHAUD_POP
```

# Un échantillon de jours

```r
set.seed(1)
ECHANTILLON <- LILLE |> slice_sample(n = 100)

mean(ECHANTILLON$temp, na.rm = TRUE) - TEMP_POP
mean(ECHANTILLON$tmax > 25, na.rm = TRUE) - CHAUD_POP
```

::: usage
`slice_sample(n = 100)` tire 100 jours au hasard (`sample_n()` est l'ancienne écriture). `set.seed()` fixe le hasard : avec la même graine, on retrouve le même échantillon, ce qui rend le résultat **reproductible**.
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
  ECHANTILLON <- LILLE |> slice_sample(n = 100)
  print(mean(ECHANTILLON$temp, na.rm = TRUE) - TEMP_POP)
}
```

::: piege
Dans une boucle, un résultat **ne s'affiche pas tout seul** : il faut `print()`. Et afficher n'est pas conserver : pour analyser les résultats, il faut les **stocker**.
:::

# Stocker les résultats dans un vecteur

On part d'un vecteur vide (`NULL`), et on lui ajoute un élément à chaque tour avec `c()`.

```r
VEC_TEMP  <- NULL
VEC_CHAUD <- NULL

for (i in 1:500) {
  ECHANTILLON <- LILLE |> slice_sample(n = 100)
  VEC_TEMP  <- c(VEC_TEMP,  mean(ECHANTILLON$temp, na.rm = TRUE))
  VEC_CHAUD <- c(VEC_CHAUD, mean(ECHANTILLON$tmax > 25, na.rm = TRUE))
}

length(VEC_TEMP)
head(VEC_TEMP)
```

# Analyser la simulation

```r
hist(VEC_TEMP - TEMP_POP,
     main = "Écart entre l'estimation et la vraie température moyenne",
     xlab = "Écart (°C)")

# Écart moyen : proche de 0 ?
mean(VEC_TEMP) - TEMP_POP

# Dispersion : de combien un échantillon se trompe-t-il typiquement ?
sd(VEC_TEMP)
sd(VEC_CHAUD)
```

::: note
**Lecture :** les écarts sont centrés sur 0 : en moyenne, l'échantillon ne se trompe pas (il est **sans biais**). Mais avec 100 jours, une estimation s'écarte typiquement d'environ 0,6 °C de la vraie valeur (l'écart-type des estimations) : c'est l'**erreur d'échantillonnage**. Elle est grande ici, car la température varie énormément d'un jour à l'autre (de l'hiver à l'été).
:::

# Une fonction : réutiliser le calcul

Pour faire varier le **nombre de jours** et le **nombre de répétitions**, on transforme le code en **fonction**.

::: usage
**Écriture :**

```
NOM_FONCTION <- function(argument1, argument2) {
  # code qui utilise argument1 et argument2
  return(résultat)
}
```
:::

```r
simulation_jours <- function(n_jours, n_repli) {
  VEC_TEMP <- NULL
  for (i in 1:n_repli) {
    ECHANTILLON <- LILLE |> slice_sample(n = n_jours)
    VEC_TEMP <- c(VEC_TEMP, mean(ECHANTILLON$temp, na.rm = TRUE))
  }
  return(tibble(NB_JOURS = n_jours,
                ECART_MOYEN = mean(VEC_TEMP) - TEMP_POP,
                ECART_TYPE = sd(VEC_TEMP)))
}

simulation_jours(100, 200)
```

::: note
Les objets créés **à l'intérieur** d'une fonction (`VEC_TEMP`, `ECHANTILLON`) n'existent que pendant son exécution : seul le résultat renvoyé par `return()` en sort.
:::

# Utiliser la fonction : l'effet du nombre de jours

```r
RESULTATS <- NULL
for (n in c(10, 50, 100, 500, 1000)) {
  RESULTATS <- bind_rows(RESULTATS, simulation_jours(n, 200))
}

RESULTATS

ggplot(RESULTATS, aes(x = NB_JOURS, y = ECART_TYPE)) +
  geom_line() +
  geom_point(size = 3) +
  labs(title = "Erreur d'estimation selon le nombre de jours tirés",
       x = "Nombre de jours", y = "Écart-type de l'estimation (°C)") +
  theme_minimal()
```

::: note
**Lecture :** l'erreur diminue vite au début, puis de plus en plus lentement : la précision progresse comme la **racine carrée** du nombre de jours. Pour diviser l'erreur par deux, il faut quatre fois plus de jours.
:::

# Une boucle sur les villes

`for` peut parcourir n'importe quel vecteur, par exemple une liste de villes. Ici, le jour le plus chaud de chaque ville.

```r
for (ville in c("Lille", "Rennes", "Nice")) {
  RECORD <- BDD_METEO |>
    filter(name == ville) |>
    slice_max(tmax, n = 1, with_ties = FALSE)
  print(paste0(ville, " : ", RECORD$tmax, " °C le ", format(RECORD$date, "%d/%m/%Y")))
}
```

::: piege
Avant d'écrire une boucle sur des groupes, demandez-vous si `group_by()` ne ferait pas la même chose en une ligne : ici, `BDD_METEO |> group_by(name) |> slice_max(tmax, n = 1)`. Les boucles servent surtout à **répéter une expérience** (comme une simulation), pas à calculer par groupe.
:::
