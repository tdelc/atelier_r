# ============================================================================
# sandbox.R — exécution sécurisée du code écrit par les étudiants
#
# Le code tapé dans les volets « Découverte » et « Exercices » est exécuté sur
# le serveur. Pour qu'aucun étudiant ne puisse lire des fichiers, lancer une
# commande système, voir le travail des autres ou bloquer l'application, on
# empile quatre protections :
#
#  1. LISTE BLANCHE — le code est analysé AVANT d'être exécuté. Chaque appel de
#     fonction doit figurer dans la liste des fonctions autorisées (verbes du
#     tidyverse, fonctions de calcul, ggplot2…). Tout le reste est refusé :
#     system(), file(), readRDS(), eval(), get(), library(), `::`, `<<-`…
#  2. ENVIRONNEMENT ISOLÉ — le code tourne dans un environnement dont le parent
#     est vide (emptyenv) : il ne « voit » que les fonctions autorisées et les
#     bases de données. Même une fonction oubliée par la liste blanche serait
#     introuvable.
#  3. GARDE-FOUS DE TAILLE ET DE TEMPS — longueur du code, nombre de
#     commandes, grands nombres, temps de calcul (15 s), taille de l'affichage.
#  4. ÉCHAPPEMENT HTML — tout ce qui est affiché est échappé (pas d'injection
#     de HTML ou de JavaScript dans la page).
#
# Pour autoriser une nouvelle fonction : l'ajouter dans SANDBOX_ALLOWED.
# Recommandation de déploiement : faire tourner le serveur Shiny sous un
# utilisateur sans droits et avec une limite de mémoire (voir README).
# ============================================================================

SANDBOX_LIMITS <- list(
  max_chars       = 8000,   # longueur du code
  max_exprs       = 80,     # nombre de commandes
  max_number      = 1e6,    # plus grand nombre écrit en dur dans le code
  max_seconds     = 15,     # temps de calcul
  max_lines       = 400,    # lignes affichées
  max_out_chars   = 60000,  # caractères affichés
  max_table_vars  = 2,      # variables dans table()
  max_plots       = 6       # graphiques par exécution
)

# --- 1. Les fonctions autorisées ---------------------------------------------
# L'ordre des paquets compte : `filter` et `lag` doivent venir de dplyr et non
# de stats.

SANDBOX_ALLOWED <- list(
  dplyr = c(
    "filter", "select", "mutate", "transmute", "summarise", "summarize",
    "group_by", "ungroup", "count", "tally", "add_count", "n", "n_distinct",
    "arrange", "desc", "distinct", "rename", "relocate", "pull",
    "slice", "slice_head", "slice_tail", "slice_sample", "slice_min",
    "slice_max", "sample_n", "if_else", "case_when", "between", "lag", "lead",
    "row_number", "first", "last", "nth", "across", "everything",
    "starts_with", "ends_with", "contains", "matches", "where", "all_of",
    "any_of", "last_col", "coalesce", "na_if", "glimpse", "reframe",
    "cummean", "min_rank", "dense_rank", "percent_rank", "ntile", "near",
    "n_groups", "group_vars", "consecutive_id", "bind_rows"
  ),
  tidyr     = c("pivot_wider", "pivot_longer", "replace_na", "drop_na", "fill",
                "separate", "unite"),
  tibble    = c("tibble", "as_tibble"),
  lubridate = c("year", "month", "day", "wday", "yday", "week", "isoweek",
                "quarter", "ymd", "dmy", "make_date", "floor_date", "as_date"),
  stringr   = c("str_detect", "str_sub", "str_replace", "str_replace_all",
                "str_to_upper", "str_to_lower", "str_length", "str_pad",
                "str_c", "str_starts", "str_ends"),
  forcats   = c("fct_reorder", "fct_infreq", "fct_rev", "fct_relevel",
                "fct_recode", "fct_lump_n"),
  scales    = c("percent", "comma", "label_percent", "label_number",
                "label_comma"),
  magrittr  = c("%>%"),
  base = c(
    # opérateurs et syntaxe
    "(", "{", "+", "-", "*", "/", "^", "%%", "%/%", "==", "!=", "<", ">",
    "<=", ">=", "&", "|", "!", "&&", "||", "%in%", ":", "$", "[", "[[", "~",
    "<-", "=", "if",
    # calculs
    "c", "list", "mean", "min", "max", "sum", "prod", "range", "round",
    "signif", "floor", "ceiling", "trunc", "abs", "sqrt", "log", "log10",
    "log2", "exp", "cumsum", "cummax", "cummin", "diff", "rev", "sort",
    "order", "rank", "unique", "length", "nrow", "ncol", "dim", "names",
    "colnames", "table", "prop.table", "summary", "print",
    "is.na", "ifelse", "cut", "which", "which.max", "which.min", "any", "all",
    "is.numeric", "is.character", "is.logical", "is.factor", "is.null",
    "isTRUE", "isFALSE", "class", "nchar", "paste", "paste0", "toupper",
    "tolower", "substr", "trimws", "as.numeric", "as.integer",
    "as.character", "as.factor", "as.logical", "factor", "levels", "nlevels",
    "as.Date", "format", "colSums", "colMeans", "rowSums", "rowMeans",
    "seq_len", "seq_along", "setdiff", "intersect", "union", "unlist",
    "identity", "invisible", "set.seed", "sample", "tabulate"
  ),
  stats    = c("median", "sd", "var", "quantile", "weighted.mean", "cor",
               "IQR", "mad", "chisq.test", "t.test", "addmargins", "reorder"),
  utils    = c("head", "tail", "str"),
  graphics = c("hist", "barplot", "boxplot", "plot", "pie", "abline", "lines",
               "points", "legend", "title", "text", "par")
)

