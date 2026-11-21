# ============================================================================
# Tests du chargement des bases (dossier bases/) :
#  - chaque base a une description valide, ses données et son contenu
#  - chaque tableau de bord se construit
#  - une nouvelle base minimale (base.txt + un CSV) est reconnue
#   Rscript tests/test_bases.R
# ============================================================================
suppressPackageStartupMessages({
  library(shiny); library(dplyr); library(tidyr); library(ggplot2); library(lubridate)
})
for (f in list.files("R", full.names = TRUE)) source(f, encoding = "UTF-8")
ok <- 0; ko <- 0
expect <- function(desc, cond) if (isTRUE(cond)) ok <<- ok + 1 else { ko <<- ko + 1; cat("ÉCHEC :", desc, "\n") }

sandbox_init(); load_bases(); load_dashboards()
load_cours(); load_pistes(); load_exercices()
cat("Bases trouvées :", paste(names(BASES), collapse = ", "), "\n")
expect("au moins une base", length(BASES) >= 1)
expect("bases désactivées non chargées", !any(c("naissances", "meteo") %in% names(BASES)) ||
         all(vapply(file.path("bases", intersect(c("naissances", "meteo"), names(BASES))), base_active, TRUE)))
for (b in names(BASES)) {
  B <- BASES[[b]]
  expect(paste(b, ": données = tableau"), is.data.frame(B$data) && nrow(B$data) > 0)
  expect(paste(b, ": dictionnaire"), is.data.frame(B$dico) && "variable" %in% names(B$dico))
  expect(paste(b, ": colonnes à compter présentes"), all(B$compter %in% names(B$data)))
  expect(paste(b, ": objet dans le bac à sable"), B$objet %in% names(base_datasets(b)))
  if (est_python(b)) {
    expect(paste(b, ": dossier Python"), dir.exists(base_path(b, B$dossier_python)))
    expect(paste(b, ": leçons en Python"), all(vapply(unlist(lapply(cours_de(b, "fr"), function(L)
      Filter(function(s) s$type == "code", unlist(lapply(L$cards, `[[`, "segments"), recursive = FALSE))),
      recursive = FALSE), function(s) s$lang == "python", TRUE)))
  }
  if (!est_python(b)) expect(paste(b, ": code libre exécutable"),
         { r <- sandbox_run(B$code_libre, sandbox_new_env(base_datasets(b))); isTRUE(r$ok) && !length(r$blocked) })
  if (!is.null(B$dash_env)) {
    ui <- tryCatch(B$dash_env$dashboard_ui(b), error = function(e) e)
    expect(paste(b, ": interface du dashboard"), !inherits(ui, "error"))
    if (exists("DASH_CODE", envir = B$dash_env, inherits = FALSE))
      cat(sprintf("  %s : dashboard, %d graphiques\n", b, length(B$dash_env$DASH_CODE)))
  }
  cat(sprintf("  %s : %d leçons, %d pistes, %d exercices\n", b, length(cours_de(b, "fr")),
              length(pistes_de(b, "fr")), length(exercices_de(b, "fr"))))
}
if (a_des_dashboards()) expect("interface de l'onglet Dashboard", !inherits(tryCatch(mod_dashboard_ui("dashboard"), error = function(e) e), "error"))
expect("configuration Python", is.list(py_config("fr")) && is.list(py_config("nl")))
expect("textes d'interface", nzchar(tr("cours.suivante", lang = "nl")) && tr("cours.n_cartes", n = 3, lang = "en") == "3 cards")
expect("sélecteur de base", !inherits(tryCatch(base_selector("base"), error = function(e) e), "error"))

# --- Une nouvelle base minimale, dans un dossier temporaire ---------------------
app <- file.path(tempdir(), "app_test"); unlink(app, recursive = TRUE)
dir.create(file.path(app, "bases", "fruits"), recursive = TRUE)
dir.create(file.path(app, "data"))
writeLines(c("# une base de test", "objet: BDD_FRUITS", "fichier: fruits.csv",
             "titre: Des fruits", "compter: couleurs = couleur", "ordre: 1"),
           file.path(app, "bases", "fruits", "base.txt"))
writeLines(c("nom;couleur;prix", "pomme;rouge;2,5", "banane;jaune;1,2", "fraise;rouge;4"),
           file.path(app, "bases", "fruits", "fruits.csv"))
# une seconde base sans base.txt : ignorée
dir.create(file.path(app, "bases", "brouillon"))
# une troisième, désactivée (« actif: non ») : ignorée, sauf si on demande tout
dir.create(file.path(app, "bases", "archive"))
writeLines(c("objet: BDD_ARCHIVE", "fichier: archive.csv", "actif: non"), file.path(app, "bases", "archive", "base.txt"))
writeLines(c("a;b", "1;2"), file.path(app, "bases", "archive", "archive.csv"))
expect("base désactivée listée sur demande", setequal(basename(list_bases(app, inactives = TRUE)), c("archive", "fruits")))
BASES_SAUVE <- BASES
load_bases(app)
expect("nouvelle base trouvée", identical(names(BASES), "fruits"))
expect("CSV lu avec le bon séparateur", identical(BASES$fruits$data$prix, c(2.5, 1.2, 4)))
expect("dictionnaire automatique", identical(BASES$fruits$dico$variable, c("nom", "couleur", "prix")))
expect("libellé par défaut", identical(BASES$fruits$libelle, "fruits"))
expect("code libre par défaut", grepl("BDD_FRUITS", BASES$fruits$code_libre))
r <- sandbox_run('BDD_FRUITS |> filter(couleur == "rouge") |> summarise(m = mean(prix))',
                 sandbox_new_env(base_datasets("fruits")))
expect("nouvelle base utilisable dans le bac à sable", isTRUE(r$ok) && abs(r$value$m - 3.25) < 1e-9)
expect("message read_csv cite la base", any(grepl("BDD_FRUITS", sandbox_check('read_csv("x.csv")'))))
expect("réglages par défaut sans atelier.txt", identical(atelier_reglages(app)$titre, "Atelier R"))
writeLines(c("titre: Mon atelier", "icone: python"), file.path(app, "atelier.txt"))
expect("réglages lus dans atelier.txt", identical(atelier_reglages(app), list(titre = "Mon atelier", icone = "python")))
BASES <- BASES_SAUVE

cat(sprintf("\n%d tests réussis, %d échecs\n", ok, ko)); if (ko) quit(status = 1)
