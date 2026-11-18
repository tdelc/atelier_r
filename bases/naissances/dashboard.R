# ============================================================================
# dashboard.R — le tableau de bord de la base NAISSANCES
#
# Ce fichier est chargé au démarrage (voir load_dashboards() dans R/data.R),
# dans un environnement propre à la base. Il doit définir :
#   dashboard_ui(id)      l'interface
#   dashboard_server(id)  la logique serveur
# BASE désigne la description de la base : BASE$data = BDD_NAIS.
#
# Le code de chaque graphique est écrit sous forme de texte (DASH_CODE) : il
# est EXÉCUTÉ pour produire le graphique ET AFFICHÉ tel quel quand l'étudiant
# clique sur « Voir le code ». Ce qu'il lit est donc exactement ce qui tourne.
#
# Objets disponibles dans ce code : donnees (BDD_NAIS filtrée sur le
# territoire), BDD_NAIS, departements (contours GeoJSON), indicateur
# ============================================================================

# Tables utilisées par ce tableau de bord (dans data/, partagées)
DEPARTEMENTS <- utils::read.csv("data/departements.csv", colClasses = "character",
                                encoding = "UTF-8", fileEncoding = "UTF-8")
GEO_DEPARTEMENTS <- jsonlite::fromJSON("data/departements.geojson", simplifyVector = FALSE)

DASH_CODE <- list()

DASH_CODE$carte <- r"--(# Un indicateur par département, sur une carte de France
# (departements = contours des départements au format GeoJSON)
par_dep <- BDD_NAIS |>
  group_by(DEPNAIS) |>
  summarise(naissances     = n(),
            age_mere       = mean(AGEMERE),
            hors_mariage   = 100 * mean(AMAR == "0000"),
            mere_etrangere = 100 * mean(INDNATM == 2),
            multiples      = 100 * mean(NBENF >= 2))

plot_ly(par_dep, type = "choropleth",
        geojson = departements, featureidkey = "properties.code",
        locations = ~DEPNAIS, z = par_dep[[indicateur]],
        customdata = ~DEPNAIS, colorscale = "Blues", reversescale = TRUE,
        marker = list(line = list(color = "white", width = 0.5)),
        hovertemplate = "Département %{location}<br>%{z:.1f}<extra></extra>") |>
  layout(geo = list(fitbounds = "locations", visible = FALSE),
         margin = list(l = 0, r = 0, t = 0, b = 0)))--"

DASH_CODE$mois <- r"--(# Naissances par jour selon le mois : on divise par le nombre de jours,
# sinon février (28 jours) paraîtrait artificiellement creux
par_mois <- donnees |>
  count(MNAIS) |>
  mutate(jours = days_in_month(as.Date(paste0("2021-", MNAIS, "-01"))),
         par_jour = n / jours)

g <- ggplot(par_mois, aes(x = MNAIS, y = par_jour,
                          text = paste0(format(round(par_jour), big.mark = " "),
                                        " naissances par jour"))) +
  geom_col(fill = "#3b6ea5") +
  geom_hline(yintercept = mean(par_mois$par_jour), linetype = "dashed") +
  labs(x = "Mois de naissance", y = "Naissances par jour") +
  theme_minimal()

ggplotly(g, tooltip = "text"))--"

DASH_CODE$pyramide <- r"--(# Âge exact des parents à la naissance, mères à droite, pères à gauche
pyramide <- donnees |>
  select(Mère = AGEXACTM, Père = AGEXACTP) |>
  pivot_longer(everything(), names_to = "parent", values_to = "age") |>
  count(parent, age) |>
  mutate(effectif = if_else(parent == "Père", -n, n))

g <- ggplot(pyramide, aes(x = age, y = effectif, fill = parent,
                          text = paste0(parent, ", ", age, " ans : ",
                                        format(n, big.mark = " ")))) +
  geom_col(width = 0.9) +
  coord_flip() +
  scale_y_continuous(labels = function(x) format(abs(x), big.mark = " ")) +
  scale_fill_manual(values = c("Mère" = "#d9822b", "Père" = "#1f3a5f")) +
  labs(x = "Âge (17 = 17 ans ou moins, 46 = 46 ans ou plus)", y = NULL, fill = NULL) +
  theme_minimal()

ggplotly(g, tooltip = "text"))--"

