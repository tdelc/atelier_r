# ============================================================================
# render.R — affichage : code R coloré, résultats, markdown avec encadrés
# ============================================================================

esc <- function(x) htmltools::htmlEscape(x)

# --- Coloration syntaxique ------------------------------------------------------
# On s'appuie sur l'analyseur de R lui-même (getParseData) : chaque morceau du
# code reçoit une classe CSS selon son rôle (fonction, texte, nombre…).

TOKEN_CLASS <- c(
  SYMBOL_FUNCTION_CALL = "tk-fn", STR_CONST = "tk-str", NUM_CONST = "tk-num",
  COMMENT = "tk-com", SYMBOL_SUB = "tk-arg", SYMBOL = "tk-sym",
  LEFT_ASSIGN = "tk-op", RIGHT_ASSIGN = "tk-op", EQ_ASSIGN = "tk-op",
  PIPE = "tk-op", SPECIAL = "tk-op", EQ = "tk-op", NE = "tk-op", GT = "tk-op",
  GE = "tk-op", LT = "tk-op", LE = "tk-op", AND = "tk-op", OR = "tk-op",
  AND2 = "tk-op", OR2 = "tk-op", "'!'" = "tk-op", "'~'" = "tk-op",
  "'+'" = "tk-op", "'-'" = "tk-op", "'*'" = "tk-op", "'/'" = "tk-op",
  "'^'" = "tk-op", "'$'" = "tk-op", "':'" = "tk-op", "'?'" = "tk-op",
  IF = "tk-kw", ELSE = "tk-kw", FOR = "tk-kw", WHILE = "tk-kw",
  FUNCTION = "tk-kw", IN = "tk-kw", NULL_CONST = "tk-num", EQ_SUB = "tk-op"
)

highlight_r <- function(code) {
  pd <- tryCatch({
    p <- parse(text = code, keep.source = TRUE)
    utils::getParseData(p)
  }, error = function(e) NULL)
  if (is.null(pd) || !nrow(pd)) return(esc(code))
  pd <- pd[pd$terminal, , drop = FALSE]
  pd <- pd[order(pd$line1, pd$col1), , drop = FALSE]

  out <- character()
  pos <- 1L
  n <- nchar(code)
  for (i in seq_len(nrow(pd))) {
    txt <- pd$text[i]
    if (!nzchar(txt)) next
    at <- regexpr(txt, substr(code, pos, n), fixed = TRUE)
    if (at < 0) next
    start <- pos + at - 1L
    if (start > pos) out <- c(out, esc(substr(code, pos, start - 1L)))
    cls <- TOKEN_CLASS[pd$token[i]]
    if (pd$token[i] == "NUM_CONST" && txt %in% c("TRUE", "FALSE", "NA", "NULL"))
      cls <- "tk-num"
    piece <- esc(txt)
    out <- c(out, if (is.na(cls)) piece else sprintf('<span class="%s">%s</span>', cls, piece))
    pos <- start + nchar(txt)
  }
  if (pos <= n) out <- c(out, esc(substr(code, pos, n)))
  paste(out, collapse = "")
}

code_block <- function(code, copy = TRUE) {
  htmltools::div(
    class = "code-wrap",
    if (copy) htmltools::tags$button(
      type = "button", class = "btn-copier", title = "Copier le code",
      `data-code` = code, htmltools::HTML("Copier")
    ),
    htmltools::tags$pre(class = "code-r", .noWS = c("inside", "outside"),
                        htmltools::tags$code(.noWS = c("inside", "outside"),
                                             htmltools::HTML(highlight_r(code))))
  )
}

# --- Résultats d'exécution -------------------------------------------------------
# show_source = TRUE : on intercale les commandes et leurs résultats, comme dans
# un document R Markdown (et comme dans le syllabus).

render_run <- function(run, show_source = TRUE, copy = FALSE) {
  if (length(run$blocked)) {
    return(htmltools::div(
      class = "res-blocked",
      htmltools::tags$strong("Code non exécuté"),
      htmltools::tags$ul(lapply(run$blocked, htmltools::tags$li))
    ))
  }
  pieces <- list()
  buf_src <- character()
  flush_src <- function() {
    if (length(buf_src) && show_source)
      pieces[[length(pieces) + 1]] <<- code_block(paste(buf_src, collapse = "\n"), copy = copy)
    buf_src <<- character()
  }
  for (it in run$items) {
    if (it$type == "source") { buf_src <- c(buf_src, it$text); next }
    flush_src()
    pieces[[length(pieces) + 1]] <- switch(
      it$type,
      output  = htmltools::tags$pre(class = "code-out", .noWS = "inside", prefix_lines(it$text)),
      plot    = htmltools::div(class = "code-plot", htmltools::tags$img(src = it$src, alt = "Graphique")),
      html    = viewer_frame(it$html),
      message = htmltools::HTML(sprintf('<div class="res-message">%s</div>', esc(it$text))),
      warning = htmltools::HTML(sprintf('<div class="res-warning"><strong>Avertissement : </strong>%s</div>', esc(it$text))),
      error   = htmltools::div(
        class = "res-error",
        htmltools::HTML(sprintf('<div class="res-msg"><strong>Erreur : </strong>%s</div>', esc(it$text))),
        if (nzchar(it$hint %||% "")) htmltools::div(class = "res-hint", it$hint)
      )
    )
  }
  flush_src()
  htmltools::tagList(pieces)
}

prefix_lines <- function(x) {
  lines <- strsplit(x, "\n", fixed = TRUE)[[1]]
  paste0("#> ", lines, collapse = "\n")
}

`%||%` <- function(a, b) if (is.null(a)) b else a

# --- Markdown avec encadrés -------------------------------------------------------
# Les encadrés reprennent ceux du mémo :
#   ::: usage   (À quoi ça sert ?)     ::: piege  (attention)
#   ::: note    (lecture / conseil)    ::: etape  (démarche)

md_to_html <- function(text) {
  if (is.null(text) || !nzchar(trimws(text))) return(htmltools::HTML(""))
  lines <- strsplit(text, "\n", fixed = TRUE)[[1]]
  out <- character(); buf <- character(); box <- NULL; box_buf <- character()
  render <- function(x) commonmark::markdown_html(paste(x, collapse = "\n"),
                                                  extensions = TRUE)
  for (l in lines) {
    if (is.null(box) && grepl("^:::\\s*[a-z]+", l)) {
      out <- c(out, render(buf)); buf <- character()
      box <- sub("^:::\\s*([a-z]+).*$", "\\1", l)
    } else if (!is.null(box) && grepl("^:::\\s*$", l)) {
      out <- c(out, sprintf('<div class="callout callout-%s">%s</div>', box, render(box_buf)))
      box <- NULL; box_buf <- character()
    } else if (!is.null(box)) {
      box_buf <- c(box_buf, l)
    } else {
      buf <- c(buf, l)
    }
  }
  if (!is.null(box)) out <- c(out, sprintf('<div class="callout callout-%s">%s</div>', box, render(box_buf)))
  out <- c(out, render(buf))
  htmltools::HTML(paste(out, collapse = "\n"))
}
