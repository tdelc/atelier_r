# ============================================================================
# preparer_donnees.R — à lancer UNE fois, depuis le dossier de l'application
#
# Transforme les deux CSV du cours en fichiers .rds, plus rapides à charger
# au démarrage de l'application. Les bases sont importées EXACTEMENT comme les
# étudiants le font dans RStudio (read_csv2 / read_csv), pour que ce qu'ils
# voient dans l'application soit identique à ce qu'ils verront chez eux.
#
#   Rscript data-raw/preparer_donnees.R chemin/FD_NAIS_2021.csv chemin/meteo_2010_2026.csv
# ============================================================================

suppressPackageStartupMessages(library(tidyverse))

args <- commandArgs(trailingOnly = TRUE)
fichier_nais  <- if (length(args) >= 1) args[1] else "FD_NAIS_2021.csv"
fichier_meteo <- if (length(args) >= 2) args[2] else "meteo_2010_2026.csv"

BDD_NAIS  <- read_csv2(fichier_nais, show_col_types = FALSE)
BDD_METEO <- read_csv(fichier_meteo, show_col_types = FALSE, name_repair = "unique_quiet")

saveRDS(BDD_NAIS,  "data/BDD_NAIS.rds")
saveRDS(BDD_METEO, "data/BDD_METEO.rds")

cat("BDD_NAIS  :", nrow(BDD_NAIS),  "lignes x", ncol(BDD_NAIS),  "colonnes\n")
cat("BDD_METEO :", nrow(BDD_METEO), "lignes x", ncol(BDD_METEO), "colonnes\n")

# --- Tables complémentaires (leçons « Ajouter et fusionner » et « Cartes ») --
# INFO_DEPARTEMENTS : une ligne par département (nom, région), à fusionner
# avec BDD_NAIS. Importée comme dans le cours, avec read_csv().
INFO_DEPARTEMENTS <- read_csv("data-raw/departements-france.csv",
                              col_types = cols(.default = col_character()))
saveRDS(INFO_DEPARTEMENTS, "data/INFO_DEPARTEMENTS.rds")

# CARTE_DEP : contours des départements sous forme de tableau de points
# (une ligne = un sommet d'un polygone), pour dessiner une carte avec
# ggplot2 + geom_polygon(), sans paquet de cartographie.
geo <- jsonlite::fromJSON("data/departements.geojson", simplifyVector = FALSE)
morceaux <- list(); k <- 0
for (f in geo$features) {
  polys <- if (f$geometry$type == "Polygon") list(f$geometry$coordinates) else f$geometry$coordinates
  for (p in seq_along(polys)) {
    anneau <- polys[[p]][[1]]                     # contour extérieur
    k <- k + 1
    morceaux[[k]] <- tibble(code_insee = f$properties$code,
                            nom = f$properties$nom,
                            groupe = paste(f$properties$code, p, sep = "_"),
                            long = vapply(anneau, function(pt) pt[[1]], 0),
                            lat  = vapply(anneau, function(pt) pt[[2]], 0))
  }
}
CARTE_DEP <- bind_rows(morceaux)
saveRDS(CARTE_DEP, "data/CARTE_DEP.rds")
cat("INFO_DEPARTEMENTS :", nrow(INFO_DEPARTEMENTS), "lignes ; CARTE_DEP :", nrow(CARTE_DEP), "points\n")
