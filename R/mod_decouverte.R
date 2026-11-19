# ============================================================================
# mod_decouverte.R — volet DÉCOUVERTE : modifier le code et tester
#
# Des pistes (bases/<base>/decouverte.md) proposent un code de départ et des
# idées à tester. L'étudiant modifie le code dans un éditeur et l'exécute dans
# le bac à sable. Chaque session a son propre environnement de travail : les
# objets créés (BDD_NAIS_NORD <- …) restent disponibles d'une exécution à
# l'autre, jusqu'à la réinitialisation.
# ============================================================================

PISTES <- new.env()

# Les pistes d'une base dans une langue (decouverte.md traduit, sinon français)
pistes_de <- function(base, lang = langue()) {
  key <- paste(base, lang)
  if (is.null(PISTES[[key]])) {
    f <- content_file(base, "decouverte.md", lang)
    PISTES[[key]] <- if (file.exists(f$path)) read_pistes(f$path) else list()
  }
  PISTES[[key]]
}

load_pistes <- function() {
  for (b in names(BASES)) for (l in names(LANGUES)) pistes_de(b, l)
}

libre_code <- function(base)
  paste0("# ", tr("dec.libre_commentaire"), "\n", info(base)$code_libre, "\n")

mod_decouverte_ui <- function(id) {
  ns <- NS(id)
  bslib::nav_panel(
    title = tagList(icon("flask"), tr("onglet.decouverte")), value = "decouverte",
    bslib::layout_sidebar(
      fillable = FALSE,
      sidebar = bslib::sidebar(
        id = ns("sb"), width = 290, title = tr("dec.pistes"), open = "desktop",
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
                      span(class = "fw-semibold", icon("code"), " ", tr("dec.votre_code")),
                      span(class = "text-muted small d-none d-md-inline", tr("commun.ctrl_entree")),
                      div(class = "ms-auto d-flex gap-2",
                          ace_button(ns("run"), ns("code"), tagList(icon("play"), tr("commun.executer")),
                                     class = "btn-primary btn-sm ace-default"),
                          actionButton(ns("reset_code"), tagList(icon("rotate-left"), tr("dec.code_depart")),
                                       class = "btn-outline-secondary btn-sm",
                                       title = tr("dec.code_depart_aide")),
                          actionButton(ns("reset_env"), tagList(icon("broom"), tr("dec.nouvel_env")),
                                       class = "btn-outline-secondary btn-sm",
                                       title = tr("dec.nouvel_env_aide"))))
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
                bslib::card_header(span(class = "fw-semibold", icon("terminal"), " ", tr("dec.resultat")),
                                   uiOutput(ns("timing"), inline = TRUE)),
                bslib::card_body(uiOutput(ns("result")),
                                 div(id = ns("pyres"), class = "py-target"))
              )
            ),
            div(
              uiOutput(ns("idees")),
              bslib::card(
                bslib::card_header(span(class = "fw-semibold", icon("box-archive"), " ", tr("dec.objets"))),
                bslib::card_body(
                  uiOutput(ns("objets")),
                  div(id = ns("objets_py"), class = "py-target"),
                  div(class = "d-flex flex-wrap gap-2",
                      actionButton(ns("dico"), tagList(icon("table-list"), tr("commun.dictionnaire")),
                                   class = "btn-outline-primary btn-sm"),
                      actionButton(ns("fonctions"), tagList(icon("shield-halved"), tr("dec.fonctions")),
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
                         env_version = 0, notice = NULL, py_ran = FALSE, py_sec = NULL)

    pistes <- reactive(pistes_de(base()))

    new_env <- function(setup = "") {
      if (est_python(base())) {
        # Python : l'environnement vit dans le navigateur
        main_session$sendCustomMessage("py_reset", list(
          base = base(), ns = "decouverte", setup = setup, objets = ns("objets_py")))
        rv$env <- NULL; rv$py_ran <- FALSE
        return(invisible())
      }
      env <- sandbox_new_env(base_datasets(base()))
      if (nzchar(setup)) sandbox_run(setup, env)
      rv$env <- env
      rv$env_version <- rv$env_version + 1
    }

    current <- reactive({
      if (identical(rv$piste, "cours") && !is.null(rv$from_cours)) {
        return(list(title = rv$from_cours$titre,
                    description = tr("dec.depuis_cours_texte"),
                    code = rv$from_cours$code, setup = rv$from_cours$setup, idees = ""))
      }
      if (identical(rv$piste, "libre") && est_python(base()))
        return(list(title = tr("dec.libre"),
                    description = tr("dec.libre_python"),
                    code = libre_code(base()), setup = "", idees = ""))
      if (identical(rv$piste, "libre"))
        return(list(title = tr("dec.libre"),
                    description = tr("dec.libre_r", objet = info(base())$objet),
                    code = libre_code(base()), setup = "", idees = ""))
      i <- suppressWarnings(as.integer(rv$piste))
      if (!length(pistes())) {
        return(list(title = tr("dec.libre"),
                    description = tr("dec.libre_court", objet = info(base())$objet),
                    code = libre_code(base()), setup = "", idees = ""))
      }
      if (is.na(i) || i > length(pistes())) i <- 1
      pistes()[[i]]
    })

    load_piste <- function() {
      p <- current()
      new_env(p$setup)
      shinyAce::updateAceEditor(session, "code", value = p$code)
      rv$run <- NULL
      main_session$sendCustomMessage("py_clear", list(ns("pyres"), ns("objets_py")))
    }

    observeEvent(base(), {
      shinyAce::updateAceEditor(session, "code", mode = base_lang(base()),
                                tabSize = if (est_python(base())) 4 else 2)
      rv$piste <- if (length(pistes())) "1" else "libre"; rv$from_cours <- NULL
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
                          sub = rep("", length(P)), group = rep(tr("dec.pistes_guidees"), length(P)),
                          stringsAsFactors = FALSE)
      extra <- data.frame(id = "libre", num = "✎", label = tr("dec.libre"),
                          sub = tr("dec.propre_code"), group = tr("dec.espace_libre"),
                          stringsAsFactors = FALSE)
      if (!is.null(rv$from_cours))
        extra <- rbind(data.frame(id = "cours", num = "↩", label = tr("dec.depuis_cours"),
                                  sub = rv$from_cours$titre, group = tr("dec.espace_libre"),
                                  stringsAsFactors = FALSE), extra)
      side_list(ns("piste"), rbind(items, extra), active = rv$piste)
    })

    output$head <- renderUI({
      p <- current()
      div(class = "lesson-head",
          div(class = "lesson-kicker", paste(tr("onglet.decouverte"), "·", base_kicker(base()))),
          h2(p$title),
          div(class = "lead-sub", md_to_html(p$description)))
    })

    output$idees <- renderUI({
      p <- current()
      # le titre « ## À essayer » (ou sa traduction) est remplacé par l'en-tête
      txt <- sub("^\\s*##[^\n]*\n", "", p$idees)
      if (!nzchar(trimws(txt))) return(NULL)
      bslib::card(
        class = "idees-card",
        bslib::card_header(span(class = "fw-semibold", icon("lightbulb"), " ", tr("dec.a_essayer"))),
        bslib::card_body(md_to_html(txt))
      )
    })

    do_run <- function(code) {
      if (est_python(base())) {
        main_session$sendCustomMessage("py_run", list(
          base = base(), ns = "decouverte", code = code, target = ns("pyres"),
          objets = ns("objets_py"), reply = ns("py_done")))
        return(invisible())
      }
      req(rv$env)
      rv$run <- sandbox_run(code, rv$env)
      rv$env_version <- rv$env_version + 1
    }
    observeEvent(input$run, do_run(input$run$code %||% ""))
    observeEvent(input$py_done, { rv$py_ran <- TRUE; rv$py_sec <- input$py_done$seconds })

    observeEvent(input$reset_code, {
      shinyAce::updateAceEditor(session, "code", value = current()$code)
    })
    observeEvent(input$reset_env, {
      new_env(current()$setup)
      rv$run <- NULL
      showNotification(tr("dec.env_recharge"),
                       type = "message", duration = 3)
    })

    output$timing <- renderUI({
      if (est_python(base())) {
        if (!rv$py_ran || is.null(rv$py_sec)) return(NULL)
        return(span(class = "text-muted small ms-2", sprintf("(%.2f s)", rv$py_sec)))
      }
      r <- rv$run
      if (is.null(r) || length(r$blocked)) return(NULL)
      span(class = "text-muted small ms-2", sprintf("(%.2f s)", r$seconds))
    })

    output$result <- renderUI({
      r <- rv$run
      if (est_python(base()))
        return(if (!rv$py_ran) div(class = "empty-result", icon("play"),
                                   " ", tr("dec.cliquez_python")))
      if (is.null(r))
        return(div(class = "empty-result", icon("play"),
                   " ", tr("dec.cliquez")))
      if (!length(r$items) && !length(r$blocked))
        return(div(class = "empty-result", tr("dec.rien_affiche")))
      div(class = "run-output", render_run(r, show_source = TRUE, copy = FALSE))
    })

    output$objets <- renderUI({
      if (est_python(base())) return(NULL)
      rv$env_version
      req(rv$env)
      env_objects_ui(rv$env)
    })

    observeEvent(input$dico, showModal(dico_modal(base())))
    observeEvent(input$fonctions, showModal(if (est_python(base())) python_modal() else fonctions_modal()))
  })
}
