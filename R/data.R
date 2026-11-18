# ============================================================================
# data.R — les bases de données de l'atelier
#
# Une base = un dossier dans bases/ :
#
#   bases/<id>/
#     base.txt          description de la base (obligatoire, « clé: valeur »)
#     <fichier>         les données (.rds, .csv ; nom donné dans base.txt)
#     dictionnaire.csv  dictionnaire des variables (facultatif)
#     cours/*.md        les leçons (facultatif)
#     decouverte.md     les pistes de découverte (facultatif)
#     exercices.md      les exercices (facultatif)
#     dashboard.R       le tableau de bord (facultatif)
#
# Pour ajouter une base, il suffit de créer un nouveau dossier : aucune ligne
# de code de l'application n'est à modifier. Les clés de base.txt sont
# décrites dans docs/GUIDE_CONTENUS.md (section « Ajouter une base »).
# ============================================================================

BASES_DIR <- "bases"
BASES <- list()

# Lit un fichier « clé: valeur » (lignes # = commentaires)
read_base_txt <- function(path) {
  lines <- read_utf8(path)
  lines <- lines[nzchar(trimws(lines)) & !grepl("^\\s*#", lines)]
  meta <- list()
  for (l in lines) {
    if (!grepl("^\\s*[A-Za-z_][A-Za-z0-9_]*\\s*:", l)) next
    k <- trimws(sub(":.*$", "", l))
    meta[[k]] <- trimws(sub("^[^:]*:", "", l))
  }
  meta
}

# « a = x, b = y » -> c(a = "x", b = "y") ; « x, y » -> c(x = "x", y = "y")
parse_named_list <- function(x) {
  if (is.null(x) || !nzchar(trimws(x))) return(character())
  parts <- trimws(strsplit(x, "[,;]")[[1]])
  parts <- parts[nzchar(parts)]
  nm <- ifelse(grepl("=", parts), trimws(sub("=.*$", "", parts)), parts)
  val <- ifelse(grepl("=", parts), trimws(sub("^[^=]*=", "", parts)), parts)
  stats::setNames(val, nm)
}

# Lit un fichier de données selon son extension
read_data_file <- function(path, separateur = NULL) {
  ext <- tolower(tools::file_ext(path))
  if (ext == "rds") return(readRDS(path))
  if (ext %in% c("csv", "txt")) {
    sep <- separateur %||% ""
    if (!nzchar(sep)) {
      first <- readLines(path, n = 1, warn = FALSE, encoding = "UTF-8")
      sep <- if (lengths(regmatches(first, gregexpr(";", first))) >
                 lengths(regmatches(first, gregexpr(",", first)))) ";" else ","
    }
    if (requireNamespace("readr", quietly = TRUE)) {
      if (sep == ";") return(suppressMessages(readr::read_csv2(path, show_col_types = FALSE, progress = FALSE)))
      return(readr::read_csv(path, show_col_types = FALSE, progress = FALSE,
                             name_repair = "unique_quiet"))
    }
    return(dplyr::as_tibble(utils::read.csv(path, sep = sep, dec = if (sep == ";") "," else ".",
                                            encoding = "UTF-8", fileEncoding = "UTF-8",
                                            stringsAsFactors = FALSE)))
  }
  stop("Format de données non reconnu : ", path, " (attendu : .rds ou .csv)")
}

# Cherche un fichier dans le dossier de la base, puis dans data/ (tables
# partagées entre plusieurs bases), puis depuis la racine de l'application
find_base_file <- function(dir, name, app_dir = ".") {
  cands <- c(file.path(dir, name), file.path(app_dir, "data", name), file.path(app_dir, name))
  if (!nzchar(tools::file_ext(name)))
    cands <- c(paste0(cands, ".rds"), paste0(cands, ".csv"), cands)
  hit <- cands[file.exists(cands)]
  if (!length(hit)) stop("Fichier introuvable : ", name, " (cherché dans ", dir, " et data/)")
  hit[1]
}

# Description d'une base (sans les données)
read_base_info <- function(dir, app_dir = ".") {
  id <- basename(dir)
  m <- read_base_txt(file.path(dir, "base.txt"))
  objet <- m$objet %||% paste0("BDD_", toupper(gsub("[^A-Za-z0-9]", "_", id)))
  fichier <- m$fichier %||% objet
  extras <- parse_named_list(m$extras)
  list(
    id        = id,
    dir       = dir,
    objet     = objet,
    fichier   = find_base_file(dir, fichier, app_dir),
    separateur = m$separateur,
    libelle   = m$libelle %||% id,
    titre     = m$titre %||% m$libelle %||% id,
    source    = m$source %||% "",
    ligne     = m$ligne %||% "une observation",
    icone     = m$icone %||% "database",
    ordre     = suppressWarnings(as.numeric(m$ordre %||% NA)),
    description = m$description %||% "",
    nom_lignes = m$nom_lignes %||% "lignes",
    compter   = parse_named_list(m$compter),
    extras    = vapply(extras, function(f) find_base_file(dir, f, app_dir), ""),
    code_libre = gsub("\\n", "\n", m$code_libre %||% paste0(objet, " |>\n  glimpse()"), fixed = TRUE),
    dashboard_titre = m$dashboard_titre %||% m$titre %||% id,
    langage   = tolower(m$langage %||% "r"),
    dossier_python = m$dossier_python %||% "fichiers",
    meta      = m,
    dash_env  = NULL       # rempli par load_dashboards()
  )
}