# ggplot2 : on prend les fonctions exportées qui suivent ces motifs…
SANDBOX_GGPLOT_PATTERN <- paste0(
  "^(ggplot|aes|after_stat|after_scale|vars|labs|xlab|ylab|ggtitle|lims|",
  "xlim|ylim|annotate|margin|guides|geom_[a-z0-9_]+|stat_[a-z0-9_]+|",
  "scale_[a-z0-9_]+|theme(_[a-z]+)?|element_[a-z]+|facet_[a-z]+|",
  "coord_[a-z]+|position_[a-z]+|guide_[a-z]+)$"
)
# … sauf celles qui modifient l'état global ou écrivent des fichiers
SANDBOX_GGPLOT_EXCLUDE <- c("ggsave", "theme_set", "theme_update",
                            "theme_replace", "theme_get")

# Fonctions présentes dans l'environnement isolé pour le fonctionnement
# interne de R (ex. t.test() reconstruit un appel à stats::model.frame), mais
# que l'étudiant ne peut pas appeler lui-même.
SANDBOX_INTERNAL <- c("::")

# Valeurs disponibles (pas des fonctions)
SANDBOX_VALUES <- list(T = TRUE, F = FALSE, pi = pi, LETTERS = LETTERS,
                       letters = letters, month.name = month.name,
                       month.abb = month.abb)

# Textes refusés quand ils désignent une fonction R non autorisée : certaines
# fonctions acceptent un nom de fonction sous forme de texte
# (ex. stat_summary(fun = "…")).
SANDBOX_STRING_NAMESPACES <- c("base", "utils", "stats", "methods", "tools",
                               "parallel", "grDevices")
