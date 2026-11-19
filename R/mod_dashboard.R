# ============================================================================
# mod_dashboard.R — volet DASHBOARD : ce que R et Shiny permettent de faire
#
# Un tableau de bord interactif par base (fichier bases/<base>/dashboard.R,
# facultatif, chargé par load_dashboards() dans R/data.R). Chaque graphique a
# un bouton « Voir le code » : le code affiché est celui qui produit le
# graphique. Ce fichier contient les outils communs à tous les tableaux de
# bord (dash_card, code_modal, run_dash_code). Objectif pédagogique : montrer qu'avec les verbes du
# cours, ggplot2 et quelques lignes de Shiny, on construit une application.
# ============================================================================

dash_card <- function(ns, id, titre, sous_titre = NULL, height = "340px") {
  bslib::card(
    full_screen = TRUE, class = "dash-card",
    bslib::card_header(
      div(class = "d-flex align-items-start gap-2",
          div(div(class = "fw-semibold", titre),
              if (!is.null(sous_titre)) div(class = "small text-muted", sous_titre)),
          actionButton(ns(paste0("code_", id)), tagList(icon("code"), tr("dash.voir_code")),
                       class = "btn-outline-secondary btn-xs ms-auto code-btn"))
    ),
    bslib::card_body(class = "p-1", plotly::plotlyOutput(ns(paste0("plot_", id)), height = height))
  )
}

code_modal <- function(titre, code, intro = NULL) {
  showModal(modalDialog(
    title = tr("dash.code_titre", titre = titre), size = "l", easyClose = TRUE,
    footer = modalButton(tr("commun.fermer")),
    if (!is.null(intro)) p(class = "text-muted", intro),
    code_block(code, copy = TRUE),
    div(class = "callout callout-note",
        HTML(tr("dash.code_note")))
  ))
}

fmt_num <- function(x, d = 0) formatC(x, format = "f", digits = d, big.mark = " ", decimal.mark = ",")

# Exécute un code de graphique dans un environnement contenant `objets`
run_dash_code <- function(code, objets) {
  env <- list2env(objets, parent = globalenv())
  p <- eval(parse(text = code, keep.source = FALSE), envir = env)
  plotly::config(p, displaylogo = FALSE, topojsonURL = "topojson/",
                 modeBarButtonsToRemove = c("lasso2d", "select2d", "autoScale2d")) |>
    plotly::layout(separators = ", ", font = list(family = "system-ui, sans-serif"))
}

# Onglet : un tableau de bord par base
mod_dashboard_ui <- function(id) {
  ns <- NS(id)
  bslib::nav_panel(
    title = tagList(icon("chart-line"), tr("onglet.dashboard")), value = "dashboard",
    div(class = "dash-intro",
        uiOutput(ns("intro"))),
    lapply(names(BASES), function(b) {
      D <- BASES[[b]]$dash_env
      if (is.null(D)) return(NULL)
      conditionalPanel(sprintf("input.base == '%s'", b), D$dashboard_ui(ns(b)))
    })
  )
}

mod_dashboard_server <- function(id, base) {
  moduleServer(id, function(input, output, session) {
    output$intro <- renderUI({
      B <- info(base())
      if (is.null(B$dash_env))
        return(aucun_contenu(tr("dash.vide_titre"),
                             tr("dash.vide_texte", fichier = base_path(base(), "dashboard.R"))))
      div(class = "lesson-head",
          div(class = "lesson-kicker", paste(tr("onglet.dashboard"), "·", B$objet)),
          h2(B$dashboard_titre),
          p(class = "lead-sub", tr("dash.intro")))
    })
    for (b in names(BASES))
      if (!is.null(BASES[[b]]$dash_env)) BASES[[b]]$dash_env$dashboard_server(b)
  })
}
