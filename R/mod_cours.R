# ============================================================================
# mod_cours.R — volet COURS : des leçons en cartes, une par une
#
# Chaque leçon est un fichier markdown (bases/<base>/cours/). Les cartes
# s'affichent une à une : explication, code, résultat, commentaire. Le code
# est réellement exécuté (dans le bac à sable) la première fois qu'une leçon
# est ouverte, puis le rendu est gardé en mémoire pour tous les étudiants.
# ============================================================================

COURS <- new.env()       # leçons lues (par base et par langue)
COURS_CACHE <- new.env() # rendus HTML des leçons (par langue/base/leçon)

# Les leçons d'une base dans une langue : chaque leçon traduite remplace la
# leçon française du même nom de fichier ; les autres restent en français
# (lesson$traduit vaut FALSE). L'ordre est celui des fichiers français.
cours_de <- function(base, lang = langue()) {
  key <- paste(base, lang)
  if (is.null(COURS[[key]])) {
    fr <- read_course(base_path(base, "cours"))
    for (id in names(fr)) fr[[id]]$traduit <- identical(lang, LANGUE_SOURCE)
    d <- file.path(BASES[[base]]$dir, lang, "cours")
    if (!identical(lang, LANGUE_SOURCE) && dir.exists(d)) {
      trad <- read_course(d)
      for (id in intersect(names(fr), names(trad))) {
        fr[[id]] <- trad[[id]]
        fr[[id]]$traduit <- TRUE
      }
    }
    COURS[[key]] <- fr
  }
  COURS[[key]]
}

load_cours <- function() {
  for (b in names(BASES)) for (l in names(LANGUES)) cours_de(b, l)
}

# Leçon en Python : le code s'exécute dans le navigateur (www/python/). Les
# cartes contiennent des emplacements <div class="py-out"> que le navigateur
# remplit ; py_lesson_chunks() donne la liste des blocs à exécuter, dans le
# même ordre que ces emplacements.
py_lesson_key <- function(base, lesson, lang = langue()) paste("cours", lang, base, lesson$id, sep = "/")

py_lesson_chunks <- function(lesson) {
  segs <- unlist(lapply(lesson$cards, `[[`, "segments"), recursive = FALSE)
  segs <- Filter(function(s) s$type == "code" && s$mode != "norun", segs)
  lapply(segs, function(s) list(code = s$code, mode = s$mode))
}

render_lesson_py <- function(base, lesson) {
  key <- py_lesson_key(base, lesson)
  idx <- -1L
  lapply(lesson$cards, function(card) {
    parts <- lapply(card$segments, function(s) {
      if (s$type == "text") return(htmltools::div(class = "card-text", md_to_html(s$md)))
      if (s$mode == "norun")
        return(htmltools::div(class = "chunk chunk-norun", code_block(s$code, lang = "python"),
                              htmltools::div(class = "chunk-badge", tr("cours.non_execute"))))
      idx <<- idx + 1L
      if (s$mode == "setup") return(NULL)
      htmltools::div(class = "chunk", code_block(s$code, copy = TRUE, lang = "python"),
                     htmltools::div(class = "py-out", `data-key` = key, `data-idx` = idx))
    })
    as.character(htmltools::tagList(parts))
  })
}

# Exécute toute une leçon et renvoie le HTML de chaque carte
render_lesson <- function(base, lesson, lang = langue()) {
  key <- paste(lang, base, lesson$id, sep = "/")
  if (!is.null(COURS_CACHE[[key]])) return(COURS_CACHE[[key]])
  if (est_python(base)) return(COURS_CACHE[[key]] <- render_lesson_py(base, lesson))
  env <- sandbox_new_env(base_datasets(base))
  cards <- lapply(lesson$cards, function(card) {
    parts <- lapply(card$segments, function(s) {
      if (s$type == "text") return(htmltools::div(class = "card-text", md_to_html(s$md)))
      if (s$mode == "norun")
        return(htmltools::div(class = "chunk chunk-norun", code_block(s$code),
                              htmltools::div(class = "chunk-badge", tr("cours.non_execute"))))
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
    title = tagList(icon("book-open"), tr("onglet.cours")), value = "cours",
    bslib::layout_sidebar(
      fillable = FALSE,
      sidebar = bslib::sidebar(
        id = ns("sb"), width = 300, title = tr("cours.lecons"), open = "desktop",
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

    lessons <- reactive(cours_de(base()))

    observeEvent(base(), {
      rv$lesson <- names(lessons())[1]
      rv$card <- 1
    })
    observeEvent(input$lesson, {
      rv$lesson <- input$lesson
      rv$card <- 1
    })

    current <- reactive({
      req(length(lessons()) > 0, rv$lesson, rv$lesson %in% names(lessons()))
      lessons()[[rv$lesson]]
    })
    n_cards <- reactive(length(current()$cards))

    # Python : le navigateur exécute la leçon (une fois) dès qu'elle s'ouvre
    observeEvent(current(), {
      if (est_python(base()))
        main_session$sendCustomMessage("py_chunks", list(
          base = base(), key = py_lesson_key(base(), current()),
          chunks = py_lesson_chunks(current())))
    })

    rendered <- reactive({
      L <- current()
      if (est_python(base())) return(render_lesson(base(), L))
      shiny::withProgress(message = tr("cours.execution"), value = 0.5,
                          render_lesson(base(), L))
    })

    output$lessons <- renderUI({
      L <- lessons()
      if (!length(L)) return(p(class = "text-muted small", tr("cours.aucune_lecon")))
      items <- data.frame(
        id = names(L),
        num = sprintf("%02d", seq_along(L)),
        label = vapply(L, `[[`, "", "titre"),
        sub = vapply(L, function(x) tr("cours.n_cartes", n = length(x$cards)), ""),
        group = vapply(L, `[[`, "", "partie"),
        stringsAsFactors = FALSE
      )
      side_list(ns("lesson"), items, active = rv$lesson)
    })

    output$head <- renderUI({
      if (!length(lessons()))
        return(aucun_contenu(tr("cours.vide_titre"),
                             tr("cours.vide_texte", dossier = base_path(base(), "cours"))))
      L <- current(); k <- rv$card; n <- n_cards()
      idx <- which(names(lessons()) == rv$lesson)
      div(class = "lesson-head",
          div(class = "lesson-kicker",
              tr("cours.kicker", i = idx, n = length(lessons()), base = base_kicker(base()))),
          h2(L$titre),
          if (!isTRUE(L$traduit)) div(class = "non-traduit", icon("language"), " ", tr("contenu.non_traduit")),
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
              actionButton(ns("prev"), tagList(icon("arrow-left"), tr("cours.precedente")),
                           class = "btn-outline-secondary btn-sm",
                           disabled = if (k == 1) "disabled"),
              if (has_code)
                actionButton(ns("try"), tagList(icon("flask"), tr("cours.essayer")),
                             class = "btn-outline-primary btn-sm"),
              div(class = "ms-auto"),
              if (k < n)
                actionButton(ns("next"), tagList(tr("cours.suivante"), icon("arrow-right")),
                             class = "btn-primary btn-sm")
              else if (!last_lesson)
                actionButton(ns("next"), tagList(tr("cours.lecon_suivante"), icon("arrow-right")),
                             class = "btn-success btn-sm")
              else span(class = "text-success small fw-semibold",
                        icon("flag-checkered"), " ", tr("cours.fin"))
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