# … sauf ces mots, qui sont des valeurs courantes d'arguments (position =
# "stack", method = "lm", colour = "gray"…)
SANDBOX_BENIGN_STRINGS <- c(
  "identity", "date", "t", "c", "stack", "jitter", "density", "smooth", "lm",
  "loess", "glm", "mode", "rank", "order", "sort", "rev", "scale", "split",
  "merge", "unique", "table", "sample", "character", "numeric", "integer",
  "logical", "double", "list", "factor", "complex", "gray", "grey", "rgb",
  "hcl", "rainbow", "colors", "colours", "dimnames", "names", "levels",
  "row", "col", "max", "min", "mean", "median", "sum", "sd", "var", "range",
  "summary", "trunc", "round", "nlevels", "weekdays", "months", "quarters",
  "julian", "match", "within", "subset", "transform", "replace", "rev",
  "append", "D", "I", "pi", "nlm", "step", "time", "start", "end",
  "frequency", "window", "update", "offset", "weights", "fitted", "terms",
  "formula", "family", "power", "poly", "spline", "line", "plot", "text",
  "box", "title", "points", "lines", "legend", "image", "contour", "abline",
  "polygon", "segments", "arrows", "rect", "symbols", "grid", "axis",
  "barplot", "boxplot", "hist", "pie", "cm"
)
# … mais ceux-là sont TOUJOURS refusés (même s'ils sont dans la liste
# ci-dessus ou n'existent pas dans les espaces de noms analysés)
SANDBOX_FORBIDDEN_STRINGS <- c(
  "system", "system2", "shell", "shell.exec", "eval", "evalq", "parse",
  "deparse", "get", "get0", "mget", "assign", "source", "sys.source",
  "do.call", "match.fun", "Recall", "readRDS", "saveRDS", "load", "save",
  "unlink", "file.remove", "file", "url", "readLines", "writeLines",
  "readline", "scan", "sink", "setwd", "library", "require",
  "loadNamespace", "requireNamespace", "attach", "environment",
  "as.environment", "globalenv", "emptyenv", "new.env", "sys.call",
  "sys.function", "parent.frame", "parent.env", "body", "formals", "rm",
  "q", "quit", "Sys.setenv", "Sys.getenv", "Sys.time", "pdf", "png",
  "jpeg", "svg", "bmp", "tiff", "dev.off", "options", "on.exit",
  "getNamespace", "asNamespace", "dyn.load", "browseURL", "download.file",
  "pipe", "fifo", "socketConnection", "gzfile", "bzfile", "xzfile",
  "write.csv", "write.table", "read.csv", "read.table", "list.files",
  "dir", "file.exists", "Sys.chmod", "invokeRestart", "reg.finalizer",
  "trace", "untrace", "debug", "browser", "lockBinding", "unlockBinding",
  "makeActiveBinding", "ggsave", "theme_set", "theme_update"
)

# --- Construction de l'environnement isolé (une fois, partagé, verrouillé) ----

sandbox_function_names <- function() {
  gg <- getNamespaceExports("ggplot2")
  gg <- setdiff(gg[grepl(SANDBOX_GGPLOT_PATTERN, gg)], SANDBOX_GGPLOT_EXCLUDE)
  sort(unique(c(unlist(SANDBOX_ALLOWED, use.names = FALSE), gg)))
}

sandbox_build_funs_env <- function() {
  env <- new.env(parent = emptyenv())
  gg <- getNamespaceExports("ggplot2")
  gg <- setdiff(gg[grepl(SANDBOX_GGPLOT_PATTERN, gg)], SANDBOX_GGPLOT_EXCLUDE)
  lst <- c(SANDBOX_ALLOWED, list(ggplot2 = gg))

  for (pkg in names(lst)) {
    for (fn in lst[[pkg]]) {
      if (exists(fn, envir = env, inherits = FALSE)) next   # 1er paquet gagne
      obj <- tryCatch(getExportedValue(pkg, fn), error = function(e) NULL)
      if (is.null(obj) && pkg == "base") obj <- get0(fn, envir = baseenv())
      if (is.null(obj)) {
        warning("Fonction introuvable pour le bac à sable : ", pkg, "::", fn)
        next
      }
      assign(fn, obj, envir = env)
    }
  }
  for (fn in SANDBOX_INTERNAL) assign(fn, get(fn, envir = baseenv()), envir = env)
  for (nm in names(SANDBOX_VALUES)) assign(nm, SANDBOX_VALUES[[nm]], envir = env)

  lockEnvironment(env, bindings = TRUE)
  env
}

# Noms de fonctions R dont un texte est suspect (calculé une fois)
sandbox_suspicious_strings <- function(allowed) {
  nms <- unlist(lapply(SANDBOX_STRING_NAMESPACES, function(ns) {
    e <- asNamespace(ns)
    n <- ls(e, all.names = FALSE)
    n[vapply(n, function(x) is.function(get(x, envir = e)), logical(1))]
  }), use.names = FALSE)
  susp <- setdiff(unique(nms), c(allowed, SANDBOX_BENIGN_STRINGS))
  unique(c(susp, SANDBOX_FORBIDDEN_STRINGS))
}

SANDBOX <- new.env()
sandbox_init <- function() {
  SANDBOX$funs_env   <- sandbox_build_funs_env()
  SANDBOX$allowed    <- sandbox_function_names()
  SANDBOX$suspicious <- sandbox_suspicious_strings(SANDBOX$allowed)
  invisible(SANDBOX)
}

# --- 2. Analyse du code avant exécution ---------------------------------------

