# ============================================================================
# compare.R — vérification automatique des exercices
#
# On compare le résultat de la dernière commande de l'étudiant à celui de la
# correction, avec tolérance :
#  - les noms de colonnes peuvent différer (AGE_MOYEN ou mean(AGEMERE)…) ;
#  - l'ordre des lignes et des colonnes aussi ;
#  - un tableau d'une case équivaut à un nombre (summarise() ou mean(BDD$X)) ;
#  - table() équivaut à count() ;
#  - les colonnes en plus chez l'étudiant sont acceptées ;
#  - un tableau gt est comparé par les données qu'il présente.
# Chaque colonne de la correction doit retrouver une colonne de l'étudiant
# avec exactement les mêmes valeurs (à 1e-6 près pour les nombres).
# ============================================================================

as_comparable <- function(x) {
  if (is.null(x)) return(NULL)
  if (inherits(x, c("ggplot", "recordedplot", "histogram"))) return(NULL)
  if (inherits(x, "gt_tbl")) x <- x[["_data"]]
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
    return(list(status = "na", message = tr("verif.na")))
  stu <- as_comparable(student)
  if (is.null(stu))
    return(list(status = "ko", message = tr("verif.pas_de_valeur_r")))

  n_sol <- length(sol[[1]]); n_stu <- length(stu[[1]])
  if (n_sol == 1 && length(sol) == 1 && n_stu == 1 && length(stu) == 1 &&
      !same_column(stu[[1]], sol[[1]]))
    return(list(status = "ko", message = tr("verif.valeur_r")))
  if (n_sol != n_stu)
    return(list(status = "ko",
                message = tr("verif.lignes_r", eleve = format(n_stu, big.mark = " "),
                             sol = format(n_sol, big.mark = " "))))
  used <- logical(length(stu))
  missing <- 0
  for (col in sol) {
    hit <- which(!used & vapply(stu, same_column, logical(1), b = col))
    if (length(hit)) used[hit[1]] <- TRUE else missing <- missing + 1
  }
  if (missing == 0)
    return(list(status = "ok", message = tr("verif.ok")))
  list(status = "ko",
       message = tr("verif.colonnes_r", n = missing))
}
