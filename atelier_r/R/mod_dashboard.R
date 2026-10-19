# ============================================================================
# mod_dashboard.R — volet DASHBOARD : ce que R et Shiny permettent de faire
#
# Deux tableaux de bord interactifs, un par base. Chaque graphique a un bouton
# « Voir le code » : le code affiché est celui qui produit le graphique
# (voir dash_code.R). Objectif pédagogique : montrer qu'avec les verbes du
# cours, ggplot2 et quelques lignes de Shiny, on construit une application.
# ============================================================================

GEO_DEPARTEMENTS <- NULL
load_geo <- function() {
  GEO_DEPARTEMENTS <<- jsonlite::fromJSON("data/departements.geojson",
                                          simplifyVector = FALSE)
}

dash_card <- function(ns, id, titre, sous_titre = NULL, height = "340px") {
  bslib::card(
    full_screen = TRUE, class = "dash-card",
    bslib::card_header(
      div(class = "d-flex align-items-start gap-2",
          div(div(class = "fw-semibold", titre),
              if (!is.null(sous_titre)) div(class = "small text-muted", sous_titre)),
          actionButton(ns(paste0("code_", id)), tagList(icon("code"), "Voir le code"),
                       class = "btn-outline-secondary btn-xs ms-auto code-btn"))
    ),
    bslib::card_body(class = "p-1", plotly::plotlyOutput(ns(paste0("plot_", id)), height = height))
  )
}

code_modal <- function(titre, code, intro) {
  showModal(modalDialog(
    title = paste("Le code R derrière :", titre), size = "l", easyClose = TRUE,
    footer = modalButton("Fermer"),
    p(class = "text-muted", intro),
    code_block(code, copy = TRUE),
    div(class = "callout callout-note",
        HTML("<p>Pour rendre un graphique <code>ggplot2</code> interactif (survol, zoom), il suffit de le passer à <code>ggplotly()</code> du paquet <strong>plotly</strong>. Dans l'application Shiny, ce code est placé dans un <code>renderPlotly({ … })</code> : il est relancé automatiquement à chaque changement de filtre.</p>"))
  ))
}

fmt_num <- function(x, d = 0) formatC(x, format = "f", digits = d, big.mark = " ", decimal.mark = ",")

# =============================================================== MÉTÉO =========

mod_dash_meteo_ui <- function(id) {
  ns <- NS(id)
  villes <- sort(unique(BASES$meteo$data$name))
  bslib::layout_sidebar(
    fillable = FALSE,
    sidebar = bslib::sidebar(
      width = 280, title = "Filtres", open = "desktop",
      selectInput(ns("ville"), "Ville", choices = villes, selected = "Lille"),
      selectInput(ns("ville2"), "Comparer avec", choices = c("(aucune)" = "", villes),
                  selected = "Marseille / Marignane"),
      sliderInput(ns("annees"), "Années", min = 2010, max = 2026, value = c(2010, 2025),
                  step = 1, sep = ""),
      sliderInput(ns("coupure"), "Comparer avant / depuis", min = 2012, max = 2024,
                  value = 2017, step = 1, sep = ""),
      div(class = "small text-muted",
          icon("circle-info"), " 2026 s'arrête le 8 septembre : l'inclure gonfle les moyennes annuelles. ",
          "Cliquez sur une station de la carte pour la sélectionner.")
    ),
    uiOutput(ns("kpis")),
    bslib::layout_columns(
      col_widths = bslib::breakpoints(sm = 12, lg = c(7, 5)),
      dash_card(ns, "evolution", "Température moyenne annuelle",
                "Avec la tendance linéaire (pointillés)"),
      dash_card(ns, "carte", "Le réchauffement station par station",
                "Écart de température moyenne entre les deux périodes")
    ),
    dash_card(ns, "bandes", "Les bandes climatiques", "Une barre par année : bleu = plus froid que la moyenne, rouge = plus chaud", height = "160px"),
    bslib::layout_columns(
      col_widths = bslib::breakpoints(sm = 12, lg = c(6, 6)),
      dash_card(ns, "saisons", "Le climat mois par mois", "Température maximale moyenne, avant et depuis l'année de coupure"),
      dash_card(ns, "chauds", "Les jours chauds", "Nombre de jours à 30 °C ou plus, par année")
    ),
    dash_card(ns, "calendrier", "Le calendrier des écarts", "Chaque case : écart de la température maximale à la normale du mois", height = "460px")
  )
}

