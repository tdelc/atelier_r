# ============================================================================
# Atelier R — apprendre l'analyse de bases de données avec R
#
#   Cours       : les leçons, carte par carte (bases/<base>/cours/)
#   Découverte  : modifier le code et tester, dans un bac à sable sécurisé
#   Exercices   : questions graduées, vérification automatique, corrections
#   Dashboard   : ce qu'on peut construire avec R et Shiny
#
# Les tableaux gt s'affichent dans un « Viewer », comme dans RStudio
# (R/viewer.R).
#
# Lancement : shiny::runApp() depuis ce dossier.
# Les fichiers du dossier R/ sont chargés automatiquement par Shiny.
# Les bases sont dans bases/ : un dossier par base, décrit par un fichier
# base.txt, avec son contenu pédagogique (markdown). Ajouter une base = ajouter
# un dossier, sans toucher au code (voir docs/GUIDE_CONTENUS.md).
# ============================================================================

suppressPackageStartupMessages({
  library(shiny)
  library(bslib)
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(lubridate)
  library(stringr)
  library(forcats)
  library(plotly)
  library(shinyAce)
  library(gt)
  library(eurostat)
})

options(shiny.maxRequestSize = 1e6)

# --- Chargement unique, partagé par toutes les sessions -------------------------
sandbox_init()
load_bases()
load_dashboards()
load_cours()
load_pistes()
load_exercices()

# --- Interface -------------------------------------------------------------------
ui <- atelier_page_navbar(
  title = span(class = "brand", icon("r-project"), "Atelier R"),
  window_title = "Atelier R",
  id = "onglets",
  theme = atelier_theme(),
  header = tagList(
    tags$head(
      tags$link(rel = "stylesheet", href = "atelier.css"),
      tags$script(src = "atelier.js"),
      tags$meta(name = "description",
                content = "Apprendre l'analyse de bases de données avec R : cours, découverte, exercices et dashboard.")
    ),
    tour_assets()
  ),
  mod_accueil_ui("accueil"),
  mod_cours_ui("cours"),
  mod_decouverte_ui("decouverte"),
  mod_exercices_ui("exercices"),
  mod_dashboard_ui("dashboard"),
  bslib::nav_spacer(),
  bslib::nav_item(
    base_selector("base")
  ),
  bslib::nav_item(actionButton("btn_dico", tagList(icon("table-list"), "Dictionnaire"),
                               class = "btn-sm btn-nav")),
  bslib::nav_item(actionButton("btn_tour", tagList(icon("compass"), "Visite"),
                               class = "btn-sm btn-nav"))
)

# --- Serveur ---------------------------------------------------------------------
server <- function(input, output, session) {
  base <- reactive({
    b <- input$base
    if (is.null(b) || !b %in% names(BASES)) names(BASES)[1] else b
  })

  # Canal entre modules (ex. « Modifier ce code dans Découverte »)
  bus <- reactiveValues(decouverte = NULL)

  tour_from_home <- mod_accueil_server("accueil", session)
  mod_cours_server("cours", base, bus, session)
  mod_decouverte_server("decouverte", base, bus, session)
  mod_exercices_server("exercices", base, session)
  mod_dashboard_server("dashboard", base)

  observeEvent(input$btn_dico, showModal(dico_modal(base())))

  tour_start <- reactiveVal(0)
  observeEvent(input$btn_tour, tour_start(tour_start() + 1))
  observeEvent(tour_from_home(), tour_start(tour_start() + 1), ignoreInit = TRUE)
  mod_tour_server(reactive(req(tour_start() > 0) && tour_start()), base, session)
}

shinyApp(ui, server)
