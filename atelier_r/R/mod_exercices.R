# ============================================================================
# mod_exercices.R — volet EXERCICES : questions graduées, vérification, corrigé
#
# Chaque exécution part d'un environnement neuf (base d'origine + éventuelle
# préparation) : le résultat ne dépend que du code de l'exercice. Le bouton
# « Vérifier » compare le résultat de la dernière ligne à celui de la
# correction (voir compare.R). La progression est gardée dans le navigateur
# de l'étudiant (localStorage) : rien n'est stocké sur le serveur.
# ============================================================================

EXERCICES <- new.env()
SOLUTIONS_CACHE <- new.env()

load_exercices <- function() {
  for (b in names(BASES))
    EXERCICES[[b]] <- read_exercises(file.path("content/exercices", paste0(b, ".md")))
}

NIVEAUX <- c("1" = "Niveau 1 · Premiers pas", "2" = "Niveau 2 · Regrouper",
             "3" = "Niveau 3 · Créer des variables", "4" = "Niveau 4 · Mettre en forme",
             "5" = "Niveau 5 · Synthèse")

solution_of <- function(base, ex) {
  key <- paste(base, ex$id, sep = "/")
  if (is.null(SOLUTIONS_CACHE[[key]])) {
    env <- sandbox_new_env(base_datasets(base))
    if (nzchar(ex$preparation)) sandbox_run(ex$preparation, env)
    SOLUTIONS_CACHE[[key]] <- sandbox_run(ex$correction, env)
  }
  SOLUTIONS_CACHE[[key]]
}

mod_exercices_ui <- function(id) {
  ns <- NS(id)
  bslib::nav_panel(
    title = tagList(icon("pen-to-square"), "Exercices"), value = "exercices",
    bslib::layout_sidebar(
      fillable = FALSE,
      sidebar = bslib::sidebar(
        id = ns("sb"), width = 300, title = "Exercices", open = "desktop",
        uiOutput(ns("progress")),
        uiOutput(ns("liste"))
      ),
      div(class = "exercices-zone",
          uiOutput(ns("enonce")),
          bslib::card(
            class = "editor-card",
            bslib::card_header(
              div(class = "d-flex flex-wrap gap-2 align-items-center",
                  span(class = "fw-semibold", icon("code"), " Votre réponse"),
                  span(class = "text-muted small d-none d-md-inline", "Ctrl + Entrée pour exécuter"),
                  div(class = "ms-auto d-flex flex-wrap gap-2",
                      ace_button(ns("run"), ns("code"), tagList(icon("play"), "Exécuter"),
                                 class = "btn-outline-primary btn-sm ace-default"),
                      ace_button(ns("check"), ns("code"), tagList(icon("circle-check"), "Vérifier"),
                                 class = "btn-primary btn-sm"),
                      actionButton(ns("reset"), tagList(icon("rotate-left"), "Effacer"),
                                   class = "btn-outline-secondary btn-sm")))
            ),
            shinyAce::aceEditor(
              ns("code"), value = "", mode = "r", theme = "chrome",
              height = "220px", fontSize = 14, tabSize = 2, showPrintMargin = FALSE,
              wordWrap = TRUE, debounce = 50, autoComplete = "live", autoCompleters = c("static", "text")
            )
          ),
          uiOutput(ns("feedback")),
          uiOutput(ns("result")),
          uiOutput(ns("correction")),
          uiOutput(ns("nav"))
      )
    )
  )
}