mod_dash_meteo_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    carte_ok <- reactiveVal(FALSE)   # la carte doit être dessinée avant d'écouter ses clics
    data_annees <- reactive({
      req(input$annees)
      BASES$meteo$data |>
        dplyr::filter(lubridate::year(date) >= input$annees[1],
                      lubridate::year(date) <= input$annees[2])
    })
    objets <- reactive(list(donnees = data_annees(), ville = input$ville,
                            ville2 = setdiff(input$ville2, input$ville),
                            annee_coupure = input$coupure))
    two_periods <- reactive(input$annees[1] < input$coupure && input$annees[2] >= input$coupure)

    output$kpis <- renderUI({
      d <- data_annees() |> dplyr::filter(name == input$ville)
      req(nrow(d) > 0)
      n_ans <- dplyr::n_distinct(lubridate::year(d$date))
      t_moy <- mean(d$temp, na.rm = TRUE)
      j30 <- sum(d$tmax >= 30, na.rm = TRUE) / n_ans
      gel <- sum(d$tmin < 0, na.rm = TRUE) / n_ans
      rec <- d[which.max(d$tmax), ]
      ecart <- if (two_periods()) {
        avant <- mean(d$temp[lubridate::year(d$date) < input$coupure], na.rm = TRUE)
        apres <- mean(d$temp[lubridate::year(d$date) >= input$coupure], na.rm = TRUE)
        sub(".", ",", sprintf("%+.1f °C depuis %d", apres - avant, input$coupure), fixed = TRUE)
      } else "choisissez une période qui encadre la coupure"
      bslib::layout_columns(
        col_widths = bslib::breakpoints(sm = 6, lg = 3), class = "kpi-row",
        bslib::value_box(title = "Température moyenne", value = paste(fmt_num(t_moy, 1), "°C"),
                         showcase = icon("temperature-half"), p(ecart), theme = "primary"),
        bslib::value_box(title = "Jours à 30 °C ou plus", value = paste(fmt_num(j30, 1), "/ an"),
                         showcase = icon("sun"), p(sprintf("%s – %s", input$annees[1], input$annees[2]))),
        bslib::value_box(title = "Jours de gel", value = paste(fmt_num(gel, 1), "/ an"),
                         showcase = icon("snowflake"), p("température minimale < 0 °C")),
        bslib::value_box(title = "Record de chaleur", value = paste(fmt_num(rec$tmax, 1), "°C"),
                         showcase = icon("fire"), p(format(rec$date, "%d/%m/%Y")))
      )
    })

    render_chart <- function(name, need_two = FALSE) {
      output[[paste0("plot_", name)]] <- plotly::renderPlotly({
        if (need_two) validate(need(two_periods(),
                                    "Choisissez des années qui encadrent l'année de coupure."))
        p <- run_dash_code(DASH_CODE$meteo[[name]], objets())
        p$x$source <- paste0("meteo_", name)
        if (name == "carte") {
          p <- plotly::event_register(p, "plotly_click")
          session$onFlushed(function() isolate(carte_ok(TRUE)))
        }
        p
      })
      observeEvent(input[[paste0("code_", name)]], {
        code_modal(name, DASH_CODE$meteo[[name]],
                   "Ce code utilise les objets donnees (BDD_METEO filtrée sur les années choisies), ville, ville2 et annee_coupure, qui viennent des filtres de gauche.")
      })
    }
    render_chart("evolution"); render_chart("bandes"); render_chart("saisons", TRUE)
    render_chart("chauds"); render_chart("calendrier"); render_chart("carte", TRUE)

    # clic sur une station de la carte -> elle devient la ville choisie
    clic_carte <- reactive({
      req(carte_ok())
      plotly::event_data("plotly_click", source = "meteo_carte", priority = "event")
    })
    observeEvent(clic_carte(), {
      v <- clic_carte()$customdata
      if (!is.null(v) && length(v) && v %in% BASES$meteo$data$name)
        updateSelectInput(session, "ville", selected = v)
    }, ignoreNULL = TRUE)
  })
}

