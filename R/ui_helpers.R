# ============================================================================
# ui_helpers.R — éléments d'interface partagés
# ============================================================================

# page_navbar() compatible avec les versions anciennes (< 0.9) et récentes de
# bslib (navbar_options() remplace les arguments bg / inverse)
atelier_page_navbar <- function(..., title, id, theme, header, window_title) {
  args <- list(..., title = title, id = id, theme = theme, header = header,
               window_title = window_title, fillable = FALSE, lang = "fr")
  if (utils::packageVersion("bslib") >= "0.9.0") {
    args$navbar_options <- bslib::navbar_options(bg = "#1f3a5f", theme = "dark",
                                                 underline = TRUE)
  } else {
    args$bg <- "#1f3a5f"
    args$inverse <- TRUE
  }
  do.call(bslib::page_navbar, args)
}

atelier_theme <- function() {
  bslib::bs_theme(
    version = 5,
    bg = "#fbfaf7",
    fg = "#1d2433",
    primary = "#1f3a5f",
    secondary = "#5d6b7e",
    success = "#3f7d4f",
    info = "#3b6ea5",
    warning = "#d9822b",
    danger = "#b5443b",
    base_font = bslib::font_collection("-apple-system", "BlinkMacSystemFont",
                                       "Segoe UI", "Roboto", "Helvetica Neue",
                                       "Arial", "sans-serif"),
    heading_font = bslib::font_collection("Charter", "Bitstream Charter",
                                          "Sitka Text", "Cambria", "Georgia",
                                          "serif"),
    code_font = bslib::font_collection("JetBrains Mono", "Cascadia Code",
                                       "Fira Code", "Consolas", "Menlo",
                                       "monospace"),
    "border-radius" = "0.5rem",
    "card-border-color" = "#e4e1d8",
    "card-cap-bg" = "#f4f2ec"
  )
}

# Bouton qui envoie le contenu de l'éditeur AVEC le clic (évite le décalage
# entre la frappe et l'envoi de la valeur). Côté serveur : input[[id]]$code.
ace_button <- function(id, editor_id, label, class = "btn-primary btn-sm") {
  tags$button(type = "button", id = id, class = paste("btn ace-send", class),
              `data-editor` = editor_id, `data-input` = id, label)
}

# Liste de boutons de navigation latérale (leçons, pistes, exercices)
# items : data.frame(id, label, sub, group, status)
side_list <- function(input_id, items, active = NULL) {
  groups <- unique(items$group)
  htmltools::div(
    class = "side-list",
    lapply(groups, function(g) {
      it <- items[items$group == g, , drop = FALSE]
      htmltools::tagList(
        if (nzchar(g)) htmltools::div(class = "side-group", g),
        lapply(seq_len(nrow(it)), function(i) {
          htmltools::tags$button(
            type = "button",
            class = paste("side-item", if (identical(it$id[i], active)) "active",
                          if ("status" %in% names(it)) paste0("st-", it$status[i])),
            onclick = sprintf("Shiny.setInputValue('%s', '%s', {priority: 'event'})",
                              input_id, it$id[i]),
            htmltools::span(class = "side-num", it$num[i]),
            htmltools::span(class = "side-txt",
                            htmltools::span(class = "side-label", it$label[i]),
                            if (nzchar(it$sub[i] %||% ""))
                              htmltools::span(class = "side-sub", it$sub[i]))
          )
        })
      )
    })
  )
}

# Fenêtre « Dictionnaire des variables »
dico_modal <- function(base) {
  d <- BASES[[base]]$dico
  shiny::modalDialog(
    title = paste("Dictionnaire des variables —", BASES[[base]]$objet),
    size = "l", easyClose = TRUE, footer = shiny::modalButton("Fermer"),
    htmltools::p(class = "text-muted",
                 sprintf("%s. Source : %s. Une ligne = %s.",
                         BASES[[base]]$titre, BASES[[base]]$source,
                         BASES[[base]]$ligne)),
    htmltools::tags$table(
      class = "table table-sm dico-table",
      htmltools::tags$thead(htmltools::tags$tr(
        htmltools::tags$th("Variable"), htmltools::tags$th("Contenu"),
        htmltools::tags$th("Type"), htmltools::tags$th("Modalités / unité"))),
      htmltools::tags$tbody(lapply(seq_len(nrow(d)), function(i) {
        htmltools::tags$tr(
          htmltools::tags$td(htmltools::tags$code(d$variable[i])),
          htmltools::tags$td(d$libelle[i]),
          htmltools::tags$td(class = "text-muted", d$type[i]),
          htmltools::tags$td(d$modalites[i]))
      }))
    )
  )
}

