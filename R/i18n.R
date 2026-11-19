# ============================================================================
# i18n.R — langues de l'atelier (français, néerlandais, anglais)
#
# Deux sortes de textes :
#
# 1. L'INTERFACE (boutons, menus, messages) : un seul fichier,
#    i18n/interface.csv, une ligne par texte, une colonne par langue :
#        cle,fr,nl,en
#        cours.suivante,Suivante,Volgende,Next
#    Dans le code : tr("cours.suivante"). Variables : tr("cours.n_cartes", n = 12)
#    remplace {n} dans le texte. Un texte non traduit s'affiche en français.
#
# 2. LE CONTENU des bases (leçons, exercices, pistes, dictionnaire) : des
#    fichiers parallèles dans un sous-dossier par langue, avec les mêmes noms
#    (bases/<base>/nl/cours/01-mise-en-route.md…). Ce qui manque retombe sur
#    le français (voir data.R et content.R).
#
# La langue est choisie par l'adresse : …/?lang=nl. Elle vaut pour toute la
# session (changer de langue recharge la page).
#
# Le test tests/test_traductions.py signale les textes non traduits, les
# fichiers manquants et les traductions périmées.
# ============================================================================

LANGUES <- c(fr = "Français", nl = "Nederlands", en = "English")
LANGUE_SOURCE <- "fr"

.i18n <- new.env()
.i18n$lang <- LANGUE_SOURCE        # langue pendant la construction de l'interface
.i18n$table <- NULL

load_i18n <- function(path = "i18n/interface.csv") {
  t <- utils::read.csv(path, stringsAsFactors = FALSE, encoding = "UTF-8",
                       fileEncoding = "UTF-8", check.names = FALSE, na.strings = character())
  dup <- t$cle[duplicated(t$cle)]
  if (length(dup)) stop("Clés en double dans ", path, " : ", paste(dup, collapse = ", "))
  .i18n$table <- lapply(stats::setNames(names(LANGUES), names(LANGUES)), function(l)
    if (l %in% names(t)) stats::setNames(t[[l]], t$cle) else character())
  invisible(t)
}

# Langue valide à partir d'un texte (« nl », « NL », NULL…)
langue_valide <- function(x) {
  x <- tolower(x %||% "")
  if (length(x) && x %in% names(LANGUES)) x else LANGUE_SOURCE
}

# Langue d'une requête HTTP (ui) ou d'une adresse (« ?lang=nl »)
langue_requete <- function(query_string) {
  langue_valide(shiny::parseQueryString(query_string %||% "")$lang)
}

# Langue courante : celle de la session Shiny si on est dans le serveur,
# sinon celle de l'interface en cours de construction
langue <- function() {
  s <- shiny::getDefaultReactiveDomain()
  l <- if (!is.null(s)) s$userData$lang else NULL
  l %||% .i18n$lang
}

# Construit l'interface dans une langue donnée
avec_langue <- function(lang, expr) {
  ancien <- .i18n$lang
  .i18n$lang <- lang
  on.exit(.i18n$lang <- ancien)
  force(expr)
}

# Le texte d'une clé dans la langue courante ; {nom} est remplacé par la
# valeur de l'argument nom
tr <- function(cle, ..., lang = langue()) {
  if (is.null(.i18n$table)) load_i18n()
  txt <- .i18n$table[[lang]][cle]
  if (is.null(txt) || is.na(txt) || !nzchar(txt)) txt <- .i18n$table[[LANGUE_SOURCE]][cle]
  if (is.null(txt) || is.na(txt)) {
    warning("Texte d'interface inconnu : ", cle)
    return(cle)
  }
  vals <- list(...)
  for (n in names(vals)) txt <- gsub(paste0("{", n, "}"), vals[[n]], txt, fixed = TRUE)
  unname(txt)
}

# Toutes les clés qui commencent par un préfixe, pour le navigateur
# (JavaScript, moteur Python) : liste nommée cle = texte
tr_prefixe <- function(prefixe, lang = langue()) {
  if (is.null(.i18n$table)) load_i18n()
  cles <- names(.i18n$table[[LANGUE_SOURCE]])
  cles <- cles[startsWith(cles, prefixe)]
  stats::setNames(lapply(cles, tr, lang = lang), cles)
}

# Le sélecteur de langue de la barre du haut : des liens « ?lang=xx »
langue_selecteur <- function(lang = langue()) {
  htmltools::div(
    class = "lang-select",
    lapply(names(LANGUES), function(l)
      htmltools::tags$a(href = paste0("?lang=", l), class = paste("lang-link", if (l == lang) "active"),
                        title = LANGUES[[l]], hreflang = l, `data-lang` = l, toupper(l))))
}
