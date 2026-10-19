# ============================================================================
# Exécute TOUT le contenu pédagogique dans le bac à sable :
#  - chaque carte de chaque leçon (dans l'ordre, comme dans l'application)
#  - chaque piste de découverte
#  - chaque correction d'exercice
# Un échec signifie qu'un étudiant verrait une erreur : à corriger.
#   Rscript tests/test_contenus.R [--verbose]
# ============================================================================

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(ggplot2); library(lubridate)
})
for (f in list.files("R", full.names = TRUE)) source(f, encoding = "UTF-8")
sandbox_init(); load_bases()
verbose <- "--verbose" %in% commandArgs(TRUE)

fails <- 0; n_runs <- 0; t_total <- 0
report <- function(where, run) {
  n_runs <<- n_runs + 1
  t_total <<- t_total + run$seconds
  errs <- c(run$blocked,
            vapply(Filter(function(i) i$type == "error", run$items), `[[`, "", "text"))
  if (length(errs)) {
    fails <<- fails + 1
    cat("\n✗", where, "\n   ", paste(errs, collapse = "\n    "), "\n")
  } else if (verbose) {
    cat(sprintf("✓ %s (%.1fs)\n", where, run$seconds))
  }
  warns <- vapply(Filter(function(i) i$type == "warning", run$items), `[[`, "", "text")
  if (length(warns) && verbose) cat("   ⚠", paste(warns, collapse = " | "), "\n")
}

for (b in names(BASES)) {
  cat("\n========== Base :", b, "==========\n")
  lessons <- read_course(file.path("content/cours", b))
  for (L in lessons) {
    env <- sandbox_new_env(base_datasets(b))
    for (k in seq_along(L$cards)) {
      for (s in L$cards[[k]]$segments) {
        if (s$type != "code" || s$mode == "norun") next
        report(sprintf("[cours] %s / carte %d « %s »", L$id, k, L$cards[[k]]$title),
               sandbox_run(s$code, env))
      }
    }
  }
  pistes <- read_pistes(file.path("content/decouverte", paste0(b, ".md")))
  for (p in pistes) {
    env <- sandbox_new_env(base_datasets(b))
    if (nzchar(p$setup)) report(paste("[découverte setup]", p$title), sandbox_run(p$setup, env))
    report(paste("[découverte]", p$title), sandbox_run(p$code, env))
  }
  exs <- read_exercises(file.path("content/exercices", paste0(b, ".md")))
  for (e in exs) {
    env <- sandbox_new_env(base_datasets(b))
    if (nzchar(e$preparation)) report(paste("[exercice prépa]", e$id, e$title), sandbox_run(e$preparation, env))
    r <- sandbox_run(e$correction, env)
    report(paste("[exercice]", e$id, e$title), r)
    if (e$verif == "valeur" && is.null(r$value))
      cat("   ⚠ exercice", e$id, ": la correction ne produit pas de valeur à comparer\n")
    if (!nzchar(e$enonce) || !nzchar(e$correction)) {
      fails <- fails + 1; cat("✗ exercice incomplet :", e$id, e$title, "\n")
    }
  }
  cat(sprintf("%s : %d leçons, %d pistes, %d exercices\n", b, length(lessons),
              length(pistes), length(exs)))
}
cat(sprintf("\n%d exécutions, %d échecs, %.0f s de calcul\n", n_runs, fails, t_total))
if (fails > 0) quit(status = 1)