# ========================================================== NAISSANCES =========

INDICATEURS_NAIS <- c("Âge moyen de la mère" = "age_mere",
                      "Part des naissances hors mariage (%)" = "hors_mariage",
                      "Part des mères étrangères (%)" = "mere_etrangere",
                      "Part des naissances multiples (%)" = "multiples",
                      "Nombre de naissances" = "naissances")

mod_dash_nais_ui <- function(id) {
  ns <- NS(id)
  dep <- DEPARTEMENTS
  regions <- sort(unique(dep$region))
  choix <- list(
    "Ensemble" = c("France entière" = "FR"),
    "Régions" = stats::setNames(paste0("R:", regions), regions),
    "Départements" = stats::setNames(paste0("D:", dep$code), paste(dep$code, "-", dep$nom))
  )
  bslib::layout_sidebar(
    fillable = FALSE,
    sidebar = bslib::sidebar(
      width = 280, title = "Filtres", open = "desktop",
      selectInput(ns("territoire"), "Territoire", choices = choix, selected = "FR"),
      selectInput(ns("indicateur"), "Indicateur de la carte", choices = INDICATEURS_NAIS,
                  selected = "hors_mariage"),
      div(class = "small text-muted",
          icon("circle-info"), " Le territoire est celui du lieu de naissance (DEPNAIS). ",
          "Cliquez sur un département de la carte pour le sélectionner.")
    ),
    uiOutput(ns("kpis")),
    bslib::layout_columns(
      col_widths = bslib::breakpoints(sm = 12, lg = c(5, 7)),
      dash_card(ns, "carte", "La carte des départements",
                "France métropolitaine, indicateur choisi à gauche", height = "420px"),
      dash_card(ns, "pyramide", "L'âge des parents à la naissance",
                "Âge exact, pères à gauche et mères à droite", height = "420px")
    ),
    bslib::layout_columns(
      col_widths = bslib::breakpoints(sm = 12, lg = c(6, 6)),
      dash_card(ns, "mois", "La saisonnalité des naissances", "Naissances par jour, selon le mois"),
      dash_card(ns, "mariage", "Les naissances hors mariage", "Selon l'âge et la nationalité de la mère")
    ),
    bslib::layout_columns(
      col_widths = bslib::breakpoints(sm = 12, lg = c(6, 6)),
      dash_card(ns, "couples", "Qui a des enfants avec qui ?", "Âge de la mère × âge du père (échelle logarithmique)", height = "400px"),
      dash_card(ns, "noms", "Le nom de famille de l'enfant", "Selon que les parents sont mariés ou non", height = "400px")
    )
  )
}