# Renvoie un vecteur de messages d'erreur (vide = code accepté)
sandbox_check <- function(code) {
  lim <- SANDBOX_LIMITS
  if (!is.character(code) || length(code) != 1) return("Code invalide.")
  if (nchar(code) > lim$max_chars)
    return(sprintf("Le code est trop long (%d caractères, maximum %d).",
                   nchar(code), lim$max_chars))

  exprs <- tryCatch(parse(text = code, keep.source = FALSE),
                    error = function(e) e)
  if (inherits(exprs, "error"))
    return(paste0("Erreur de syntaxe : ", sandbox_syntax_message(exprs)))
  if (length(exprs) > lim$max_exprs)
    return(sprintf("Trop de commandes (%d, maximum %d).",
                   length(exprs), lim$max_exprs))

  problems <- character()
  add <- function(msg) problems <<- c(problems, msg)
  allowed <- SANDBOX$allowed
  is_empty <- function(x) identical(x, quote(expr = ))

  walk <- function(e) {
    if (is.call(e)) {
      head <- e[[1]]
      if (!is.symbol(head)) {
        add("Forme d'appel non autorisée : appelez les fonctions directement par leur nom.")
      } else {
        fn <- as.character(head)
        if (fn %in% c("::", ":::")) {
          add(sprintf("L'opérateur %s n'est pas utilisé dans l'atelier : les paquets sont déjà chargés, écrivez directement le nom de la fonction.", fn))
        } else if (fn %in% c("<<-", "->>")) {
          add("L'opérateur <<- n'est pas autorisé : utilisez <-.")
        } else if (fn %in% c("library", "require", "install.packages")) {
          add(sprintf("%s() n'est pas nécessaire ici : tous les paquets du cours (tidyverse, ggplot2) sont déjà chargés.", fn))
        } else if (fn %in% c("setwd", "read_csv", "read_csv2", "read.csv", "read_delim")) {
          add(sprintf("%s() n'est pas utilisable dans l'atelier : les bases BDD_NAIS et BDD_METEO sont déjà chargées.", fn))
        } else if (fn == "function") {
          add("La création de fonctions (function) n'est pas autorisée dans l'atelier.")
        } else if (!fn %in% allowed) {
          add(sprintf("La fonction %s() n'est pas disponible dans l'atelier (voir la liste des fonctions autorisées).", fn))
        } else {
          # règles particulières
          if (fn %in% c("<-", "=") && length(e) == 3 && !is.symbol(e[[2]]))
            add("Seule l'écriture NOM <- valeur est autorisée. Pour modifier une colonne, utilisez mutate().")
          if (fn == "table") {
            nm <- names(e); if (is.null(nm)) nm <- rep("", length(e))
            n_vars <- sum(nm[-1] == "")
            if (n_vars > SANDBOX_LIMITS$max_table_vars)
              add(sprintf("table() est limité à %d variables dans l'atelier : utilisez group_by() + count().",
                          SANDBOX_LIMITS$max_table_vars))
          }
        }
      }
      args <- as.list(e)[-1]
      for (i in seq_along(args)) {
        if (is_empty(args[[i]])) next
        walk(args[[i]])
      }
    } else if (is.character(e)) {
      bad <- e[e %in% SANDBOX$suspicious | grepl("::", e, fixed = TRUE)]
      if (length(bad))
        add(sprintf("Le texte \"%s\" désigne une fonction non autorisée.", bad[1]))
    } else if (is.numeric(e)) {
      if (any(abs(e) > SANDBOX_LIMITS$max_number, na.rm = TRUE))
        add(sprintf("Les nombres supérieurs à %s ne sont pas autorisés dans l'atelier.",
                    format(SANDBOX_LIMITS$max_number, big.mark = " ", scientific = FALSE)))
    } else if (is.pairlist(e)) {
      for (i in seq_along(e)) if (!is_empty(e[[i]])) walk(e[[i]])
    }
    invisible(NULL)
  }
  for (ex in exprs) walk(ex)
  unique(problems)
}

