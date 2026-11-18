# ============================================================================
# dashboard.R — le tableau de bord de la base MÉTÉO
#
# Ce fichier est chargé au démarrage (voir load_dashboards() dans R/data.R),
# dans un environnement propre à la base. Il doit définir :
#   dashboard_ui(id)      l'interface
#   dashboard_server(id)  la logique serveur
# BASE désigne la description de la base : BASE$data = BDD_METEO.
#
# Le code de chaque graphique est écrit sous forme de texte (DASH_CODE) : il
# est EXÉCUTÉ pour produire le graphique ET AFFICHÉ tel quel quand l'étudiant
# clique sur « Voir le code ». Ce qu'il lit est donc exactement ce qui tourne.
#
# Objets disponibles dans ce code : donnees (BDD_METEO filtrée sur les années
# choisies), ville, ville2 (comparaison, "" si aucune), annee_coupure
# ============================================================================

DASH_CODE <- list()

DASH_CODE$bandes <- r"--(# Les « bandes climatiques » : une barre par année, colorée selon l'écart
# à la moyenne de la période (bleu = plus froid, rouge = plus chaud)
bandes <- donnees |>
  filter(name == ville) |>
  group_by(annee = year(date)) |>
  summarise(temp_moy = mean(temp, na.rm = TRUE)) |>
  mutate(ecart = temp_moy - mean(temp_moy))

g <- ggplot(bandes, aes(x = annee, y = 1, fill = ecart,
                        text = paste0(annee, " : ", round(temp_moy, 1), " °C (",
                                      sprintf("%+.1f", ecart), " °C)"))) +
  geom_tile() +
  scale_fill_gradient2(low = "#2166ac", mid = "white", high = "#b2182b") +
  scale_x_continuous(breaks = seq(2010, 2026, 2)) +
  labs(x = NULL, y = NULL, fill = "Écart (°C)") +
  theme_minimal() +
  theme(axis.text.y = element_blank(), panel.grid = element_blank())

ggplotly(g, tooltip = "text") |> hide_colorbar())--"

DASH_CODE$evolution <- r"--(evolution <- donnees |>
  filter(name %in% c(ville, ville2)) |>
  group_by(name, annee = year(date)) |>
  summarise(temp_moy = mean(temp, na.rm = TRUE), .groups = "drop")

g <- ggplot(evolution, aes(x = annee, y = temp_moy, colour = name)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  geom_smooth(method = "lm", formula = y ~ x, se = FALSE,
              linetype = "dashed", linewidth = 0.6) +
  scale_colour_manual(values = c("#1f3a5f", "#d9822b")) +
  labs(x = NULL, y = "Température moyenne (°C)", colour = NULL) +
  theme_minimal()

ggplotly(g) |> layout(legend = list(orientation = "h", y = -0.15)))--"

DASH_CODE$saisons <- r"--(# Le climat moyen mois par mois, avant et après l'année de coupure
climat <- donnees |>
  filter(name == ville) |>
  mutate(mois = month(date),
         periode = if_else(year(date) < annee_coupure,
                           paste("Avant", annee_coupure),
                           paste("Depuis", annee_coupure))) |>
  group_by(periode, mois) |>
  summarise(tmax_moy = mean(tmax, na.rm = TRUE), .groups = "drop")

g <- ggplot(climat, aes(x = mois, y = tmax_moy, colour = periode)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  scale_x_continuous(breaks = 1:12,
                     labels = c("Jan", "Fév", "Mar", "Avr", "Mai", "Juin",
                                "Juil", "Août", "Sep", "Oct", "Nov", "Déc")) +
  scale_colour_manual(values = c("#3b6ea5", "#d9822b")) +
  labs(x = NULL, y = "Température maximale moyenne (°C)", colour = NULL) +
  theme_minimal()

ggplotly(g) |> layout(legend = list(orientation = "h", y = -0.15)))--"

