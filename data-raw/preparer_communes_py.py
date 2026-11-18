# ============================================================================
# preparer_communes_py.py — fichiers de la base « communes_py » (cours Python
# « par la table »). À lancer depuis le dossier de l'application, APRÈS
# data-raw/preparer_communes_be.py (on réutilise ses fichiers) :
#   python data-raw/preparer_communes_py.py
#
# Tables préchargées (fichiers/demarrage.py) :
#   communes  une ligne par commune : code INS, nom, arrondissement, province,
#             région, hommes, femmes, total (Statbel, 1er janvier 2026)
#   pop_sexe  la même chose en format long : une ligne par commune et par sexe
# Fichiers à lire dans les leçons « Importer » et suivantes : les fichiers
# Statbel d'origine et les trois livraisons régionales (avec anomalies) de la
# base communes_be.
# ============================================================================

import shutil
import pandas as pd

SRC = "bases/communes_be/fichiers/"
D = "bases/communes_py/fichiers/"

pop = pd.read_csv(SRC + "donnees/population_communes_2026.csv", sep=";", dtype={"code_ins": str})
ref = pd.read_csv(SRC + "referentiels/nuts_lau_2027.txt", sep="|", encoding="cp1252", dtype=str)
vig = ref[ref["DT_VLDT_STOP"] == "31/12/9999"]

def court(nom):
    for prefixe in ["Arrondissement de ", "Arrondissement d’", "Province de ", "Province d’"]:
        if nom.startswith(prefixe):
            return nom[len(prefixe):]
    return nom

com = vig[vig["CD_LVL"] == "4"][["CD_MUNTY_REFNIS", "CD_LVL_SUP"]].rename(
    columns={"CD_MUNTY_REFNIS": "code_ins", "CD_LVL_SUP": "nuts3"})
arr = vig[vig["CD_LVL"] == "3"][["CD_LAU", "TX_DESCR_FR", "CD_LVL_SUP"]].rename(
    columns={"CD_LAU": "nuts3", "TX_DESCR_FR": "arrondissement", "CD_LVL_SUP": "nuts2"})
prov = vig[vig["CD_LVL"] == "2"][["CD_LAU", "TX_DESCR_FR"]].rename(
    columns={"CD_LAU": "nuts2", "TX_DESCR_FR": "province"})

t = (pop.merge(com, on="code_ins", how="left", validate="one_to_one")
        .merge(arr, on="nuts3", how="left", validate="many_to_one")
        .merge(prov, on="nuts2", how="left", validate="many_to_one"))
t["arrondissement"] = t["arrondissement"].map(court)
t["province"] = t["province"].fillna("Bruxelles-Capitale").map(court)
t["region"] = t["nuts3"].str.slice(0, 3).map({"BE1": "Bruxelles", "BE2": "Flandre", "BE3": "Wallonie"})
assert t[["arrondissement", "province", "region"]].notna().all().all()
communes = t[["code_ins", "commune", "arrondissement", "province", "region",
              "hommes", "femmes", "total"]].sort_values("code_ins").reset_index(drop=True)

pop_sexe = (communes.melt(id_vars=["code_ins", "commune", "province", "region"],
                          value_vars=["hommes", "femmes"], var_name="sexe",
                          value_name="population")
            .assign(sexe=lambda d: d["sexe"].map({"hommes": "H", "femmes": "F"}))
            .sort_values(["code_ins", "sexe"], ascending=[True, False])
            .reset_index(drop=True))

communes.to_parquet(D + "donnees/communes_2026.parquet", index=False)
communes.to_csv(D + "donnees/communes_2026.csv", sep=";", index=False, encoding="utf-8")
pop_sexe.to_parquet(D + "donnees/pop_sexe_2026.parquet", index=False)

for f in ["donnees/population_2026.txt", "donnees/population_provinces_2026.xlsx",
          "donnees/population_bruxelles_2026.csv", "donnees/population_flandre_2026.xlsx",
          "donnees/population_wallonie_2026.txt", "referentiels/nuts_lau_2027.txt"]:
    shutil.copyfile(SRC + f, D + f)

print(communes.shape, pop_sexe.shape)
print(communes.groupby(["region", "province"]).size())
