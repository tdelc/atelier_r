# ============================================================================
# mod_decouverte.R — volet DÉCOUVERTE : modifier le code et tester
#
# Des pistes (content/decouverte/<base>.md) proposent un code de départ et des
# idées à tester. L'étudiant modifie le code dans un éditeur et l'exécute dans
# le bac à sable. Chaque session a son propre environnement de travail : les
# objets créés (BDD_NAIS_NORD <- …) restent disponibles d'une exécution à
# l'autre, jusqu'à la réinitialisation.
# ============================================================================

PISTES <- new.env()
load_pistes <- function() {
  for (b in names(BASES))
    PISTES[[b]] <- read_pistes(file.path("content/decouverte", paste0(b, ".md")))
}

LIBRE_CODE <- list(
  naissances = "# Bac à sable libre : écrivez votre code ici, puis Ctrl + Entrée\nBDD_NAIS |>\n  count(SEXE)\n",
  meteo = "# Bac à sable libre : écrivez votre code ici, puis Ctrl + Entrée\nBDD_METEO |>\n  count(name)\n"
)

mod_decouverte_ui <- function(id) {
  ns <- NS(id)
  bslib::nav_panel(
    title = tagList(icon("flask"), "Découverte"), value = "decouverte",
    bslib::layout_sidebar(
      fillable = FALSE,
      sidebar = bslib::sidebar(
        id = ns("sb"), width = 290, title = "Pistes à explorer", open = "desktop",
        uiOutput(ns("pistes"))
      ),
      div(class = "decouverte-zone",
          uiOutput(ns("head")),
          bslib::layout_columns(
            col_widths = bslib::breakpoints(sm = 12, lg = c(8, 4)),
            div(
              bslib::card(
                class = "editor-card",
                bslib::card_header(
                  div(class = "d-flex flex-wrap gap-2 align-items-center",
                      span(class = "fw-semibold", icon("code"), " Votre code"),
                      span(class = "text-muted small d-none d-md-inline", "Ctrl + Entrée pour exécuter"),
                      div(class = "ms-auto d-flex gap-2",
                          ace_button(ns("run"), ns("code"), tagList(icon("play"), "Exécuter"),
                                     class = "btn-primary btn-sm ace-default"),
                          actionButton(ns("reset_code"), tagList(icon("rotate-left"), "Code de départ"),
                                       class = "btn-outline-secondary btn-sm",
                                       title = "Remettre le code de départ de la piste"),
                          actionButton(ns("reset_env"), tagList(icon("broom"), "Nouvel environnement"),
                                       class = "btn-outline-secondary btn-sm",
                                       title = "Effacer les objets créés et recharger les bases d'origine")))
                ),
                shinyAce::aceEditor(
                  ns("code"), value = "", mode = "r", theme = "chrome",
                  height = "280px", fontSize = 14, tabSize = 2, showPrintMargin = FALSE,
                  wordWrap = TRUE, debounce = 50, autoComplete = "live",
                  autoCompleters = c("static", "text")
                )
              ),
              bslib::card(
                class = "result-card",
                bslib::card_header(span(class = "fw-semibold", icon("terminal"), " Résultat"),
                                   uiOutput(ns("timing"), inline = TRUE)),
                bslib::card_body(uiOutput(ns("result")))
              )
            ),
            div(
              uiOutput(ns("idees")),
              bslib::card(
                bslib::card_header(span(class = "fw-semibold", icon("box-archive"), " Objets disponibles")),
                bslib::card_body(
                  uiOutput(ns("objets")),
                  div(class = "d-flex flex-wrap gap-2",
                      actionButton(ns("dico"), tagList(icon("table-list"), "Dictionnaire"),
                                   class = "btn-outline-primary btn-sm"),
                      actionButton(ns("fonctions"), tagList(icon("shield-halved"), "Fonctions autorisées"),
                                   class = "btn-outline-secondary btn-sm"))
                )
              )
            )
          ))
    )
  )
}

