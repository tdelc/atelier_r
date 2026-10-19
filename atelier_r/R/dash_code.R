# ============================================================================
# dash_code.R — le code R de chaque graphique des tableaux de bord
#
# Le code est écrit ici sous forme de texte : il est EXÉCUTÉ pour produire le
# graphique ET AFFICHÉ tel quel quand l'étudiant clique sur « Voir le code ».
# Ce qu'il lit est donc exactement ce qui tourne.
#
# Objets disponibles dans ce code :
#   météo      : donnees (BDD_METEO filtrée sur les années choisies), ville,
#                ville2 (comparaison, "" si aucune), annee_coupure
#   naissances : donnees (BDD_NAIS filtrée sur le territoire), BDD_NAIS,
#                departements (contours GeoJSON), indicateur
# ============================================================================

DASH_CODE <- list(meteo = list(), naissances = list())

# ---------------------------------------------------------------- MÉTÉO ------

DASH_CODE$meteo$bandes <- r"--(# Les « bandes climatiques » : une barre par année, colorée selon l'écart
# à la moyenne de la période (bleu = plus froid, rouge = plus chaud)
bandes <- donnees |>
  filter(name == ville) |>
  group_by(annee = year(date)) |>
  summarise(temp_moy = mean(temp, na.rm = TRUE)) |>
  mutate(ecart = temp_moy - mean(temp_moy))

g <- ggplot(bandes, aes(x = annee, y = 1, fill = ecart,
                        text = paste0(annee, " : ", round(temp_moy, 1), " °C (",
                                      sprintf("%+.1f", ecart), " °C)"))) +
  geom_tile() +
  scale_fill_gradient2(low = "#2166ac", mid = "white", high = "#b2182b") +
  scale_x_continuous(breaks = seq(2010, 2026, 2)) +
  labs(x = NULL, y = NULL, fill = "Écart (°C)") +
  theme_minimal() +
  theme(axis.text.y = element_blank(), panel.grid = element_blank())

ggplotly(g, tooltip = "text") |> hide_colorbar())--"

DASH_CODE$meteo$evolution <- r"--(evolution <- donnees |>
  filter(name %in% c(ville, ville2)) |>
  group_by(name, annee = year(date)) |>
  summarise(temp_moy = mean(temp, na.rm = TRUE), .groups = "drop")

g <- ggplot(evolution, aes(x = annee, y = temp_moy, colour = name)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  geom_smooth(method = "lm", formula = y ~ x, se = FALSE,
              linetype = "dashed", linewidth = 0.6) +
  scale_colour_manual(values = c("#1f3a5f", "#d9822b")) +
  labs(x = NULL, y = "Température moyenne (°C)", colour = NULL) +
  theme_minimal()

ggplotly(g) |> layout(legend = list(orientation = "h", y = -0.15)))--"

DASH_CODE$meteo$saisons <- r"--(# Le climat moyen mois par mois, avant et après l'année de coupure
climat <- donnees |>
  filter(name == ville) |>
  mutate(mois = month(date),
         periode = if_else(year(date) < annee_coupure,
                           paste("Avant", annee_coupure),
                           paste("Depuis", annee_coupure))) |>
  group_by(periode, mois) |>
  summarise(tmax_moy = mean(tmax, na.rm = TRUE), .groups = "drop")

g <- ggplot(climat, aes(x = mois, y = tmax_moy, colour = periode)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  scale_x_continuous(breaks = 1:12,
                     labels = c("Jan", "Fév", "Mar", "Avr", "Mai", "Juin",
                                "Juil", "Août", "Sep", "Oct", "Nov", "Déc")) +
  scale_colour_manual(values = c("#3b6ea5", "#d9822b")) +
  labs(x = NULL, y = "Température maximale moyenne (°C)", colour = NULL) +
  theme_minimal()

ggplotly(g) |> layout(legend = list(orientation = "h", y = -0.15)))--"

DASH_CODE$meteo$calendrier <- r"--(# Chaque case = un mois d'une année, colorée selon l'écart à la normale
# de ce mois (la moyenne de ce mois sur toute la période)
calendrier <- donnees |>
  filter(name == ville) |>
  mutate(annee = year(date), mois = month(date)) |>
  group_by(mois) |>
  mutate(normale = mean(tmax, na.rm = TRUE)) |>
  group_by(annee, mois) |>
  summarise(ecart = mean(tmax - normale, na.rm = TRUE), .groups = "drop")