mod_exercices_server <- function(id, base, main_session) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    rv <- reactiveValues(i = 1, run = NULL, feedback = NULL, show_hint = FALSE,
                         show_corr = FALSE, progress = list())

    exs <- reactive(EXERCICES[[base()]])
    ex <- reactive({ i <- min(rv$i, length(exs())); exs()[[i]] })
    pkey <- function(e = ex()) paste(base(), e$id, sep = "/")

    # --- progression (localStorage via atelier.js) ---
    observeEvent(main_session$input$progress_init, {
      p <- tryCatch(jsonlite::fromJSON(main_session$input$progress_init, simplifyVector = FALSE),
                    error = function(e) list())
      if (is.list(p)) rv$progress <- p
    }, once = TRUE)
    set_status <- function(status) {
      k <- pkey(); old <- rv$progress[[k]] %||% ""
      rank <- c("tente" = 1, "vu" = 2, "reussi" = 3)
      if (!nzchar(old) || rank[[status]] > rank[[old]]) {
        rv$progress[[k]] <- status
        session$sendCustomMessage("atelier_save_progress",
                                  as.character(jsonlite::toJSON(rv$progress, auto_unbox = TRUE)))
      }
    }

    reset_view <- function() {
      e <- ex()
      shinyAce::updateAceEditor(session, "code",
                                value = if (nzchar(e$depart)) e$depart else "")
      rv$run <- NULL; rv$feedback <- NULL; rv$show_hint <- FALSE; rv$show_corr <- FALSE
    }
    observeEvent(base(), { rv$i <- 1; reset_view() })
    observeEvent(input$pick, { rv$i <- as.integer(sub("ex", "", input$pick)); reset_view() })
    observeEvent(input$prev, { rv$i <- max(1, rv$i - 1); reset_view() })
    observeEvent(input$suiv, { rv$i <- min(length(exs()), rv$i + 1); reset_view() })
    observeEvent(input$reset, reset_view())

    run_student <- function(code) {
      e <- ex()
      env <- sandbox_new_env(base_datasets(base()))
      if (nzchar(e$preparation)) sandbox_run(e$preparation, env)
      sandbox_run(code %||% "", env)
    }
    observeEvent(input$run, { rv$run <- run_student(input$run$code); rv$feedback <- NULL; set_status("tente") })

    observeEvent(input$check, {
      e <- ex()
      r <- run_student(input$check$code); rv$run <- r
      if (length(r$blocked) || !r$ok) {
        rv$feedback <- list(status = "ko", message = "Votre code produit une erreur : corrigez-la d'abord (voir le résultat ci-dessous).")
      } else if (e$verif == "aucune") {
        rv$feedback <- list(status = "na", message = "Pas de vérification automatique pour cet exercice : comparez avec la correction.")
      } else {
        rv$feedback <- compare_results(r$value, solution_of(base(), e)$value)
      }
      set_status(if (identical(rv$feedback$status, "ok")) "reussi" else "tente")
    })

    observeEvent(input$hint, rv$show_hint <- !rv$show_hint)
    observeEvent(input$show_corr, { rv$show_corr <- TRUE; set_status("vu") })
    observeEvent(input$hide_corr, rv$show_corr <- FALSE)

    output$progress <- renderUI({
      E <- exs(); st <- vapply(E, function(e) rv$progress[[pkey(e)]] %||% "", "")
      ok <- sum(st == "reussi"); n <- length(E)
      div(class = "ex-progress",
          div(class = "d-flex justify-content-between small",
              span("Réussis"), span(class = "fw-semibold", sprintf("%d / %d", ok, n))),
          div(class = "progress", style = "height: 6px;",
              div(class = "progress-bar bg-success", style = sprintf("width: %.0f%%", 100 * ok / n))))
    })

    output$liste <- renderUI({
      E <- exs()
      st <- vapply(E, function(e) rv$progress[[pkey(e)]] %||% "", "")
      items <- data.frame(
        id = vapply(E, `[[`, "", "id"),
        num = ifelse(st == "reussi", "✓", sprintf("%02d", seq_along(E))),
        label = vapply(E, `[[`, "", "title"),
        sub = vapply(E, `[[`, "", "theme"),
        group = NIVEAUX[as.character(vapply(E, `[[`, 1L, "niveau"))],
        status = ifelse(nzchar(st), st, "aucun"),
        stringsAsFactors = FALSE
      )
      side_list(ns("pick"), items, active = ex()$id)
    })

    output$enonce <- renderUI({
      e <- ex(); n <- length(exs())
      bslib::card(
        class = "enonce-card",
        bslib::card_header(
          div(class = "d-flex flex-wrap align-items-center gap-2",
              span(class = "card-count", sprintf("%d / %d", min(rv$i, n), n)),
              h4(class = "m-0", e$title),
              span(class = paste0("badge niveau niveau-", e$niveau),
                   sprintf("Niveau %d", e$niveau)),
              if (nzchar(e$theme)) span(class = "badge theme-badge", e$theme))
        ),
        bslib::card_body(
          md_to_html(e$enonce),
          if (nzchar(e$preparation))
            tags$details(class = "prep",
                         tags$summary("Code déjà exécuté avant le vôtre"),
                         code_block(e$preparation, copy = FALSE)),
          div(class = "d-flex flex-wrap gap-2 mt-2",
              actionButton(ns("hint"), tagList(icon("lightbulb"),
                                               if (rv$show_hint) "Masquer l'indice" else "Indice"),
                           class = "btn-outline-warning btn-sm"),
              if (!rv$show_corr)
                actionButton(ns("show_corr"), tagList(icon("eye"), "Voir la correction"),
                             class = "btn-outline-secondary btn-sm")),
          if (rv$show_hint && nzchar(e$indice))
            div(class = "callout callout-usage mt-3", md_to_html(e$indice))
        )
      )
    })

    output$feedback <- renderUI({
      f <- rv$feedback
      if (is.null(f)) return(NULL)
      cls <- switch(f$status, ok = "fb-ok", ko = "fb-ko", "fb-na")
      ic <- switch(f$status, ok = "circle-check", ko = "circle-xmark", "circle-info")
      div(class = paste("feedback", cls), icon(ic), span(f$message))
    })

    output$result <- renderUI({
      r <- rv$run
      if (is.null(r)) return(NULL)
      bslib::card(
        class = "result-card",
        bslib::card_header(span(class = "fw-semibold", icon("terminal"), " Votre résultat")),
        bslib::card_body(
          if (!length(r$items) && !length(r$blocked))
            div(class = "empty-result", "Le code s'est exécuté sans rien afficher.")
          else div(class = "run-output", render_run(r, show_source = TRUE)))
      )
    })

    output$correction <- renderUI({
      if (!rv$show_corr) return(NULL)
      e <- ex(); sol <- solution_of(base(), e)
      bslib::card(
        class = "correction-card",
        bslib::card_header(
          div(class = "d-flex align-items-center",
              span(class = "fw-semibold", icon("graduation-cap"), " Correction"),
              actionButton(ns("hide_corr"), "Masquer", class = "btn-link btn-sm ms-auto"))),
        bslib::card_body(
          div(class = "run-output", render_run(sol, show_source = TRUE, copy = TRUE)),
          if (nzchar(e$commentaire))
            div(class = "callout callout-note mt-3", md_to_html(e$commentaire)))
      )
    })

    output$nav <- renderUI({
      n <- length(exs())
      div(class = "d-flex gap-2 my-3",
          actionButton(ns("prev"), tagList(icon("arrow-left"), "Exercice précédent"),
                       class = "btn-outline-secondary btn-sm",
                       disabled = if (rv$i <= 1) "disabled"),
          div(class = "ms-auto"),
          actionButton(ns("suiv"), tagList("Exercice suivant", icon("arrow-right")),
                       class = "btn-primary btn-sm",
                       disabled = if (rv$i >= n) "disabled"))
    })
  })
}