sandbox_syntax_message <- function(err) {
  msg <- conditionMessage(err)
  msg <- sub("^<text>:", "ligne ", msg)
  hint <- ""
  if (grepl("unexpected end of input", msg))
    hint <- " — il manque probablement une parenthèse fermante ) ou un guillemet."
  else if (grepl("unexpected symbol", msg))
    hint <- " — il manque peut-être une virgule, un |> ou un opérateur entre deux mots."
  else if (grepl("unexpected '\\)'", msg))
    hint <- " — il y a une parenthèse fermante en trop."
  else if (grepl("unexpected '='", msg))
    hint <- " — pour tester une égalité, écrivez == (deux signes égal)."
  else if (grepl("unexpected string constant", msg))
    hint <- " — il manque peut-être une virgule avant ce texte."
  else if (grepl("unexpected input", msg))
    hint <- " — un caractère n'est pas reconnu (guillemets typographiques « » ou ’ ?)."
  paste0(msg, hint)
}

# --- 3. Exécution ---------------------------------------------------------------

# Nouvel environnement de travail : contient les bases demandées
sandbox_new_env <- function(datasets = list()) {
  env <- new.env(parent = SANDBOX$funs_env)
  for (nm in names(datasets)) assign(nm, datasets[[nm]], envir = env)
  env
}

# Traduction des erreurs les plus fréquentes
sandbox_error_hint <- function(msg) {
  if (grepl("reached (elapsed|CPU) time limit", msg))
    return(sprintf("Calcul interrompu : il a dépassé %d secondes.", SANDBOX_LIMITS$max_seconds))
  m <- regmatches(msg, regexec("object '([^']+)' not found", msg))[[1]]
  if (length(m) == 2)
    return(sprintf("L'objet ou la colonne « %s » est introuvable. Vérifiez l'orthographe (R distingue majuscules et minuscules) et que la variable a bien été créée (avec <- pour la conserver).", m[2]))
  m <- regmatches(msg, regexec("could not find function \"([^\"]+)\"", msg))[[1]]
  if (length(m) == 2)
    return(sprintf("La fonction %s() n'existe pas ou n'est pas disponible dans l'atelier.", m[2]))
  if (grepl("non-numeric argument", msg))
    return("Un calcul porte sur du texte : vérifiez le type de la colonne (glimpse) et les guillemets.")
  if (grepl("Column `([^`]+)` doesn't exist", msg) || grepl("doesn't exist", msg))
    return("Une colonne citée n'existe pas dans le tableau à cette étape. Vérifiez son nom, et qu'elle n'a pas disparu après un summarise() ou un select().")
  if (grepl("must be size", msg))
    return("Le résultat d'un calcul n'a pas la bonne longueur : dans mutate(), le calcul doit donner une valeur par ligne ; dans summarise(), une valeur par groupe.")
  if (grepl("Values from .* are not uniquely identified", msg))
    return("pivot_wider() trouve plusieurs valeurs pour une même case : gardez seulement trois colonnes avant de pivoter (select), ou résumez d'abord avec summarise().")
  if (grepl("unused argument", msg))
    return("Un argument n'est pas reconnu par la fonction : vérifiez son nom et la position des parenthèses.")
  if (grepl("argument is not numeric or logical", msg))
    return("La fonction attend des nombres : la colonne est peut-être du texte.")
  ""
}

clip_text <- function(x, max_lines, max_chars) {
  lines <- strsplit(x, "\n", fixed = TRUE)[[1]]
  cut <- FALSE
  if (length(lines) > max_lines) { lines <- lines[seq_len(max_lines)]; cut <- TRUE }
  out <- paste(lines, collapse = "\n")
  if (nchar(out) > max_chars) { out <- substr(out, 1, max_chars); cut <- TRUE }
  list(text = out, cut = cut)
}

