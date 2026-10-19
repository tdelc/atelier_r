# ============================================================================
# content.R — lecture des contenus pédagogiques (fichiers markdown)
#
# Tout le contenu est dans le dossier content/ : on peut corriger un texte,
# ajouter une carte ou un exercice sans toucher au code R de l'application.
#
# LEÇON (content/cours/<base>/NN-nom.md) :
#
#   ---
#   titre: Filtrer les lignes
#   resume: Une phrase de présentation
#   ---
#
#   # Titre de la carte
#   Texte en markdown…
#   ```r
#   BDD_NAIS |> filter(DEPNAIS == "59")
#   ```
#   Commentaire après le résultat… (encadrés ::: usage / piege / note / etape)
#
#   Blocs de code :  ```r         exécuté et affiché
#                    ```r norun   affiché, non exécuté (ex. setwd)
#                    ```r setup   exécuté, non affiché
#
# PISTES DE DÉCOUVERTE (content/decouverte/<base>.md) : même format ; le
# premier bloc ```r est le code de départ, le texte qui suit les idées à tester.
#
# EXERCICES (content/exercices/<base>.md) : une section « # » par exercice,
# des métadonnées (niveau, theme, verif), puis des sous-sections « ## » :
# Énoncé, Indice, Préparation, Code de départ, Correction, Commentaire.
# ============================================================================

read_utf8 <- function(path) readLines(path, warn = FALSE, encoding = "UTF-8")

# Sépare l'en-tête YAML simple (clé: valeur) du corps
split_front_matter <- function(lines) {
  meta <- list()
  if (length(lines) && grepl("^---\\s*$", lines[1])) {
    end <- which(grepl("^---\\s*$", lines))[2]
    if (!is.na(end)) {
      for (l in lines[2:(end - 1)]) {
        if (grepl("^[A-Za-z_]+\\s*:", l)) {
          k <- trimws(sub(":.*$", "", l))
          meta[[k]] <- trimws(sub("^[^:]*:", "", l))
        }
      }
      lines <- lines[-(1:end)]
    }
  }
  list(meta = meta, lines = lines)
}

# Découpe en sections selon un niveau de titre (# ou ##), en ignorant les
# lignes à l'intérieur des blocs de code (les commentaires R commencent aussi
# par #).
split_sections <- function(lines, level = 1) {
  pattern <- paste0("^", strrep("#", level), "\\s+\\S")
  in_code <- FALSE
  starts <- integer()
  for (i in seq_along(lines)) {
    if (grepl("^```", lines[i])) in_code <- !in_code
    if (!in_code && grepl(pattern, lines[i]) &&
        !grepl(paste0("^", strrep("#", level + 1)), lines[i]))
      starts <- c(starts, i)
  }
  if (!length(starts)) return(list())
  ends <- c(starts[-1] - 1L, length(lines))
  lapply(seq_along(starts), function(k) {
    s <- starts[k]; e <- ends[k]
    list(title = trimws(sub(pattern = paste0("^", strrep("#", level), "\\s+"), "", lines[s])),
         lines = if (e > s) lines[(s + 1):e] else character())
  })
}

# Découpe un corps en segments texte / code
split_segments <- function(lines) {
  segs <- list(); buf <- character(); in_code <- FALSE; mode <- "run"; code <- character()
  push_text <- function() {
    txt <- paste(buf, collapse = "\n")
    if (nzchar(trimws(txt))) segs[[length(segs) + 1]] <<- list(type = "text", md = txt)
    buf <<- character()
  }
  for (l in lines) {
    if (!in_code && grepl("^```\\s*\\{?r", l)) {
      push_text()
      in_code <- TRUE; code <- character()
      mode <- if (grepl("norun", l)) "norun" else if (grepl("setup", l)) "setup" else "run"
    } else if (in_code && grepl("^```\\s*$", l)) {
      in_code <- FALSE
      segs[[length(segs) + 1]] <- list(type = "code", code = paste(code, collapse = "\n"), mode = mode)
    } else if (in_code) {
      code <- c(code, l)
    } else {
      buf <- c(buf, l)
    }
  }
  push_text()
  segs
}

# Métadonnées « cle: valeur » en tête de section
take_meta <- function(lines) {
  meta <- list()
  while (length(lines) && (grepl("^[a-z_]+:\\s", lines[1]) || !nzchar(trimws(lines[1])))) {
    if (nzchar(trimws(lines[1]))) {
      meta[[trimws(sub(":.*$", "", lines[1]))]] <- trimws(sub("^[^:]*:", "", lines[1]))
    }
    lines <- lines[-1]
  }
  list(meta = meta, lines = lines)
}

