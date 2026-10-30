# ============================================================================
# viewer.R — le « Viewer » de l'atelier : les résultats qui sont des pages HTML
#
# Dans RStudio, certains objets (un tableau gt…) ne s'affichent pas dans la
# console mais dans le Viewer. Ici, c'est pareil : quand une commande renvoie
# un tel objet, son HTML est affiché sous le code, dans un cadre isolé
# (iframe), partout où du code s'exécute : cours, découverte, exercices.
# Aucun réglage n'est nécessaire dans les fichiers de contenu.
#
# Le cadre isolé n'exécute aucun JavaScript et ne charge rien depuis
# Internet : même si un texte du tableau contient du HTML (md(), libellés…),
# il ne peut pas agir sur la page de l'atelier.
#
# Pour ajouter un type d'objet : une entrée dans VIEWER_TYPES, « classe R =
# fonction qui renvoie le HTML (texte) ». Les objets qui ont besoin de
# JavaScript (htmlwidgets : leaflet, plotly…) ne s'affichent pas dans ce cadre.
# ============================================================================

VIEWER_TYPES <- list(
  gt_tbl = function(x) as.character(gt::as_raw_html(x, inline_css = FALSE))
)

# HTML d'un objet à afficher dans le Viewer, ou NULL si ce n'en est pas un
viewer_html <- function(x) {
  for (cl in names(VIEWER_TYPES)) {
    if (inherits(x, cl)) return(VIEWER_TYPES[[cl]](x))
  }
  NULL
}

# Page complète placée dans l'iframe : la politique de sécurité (CSP) interdit
# scripts et ressources externes ; seuls les styles du tableau et les images
# intégrées (data:) sont permis.
viewer_page <- function(html) {
  paste0(
    '<!DOCTYPE html><html><head><meta charset="utf-8">',
    '<meta http-equiv="Content-Security-Policy" content="default-src \'none\'; ',
    'style-src \'unsafe-inline\'; img-src data:; font-src data:">',
    '<style>html,body{margin:0;padding:0;background:#fff;}',
    'body{padding:.4rem .6rem;font-family:system-ui,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;}</style>',
    '</head><body>', html, '</body></html>'
  )
}

# L'iframe : `sandbox` sans « allow-scripts » bloque tout script ;
# « allow-same-origin » permet seulement à la page de l'atelier de mesurer la
# hauteur du tableau pour ajuster le cadre (voir atelier.js).
viewer_frame <- function(html) {
  htmltools::div(
    class = "code-viewer",
    htmltools::tags$iframe(
      class = "viewer-frame", title = "Viewer",
      sandbox = "allow-same-origin", referrerpolicy = "no-referrer",
      srcdoc = viewer_page(html)
    )
  )
}
