# ============================================================================
# Tests de la vérification automatique des exercices et de la limite de temps
#   Rscript tests/test_verification.R
# ============================================================================
suppressPackageStartupMessages({ library(dplyr); library(tidyr); library(ggplot2); library(lubridate) })
for (f in list.files("R", full.names = TRUE)) source(f, encoding = "UTF-8")
sandbox_init(); load_bases(); load_exercices()
ok <- 0; ko <- 0
expect <- function(desc, cond) if (isTRUE(cond)) ok <<- ok + 1 else { ko <<- ko + 1; cat("ÉCHEC :", desc, "\n") }
verdict <- function(base, id, code) {
  e <- Filter(function(x) x$id == id, EXERCICES[[base]])[[1]]
  env <- sandbox_new_env(base_datasets(base))
  if (nzchar(e$preparation)) sandbox_run(e$preparation, env)
  compare_results(sandbox_run(code, env)$value, solution_of(base, e)$value)$status
}
# Chaque correction est acceptée par la vérification
for (b in names(BASES)) for (e in EXERCICES[[b]]) if (e$verif == "valeur")
  expect(paste("correction acceptée", b, e$id), verdict(b, e$id, e$correction) == "ok")

# Réponses équivalentes écrites autrement
expect("summarise(n()) au lieu de count()", verdict("naissances", "ex02", 'BDD_NAIS |> filter(DEPNAIS == "75") |> summarise(NB = n())') == "ok")
expect("nrow() au lieu de count()", verdict("naissances", "ex02", 'nrow(BDD_NAIS |> filter(DEPNAIS == "75"))') == "ok")
expect("mean() sur une colonne", verdict("naissances", "ex01", 'N <- BDD_NAIS |> filter(DEPNAIS == "59")\nmean(N$AGEMERE)') == "ok")
expect("table() au lieu de count()", verdict("naissances", "ex09", 'table(BDD_NAIS$SEXE)') == "ok")
expect("count(SEXE) direct", verdict("naissances", "ex09", 'BDD_NAIS |> count(SEXE)') == "ok")
expect("table useNA = count", verdict("meteo", "ex08", 'L <- BDD_METEO |> filter(name == "Lille")\ntable(L$cldc, useNA = "ifany")') == "ok")
expect("slice_max au lieu d'arrange", verdict("meteo", "ex04", 'BDD_METEO |> slice_max(tmax, n = 1) |> select(name, date, tmax)') == "ok")
expect("autre ordre de colonnes", verdict("naissances", "ex12", 'BDD_NAIS |> filter(DEPNAIS == "59") |> group_by(SEXE) |> summarise(M = mean(AGEMERE), P = mean(AGEPERE))') == "ok")
# Réponses fausses
expect("mauvais département refusé", verdict("naissances", "ex02", 'BDD_NAIS |> filter(DEPNAIS == "59") |> count()') == "ko")
expect("oubli du filtre refusé", verdict("naissances", "ex01", 'BDD_NAIS |> summarise(mean(AGEMERE))') == "ko")
expect("seuil faux refusé", verdict("meteo", "ex03", 'BDD_METEO |> filter(name == "Perpignan" & tmax >= 30) |> count()') == "ko")

# Limite de temps (abaissée à 1 s pour le test)
SANDBOX_LIMITS$max_seconds <- 1
env <- sandbox_new_env(base_datasets("naissances"))
r <- sandbox_run('for_test <- BDD_NAIS |> mutate(x = paste(DEPNAIS, AGEMERE, AGEPERE, MNAIS, SEXE)) |> group_by(x) |> summarise(m = median(AGEXACTM)) |> arrange(desc(m))\nX <- BDD_NAIS |> mutate(y = paste(x = DEPDOM, AMAR, ARECC, MNAIS)) |> count(y) |> arrange(y)\nY <- BDD_NAIS |> mutate(z = paste(AGEXACTP, AGEXACTM, DEPNAIS, DEPDOM, MNAIS, SEXE, NBENF)) |> count(z) |> arrange(z)', env)
interrompu <- any(vapply(r$items, function(i) i$type == "error" && grepl("secondes", i$hint %||% ""), TRUE))
cat(sprintf("Durée : %.1f s, interrompu : %s\n", r$seconds, interrompu))
expect("calcul long interrompu", interrompu || r$seconds < 1.5)
expect("limite levée après le calcul", { x <- 0; for (i in 1:3e6) x <- x + 1; TRUE })
cat(sprintf("\n%d tests réussis, %d échecs\n", ok, ko)); if (ko) quit(status = 1)
