# ============================================================================
# data.R — les deux bases et leur description
# ============================================================================

BASES <- list(
  naissances = list(
    id       = "naissances",
    objet    = "BDD_NAIS",
    libelle  = "Naissances",
    titre    = "Naissances en France, 2021",
    source   = "INSEE, fichier détail de l'état civil",
    ligne    = "une naissance",
    fichier  = "data/BDD_NAIS.rds",
    icone    = "baby"
  ),
  meteo = list(
    id       = "meteo",
    objet    = "BDD_METEO",
    libelle  = "Météo",
    titre    = "Météo quotidienne de 13 villes, 2010-2026",
    source   = "meteostat.net",
    ligne    = "une ville × un jour",
    fichier  = "data/BDD_METEO.rds",
    icone    = "cloud-sun"
  )
)

# Chargées une seule fois au démarrage, partagées (en lecture) par toutes les
# sessions : chaque session travaille sur sa propre copie logique (R ne
# duplique réellement que les colonnes modifiées).
load_bases <- function(dir = ".") {
  for (b in names(BASES)) {
    BASES[[b]]$data <<- readRDS(file.path(dir, BASES[[b]]$fichier))
    BASES[[b]]$dico <<- read_dictionary(file.path(dir, "content/dictionnaires",
                                                   paste0(b, ".csv")))
  }
  invisible(BASES)
}

# Liste nommée « nom de l'objet R » = données, pour le bac à sable
base_datasets <- function(base) {
  stats::setNames(list(BASES[[base]]$data), BASES[[base]]$objet)
}

DEPARTEMENTS <- NULL
load_departements <- function(dir = ".") {
  DEPARTEMENTS <<- utils::read.csv(file.path(dir, "data/departements.csv"),
                                   colClasses = "character", encoding = "UTF-8",
                                   fileEncoding = "UTF-8")
}
