# ============================================================================
# compare.R — vérification automatique des exercices
#
# On compare le résultat de la dernière commande de l'étudiant à celui de la
# correction, avec tolérance :
#  - les noms de colonnes peuvent différer (AGE_MOYEN ou mean(AGEMERE)…) ;
#  - l'ordre des lignes et des colonnes aussi ;
#  - un tableau d'une case équivaut à un nombre (summarise() ou mean(BDD$X)) ;
#  - table() équivaut à count() ;
#  - les colonnes en plus chez l'étudiant sont acceptées.
# Chaque colonne de la correction doit retrouver une colonne de l'étudiant
# avec exactement les mêmes valeurs (à 1e-6 près pour les nombres).
# ============================================================================

as_comparable <- function(x) {
  if (is.null(x)) return(NULL)
  if (inherits(x, c("ggplot", "recordedplot", "histogram"))) return(NULL)
  if (inherits(x, "table")) {
    x <- as.data.frame(x, stringsAsFactors = FALSE, responseName = "n")
  } else if (inherits(x, "htest")) {
    x <- data.frame(statistic = unname(x$statistic), p = x$p.value)
  } else if (is.atomic(x) && !is.data.frame(x)) {
    x <- data.frame(valeur = unname(x))
  }
  if (!is.data.frame(x)) return(NULL)
  x <- as.data.frame(dplyr::ungroup(x))
  lapply(x, function(col) {
    if (is.factor(col)) col <- as.character(col)
    if (is.logical(col)) col <- as.numeric(col)
    if (inherits(col, "Date")) col <- as.character(col)
    if (is.numeric(col)) col <- round(col, 6)
    col
  })
}

same_column <- function(a, b) {
  if (length(a) != length(b)) return(FALSE)
  if (is.numeric(a) && is.numeric(b)) {
    a <- sort(a, na.last = TRUE); b <- sort(b, na.last = TRUE)
    na_ok <- identical(is.na(a), is.na(b))
    return(na_ok && isTRUE(all(abs(a[!is.na(a)] - b[!is.na(b)]) < 1e-6)))
  }
  a <- sort(as.character(a), na.last = TRUE)
  b <- sort(as.character(b), na.last = TRUE)
  identical(a, b)
}

# Renvoie list(status = "ok" | "ko" | "na", message = …)
compare_results <- function(student, solution) {
  sol <- as_comparable(solution)
  if (is.null(sol))
    return(list(status = "na", message = "Ce résultat ne se vérifie pas automatiquement : comparez avec la correction."))
  stu <- as_comparable(student)
  if (is.null(stu))
    return(list(status = "ko", message = "Votre code ne produit pas de tableau ou de valeur à comparer. La dernière ligne de votre code doit afficher le résultat demandé."))

  n_sol <- length(sol[[1]]); n_stu <- length(stu[[1]])
  if (n_sol == 1 && length(sol) == 1 && n_stu == 1 && length(stu) == 1 &&
      !same_column(stu[[1]], sol[[1]]))
    return(list(status = "ko", message = "La valeur obtenue n'est pas celle attendue. Relisez l'énoncé : population (filtre), variable et calcul."))
  if (n_sol != n_stu)
    return(list(status = "ko",
                message = sprintf("Votre résultat a %s ligne(s), la correction en a %s. Vérifiez vos filtres et vos regroupements.",
                                  format(n_stu, big.mark = " "), format(n_sol, big.mark = " "))))
  used <- logical(length(stu))
  missing <- 0
  for (col in sol) {
    hit <- which(!used & vapply(stu, same_column, logical(1), b = col))
    if (length(hit)) used[hit[1]] <- TRUE else missing <- missing + 1
  }
  if (missing == 0)
    return(list(status = "ok", message = "Bravo, votre résultat correspond à la correction !"))
  list(status = "ko",
       message = sprintf("Le nombre de lignes est bon, mais %d colonne(s) de la correction ne se retrouvent pas dans votre résultat. Vérifiez vos calculs (na.rm, conditions, variable utilisée).",
                         missing))
}
