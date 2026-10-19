# ============================================================================
# mod_tour.R — visite guidée (même principe que vizsurvey)
#
# Les étapes sont écrites dans content/tour_fr.md :
#
#   # 03-lecons
#   tab: cours
#   target: #cours-lessons
#   ## Titre de la bulle
#   Texte en markdown. {base} est remplacé par la base choisie.
#
#   tab    : onglet à ouvrir (facultatif ; valeur d'un nav_panel)
#   target : sélecteur CSS de l'élément à entourer (facultatif -> bulle centrée)
#
# Le fichier est relu à chaque lancement : on peut le corriger sans
# redémarrer l'application. Flèches du clavier et Échap fonctionnent.
# ============================================================================

tour_assets <- function() {
  tags$script(HTML("
  (function() {
    var box = null, target = null;
    function send(a) { Shiny.setInputValue('atelier_tour_action', {action: a, ts: Date.now()}, {priority: 'event'}); }
    function build() {
      box = document.createElement('div');
      box.className = 'tour-box';
      document.body.appendChild(box);
      box.addEventListener('click', function(e) {
        var b = e.target.closest('[data-tour]'); if (b) send(b.dataset.tour);
      });
      document.addEventListener('keydown', function(e) {
        if (!box || box.style.display !== 'block') return;
        if (e.key === 'Escape') send('quit');
        if (e.key === 'ArrowRight') { e.stopPropagation(); send('next'); }
        if (e.key === 'ArrowLeft') { e.stopPropagation(); send('prev'); }
      }, true);
    }
    function unhighlight() { if (target) { target.classList.remove('tour-target'); target = null; } }
    function position(el) {
      var m = 12, w = box.offsetWidth, h = box.offsetHeight, top, left;
      if (el) {
        var r = el.getBoundingClientRect();
        top = r.bottom + m; left = r.left;
        if (top + h > window.innerHeight - m) top = Math.max(m, r.top - h - m);
        if (left + w > window.innerWidth - m) left = Math.max(m, window.innerWidth - w - m);
      } else {
        top = Math.max(m, (window.innerHeight - h) / 2); left = (window.innerWidth - w) / 2;
      }
      box.style.top = top + 'px'; box.style.left = Math.max(m, left) + 'px';
    }
    $(document).on('shiny:connected', function() {
      Shiny.addCustomMessageHandler('atelier_tour', function(msg) {
        if (!box) build();
        if (msg.action === 'stop') { unhighlight(); box.style.display = 'none'; return; }
        unhighlight();
        setTimeout(function() {
          var el = msg.selector ? document.querySelector(msg.selector) : null;
          if (el && el.offsetParent === null) el = null;
          if (el) { el.classList.add('tour-target'); target = el; el.scrollIntoView({behavior: 'smooth', block: 'center'}); }
          var last = msg.step >= msg.total;
          box.innerHTML = (msg.title ? '<h5>' + msg.title + '</h5>' : '') + msg.html +
            '<div class=\"tour-foot\"><span class=\"tour-step\">Étape ' + msg.step + ' / ' + msg.total + '</span>' +
            '<button class=\"btn btn-sm btn-link\" data-tour=\"quit\">Quitter</button>' +
            (msg.step > 1 ? '<button class=\"btn btn-sm btn-outline-secondary\" data-tour=\"prev\">Précédent</button>' : '') +
            '<button class=\"btn btn-sm btn-primary\" data-tour=\"next\">' + (last ? 'Terminer' : 'Suivant') + '</button></div>';
          box.style.display = 'block';
          position(el);
          setTimeout(function() { position(el); }, 450);
        }, msg.delay || 200);
      });
    });
  })();
  "))
}

mod_tour_server <- function(start, base, main_session) {
  rv <- reactiveValues(steps = list(), i = 0)
  session <- main_session

  stop_tour <- function() {
    rv$i <- 0
    session$sendCustomMessage("atelier_tour", list(action = "stop"))
  }
  show_step <- function(i) {
    s <- rv$steps[[i]]
    if (!is.null(s$tab) && nzchar(s$tab)) bslib::nav_select("onglets", s$tab, session = session)
    vals <- list(base = BASES[[base()]]$objet, titre_base = BASES[[base()]]$titre)
    fill <- function(x) { for (k in names(vals)) x <- gsub(paste0("{", k, "}"), vals[[k]], x, fixed = TRUE); x }
    session$sendCustomMessage("atelier_tour", list(
      action = "show",
      selector = s$target %||% "",
      title = fill(s$title %||% ""),
      html = as.character(md_to_html(fill(s$body))),
      step = i, total = length(rv$steps),
      delay = if (is.null(s$tab)) 150 else 550
    ))
  }
  observeEvent(start(), {
    rv$steps <- read_tour("content/tour_fr.md")
    if (!length(rv$steps)) return()
    rv$i <- 1; show_step(1)
  })
  observeEvent(session$input$atelier_tour_action, {
    req(rv$i > 0)
    a <- session$input$atelier_tour_action$action
    if (identical(a, "quit")) return(stop_tour())
    i <- rv$i + if (identical(a, "prev")) -1 else 1
    if (i < 1 || i > length(rv$steps)) return(stop_tour())
    rv$i <- i; show_step(i)
  })
}
