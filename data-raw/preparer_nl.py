# ============================================================================
# preparer_nl.py — les fichiers NÉERLANDAIS des deux cours Python
#
# À lancer depuis le dossier de l'application, après preparer_communes_be.py
# et preparer_communes_py.py :
#   python data-raw/preparer_nl.py chemin/Bevolking_per_gemeente_2026.txt
#
# Les fichiers français ne sont pas modifiés. Les fichiers néerlandais sont
# écrits à côté, dans les dossiers gegevens/ (données) et referenties/
# (nomenclature), avec des colonnes et des valeurs en néerlandais :
#   nis_code, gemeente, arrondissement, provincie, gewest, mannen, vrouwen,
#   totaal ; geslacht M / V ; bevolking.
# Noms des communes : fichier Statbel néerlandais (« Woonplaats ») ; noms des
# arrondissements et provinces : nomenclature NUTS (TX_DESCR_NL).
# Les livraisons régionales (fil rouge) ont les mêmes anomalies que les
# fichiers français (voir preparer_communes_be.py).
# ============================================================================

import os
import shutil
import sys

import pandas as pd

SRC_NL = sys.argv[1] if len(sys.argv) > 1 else "Bevolking_per_gemeente_2026.txt"
BE = "bases/communes_be/fichiers/"
PY = "bases/communes_py/fichiers/"

# --- Le fichier Statbel néerlandais, tel que publié ---------------------------
for d in (BE, PY):
    os.makedirs(d + "gegevens", exist_ok=True)
    os.makedirs(d + "referenties", exist_ok=True)
    shutil.copyfile(SRC_NL, d + "gegevens/bevolking_2026.txt")
    shutil.copyfile(BE + "referentiels/nuts_lau_2027.txt", d + "referenties/nuts_lau_2027.txt")

brut = pd.read_csv(SRC_NL, sep="\t", thousands=".", dtype={"NIS code": str}).dropna(how="all")
brut.columns = ["nis_code", "plaats", "mannen", "vrouwen", "totaal"]
for c in ["mannen", "vrouwen", "totaal"]:
    brut[c] = brut[c].astype("int64")
est_gemeente = ~brut["nis_code"].str.endswith("000") & ~brut["nis_code"].isin(["20001", "20002"])
gem = brut[est_gemeente].rename(columns={"plaats": "gemeente"}).reset_index(drop=True)

# --- Hiérarchie (nomenclature NUTS, noms néerlandais) ------------------------
ref = pd.read_csv(BE + "referentiels/nuts_lau_2027.txt", sep="|", encoding="cp1252", dtype=str)
vig = ref[ref["DT_VLDT_STOP"] == "31/12/9999"]


def kort(naam):
    for prefix in ["Arrondissement ", "Provincie "]:
        if isinstance(naam, str) and naam.startswith(prefix):
            return naam[len(prefix):]
    return naam


com = vig[vig["CD_LVL"] == "4"][["CD_MUNTY_REFNIS", "CD_LVL_SUP"]].rename(
    columns={"CD_MUNTY_REFNIS": "nis_code", "CD_LVL_SUP": "nuts3"})
arr = vig[vig["CD_LVL"] == "3"][["CD_LAU", "TX_DESCR_NL", "CD_LVL_SUP"]].rename(
    columns={"CD_LAU": "nuts3", "TX_DESCR_NL": "arrondissement", "CD_LVL_SUP": "nuts2"})
prov = vig[vig["CD_LVL"] == "2"][["CD_LAU", "TX_DESCR_NL"]].rename(
    columns={"CD_LAU": "nuts2", "TX_DESCR_NL": "provincie"})
t = (gem.merge(com, on="nis_code", how="left", validate="one_to_one")
        .merge(arr, on="nuts3", how="left", validate="many_to_one")
        .merge(prov, on="nuts2", how="left", validate="many_to_one"))
t["arrondissement"] = t["arrondissement"].map(kort)
t["provincie"] = t["provincie"].fillna("Brussel-Hoofdstad").map(kort)
t["gewest"] = t["nuts3"].str.slice(0, 3).map({"BE1": "Brussel", "BE2": "Vlaanderen", "BE3": "Wallonië"})
assert t[["arrondissement", "provincie", "gewest"]].notna().all().all()
gemeenten = t[["nis_code", "gemeente", "arrondissement", "provincie", "gewest",
               "mannen", "vrouwen", "totaal"]].sort_values("nis_code").reset_index(drop=True)

# contrôle : mêmes chiffres que la table française
fr = pd.read_parquet(PY + "donnees/communes_2026.parquet")
assert (fr["code_ins"].tolist() == gemeenten["nis_code"].tolist()
        and fr["total"].tolist() == gemeenten["totaal"].tolist()), "chiffres différents du fichier français"

bevolking_geslacht = (gemeenten.melt(id_vars=["nis_code", "gemeente", "provincie", "gewest"],
                                     value_vars=["mannen", "vrouwen"], var_name="geslacht",
                                     value_name="bevolking")
                      .assign(geslacht=lambda d: d["geslacht"].map({"mannen": "M", "vrouwen": "V"}))
                      .sort_values(["nis_code", "geslacht"]).reset_index(drop=True))

