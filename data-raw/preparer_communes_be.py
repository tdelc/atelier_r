# ============================================================================
# preparer_communes_be.py — fichiers de la base « Communes belges » (Python)
#
# À lancer depuis le dossier de l'application :
#   python data-raw/preparer_communes_be.py
#
# Fichiers d'origine (Statbel), copiés TELS QUELS, avec leurs particularités
# qui servent au cours (encodage, séparateurs, lignes vides…) :
#   bases/communes_be/fichiers/donnees/population_2026.txt
#       « Population par commune au 1er janvier 2026 » : texte tabulé, UTF-8,
#       points comme séparateurs des milliers, deux lignes vides après les
#       en-têtes, communes mélangées aux régions, provinces et arrondissements.
#   bases/communes_be/fichiers/referentiels/nuts_lau_2027.txt
#       Correspondance codes NUTS 2027 / LAU 2025 : séparateur « | »,
#       encodage latin-1, fins de ligne Windows, historique des communes.
#
# Fichiers DÉRIVÉS de population_2026.txt (même chiffres, autre format), pour
# pratiquer les autres lectures de la demi-journée 1 :
#   donnees/population_communes_2026.csv   communes seulement, séparateur « ; »
#   donnees/population_provinces_2026.xlsx provinces, deux lignes de titre
# ============================================================================

import pandas as pd

D = "bases/communes_be/fichiers/"

brut = pd.read_csv(D + "donnees/population_2026.txt", sep="\t", thousands=".",
                   dtype={" Code INS": str}).dropna(how="all")
brut.columns = ["code_ins", "lieu", "hommes", "femmes", "total"]
for c in ["hommes", "femmes", "total"]:
    brut[c] = brut[c].astype("int64")

# Communes : codes qui ne finissent pas par 000 (régions, provinces,
# arrondissements), sauf les deux provinces du Brabant (20001, 20002)
est_commune = ~brut["code_ins"].str.endswith("000") & ~brut["code_ins"].isin(["20001", "20002"])
communes = brut[est_commune].rename(columns={"lieu": "commune"})
communes.to_csv(D + "donnees/population_communes_2026.csv", sep=";", index=False,
                encoding="utf-8")

# Provinces (+ Région de Bruxelles-Capitale, qui n'est dans aucune province)
codes_prov = ["10000", "20001", "20002", "30000", "40000", "50000", "60000",
              "70000", "80000", "90000", "04000"]
prov = brut[brut["code_ins"].isin(codes_prov)].rename(columns={"lieu": "province"})
with pd.ExcelWriter(D + "donnees/population_provinces_2026.xlsx") as xl:
    titre = pd.DataFrame([["Population par province au 1er janvier 2026"],
                          ["Source : Statbel (Direction générale Statistique)"]])
    titre.to_excel(xl, index=False, header=False, startrow=0)
    prov.to_excel(xl, index=False, startrow=2)

print("communes :", communes.shape, "| provinces :", prov.shape,
      "| total Belgique :", communes["total"].sum())
