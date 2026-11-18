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

# ============================================================================
# FIL ROUGE des demi-journées 2 à 5 : trois « livraisons » de la population
# par commune et par sexe, une par région, dans trois formats. Les chiffres
# sont ceux de Statbel ; quelques ANOMALIES sont ajoutées volontairement pour
# les exercices de contrôle et de nettoyage (elles sont listées ci-dessous et
# signalées dans le cours) :
#   Bruxelles (CSV « ; »)          aucune anomalie
#   Flandre (Excel, 2 lignes de titre)  une ligne en double (Gand, F)
#   Wallonie (TXT tabulé)          sexe « f » (Namur, F) ; code « 62063 »
#                                  précédé d'une espace (Liège, H) ;
#                                  population manquante (Daverdisse, H) ;
#                                  population négative (Martelange, F) ;
#                                  une commune « 99999 » inconnue du référentiel
# ============================================================================

import numpy as np

ref = pd.read_csv(D + "referentiels/nuts_lau_2027.txt", sep="|", encoding="latin-1", dtype=str)
actives = ref[(ref["CD_LVL"] == "4") & (ref["DT_VLDT_STOP"] == "31/12/9999")]
region_nuts = dict(zip(actives["CD_MUNTY_REFNIS"], actives["CD_LVL_SUP"].str[:3]))
noms_regions = {"BE1": "Bruxelles", "BE2": "Flandre", "BE3": "Wallonie"}

long = (communes.melt(id_vars=["code_ins", "commune"], value_vars=["hommes", "femmes"],
                      var_name="sexe", value_name="population")
        .assign(sexe=lambda d: d["sexe"].map({"hommes": "H", "femmes": "F"}), annee=2026)
        .sort_values(["code_ins", "sexe"], ascending=[True, False])
        [["code_ins", "commune", "annee", "sexe", "population"]])
long["population"] = long["population"].astype(object)
long["region"] = long["code_ins"].map(region_nuts).map(noms_regions)
assert long["region"].notna().all()

def ligne(d, code, sexe):
    return (d["code_ins"] == code) & (d["sexe"] == sexe)

bxl = long[long["region"] == "Bruxelles"].drop(columns="region").copy()
fla = long[long["region"] == "Flandre"].drop(columns="region").copy()
wal = long[long["region"] == "Wallonie"].drop(columns="region").copy()

# Flandre : un doublon exact (Gand, femmes), inséré juste après l'original
i = fla.index[ligne(fla, "44021", "F")][0]
pos = fla.index.get_loc(i)
fla = pd.concat([fla.iloc[:pos + 1], fla.iloc[[pos]], fla.iloc[pos + 1:]])

# Wallonie : quatre anomalies et une commune inconnue
wal.loc[ligne(wal, "92094", "F"), "sexe"] = "f"
wal.loc[ligne(wal, "62063", "H"), "code_ins"] = " 62063"
wal.loc[ligne(wal, "84016", "H"), "population"] = None
wal.loc[ligne(wal, "81013", "F"), "population"] = -1059
wal = pd.concat([wal, pd.DataFrame([{"code_ins": "99999", "commune": "Commune test",
                                     "annee": 2026, "sexe": "H", "population": 120}])])

bxl.to_csv(D + "donnees/population_bruxelles_2026.csv", sep=";", index=False, encoding="utf-8")
with pd.ExcelWriter(D + "donnees/population_flandre_2026.xlsx") as xl:
    pd.DataFrame([["Population par commune et par sexe, Région flamande, 1er janvier 2026"],
                  ["Source : Statbel"]]).to_excel(xl, index=False, header=False)
    fla.to_excel(xl, index=False, startrow=2)
wal.to_csv(D + "donnees/population_wallonie_2026.txt", sep="\t", index=False, encoding="utf-8")

# Parquet des demi-journées 4 et 5 : les trois livraisons empilées (brut),
# et la table nettoyée selon les règles de l'atelier 4 (fichier de secours)
brut_fr = pd.concat([bxl.assign(region="Bruxelles"), fla.assign(region="Flandre"),
                     wal.assign(region="Wallonie")], ignore_index=True)
brut_fr["population"] = pd.to_numeric(brut_fr["population"]).astype("float64")
brut_fr["annee"] = brut_fr["annee"].astype("int64")
brut_fr.to_parquet(D + "donnees/population_brut.parquet", index=False)

net = brut_fr.drop_duplicates().copy()
net["code_ins"] = net["code_ins"].str.strip().str.zfill(5)
net["sexe"] = net["sexe"].str.strip().str.upper()
net = net.dropna(subset=["population"])
net = net[net["population"] >= 0].copy()
net["population"] = net["population"].astype("int64")
net["date_reference"] = pd.to_datetime(net["annee"].astype(str) + "-01-01")
net["pop_milliers"] = (net["population"] / 1000).round(2)
net.to_parquet(D + "donnees/population_nettoyee.parquet", index=False)

print("fil rouge : Bruxelles", bxl.shape, "| Flandre", fla.shape, "| Wallonie", wal.shape,
      "| brut", brut_fr.shape, "| nettoyée", net.shape)