# Liste les dossiers de bases (ceux qui contiennent un base.txt), triés par
# la clé « ordre » puis par nom
list_bases <- function(app_dir = ".") {
  root <- file.path(app_dir, BASES_DIR)
  dirs <- list.dirs(root, recursive = FALSE, full.names = TRUE)
  dirs[file.exists(file.path(dirs, "base.txt"))]
}

# Chargées une seule fois au démarrage, partagées (en lecture) par toutes les
# sessions : chaque session travaille sur sa propre copie logique (R ne
# duplique réellement que les colonnes modifiées).
load_bases <- function(app_dir = ".") {
  infos <- lapply(list_bases(app_dir), read_base_info, app_dir = app_dir)
  if (!length(infos)) stop("Aucune base trouvée dans ", file.path(app_dir, BASES_DIR),
                           " (chaque base est un dossier contenant un fichier base.txt).")
  ord <- order(vapply(infos, function(b) if (is.na(b$ordre)) Inf else b$ordre, 0),
               vapply(infos, `[[`, "", "id"))
  infos <- infos[ord]
  names(infos) <- vapply(infos, `[[`, "", "id")
  dup <- duplicated(vapply(infos, `[[`, "", "objet"))
  if (any(dup)) stop("Deux bases utilisent le même nom d'objet : ",
                     paste(vapply(infos[dup], `[[`, "", "objet"), collapse = ", "))
  for (b in names(infos)) {
    B <- infos[[b]]
    B$data <- read_data_file(B$fichier, B$separateur)
    B$extras_data <- lapply(B$extras, read_data_file)
    dico <- file.path(B$dir, "dictionnaire.csv")
    B$dico <- if (file.exists(dico)) read_dictionary(dico) else auto_dictionary(B$data)
    infos[[b]] <- B
  }
  BASES <<- infos
  invisible(BASES)
}

# Dictionnaire minimal quand la base n'en a pas
auto_dictionary <- function(d) {
  type <- vapply(d, function(x) {
    if (inherits(x, "Date")) "Date"
    else if (is.numeric(x)) "Numérique"
    else if (is.logical(x)) "Logique"
    else "Texte"
  }, "")
  data.frame(variable = names(d), libelle = "", type = unname(type),
             modalites = "", stringsAsFactors = FALSE, check.names = FALSE)
}

# Chemin d'un fichier de contenu d'une base
base_path <- function(base, ...) file.path(BASES[[base]]$dir, ...)

# Liste nommée « nom de l'objet R » = données, pour le bac à sable
base_datasets <- function(base) {
  c(stats::setNames(list(BASES[[base]]$data), BASES[[base]]$objet),
    BASES[[base]]$extras_data)
}

# Noms des objets de toutes les bases (pour les messages)
bases_objets <- function() vapply(BASES, `[[`, "", "objet")

# --- Tableaux de bord ---------------------------------------------------------
# Chaque base peut avoir un fichier dashboard.R qui définit deux fonctions :
#   dashboard_ui(id)      l'interface (filtres, graphiques…)
#   dashboard_server(id)  la logique serveur
# Le fichier est chargé dans un environnement propre à la base : deux bases
# peuvent utiliser les mêmes noms de fonctions et d'objets sans se gêner.
# Dans ce fichier, BASE désigne la description de la base (BASE$data = les
# données, BASE$dir = le dossier).
load_dashboards <- function() {
  for (b in names(BASES)) {
    f <- base_path(b, "dashboard.R")
    if (!file.exists(f)) next
    # parent = l'environnement où sont chargés les fichiers R/ de
    # l'application (Shiny ne les charge pas dans globalenv())
    env <- new.env(parent = environment(load_dashboards))
    env$BASE <- BASES[[b]]
    for (e in parse(f, encoding = "UTF-8", keep.source = FALSE)) eval(e, envir = env)
    if (!is.function(env$dashboard_ui) || !is.function(env$dashboard_server))
      stop(f, " doit définir les fonctions dashboard_ui(id) et dashboard_server(id).")
    BASES[[b]]$dash_env <<- env
  }
  invisible(NULL)
}

# --- Bases en Python ----------------------------------------------------------
# Une base dont le base.txt contient « langage: python » a un cours en Python.
# Le code s'exécute dans le navigateur de l'étudiant (Pyodide : voir
# www/python/). Le dossier « dossier_python » de la base (par défaut
# fichiers/) est copié dans son dossier de travail Python.

est_python <- function(base) identical(BASES[[base]]$langage, "python")
base_lang <- function(base) if (est_python(base)) "python" else "r"

# Petit libellé en tête des pages : l'objet R (BDD_NAIS) ou « Python · … »
base_kicker <- function(base)
  if (est_python(base)) paste("Python ·", BASES[[base]]$libelle) else BASES[[base]]$objet

# Adresse web des fichiers d'une base Python
py_resource <- function(base) paste0("pyfiles-", base)

# Rend les fichiers des bases Python accessibles au navigateur, et renvoie la
# configuration lue par www/python/atelier_py.js
register_python <- function() {
  conf <- list()
  for (b in names(BASES)) {
    if (!est_python(b)) next
    dir <- base_path(b, BASES[[b]]$dossier_python)
    files <- if (dir.exists(dir)) list.files(dir, recursive = TRUE) else character()
    if (dir.exists(dir)) shiny::addResourcePath(py_resource(b), normalizePath(dir))
    conf[[b]] <- list(files = lapply(files, function(f)
      list(path = f, url = paste0(py_resource(b), "/", utils::URLencode(f)))))
  }
  conf
}