mod_decouverte_server <- function(id, base, bus, main_session) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    rv <- reactiveValues(piste = "1", env = NULL, run = NULL, from_cours = NULL,
                         env_version = 0, notice = NULL)

    pistes <- reactive(PISTES[[base()]])

    new_env <- function(setup = "") {
      env <- sandbox_new_env(base_datasets(base()))
      if (nzchar(setup)) sandbox_run(setup, env)
      rv$env <- env
      rv$env_version <- rv$env_version + 1
    }

    current <- reactive({
      if (identical(rv$piste, "cours") && !is.null(rv$from_cours)) {
        return(list(title = rv$from_cours$titre,
                    description = "Code importé depuis le cours. Les cartes précédentes de la leçon ont été exécutées en arrière-plan : les variables qu'elles créent sont disponibles.",
                    code = rv$from_cours$code, setup = rv$from_cours$setup, idees = ""))
      }
      if (identical(rv$piste, "libre"))
        return(list(title = "Bac à sable libre",
                    description = sprintf("Un espace pour écrire votre propre code sur `%s`. Les objets que vous créez restent disponibles tant que vous ne cliquez pas sur « Nouvel environnement ».", BASES[[base()]]$objet),
                    code = LIBRE_CODE[[base()]], setup = "", idees = ""))
      i <- suppressWarnings(as.integer(rv$piste))
      if (is.na(i) || i > length(pistes())) i <- 1
      pistes()[[i]]
    })

    load_piste <- function() {
      p <- current()
      new_env(p$setup)
      shinyAce::updateAceEditor(session, "code", value = p$code)
      rv$run <- NULL
    }

    observeEvent(base(), {
      rv$piste <- "1"; rv$from_cours <- NULL
      load_piste()
    })
    observeEvent(input$piste, {
      rv$piste <- input$piste
      load_piste()
    })
    observeEvent(bus$decouverte, {
      rv$from_cours <- bus$decouverte
      rv$piste <- "cours"
      load_piste()
    }, ignoreInit = TRUE)

    output$pistes <- renderUI({
      P <- pistes()
      items <- data.frame(id = as.character(seq_along(P)),
                          num = sprintf("%02d", seq_along(P)),
                          label = vapply(P, `[[`, "", "title"),
                          sub = "", group = "Pistes guidées",
                          stringsAsFactors = FALSE)
      extra <- data.frame(id = "libre", num = "✎", label = "Bac à sable libre",
                          sub = "Votre propre code", group = "Espace libre",
                          stringsAsFactors = FALSE)
      if (!is.null(rv$from_cours))
        extra <- rbind(data.frame(id = "cours", num = "↩", label = "Code venant du cours",
                                  sub = rv$from_cours$titre, group = "Espace libre",
                                  stringsAsFactors = FALSE), extra)
      side_list(ns("piste"), rbind(items, extra), active = rv$piste)
    })

    output$head <- renderUI({
      p <- current()
      div(class = "lesson-head",
          div(class = "lesson-kicker", paste("Découverte ·", BASES[[base()]]$objet)),
          h2(p$title),
          div(class = "lead-sub", md_to_html(p$description)))
    })

    output$idees <- renderUI({
      p <- current()
      txt <- sub("^\\s*##\\s*À essayer\\s*\n", "", p$idees)
      if (!nzchar(trimws(txt))) return(NULL)
      bslib::card(
        class = "idees-card",
        bslib::card_header(span(class = "fw-semibold", icon("lightbulb"), " À essayer")),
        bslib::card_body(md_to_html(txt))
      )
    })

    do_run <- function(code) {
      req(rv$env)
      rv$run <- sandbox_run(code, rv$env)
      rv$env_version <- rv$env_version + 1
    }
    observeEvent(input$run, do_run(input$run$code %||% ""))

    observeEvent(input$reset_code, {
      shinyAce::updateAceEditor(session, "code", value = current()$code)
    })
    observeEvent(input$reset_env, {
      new_env(current()$setup)
      rv$run <- NULL
      showNotification("Nouvel environnement : les bases d'origine sont rechargées.",
                       type = "message", duration = 3)
    })

    output$timing <- renderUI({
      r <- rv$run
      if (is.null(r) || length(r$blocked)) return(NULL)
      span(class = "text-muted small ms-2", sprintf("(%.2f s)", r$seconds))
    })

    output$result <- renderUI({
      r <- rv$run
      if (is.null(r))
        return(div(class = "empty-result", icon("play"),
                   " Cliquez sur « Exécuter » (ou Ctrl + Entrée) pour lancer le code."))
      if (!length(r$items) && !length(r$blocked))
        return(div(class = "empty-result", "Le code s'est exécuté sans rien afficher. Pour voir un objet, tapez son nom sur une ligne."))
      div(class = "run-output", render_run(r, show_source = TRUE, copy = FALSE))
    })

    output$objets <- renderUI({
      rv$env_version
      req(rv$env)
      env_objects_ui(rv$env)
    })

    observeEvent(input$dico, showModal(dico_modal(base())))
    observeEvent(input$fonctions, showModal(fonctions_modal()))
  })
}
