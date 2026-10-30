# ============================================================================
# Tests du bac à sable : ce qui doit marcher, et ce qui doit être bloqué.
#   Rscript tests/test_sandbox.R      (depuis le dossier de l'application)
# ============================================================================

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(ggplot2); library(lubridate)
})
for (f in list.files("R", full.names = TRUE)) source(f, encoding = "UTF-8")
sandbox_init()

df <- tibble(a = c(1, 2, NA, 10), g = c("x", "x", "y", "y"),
             d = as.Date("2020-01-01") + 0:3)
nb_ok <- 0; nb_ko <- 0
expect <- function(desc, cond) {
  if (isTRUE(cond)) { nb_ok <<- nb_ok + 1 } else {
    nb_ko <<- nb_ko + 1; cat("ÉCHEC :", desc, "\n")
  }
}
run <- function(code, env = sandbox_new_env(list(BDD = df))) sandbox_run(code, env)
blocked <- function(code) length(sandbox_check(code)) > 0
runs_ok <- function(code) { r <- run(code); isTRUE(r$ok) && !length(r$blocked) }

# --- Ce qui doit fonctionner ---------------------------------------------------
ok_codes <- c(
  'BDD |> filter(g == "x") |> summarise(m = mean(a, na.rm = T))',
  'BDD |> group_by(g) |> count() |> pivot_wider(names_from = g, values_from = n)',
  'BDD |> mutate(an = year(d), b = if_else(a > 1, "oui", "non")) |> select(an, b)',
  'BDD |> mutate(c = case_when(a > 5 ~ "grand", .default = "petit"))',
  'X <- BDD |> filter(!is.na(a)); summary(X$a); table(X$g, useNA = "ifany")',
  'hist(BDD$a)',
  'ggplot(BDD, aes(x = g, y = a)) + geom_col() + theme_minimal() + labs(title = "t")',
  'BDD |> summarise(across(where(is.numeric), ~ mean(.x, na.rm = TRUE)))',
  'BDD |> pivot_longer(-g, names_to = "ind", values_to = "v", values_transform = as.character)',
  'BDD %>% arrange(desc(a)) %>% head(2)',
  'quantile(BDD$a, 0.75, na.rm = TRUE); BDD |> print(n = 50)',
  'BDD |> mutate(cl = cut(a, breaks = c(0, 5, 20), labels = c("a", "b")))',
  'BDD |> mutate(l = lag(a, 1, default = 0)) |> slice_sample(n = 2)',
  'ggplot(BDD, aes(g)) + geom_bar(position = "stack", fill = "steelblue")',
  'BDD |> filter(g %in% c("x", "y")) |> glimpse()',
  'B <- tibble(v = c(1, 2, 3, 5, 6, 8), h = c("x", "x", "x", "y", "y", "y")); t.test(v ~ h, data = B)'
)
for (cd in ok_codes) expect(paste("doit marcher :", cd), runs_ok(cd))

r <- run("hist(BDD$a)")
expect("un histogramme produit une image", any(vapply(r$items, function(i) i$type == "plot", TRUE)))
r <- run("BDD |> count(g)")
expect("valeur finale récupérée", is.data.frame(r$value) && nrow(r$value) == 2)
r <- run("BDD |> filter(gg == 1)")
expect("erreur traduite", !r$ok && any(vapply(r$items, function(i) i$type == "error", TRUE)))
r <- run('x <- 1\nprint(x)\nzzz')
expect("erreur sur objet inconnu avec indice",
       any(vapply(r$items, function(i) i$type == "error" && grepl("introuvable", i$hint), TRUE)))

# --- Ce qui doit être bloqué -----------------------------------------------------
bad_codes <- c(
  'system("ls")', 'system2("ls")', 'base::system("ls")', 'base:::system("id")',
  'file("/etc/passwd")', 'readLines("/etc/passwd")', 'readRDS("data/BDD_NAIS.rds")',
  'eval(parse(text = "system(\'ls\')"))', 'get("system")("ls")',
  '"system"("ls")', 'do.call("system", list("ls"))', 'match.fun("system")',
  'Sys.getenv()', 'Sys.setenv(A = 1)', 'setwd("/")', 'library(httr)',
  'x <<- 1', 'environment(mean)', 'globalenv()',
  'f <- function() system("ls")', 'f <- function(x) get("x")', 'g(1)',
  'repeat { 1 }',
  '(\\(x) x)(1)', 'BDD$z <- 1', 'names(BDD) <- "a"', 'assign("x", 1)',
  'stat_summary(fun = "system")', 'BDD |> summarise(across(everything(), "system"))',
  'rep(1, 10)', 'x <- 1:1e9', 'seq(1, 10)', 'table(BDD$a, BDD$g, BDD$d)',
  'ggsave("x.png")', 'theme_set(theme_void())', 'quit()', 'q("no")',
  'options(warn = 2)', 'sink("f")', 'list.files("/")', 'BDD[[1]](1)',
  'mean$x(1)', 'write.csv(BDD, "a.csv")', 'invokeRestart("abort")',
  'while (TRUE) 1', 'Recall()',
  'paste0("sys", "tem")("ls")', 'BDD |> mutate(x = "base::system")',
  'source("app.R")', 'loadNamespace("utils")', 'tracemem(BDD)',
  'on.exit(1)', 'lapply(1:3, print)', 'sapply(1:3, sqrt)', 'Reduce(`+`, 1:3)',
  'aggregate(a ~ g, data = BDD, FUN = mean)', 'local(1)', 'with(BDD, a)',
  'parent.frame()', 'sys.call()', 'body(mean)', 'attr(BDD, "x") <- 1',
  'slice_sample(BDD, n = 1e9, replace = TRUE)'
)
for (cd in bad_codes) expect(paste("doit être bloqué :", cd), blocked(cd))