g <- ggplot(calendrier, aes(x = mois, y = annee, fill = ecart,
                            text = paste0(mois, "/", annee, " : ",
                                          sprintf("%+.1f", ecart), " °C"))) +
  geom_tile(colour = "white") +
  scale_fill_gradient2(low = "#2166ac", mid = "#f7f7f7", high = "#b2182b") +
  scale_x_continuous(breaks = 1:12,
                     labels = c("J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D")) +
  scale_y_reverse(breaks = 2010:2026) +
  labs(x = NULL, y = NULL, fill = "Écart (°C)") +
  theme_minimal() +
  theme(panel.grid = element_blank())

ggplotly(g, tooltip = "text"))--"

DASH_CODE$meteo$chauds <- r"--(chauds <- donnees |>
  filter(name %in% c(ville, ville2)) |>
  group_by(name, annee = year(date)) |>
  summarise(jours_30 = sum(tmax >= 30, na.rm = TRUE), .groups = "drop")

g <- ggplot(chauds, aes(x = annee, y = jours_30, fill = name)) +
  geom_col(position = "dodge") +
  scale_fill_manual(values = c("#1f3a5f", "#d9822b")) +
  labs(x = NULL, y = "Jours à 30 °C ou plus", fill = NULL) +
  theme_minimal()

ggplotly(g) |> layout(legend = list(orientation = "h", y = -0.15)))--"

DASH_CODE$meteo$carte <- r"--(# Le réchauffement de chaque station : température moyenne depuis
# l'année de coupure, moins température moyenne avant
stations <- donnees |>
  mutate(periode = if_else(year(date) < annee_coupure, "avant", "apres")) |>
  group_by(name, latitude, longitude, periode) |>
  summarise(temp = mean(temp, na.rm = TRUE), .groups = "drop") |>
  pivot_wider(names_from = periode, values_from = temp) |>
  mutate(rechauffement = apres - avant)

plot_ly(stations, type = "scattergeo", mode = "markers+text",
        lat = ~latitude, lon = ~longitude, text = ~name,
        textposition = "top center", customdata = ~name,
        hovertemplate = "%{text}<br>%{marker.color:+.2f} °C<extra></extra>",
        marker = list(size = 18, color = ~rechauffement,
                      colorscale = "YlOrRd", reversescale = TRUE, showscale = TRUE,
                      line = list(color = "#1f3a5f", width = 1),
                      colorbar = list(title = "°C"))) |>
  layout(geo = list(resolution = 50, showland = TRUE, landcolor = "#f4f2ec",
                    showcountries = TRUE, countrycolor = "#c9c4b8",
                    showocean = TRUE, oceancolor = "#eaf1f8",
                    lataxis = list(range = c(41.2, 52)),
                    lonaxis = list(range = c(-5.5, 10.5))),
         margin = list(l = 0, r = 0, t = 0, b = 0)))--"

# ---------------------------------------------------------- NAISSANCES ------

DASH_CODE$naissances$carte <- r"--(# Un indicateur par département, sur une carte de France
# (departements = contours des départements au format GeoJSON)
par_dep <- BDD_NAIS |>
  group_by(DEPNAIS) |>
  summarise(naissances     = n(),
            age_mere       = mean(AGEMERE),
            hors_mariage   = 100 * mean(AMAR == "0000"),
            mere_etrangere = 100 * mean(INDNATM == 2),
            multiples      = 100 * mean(NBENF >= 2))

plot_ly(par_dep, type = "choropleth",
        geojson = departements, featureidkey = "properties.code",
        locations = ~DEPNAIS, z = par_dep[[indicateur]],
        customdata = ~DEPNAIS, colorscale = "Blues", reversescale = TRUE,
        marker = list(line = list(color = "white", width = 0.5)),
        hovertemplate = "Département %{location}<br>%{z:.1f}<extra></extra>") |>
  layout(geo = list(fitbounds = "locations", visible = FALSE),
         margin = list(l = 0, r = 0, t = 0, b = 0)))--"

DASH_CODE$naissances$mois <- r"--(# Naissances par jour selon le mois : on divise par le nombre de jours,
# sinon février (28 jours) paraîtrait artificiellement creux
par_mois <- donnees |>
  count(MNAIS) |>
  mutate(jours = days_in_month(as.Date(paste0("2021-", MNAIS, "-01"))),
         par_jour = n / jours)

g <- ggplot(par_mois, aes(x = MNAIS, y = par_jour,
                          text = paste0(format(round(par_jour), big.mark = " "),
                                        " naissances par jour"))) +
  geom_col(fill = "#3b6ea5") +
  geom_hline(yintercept = mean(par_mois$par_jour), linetype = "dashed") +
  labs(x = "Mois de naissance", y = "Naissances par jour") +
  theme_minimal()

