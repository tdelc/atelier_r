# ============================================================================
# mod_cours.R — volet COURS : des leçons en cartes, une par une
#
# Chaque leçon est un fichier markdown (content/cours/<base>/). Les cartes
# s'affichent une à une : explication, code, résultat, commentaire. Le code
# est réellement exécuté (dans le bac à sable) la première fois qu'une leçon
# est ouverte, puis le rendu est gardé en mémoire pour tous les étudiants.
# ============================================================================

COURS <- new.env()       # leçons lues (par base)
COURS_CACHE <- new.env() # rendus HTML des leçons (par base/leçon)

load_cours <- function() {
  for (b in names(BASES)) COURS[[b]] <- read_course(file.path("content/cours", b))
}

# Exécute toute une leçon et renvoie le HTML de chaque carte
render_lesson <- function(base, lesson) {
  key <- paste(base, lesson$id, sep = "/")
  if (!is.null(COURS_CACHE[[key]])) return(COURS_CACHE[[key]])
  env <- sandbox_new_env(base_datasets(base))
  cards <- lapply(lesson$cards, function(card) {
    parts <- lapply(card$segments, function(s) {
      if (s$type == "text") return(htmltools::div(class = "card-text", md_to_html(s$md)))
      if (s$mode == "norun")
        return(htmltools::div(class = "chunk chunk-norun", code_block(s$code),
                              htmltools::div(class = "chunk-badge", "Non exécuté dans l'atelier")))
      run <- sandbox_run(s$code, env)
      if (s$mode == "setup") return(NULL)
      htmltools::div(class = "chunk", render_run(run, show_source = TRUE, copy = TRUE))
    })
    as.character(htmltools::tagList(parts))
  })
  COURS_CACHE[[key]] <- cards
  cards
}

mod_cours_ui <- function(id) {
  ns <- NS(id)
  bslib::nav_panel(
    title = tagList(icon("book-open"), "Cours"), value = "cours",
    bslib::layout_sidebar(
      fillable = FALSE,
      sidebar = bslib::sidebar(
        id = ns("sb"), width = 300, title = "Leçons", open = "desktop",
        uiOutput(ns("lessons"))
      ),
      div(id = ns("zone"), class = "cours-zone",
          uiOutput(ns("head")),
          uiOutput(ns("card")))
    )
  )
}

mod_cours_server <- function(id, base, bus, main_session) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    rv <- reactiveValues(lesson = NULL, card = 1)

    lessons <- reactive(COURS[[base()]])

    observeEvent(base(), {
      rv$lesson <- names(lessons())[1]
      rv$card <- 1
    })
    observeEvent(input$lesson, {
      rv$lesson <- input$lesson
      rv$card <- 1
    })

    current <- reactive({
      req(rv$lesson, rv$lesson %in% names(lessons()))
      lessons()[[rv$lesson]]
    })
    n_cards <- reactive(length(current()$cards))

    rendered <- reactive({
      L <- current()
      shiny::withProgress(message = "Exécution du code de la leçon…", value = 0.5,
                          render_lesson(base(), L))
    })

    output$lessons <- renderUI({
      L <- lessons()
      items <- data.frame(
        id = names(L),
        num = sprintf("%02d", seq_along(L)),
        label = vapply(L, `[[`, "", "titre"),
        sub = sprintf("%d cartes", vapply(L, function(x) length(x$cards), 1L)),
        group = vapply(L, `[[`, "", "partie"),
        stringsAsFactors = FALSE
      )
      side_list(ns("lesson"), items, active = rv$lesson)
    })

    output$head <- renderUI({
      L <- current(); k <- rv$card; n <- n_cards()
      idx <- which(names(lessons()) == rv$lesson)
      div(class = "lesson-head",
          div(class = "lesson-kicker",
              sprintf("Leçon %d / %d · %s", idx, length(lessons()), BASES[[base()]]$objet)),
          h2(L$titre),
          p(class = "lead-sub", L$resume),
          div(class = "card-dots",
              lapply(seq_len(n), function(i) {
                tags$button(type = "button",
                            class = paste("dot", if (i == k) "active", if (i < k) "done"),
                            title = L$cards[[i]]$title,
                            onclick = sprintf("Shiny.setInputValue('%s', %d, {priority: 'event'})",
                                              ns("goto"), i))
              })))
    })

    observeEvent(input$goto, rv$card <- as.integer(input$goto))
    observeEvent(input$prev, rv$card <- max(1, rv$card - 1))
    observeEvent(input[["next"]], {
      if (rv$card < n_cards()) {
        rv$card <- rv$card + 1
      } else {
        ids <- names(lessons()); i <- which(ids == rv$lesson)
        if (i < length(ids)) { rv$lesson <- ids[i + 1]; rv$card <- 1 }
      }
    })
    # flèches du clavier (envoyées par atelier.js)
    observeEvent(main_session$input$cours_key, {
      if (identical(main_session$input$cours_key$dir, "next")) {
        if (rv$card < n_cards()) rv$card <- rv$card + 1
      } else rv$card <- max(1, rv$card - 1)
    })

    output$card <- renderUI({
      L <- current(); k <- min(rv$card, n_cards()); n <- n_cards()
      html <- rendered()[[k]]
      card <- L$cards[[k]]
      has_code <- length(card_code(card, "run")) > 0
      ids <- names(lessons()); last_lesson <- which(ids == rv$lesson) == length(ids)
      bslib::card(
        class = "lesson-card",
        bslib::card_header(
          div(class = "d-flex align-items-baseline gap-3",
              span(class = "card-count", sprintf("%d / %d", k, n)),
              h4(class = "m-0", card$title))
        ),
        bslib::card_body(class = "lesson-body", HTML(html)),
        bslib::card_footer(
          div(class = "d-flex flex-wrap gap-2 align-items-center",
              actionButton(ns("prev"), tagList(icon("arrow-left"), "Précédente"),
                           class = "btn-outline-secondary btn-sm",
                           disabled = if (k == 1) "disabled"),
              if (has_code)
                actionButton(ns("try"), tagList(icon("flask"), "Modifier ce code dans Découverte"),
                             class = "btn-outline-primary btn-sm"),
              div(class = "ms-auto"),
              if (k < n)
                actionButton(ns("next"), tagList("Suivante", icon("arrow-right")),
                             class = "btn-primary btn-sm")
              else if (!last_lesson)
                actionButton(ns("next"), tagList("Leçon suivante", icon("arrow-right")),
                             class = "btn-success btn-sm")
              else span(class = "text-success small fw-semibold",
                        icon("flag-checkered"), " Fin du cours : place aux exercices !")
          )
        )
      )
    })

    # Envoi vers Découverte : le code de la carte + le code des cartes
    # précédentes, rejoué en silence pour reconstituer l'environnement
    observeEvent(input$try, {
      L <- current(); k <- rv$card
      prev <- unlist(lapply(L$cards[seq_len(k - 1)], card_code), use.names = FALSE)
      bus$decouverte <- list(
        titre = paste0(L$titre, " — ", L$cards[[k]]$title),
        code = paste(card_code(L$cards[[k]], "run"), collapse = "\n\n"),
        setup = paste(prev, collapse = "\n"),
        ts = Sys.time()
      )
      bslib::nav_select("onglets", "decouverte", session = main_session)
    })
  })
}