# Fenêtre « Fonctions autorisées »
fonctions_modal <- function() {
  groupes <- list(
    "Verbes du tidyverse" = c(SANDBOX_ALLOWED$dplyr, SANDBOX_ALLOWED$tidyr),
    "Jointures" = names(SANDBOX_WRAPPERS),
    "Boucles et fonctions" = c("for", "function", "return", "break", "next"),
    "Dates (lubridate)" = SANDBOX_ALLOWED$lubridate,
    "Texte et facteurs" = c(SANDBOX_ALLOWED$stringr, SANDBOX_ALLOWED$forcats),
    "R base et statistiques" = setdiff(c(SANDBOX_ALLOWED$base, SANDBOX_ALLOWED$stats,
                                         SANDBOX_ALLOWED$utils),
                                       c("(", "{", "<-", "=", "if", "[", "[[", "$",
                                         "for", "function", "return", "break", "next")),
    "Graphiques de base" = SANDBOX_ALLOWED$graphics,
    "ggplot2" = c("ggplot", "aes", "geom_*", "stat_*", "scale_*", "labs",
                  "theme_*", "facet_wrap", "facet_grid", "coord_*", "..."),
    "Échelles (scales)" = SANDBOX_ALLOWED$scales,
    "Tableaux (gt, affichés dans le Viewer)" = SANDBOX_ALLOWED$gt
  )
  shiny::modalDialog(
    title = "Les fonctions disponibles dans l'atelier",
    size = "l", easyClose = TRUE, footer = shiny::modalButton("Fermer"),
    htmltools::p("Pour des raisons de sécurité, le code est exécuté sur le serveur dans un espace protégé : seules les fonctions ci-dessous sont autorisées. Elles couvrent tout le cours. Les bases sont déjà chargées : pas besoin de ", htmltools::tags$code("library()"), " ni de ", htmltools::tags$code("read_csv()"), "."),
    lapply(names(groupes), function(g) {
      htmltools::tagList(
        htmltools::h6(class = "mt-3", g),
        htmltools::div(class = "fn-list",
                       lapply(sort(unique(groupes[[g]])), function(f) htmltools::tags$code(f)))
      )
    }),
    htmltools::div(class = "callout callout-piege mt-3",
                   htmltools::HTML("<p>Non disponibles ici : lire ou écrire des fichiers, <code>library()</code>, <code>::</code>, les boucles <code>while</code> et <code>repeat</code>, les fonctions récursives, <code>&lt;&lt;-</code>. La base de droite d\'une jointure doit avoir une seule ligne par clé. Le calcul est interrompu au-delà de 15 secondes.</p>"))
  )
}

# Petit en-tête de page (titre + sous-titre)
page_head <- function(titre, sous_titre = NULL, ...) {
  htmltools::div(class = "page-head",
                 htmltools::div(htmltools::h2(titre),
                                if (!is.null(sous_titre)) htmltools::p(class = "lead-sub", sous_titre)),
                 htmltools::div(class = "page-head-tools", ...))
}

# Tableau des objets d'un environnement de travail
env_objects_ui <- function(env) {
  nms <- sort(ls(env))
  if (!length(nms)) return(htmltools::p(class = "text-muted small", "Aucun objet."))
  htmltools::tags$table(
    class = "table table-sm env-table",
    htmltools::tags$tbody(lapply(nms, function(n) {
      obj <- get(n, envir = env)
      desc <- if (is.data.frame(obj)) {
        sprintf("tableau : %s × %s", format(nrow(obj), big.mark = " "), ncol(obj))
      } else if (inherits(obj, "ggplot")) {
        "graphique ggplot"
      } else if (is.atomic(obj)) {
        sprintf("%s [%s]", class(obj)[1], format(length(obj), big.mark = " "))
      } else class(obj)[1]
      htmltools::tags$tr(htmltools::tags$td(htmltools::tags$code(n)),
                         htmltools::tags$td(class = "text-muted", desc))
    }))
  )
}