mod_dash_nais_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    carte_ok <- reactiveVal(FALSE)   # la carte doit être dessinée avant d'écouter ses clics
    donnees <- reactive({
      t <- input$territoire; req(t)
      B <- BASES$naissances$data
      if (identical(t, "FR")) return(B)
      if (startsWith(t, "R:")) {
        codes <- DEPARTEMENTS$code[DEPARTEMENTS$region == sub("^R:", "", t)]
        return(B[B$DEPNAIS %in% codes, ])
      }
      B[B$DEPNAIS == sub("^D:", "", t), ]
    })
    libelle <- reactive({
      t <- input$territoire
      if (identical(t, "FR")) return("France entière")
      if (startsWith(t, "R:")) return(sub("^R:", "", t))
      d <- DEPARTEMENTS[DEPARTEMENTS$code == sub("^D:", "", t), ]
      paste(d$code, "-", d$nom)
    })
    objets <- reactive(list(donnees = donnees(), BDD_NAIS = BASES$naissances$data,
                            departements = GEO_DEPARTEMENTS,
                            indicateur = input$indicateur))

    output$kpis <- renderUI({
      d <- donnees(); req(nrow(d) > 0)
      bslib::layout_columns(
        col_widths = bslib::breakpoints(sm = 6, lg = 3), class = "kpi-row",
        bslib::value_box(title = "Naissances en 2021", value = fmt_num(nrow(d)),
                         showcase = icon("baby"), p(libelle()), theme = "primary"),
        bslib::value_box(title = "Âge moyen de la mère", value = paste(fmt_num(mean(d$AGEXACTM), 1), "ans"),
                         showcase = icon("person-pregnant"),
                         p(sprintf("père : %s ans", fmt_num(mean(d$AGEXACTP), 1)))),
        bslib::value_box(title = "Naissances hors mariage", value = paste(fmt_num(100 * mean(d$AMAR == "0000"), 1), "%"),
                         showcase = icon("ring"), p("parents non mariés à la naissance")),
        bslib::value_box(title = "Naissances multiples", value = paste(fmt_num(100 * mean(d$NBENF >= 2), 1), "%"),
                         showcase = icon("children"), p("enfants nés de jumeaux ou plus"))
      )
    })

    render_chart <- function(name) {
      output[[paste0("plot_", name)]] <- plotly::renderPlotly({
        p <- run_dash_code(DASH_CODE$naissances[[name]], objets())
        p$x$source <- paste0("nais_", name)
        if (name == "carte") {
          p <- plotly::event_register(p, "plotly_click")
          session$onFlushed(function() isolate(carte_ok(TRUE)))
        }
        p
      })
      observeEvent(input[[paste0("code_", name)]], {
        code_modal(name, DASH_CODE$naissances[[name]],
                   "Ce code utilise les objets donnees (BDD_NAIS filtrée sur le territoire choisi), BDD_NAIS, departements (les contours de la carte) et indicateur, qui viennent des filtres de gauche.")
      })
    }
    for (nm in names(DASH_CODE$naissances)) render_chart(nm)

    clic_carte <- reactive({
      req(carte_ok())
      plotly::event_data("plotly_click", source = "nais_carte", priority = "event")
    })
    observeEvent(clic_carte(), {
      ev <- clic_carte()
      code <- ev$location %||% ev$customdata
      if (!is.null(code) && length(code) && code %in% DEPARTEMENTS$code)
        updateSelectInput(session, "territoire", selected = paste0("D:", code))
    }, ignoreNULL = TRUE)
  })
}

# Onglet : un tableau de bord par base
mod_dashboard_ui <- function(id) {
  ns <- NS(id)
  bslib::nav_panel(
    title = tagList(icon("chart-line"), "Dashboard"), value = "dashboard",
    div(class = "dash-intro",
        uiOutput(ns("intro"))),
    conditionalPanel("input.base == 'meteo'", mod_dash_meteo_ui(ns("meteo"))),
    conditionalPanel("input.base == 'naissances'", mod_dash_nais_ui(ns("nais")))
  )
}

mod_dashboard_server <- function(id, base) {
  moduleServer(id, function(input, output, session) {
    output$intro <- renderUI({
      div(class = "lesson-head",
          div(class = "lesson-kicker", paste("Dashboard ·", BASES[[base()]]$objet)),
          h2(if (base() == "meteo") "Le climat de 13 villes françaises, 2010-2026"
             else "Les naissances en France en 2021"),
          p(class = "lead-sub",
            "Ce tableau de bord est écrit en R, avec les outils du cours : les verbes du tidyverse pour préparer les données, ggplot2 pour les graphiques, plotly pour l'interactivité et Shiny pour l'application. Cliquez sur « Voir le code » sous chaque titre."))
    })
    mod_dash_meteo_server("meteo")
    mod_dash_nais_server("nais")
  })
}