# --- Cours « par la table » (communes_py) ------------------------------------
gemeenten.to_parquet(PY + "gegevens/gemeenten_2026.parquet", index=False)
gemeenten.to_csv(PY + "gegevens/gemeenten_2026.csv", sep=";", index=False, encoding="utf-8")
bevolking_geslacht.to_parquet(PY + "gegevens/bevolking_geslacht_2026.parquet", index=False)

# --- Cours « support d'origine » (communes_be) -------------------------------
gemeenten[["nis_code", "gemeente", "mannen", "vrouwen", "totaal"]].to_csv(
    BE + "gegevens/bevolking_gemeenten_2026.csv", sep=";", index=False, encoding="utf-8")
codes_prov = ["10000", "20001", "20002", "30000", "40000", "50000", "60000",
              "70000", "80000", "90000", "04000"]
pv = brut[brut["nis_code"].isin(codes_prov)].rename(columns={"plaats": "provincie"})
with pd.ExcelWriter(BE + "gegevens/bevolking_provincies_2026.xlsx") as xl:
    pd.DataFrame([["Bevolking per provincie op 1 januari 2026"],
                  ["Bron: Statbel (Algemene Directie Statistiek)"]]).to_excel(xl, index=False, header=False)
    pv.to_excel(xl, index=False, startrow=2)

# --- Fil rouge : trois livraisons régionales, avec les mêmes anomalies -------
lang = (gemeenten.melt(id_vars=["nis_code", "gemeente", "gewest"], value_vars=["mannen", "vrouwen"],
                       var_name="geslacht", value_name="bevolking")
        .assign(geslacht=lambda d: d["geslacht"].map({"mannen": "M", "vrouwen": "V"}), jaar=2026)
        .sort_values(["nis_code", "geslacht"])[["nis_code", "gemeente", "jaar", "geslacht", "bevolking", "gewest"]])
lang["bevolking"] = lang["bevolking"].astype(object)


def rij(d, code, g):
    return (d["nis_code"] == code) & (d["geslacht"] == g)


bru = lang[lang["gewest"] == "Brussel"].drop(columns="gewest").copy()
vla = lang[lang["gewest"] == "Vlaanderen"].drop(columns="gewest").copy()
wal = lang[lang["gewest"] == "Wallonië"].drop(columns="gewest").copy()

i = vla.index[rij(vla, "44021", "V")][0]                 # Gent, vrouwen : dubbel
pos = vla.index.get_loc(i)
vla = pd.concat([vla.iloc[:pos + 1], vla.iloc[[pos]], vla.iloc[pos + 1:]])
wal.loc[rij(wal, "92094", "V"), "geslacht"] = "v"        # Namen
wal.loc[rij(wal, "62063", "M"), "nis_code"] = " 62063"   # Luik
wal.loc[rij(wal, "84016", "M"), "bevolking"] = None      # Daverdisse
wal.loc[rij(wal, "81013", "V"), "bevolking"] = -1059     # Martelange
wal = pd.concat([wal, pd.DataFrame([{"nis_code": "99999", "gemeente": "Testgemeente",
                                     "jaar": 2026, "geslacht": "M", "bevolking": 120}])])

for d in (BE, PY):
    bru.to_csv(d + "gegevens/bevolking_brussel_2026.csv", sep=";", index=False, encoding="utf-8")
    with pd.ExcelWriter(d + "gegevens/bevolking_vlaanderen_2026.xlsx") as xl:
        pd.DataFrame([["Bevolking per gemeente en geslacht, Vlaams Gewest, 1 januari 2026"],
                      ["Bron: Statbel"]]).to_excel(xl, index=False, header=False)
        vla.to_excel(xl, index=False, startrow=2)
    wal.to_csv(d + "gegevens/bevolking_wallonie_2026.txt", sep="\t", index=False, encoding="utf-8")

ruw = pd.concat([bru.assign(gewest="Brussel"), vla.assign(gewest="Vlaanderen"),
                 wal.assign(gewest="Wallonië")], ignore_index=True)
ruw["bevolking"] = pd.to_numeric(ruw["bevolking"]).astype("float64")
ruw["jaar"] = ruw["jaar"].astype("int64")
ruw.to_parquet(BE + "gegevens/bevolking_ruw.parquet", index=False)

net = ruw.drop_duplicates().copy()
net["nis_code"] = net["nis_code"].str.strip().str.zfill(5)
net["geslacht"] = net["geslacht"].str.strip().str.upper()
net = net.dropna(subset=["bevolking"])
net = net[net["bevolking"] >= 0].copy()
net["bevolking"] = net["bevolking"].astype("int64")
net["referentiedatum"] = pd.to_datetime(net["jaar"].astype(str) + "-01-01")
net["bevolking_duizend"] = (net["bevolking"] / 1000).round(2)
net.to_parquet(BE + "gegevens/bevolking_opgeschoond.parquet", index=False)

print("gemeenten", gemeenten.shape, "| bevolking_geslacht", bevolking_geslacht.shape,
      "| Brussel", bru.shape, "| Vlaanderen", vla.shape, "| Wallonië", wal.shape,
      "| ruw", ruw.shape, "| opgeschoond", net.shape)