DASH_CODE$mariage <- r"--(hors_mariage <- donnees |>
  mutate(nationalite = if_else(INDNATM == 1, "Mère française", "Mère étrangère")) |>
  group_by(nationalite, AGEMERE) |>
  summarise(part = mean(AMAR == "0000"), n = n(), .groups = "drop") |>
  filter(n >= 30)   # on écarte les âges trop peu représentés

g <- ggplot(hors_mariage, aes(x = AGEMERE, y = part, colour = nationalite)) +
  geom_line(linewidth = 1) +
  scale_y_continuous(labels = scales::percent, limits = c(0, 1)) +
  scale_colour_manual(values = c("#d9822b", "#1f3a5f")) +
  labs(x = "Âge de la mère", y = "Part des naissances hors mariage", colour = NULL) +
  theme_minimal()

ggplotly(g) |> layout(legend = list(orientation = "h", y = -0.2)))--"

DASH_CODE$couples <- r"--(# Âge de la mère × âge du père : chaque case compte les naissances
couples <- donnees |>
  count(AGEMERE, AGEPERE)

g <- ggplot(couples, aes(x = AGEMERE, y = AGEPERE, fill = n,
                         text = paste0("Mère ", AGEMERE, " ans, père ", AGEPERE,
                                       " ans : ", format(n, big.mark = " ")))) +
  geom_tile() +
  geom_abline(slope = 1, intercept = 0, colour = "white", linetype = "dashed") +
  scale_fill_viridis_c(trans = "log10") +
  labs(x = "Âge de la mère", y = "Âge du père", fill = "Naissances") +
  theme_minimal()

ggplotly(g, tooltip = "text"))--"

DASH_CODE$noms <- r"--(noms <- donnees |>
  filter(!is.na(ORIGINOM)) |>
  mutate(origine = case_when(ORIGINOM == 1 ~ "1. Nom du père",
                             ORIGINOM == 2 ~ "2. Nom de la mère",
                             ORIGINOM == 3 ~ "3. Père-Mère",
                             ORIGINOM == 4 ~ "4. Mère-Père",
                             .default = "5. Autre"),
         parents = if_else(AMAR == "0000", "Parents non mariés", "Parents mariés")) |>
  count(parents, origine) |>
  group_by(parents) |>
  mutate(part = n / sum(n))

g <- ggplot(noms, aes(x = parents, y = part, fill = origine,
                      text = paste0(origine, " : ", round(100 * part, 1), " %"))) +
  geom_col() +
  coord_flip() +
  scale_y_continuous(labels = scales::percent) +
  scale_fill_manual(values = c("#1f3a5f", "#d9822b", "#3b6ea5", "#e9b872", "#9aa5b1")) +
  labs(x = NULL, y = NULL, fill = NULL) +
  theme_minimal()

ggplotly(g, tooltip = "text") |> layout(legend = list(orientation = "h", y = -0.2)))--"

# ---------------------------------------------------------------- Interface ---

INDICATEURS_NAIS <- c("Âge moyen de la mère" = "age_mere",
                      "Part des naissances hors mariage (%)" = "hors_mariage",
                      "Part des mères étrangères (%)" = "mere_etrangere",
                      "Part des naissances multiples (%)" = "multiples",
                      "Nombre de naissances" = "naissances")

dashboard_ui <- function(id) {
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

dashboard_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    carte_ok <- reactiveVal(FALSE)   # la carte doit être dessinée avant d'écouter ses clics
    donnees <- reactive({
      t <- input$territoire; req(t)
      B <- BASE$data
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
    objets <- reactive(list(donnees = donnees(), BDD_NAIS = BASE$data,
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
        p <- run_dash_code(DASH_CODE[[name]], objets())
        p$x$source <- paste0("nais_", name)
        if (name == "carte") {
          p <- plotly::event_register(p, "plotly_click")
          session$onFlushed(function() isolate(carte_ok(TRUE)))
        }
        p
      })
      observeEvent(input[[paste0("code_", name)]], {
        code_modal(name, DASH_CODE[[name]],
                   "Ce code utilise les objets donnees (BDD_NAIS filtrée sur le territoire choisi), BDD_NAIS, departements (les contours de la carte) et indicateur, qui viennent des filtres de gauche.")
      })
    }
    for (nm in names(DASH_CODE)) render_chart(nm)

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
