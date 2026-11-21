# ============================================================================
# mod_accueil.R — page d'accueil
# ============================================================================

mod_accueil_ui <- function(id) {
  ns <- NS(id)
  volet <- function(onglet, ic, titre, texte) {
    tags$button(
      type = "button", class = "volet",
      onclick = sprintf("Shiny.setInputValue('%s', '%s', {priority: 'event'})", ns("aller"), onglet),
      div(class = "volet-icon", icon(ic)),
      div(class = "volet-titre", titre),
      div(class = "volet-texte", texte)
    )
  }
  bslib::nav_panel(
    title = tagList(icon("house"), tr("onglet.accueil")), value = "accueil",
    div(class = "accueil",
        div(class = "hero",
            div(class = "hero-kicker", tr(switch(paste(sort(langages_actifs()), collapse = "+"),
                                                python = "accueil.kicker_python", r = "accueil.kicker_r",
                                                "accueil.kicker"))),
            h1(atelier_reglages()$titre),
            p(class = "hero-lead", tr("accueil.lead")),
            div(class = "d-flex flex-wrap gap-2",
                actionButton(ns("tour"), tagList(icon("compass"), tr("accueil.visite")),
                             class = "btn-primary"),
                actionButton(ns("go_cours"), tagList(tr("accueil.commencer"), icon("arrow-right")),
                             class = "btn-outline-primary"))),

        h3(class = "section-title", tr(if (a_des_dashboards()) "accueil.quatre_facons" else "accueil.trois_facons")),
        div(class = "volets",
            volet("cours", "book-open", tr("onglet.cours"), tr("accueil.volet_cours")),
            volet("decouverte", "flask", tr("onglet.decouverte"), tr("accueil.volet_decouverte")),
            volet("exercices", "pen-to-square", tr("onglet.exercices"), tr("accueil.volet_exercices")),
            if (a_des_dashboards())
              volet("dashboard", "chart-line", tr("onglet.dashboard"), tr("accueil.volet_dashboard"))),

        h3(class = "section-title", nombre_bases_titre()),
        p(class = "text-muted", tr("accueil.choisir_base")),
        uiOutput(ns("bases")),

        h3(class = "section-title", tr("accueil.bon_a_savoir")),
        div(class = "savoir",
            div(icon("shield-halved"),
                div(tags$strong(tr("accueil.protege_titre"), " "), tr("accueil.protege_texte"))),
            div(icon("floppy-disk"),
                div(tags$strong(tr("accueil.progression_titre"), " "), tr("accueil.progression_texte"))),
            div(icon("laptop-code"),
                div(tags$strong(tr("accueil.rstudio_titre"), " "), HTML(tr(if (identical(langages_actifs(), "python")) "accueil.poste_python"
                                                       else "accueil.rstudio_texte")))))
    )
  )
}

mod_accueil_server <- function(id, main_session, base_input_id = "base") {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$aller, bslib::nav_select("onglets", input$aller, session = main_session))
    observeEvent(input$go_cours, bslib::nav_select("onglets", "cours", session = main_session))

    output$bases <- renderUI({
      cur <- main_session$input[[base_input_id]]
      carte_base <- function(b) {
        B <- info(b); D <- B$data
        chiffres <- c(stats::setNames(list(format(nrow(D), big.mark = " ")), B$nom_lignes),
                      stats::setNames(list(ncol(D)), tr("accueil.variables")),
                      lapply(B$compter, function(col)
                        if (col %in% names(D)) dplyr::n_distinct(D[[col]]) else "?"))
        tags$button(
          type = "button", class = paste("base-card", if (identical(cur, b)) "active"),
          onclick = sprintf("Shiny.setInputValue('%s', '%s', {priority: 'event'})", session$ns("choisir"), b),
          div(class = "base-head", icon(B$icone), span(B$titre)),
          div(class = "base-meta", tags$code(B$objet), " · ", tr("accueil.une_ligne"), " ", B$ligne),
          if (nzchar(B$description)) div(class = "base-desc", B$description),
          div(class = "base-chiffres",
              lapply(names(chiffres), function(n) div(div(class = "bc-val", chiffres[[n]]),
                                                     div(class = "bc-lab", n)))),
          if (nzchar(B$source)) div(class = "base-source", tr("accueil.source"), " ", B$source),
          if (identical(cur, b)) div(class = "base-active", icon("check"), " ", tr("accueil.selectionnee"))
        )
      }
      div(class = "bases", lapply(names(BASES), carte_base))
    })
    observeEvent(input$choisir, {
      if (length(BASES) <= 3)
        updateRadioButtons(main_session, base_input_id, selected = input$choisir)
      else
        updateSelectInput(main_session, base_input_id, selected = input$choisir)
    })
    reactive(input$tour)
  })
}

# « Deux bases de données », « Trois bases de données »…
nombre_bases_titre <- function(n = length(BASES)) {
  if (n >= 1 && n <= 10) tr(paste0("accueil.bases", n)) else tr("accueil.basesN", n = n)
}