ggplotly(g, tooltip = "text"))--"

DASH_CODE$naissances$pyramide <- r"--(# Âge exact des parents à la naissance, mères à droite, pères à gauche
pyramide <- donnees |>
  select(Mère = AGEXACTM, Père = AGEXACTP) |>
  pivot_longer(everything(), names_to = "parent", values_to = "age") |>
  count(parent, age) |>
  mutate(effectif = if_else(parent == "Père", -n, n))

g <- ggplot(pyramide, aes(x = age, y = effectif, fill = parent,
                          text = paste0(parent, ", ", age, " ans : ",
                                        format(n, big.mark = " ")))) +
  geom_col(width = 0.9) +
  coord_flip() +
  scale_y_continuous(labels = function(x) format(abs(x), big.mark = " ")) +
  scale_fill_manual(values = c("Mère" = "#d9822b", "Père" = "#1f3a5f")) +
  labs(x = "Âge (17 = 17 ans ou moins, 46 = 46 ans ou plus)", y = NULL, fill = NULL) +
  theme_minimal()

ggplotly(g, tooltip = "text"))--"

DASH_CODE$naissances$mariage <- r"--(hors_mariage <- donnees |>
  mutate(nationalite = if_else(INDNATM == 1, "Mère française", "Mère étrangère")) |>
  group_by(nationalite, AGEMERE) |>
  summarise(part = mean(AMAR == "0000"), n = n(), .groups = "drop") |>
  filter(n >= 30)   # on écarte les âges trop peu représentés

g <- ggplot(hors_mariage, aes(x = AGEMERE, y = part, colour = nationalite)) +
  geom_line(linewidth = 1) +
  scale_y_continuous(labels = scales::percent, limits = c(0, 1)) +
  scale_colour_manual(values = c("#d9822b", "#1f3a5f")) +
  labs(x = "Âge de la mère", y = "Part des naissances hors mariage", colour = NULL) +
  theme_minimal()

ggplotly(g) |> layout(legend = list(orientation = "h", y = -0.2)))--"

DASH_CODE$naissances$couples <- r"--(# Âge de la mère × âge du père : chaque case compte les naissances
couples <- donnees |>
  count(AGEMERE, AGEPERE)

g <- ggplot(couples, aes(x = AGEMERE, y = AGEPERE, fill = n,
                         text = paste0("Mère ", AGEMERE, " ans, père ", AGEPERE,
                                       " ans : ", format(n, big.mark = " ")))) +
  geom_tile() +
  geom_abline(slope = 1, intercept = 0, colour = "white", linetype = "dashed") +
  scale_fill_viridis_c(trans = "log10") +
  labs(x = "Âge de la mère", y = "Âge du père", fill = "Naissances") +
  theme_minimal()

ggplotly(g, tooltip = "text"))--"

DASH_CODE$naissances$noms <- r"--(noms <- donnees |>
  filter(!is.na(ORIGINOM)) |>
  mutate(origine = case_when(ORIGINOM == 1 ~ "1. Nom du père",
                             ORIGINOM == 2 ~ "2. Nom de la mère",
                             ORIGINOM == 3 ~ "3. Père-Mère",
                             ORIGINOM == 4 ~ "4. Mère-Père",
                             .default = "5. Autre"),
         parents = if_else(AMAR == "0000", "Parents non mariés", "Parents mariés")) |>
  count(parents, origine) |>
  group_by(parents) |>
  mutate(part = n / sum(n))

g <- ggplot(noms, aes(x = parents, y = part, fill = origine,
                      text = paste0(origine, " : ", round(100 * part, 1), " %"))) +
  geom_col() +
  coord_flip() +
  scale_y_continuous(labels = scales::percent) +
  scale_fill_manual(values = c("#1f3a5f", "#d9822b", "#3b6ea5", "#e9b872", "#9aa5b1")) +
  labs(x = NULL, y = NULL, fill = NULL) +
  theme_minimal()

ggplotly(g, tooltip = "text") |> layout(legend = list(orientation = "h", y = -0.2)))--"

# Exécute un code de graphique dans un environnement contenant `objets`
run_dash_code <- function(code, objets) {
  env <- list2env(objets, parent = globalenv())
  p <- eval(parse(text = code, keep.source = FALSE), envir = env)
  plotly::config(p, displaylogo = FALSE, topojsonURL = "topojson/",
                 modeBarButtonsToRemove = c("lasso2d", "select2d", "autoScale2d")) |>
    plotly::layout(separators = ", ", font = list(family = "system-ui, sans-serif"))
}