# Exécute du code dans `env`. Renvoie une liste :
#   ok       : TRUE si aucune erreur
#   blocked  : messages de la liste blanche (le code n'a pas été exécuté)
#   items    : éléments à afficher, dans l'ordre (source / output / plot /
#              message / warning / error)
#   value    : valeur de la dernière commande exécutée sans erreur
#   seconds  : durée
sandbox_run <- function(code, env, check = TRUE, plot_width = 7,
                        plot_height = 4.2) {
  code <- gsub("\r\n?", "\n", code)
  # guillemets et apostrophes typographiques collés depuis un traitement de texte
  code <- chartr("“”‘’", "\"\"''", code)

  if (check) {
    probs <- sandbox_check(code)
    if (length(probs))
      return(list(ok = FALSE, blocked = probs, items = list(), value = NULL,
                  seconds = 0))
  }
  if (!nzchar(trimws(code)))
    return(list(ok = TRUE, blocked = character(), items = list(),
                value = NULL, seconds = 0))

  last <- new.env()
  last$value <- NULL
  last$n_plots <- 0L
  handler <- evaluate::new_output_handler(
    value = function(x, visible) {
      last$value <- x
      if (visible) print(x) else invisible(NULL)
    }
  )

  old_opt <- options(width = 92, cli.num_colors = 1, crayon.enabled = FALSE,
                     pillar.subtle = FALSE, dplyr.summarise.inform = FALSE,
                     warn = 1, digits = 7, OutDec = ".")
  on.exit(options(old_opt), add = TRUE)

  t0 <- Sys.time()
  setTimeLimit(cpu = SANDBOX_LIMITS$max_seconds,
               elapsed = SANDBOX_LIMITS$max_seconds, transient = TRUE)
  on.exit(setTimeLimit(cpu = Inf, elapsed = Inf, transient = FALSE), add = TRUE)

  res <- tryCatch(
    evaluate::evaluate(code, envir = env, stop_on_error = 1L,
                       new_device = TRUE, output_handler = handler,
                       keep_warning = TRUE, keep_message = TRUE),
    error = function(e) list(e)
  )
  setTimeLimit(cpu = Inf, elapsed = Inf, transient = FALSE)
  secs <- as.numeric(difftime(Sys.time(), t0, units = "secs"))

  items <- list()
  n_lines <- 0; n_chars <- 0; clipped <- FALSE; ok <- TRUE; n_plots <- 0
  for (r in res) {
    if (inherits(r, "source")) {
      items[[length(items) + 1]] <- list(type = "source", text = sub("\n$", "", r$src))
    } else if (is.character(r)) {
      if (clipped) next
      cl <- clip_text(r, SANDBOX_LIMITS$max_lines - n_lines,
                      SANDBOX_LIMITS$max_out_chars - n_chars)
      n_lines <- n_lines + length(strsplit(cl$text, "\n")[[1]])
      n_chars <- n_chars + nchar(cl$text)
      items[[length(items) + 1]] <- list(type = "output", text = sub("\n$", "", cl$text))
      if (cl$cut) {
        clipped <- TRUE
        items[[length(items) + 1]] <- list(type = "message",
          text = "Affichage tronqué : le résultat est trop long. Utilisez head(), print(n = …) ou un filtre.")
      }
    } else if (inherits(r, "recordedplot")) {
      n_plots <- n_plots + 1
      if (n_plots > SANDBOX_LIMITS$max_plots) next
      img <- tryCatch(plot_to_base64(r, plot_width, plot_height),
                      error = function(e) NULL)
      if (!is.null(img)) items[[length(items) + 1]] <- list(type = "plot", src = img)
    } else if (inherits(r, "error")) {
      ok <- FALSE
      msg <- conditionMessage(r)
      items[[length(items) + 1]] <- list(type = "error", text = clean_condition(msg),
                                         hint = sandbox_error_hint(msg))
    } else if (inherits(r, "warning")) {
      items[[length(items) + 1]] <- list(type = "warning",
                                         text = clean_condition(conditionMessage(r)))
    } else if (inherits(r, "message")) {
      items[[length(items) + 1]] <- list(type = "message",
                                         text = sub("\n$", "", clean_condition(conditionMessage(r))))
    }
  }
  list(ok = ok, blocked = character(), items = items, value = last$value,
       seconds = secs)
}

clean_condition <- function(x) {
  x <- gsub("\033\\[[0-9;]*m", "", x)   # codes couleur
  x <- gsub("ℹ", "i", x)
  x
}

plot_to_base64 <- function(rec, width = 7, height = 4.2, res = 110) {
  f <- tempfile(fileext = ".png")
  on.exit(unlink(f), add = TRUE)
  type <- if (capabilities("cairo")) "cairo" else NULL
  args <- list(filename = f, width = width, height = height, units = "in",
               res = res, bg = "white")
  if (!is.null(type)) args$type <- type
  do.call(grDevices::png, args)
  ok <- tryCatch({ grDevices::replayPlot(rec); TRUE },
                 error = function(e) FALSE, finally = grDevices::dev.off())
  if (!ok) return(NULL)
  paste0("data:image/png;base64,",
         jsonlite::base64_enc(readBin(f, "raw", file.info(f)$size)))
}