# --- Boucles, fonctions, jointures (ajoutées pour les leçons complémentaires)
ok2 <- c(
  'v <- NULL\nfor (i in 1:20) { s <- slice_sample(BDD, n = 2); v <- c(v, mean(s$a, na.rm = TRUE)) }\nlength(v)',
  'moyenne_g <- function(base, groupe) { base |> filter(g == groupe) |> summarise(m = mean(a, na.rm = TRUE)) }\nmoyenne_g(BDD, "x")',
  'carre <- function(x) { return(x^2) }\nsapply_free <- carre(1:5)\nsapply_free',
  'INFO <- tibble(g = c("x", "y"), libelle = c("groupe X", "groupe Y"))\nBDD |> left_join(INFO, by = "g")',
  'INFO <- tibble(g = c("x"), libelle = c("groupe X"))\nBDD |> anti_join(INFO, by = "g")'
)
for (cd in ok2) expect(paste("doit marcher :", cd), runs_ok(cd))
e <- sandbox_new_env(list(BDD = df))
invisible(sandbox_run("double <- function(x) 2 * x", e))
expect("fonction créée réutilisable à l'exécution suivante", isTRUE(sandbox_run("double(3)", e)$ok))
r <- run('BDD |> left_join(BDD, by = "g")')
expect("jointure plusieurs-à-plusieurs refusée", !r$ok &&
       any(vapply(r$items, function(i) i$type == "error" && grepl("une seule ligne", i$hint %||% ""), TRUE)))
big <- tibble(g = as.character(1:60000))
r <- sandbox_run('BDD |> left_join(GROS, by = "g")', sandbox_new_env(list(BDD = df, GROS = big)))
expect("grande base de droite refusée", !r$ok)
r <- run('BDD |> left_join(tibble(g = "x"), by = "g", relationship = "many-to-many")')
expect("relationship imposé", isTRUE(r$ok))
expect("récursion refusée", blocked('f <- function(n) f(n + 1)\nf(1)'))
expect("récursion croisée refusée", blocked('f <- function(n) g(n)\ng <- function(n) f(n)\nf(1)'))
SANDBOX_LIMITS$max_seconds <- 2
r <- run('x <- 0\nfor (i in 1:1000000) for (j in 1:1000000) x <- x + 1')
SANDBOX_LIMITS$max_seconds <- 15
expect("boucle trop longue interrompue", !r$ok && r$seconds < 5)
expect("fonction utilisateur isolée", inherits(try(eval(quote(system("ls")), e), silent = TRUE), "try-error"))

# Même si une fonction dangereuse était oubliée par la liste blanche, elle
# serait introuvable dans l'environnement isolé :
e <- sandbox_new_env(list(BDD = df))
expect("system introuvable dans l'env isolé",
       inherits(try(eval(quote(system("ls")), e), silent = TRUE), "try-error"))
expect("Sys.time introuvable dans l'env isolé",
       inherits(try(eval(quote(Sys.time()), e), silent = TRUE), "try-error"))
expect("l'env des fonctions est verrouillé",
       inherits(try(assign("mean", 1, envir = SANDBOX$funs_env), silent = TRUE), "try-error"))

# Une session ne voit pas les objets d'une autre
e1 <- sandbox_new_env(list(BDD = df)); e2 <- sandbox_new_env(list(BDD = df))
invisible(sandbox_run("SECRET <- 42", e1))
r <- sandbox_run("SECRET", e2)
expect("isolation entre sessions", !r$ok)

# La base d'origine n'est jamais modifiée
invisible(sandbox_run("BDD <- BDD |> filter(g == 'x')", e1))
expect("base d'origine intacte", nrow(df) == 4)

# Limite de temps
t0 <- Sys.time()
r <- sandbox_run("x <- 0:999999\nfor_ever <- BDD |> slice(1)\n", sandbox_new_env(list(BDD = df)))
expect("code normal non interrompu", r$ok)

# Affichage : HTML échappé
r <- run('"<script>alert(1)</script>"')
html <- as.character(render_run(r))
expect("HTML échappé", !grepl("<script>", html, fixed = TRUE))

# Coloration syntaxique
h <- highlight_r('BDD |> filter(A == "59") # commentaire é')
expect("coloration", grepl("tk-fn", h) && grepl("tk-str", h) && grepl("tk-com", h) && grepl("é", h))

cat(sprintf("\n%d tests réussis, %d échecs\n", nb_ok, nb_ko))
if (nb_ko > 0) quit(status = 1)