read_lesson <- function(path) {
  fm <- split_front_matter(read_utf8(path))
  cards <- lapply(split_sections(fm$lines, 1), function(s) {
    tm <- take_meta(s$lines)
    list(title = s$title, meta = tm$meta, segments = split_segments(tm$lines))
  })
  id <- tools::file_path_sans_ext(basename(path))
  list(id = id,
       titre = fm$meta$titre %||% id,
       resume = fm$meta$resume %||% "",
       partie = fm$meta$partie %||% "",
       cards = cards)
}

read_course <- function(dir) {
  files <- sort(list.files(dir, pattern = "\\.md$", full.names = TRUE))
  lessons <- lapply(files, read_lesson)
  names(lessons) <- vapply(lessons, `[[`, "", "id")
  lessons
}

# Code exécuté (run + setup) d'une carte : utile pour reconstituer l'état
card_code <- function(card, modes = c("run", "setup")) {
  segs <- Filter(function(s) s$type == "code" && s$mode %in% modes, card$segments)
  vapply(segs, `[[`, "", "code")
}

# --- Pistes de découverte ---------------------------------------------------------

read_pistes <- function(path) {
  fm <- split_front_matter(read_utf8(path))
  lapply(split_sections(fm$lines, 1), function(s) {
    tm <- take_meta(s$lines)
    segs <- split_segments(tm$lines)
    is_code <- vapply(segs, function(x) x$type == "code", TRUE)
    setup <- vapply(Filter(function(x) x$type == "code" && x$mode == "setup", segs),
                    `[[`, "", "code")
    first_run <- which(vapply(segs, function(x) x$type == "code" && x$mode == "run", TRUE))[1]
    before <- if (is.na(first_run)) segs else segs[seq_len(first_run - 1)]
    after  <- if (is.na(first_run)) list() else segs[-seq_len(first_run)]
    txt <- function(l) paste(vapply(Filter(function(x) x$type == "text", l), `[[`, "", "md"),
                             collapse = "\n\n")
    list(title = s$title, meta = tm$meta,
         description = txt(before),
         code = if (is.na(first_run)) "" else segs[[first_run]]$code,
         setup = paste(setup, collapse = "\n"),
         idees = txt(after))
  })
}

# --- Exercices -------------------------------------------------------------------

read_exercises <- function(path) {
  fm <- split_front_matter(read_utf8(path))
  exs <- lapply(split_sections(fm$lines, 1), function(s) {
    tm <- take_meta(s$lines)
    subs <- split_sections(tm$lines, 2)
    get_sub <- function(name) {
      k <- which(tolower(vapply(subs, `[[`, "", "title")) == tolower(name))
      if (!length(k)) return(NULL)
      subs[[k[1]]]$lines
    }
    code_of <- function(lines) {
      if (is.null(lines)) return("")
      segs <- Filter(function(x) x$type == "code", split_segments(lines))
      paste(vapply(segs, `[[`, "", "code"), collapse = "\n")
    }
    text_of <- function(lines) if (is.null(lines)) "" else paste(lines, collapse = "\n")
    list(
      title = s$title,
      niveau = as.integer(tm$meta$niveau %||% 1),
      theme = tm$meta$theme %||% "",
      verif = tm$meta$verif %||% "valeur",
      enonce = text_of(get_sub("Énoncé")),
      indice = text_of(get_sub("Indice")),
      preparation = code_of(get_sub("Préparation")),
      depart = code_of(get_sub("Code de départ")),
      correction = code_of(get_sub("Correction")),
      commentaire = text_of(get_sub("Commentaire"))
    )
  })
  for (i in seq_along(exs)) exs[[i]]$id <- sprintf("ex%02d", i)
  exs
}

# --- Visite guidée (même format que vizsurvey) ---------------------------------

read_tour <- function(path) {
  in_comment <- FALSE
  raw <- read_utf8(path); keep_lines <- character()
  for (l in raw) {
    if (grepl("^<!--", l)) in_comment <- TRUE
    if (!in_comment) keep_lines <- c(keep_lines, l)
    if (grepl("-->\\s*$", l)) in_comment <- FALSE
  }
  lapply(split_sections(keep_lines, 1), function(s) {
    tm <- take_meta(s$lines)
    body <- tm$lines
    title <- NULL
    if (length(body) && grepl("^##\\s+", body[1])) {
      title <- trimws(sub("^##\\s+", "", body[1])); body <- body[-1]
    }
    list(tab = tm$meta$tab, target = tm$meta$target, title = title,
         body = paste(body, collapse = "\n"))
  })
}

read_dictionary <- function(path) {
  d <- utils::read.csv(path, stringsAsFactors = FALSE, encoding = "UTF-8",
                       fileEncoding = "UTF-8", check.names = FALSE)
  d
}
