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
    title = tagList(icon("house"), "Accueil"), value = "accueil",
    div(class = "accueil",
        div(class = "hero",
            div(class = "hero-kicker", "Introduction aux bases de données avec R"),
            h1("Atelier R"),
            p(class = "hero-lead",
              "Apprendre, s'entraîner et découvrir l'analyse d'une base de données avec R et le tidyverse, ",
              "à son rythme, depuis n'importe quel navigateur. Rien à installer : le code s'exécute sur le serveur."),
            div(class = "d-flex flex-wrap gap-2",
                actionButton(ns("tour"), tagList(icon("compass"), "Visite guidée"),
                             class = "btn-primary"),
                actionButton(ns("go_cours"), tagList("Commencer le cours", icon("arrow-right")),
                             class = "btn-outline-primary"))),

        h3(class = "section-title", "Quatre façons de travailler"),
        div(class = "volets",
            volet("cours", "book-open", "Cours",
                  "Les leçons du cours, carte par carte : l'explication, le code, le résultat, le commentaire. Jusqu'à une étude de cas complète."),
            volet("decouverte", "flask", "Découverte",
                  "Modifiez le code des exemples et observez ce qui change. Un bac à sable libre pour tester vos propres idées."),
            volet("exercices", "pen-to-square", "Exercices",
                  "Des questions de plus en plus difficiles, avec indice, vérification automatique de votre résultat et correction commentée."),
            volet("dashboard", "chart-line", "Dashboard",
                  "Un tableau de bord interactif écrit en R : ce que vous saurez faire avec les outils du cours.")),

        h3(class = "section-title", nombre_bases_titre()),
        p(class = "text-muted", "Choisissez la base en haut de l'écran : tous les volets s'adaptent."),
        uiOutput(ns("bases")),

        h3(class = "section-title", "Bon à savoir"),
        div(class = "savoir",
            div(icon("shield-halved"),
                div(tags$strong("Un espace protégé. "),
                    "Votre code s'exécute dans un environnement isolé : seules les fonctions du cours sont autorisées, et vous ne pouvez rien casser. Les bases d'origine restent intactes.")),
            div(icon("floppy-disk"),
                div(tags$strong("Votre progression reste dans votre navigateur. "),
                    "Les exercices réussis sont mémorisés sur cet ordinateur, rien n'est envoyé à l'enseignant.")),
            div(icon("laptop-code"),
                div(tags$strong("Et dans RStudio ? "),
                    "Tout le code de l'atelier fonctionne tel quel dans RStudio, après ",
                    tags$code("library(tidyverse)"), " et l'import de la base avec ",
                    tags$code("read_csv2()"), " ou ", tags$code("read_csv()"), ".")))
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
        B <- BASES[[b]]; D <- B$data
        chiffres <- c(stats::setNames(list(format(nrow(D), big.mark = " ")), B$nom_lignes),
                      list(variables = ncol(D)),
                      lapply(B$compter, function(col)
                        if (col %in% names(D)) dplyr::n_distinct(D[[col]]) else "?"))
        tags$button(
          type = "button", class = paste("base-card", if (identical(cur, b)) "active"),
          onclick = sprintf("Shiny.setInputValue('%s', '%s', {priority: 'event'})", session$ns("choisir"), b),
          div(class = "base-head", icon(B$icone), span(B$titre)),
          div(class = "base-meta", tags$code(B$objet), " · une ligne = ", B$ligne),
          if (nzchar(B$description)) div(class = "base-desc", B$description),
          div(class = "base-chiffres",
              lapply(names(chiffres), function(n) div(div(class = "bc-val", chiffres[[n]]),
                                                     div(class = "bc-lab", n)))),
          if (nzchar(B$source)) div(class = "base-source", "Source : ", B$source),
          if (identical(cur, b)) div(class = "base-active", icon("check"), " Base sélectionnée")
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
  mots <- c("Une base", "Deux bases", "Trois bases", "Quatre bases", "Cinq bases",
            "Six bases", "Sept bases", "Huit bases", "Neuf bases", "Dix bases")
  paste(if (n >= 1 && n <= 10) mots[n] else paste(n, "bases"), "de données")
}