DASH_CODE$calendrier <- r"--(# Chaque case = un mois d'une année, colorée selon l'écart à la normale
# de ce mois (la moyenne de ce mois sur toute la période)
calendrier <- donnees |>
  filter(name == ville) |>
  mutate(annee = year(date), mois = month(date)) |>
  group_by(mois) |>
  mutate(normale = mean(tmax, na.rm = TRUE)) |>
  group_by(annee, mois) |>
  summarise(ecart = mean(tmax - normale, na.rm = TRUE), .groups = "drop")

g <- ggplot(calendrier, aes(x = mois, y = annee, fill = ecart,
                            text = paste0(mois, "/", annee, " : ",
                                          sprintf("%+.1f", ecart), " °C"))) +
  geom_tile(colour = "white") +
  scale_fill_gradient2(low = "#2166ac", mid = "#f7f7f7", high = "#b2182b") +
  scale_x_continuous(breaks = 1:12,
                     labels = c("J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D")) +
  scale_y_reverse(breaks = 2010:2026) +
  labs(x = NULL, y = NULL, fill = "Écart (°C)") +
  theme_minimal() +
  theme(panel.grid = element_blank())

ggplotly(g, tooltip = "text"))--"

DASH_CODE$chauds <- r"--(chauds <- donnees |>
  filter(name %in% c(ville, ville2)) |>
  group_by(name, annee = year(date)) |>
  summarise(jours_30 = sum(tmax >= 30, na.rm = TRUE), .groups = "drop")

g <- ggplot(chauds, aes(x = annee, y = jours_30, fill = name)) +
  geom_col(position = "dodge") +
  scale_fill_manual(values = c("#1f3a5f", "#d9822b")) +
  labs(x = NULL, y = "Jours à 30 °C ou plus", fill = NULL) +
  theme_minimal()

ggplotly(g) |> layout(legend = list(orientation = "h", y = -0.15)))--"

DASH_CODE$carte <- r"--(# Le réchauffement de chaque station : température moyenne depuis
# l'année de coupure, moins température moyenne avant
stations <- donnees |>
  mutate(periode = if_else(year(date) < annee_coupure, "avant", "apres")) |>
  group_by(name, latitude, longitude, periode) |>
  summarise(temp = mean(temp, na.rm = TRUE), .groups = "drop") |>
  pivot_wider(names_from = periode, values_from = temp) |>
  mutate(rechauffement = apres - avant)

plot_ly(stations, type = "scattergeo", mode = "markers+text",
        lat = ~latitude, lon = ~longitude, text = ~name,
        textposition = "top center", customdata = ~name,
        hovertemplate = "%{text}<br>%{marker.color:+.2f} °C<extra></extra>",
        marker = list(size = 18, color = ~rechauffement,
                      colorscale = "YlOrRd", reversescale = TRUE, showscale = TRUE,
                      line = list(color = "#1f3a5f", width = 1),
                      colorbar = list(title = "°C"))) |>
  layout(geo = list(resolution = 50, showland = TRUE, landcolor = "#f4f2ec",
                    showcountries = TRUE, countrycolor = "#c9c4b8",
                    showocean = TRUE, oceancolor = "#eaf1f8",
                    lataxis = list(range = c(41.2, 52)),
                    lonaxis = list(range = c(-5.5, 10.5))),
         margin = list(l = 0, r = 0, t = 0, b = 0)))--"

# ---------------------------------------------------------------- Interface ---

dashboard_ui <- function(id) {
  ns <- NS(id)
  villes <- sort(unique(BASE$data$name))
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

dashboard_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    carte_ok <- reactiveVal(FALSE)   # la carte doit être dessinée avant d'écouter ses clics
    data_annees <- reactive({
      req(input$annees)
      BASE$data |>
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
        p <- run_dash_code(DASH_CODE[[name]], objets())
        p$x$source <- paste0("meteo_", name)
        if (name == "carte") {
          p <- plotly::event_register(p, "plotly_click")
          session$onFlushed(function() isolate(carte_ok(TRUE)))
        }
        p
      })
      observeEvent(input[[paste0("code_", name)]], {
        code_modal(name, DASH_CODE[[name]],
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
      if (!is.null(v) && length(v) && v %in% BASE$data$name)
        updateSelectInput(session, "ville", selected = v)
    }, ignoreNULL = TRUE)
  })
}
