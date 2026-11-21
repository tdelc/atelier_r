# ============================================================================
# preparer_citoyens_py.py — fichiers de la base « citoyens_py » (cours Python
# « par la table », côté citoyens). À lancer depuis le dossier de
# l'application, après preparer_communes_py.py :
#   python data-raw/preparer_citoyens_py.py
#
# LES PERSONNES SONT FICTIVES. C'est un échantillon d'enquête simulé pour
# l'atelier (dans l'esprit de l'enquête sur les revenus et les conditions de
# vie et de l'enquête sur les forces de travail), avec des ordres de grandeur
# plausibles, mais aucun chiffre ne décrit la Belgique ni une personne réelle.
# Les identifiants (id_pseudo) sont des pseudonymes aléatoires. Ce qui est
# réel : les communes (Statbel), la nomenclature NUTS et les fusions de
# communes du 1er janvier 2025.
#
# Fichiers produits (bases/citoyens_py/fichiers/) :
#   donnees/personnes_2025.parquet / .csv   une ligne par personne de
#           l'échantillon (table préchargée « personnes »), avec sa pondération
#   donnees/registre_national_2026.csv     extrait pseudonymisé du Registre
#           national (date de naissance, sexe codé 1/2, commune, décès),
#           avec un historique d'adresses et des anciens codes de communes
#   donnees/onem_allocations_2025.xlsx     allocations de chômage (ONEM)
#   donnees/spf_finances_revenus_2024.txt  revenus imposables 2024 (SPF Finances)
#   donnees/ris_2025_bruxelles.csv, ris_2025_flandre.xlsx, ris_2025_wallonie.txt
#           revenu d'intégration (CPAS, via le SPP Intégration sociale)
#   referentiels/fusions_communes_2025.csv  anciens et nouveaux codes INS
#   referentiels/nuts_lau_2027.txt          nomenclature des territoires (Statbel)
# ============================================================================

import shutil
import numpy as np
import pandas as pd

rng = np.random.default_rng(2026)
D = "bases/citoyens_py/fichiers/"
communes = pd.read_parquet("bases/communes_py/fichiers/donnees/communes_2026.parquet")
POP = communes.groupby("region")["total"].sum()          # vraies populations régionales

# --- Ménages ---------------------------------------------------------------
H = 6000
part_echantillon = {"Bruxelles": .25, "Flandre": .45, "Wallonie": .30}   # Bruxelles suréchantillonnée
types = ["isolé", "couple sans enfant", "couple avec enfants", "famille monoparentale", "autre"]
p_type = {"Bruxelles": [.38, .16, .26, .16, .04], "Flandre": [.31, .31, .29, .06, .03],
          "Wallonie": [.34, .26, .25, .11, .04]}
p_dipl = {"Bruxelles": [.32, .28, .40], "Flandre": [.20, .40, .40], "Wallonie": [.27, .40, .33]}
p_emploi = {  # probabilité d'être en emploi, 25-59 ans, selon le diplôme (faible, moyen, élevé)
    "Bruxelles": [.44, .68, .87], "Flandre": [.74, .89, .94], "Wallonie": [.56, .77, .89]}
chomage = {"Bruxelles": .082, "Flandre": .035, "Wallonie": .062}   # part des actifs au chômage

personnes = []
for h in range(H):
    reg = rng.choice(list(part_echantillon), p=list(part_echantillon.values()))
    c = communes[communes["region"] == reg]
    com = c.iloc[rng.choice(len(c), p=(c["total"] / c["total"].sum()).to_numpy())]
    t = rng.choice(types, p=p_type[reg])
    ages = []
    if t == "isolé":
        ages = [int(rng.choice([rng.integers(24, 40), rng.integers(40, 65), rng.integers(65, 95)], p=[.35, .3, .35]))]
    elif t == "couple sans enfant":
        a = int(rng.choice([rng.integers(24, 40), rng.integers(50, 88)], p=[.35, .65]))
        ages = [a, max(19, a + int(rng.integers(-5, 6)))]
    elif t == "couple avec enfants":
        a = int(rng.integers(27, 56)); ages = [a, max(20, a + int(rng.integers(-4, 5)))]
        for _ in range(int(rng.choice([1, 2, 3, 4], p=[.38, .42, .16, .04]))):
            ages.append(int(np.clip(a - rng.integers(22, 42), 0, 24)))
    elif t == "famille monoparentale":
        a = int(rng.integers(24, 58)); ages = [a]
        for _ in range(int(rng.choice([1, 2, 3], p=[.5, .37, .13]))):
            ages.append(int(np.clip(a - rng.integers(20, 40), 0, 24)))
    else:
        a = int(rng.integers(45, 70)); ages = [a, a + int(rng.integers(-4, 5)), int(rng.integers(18, 32))]
    for i, age in enumerate(ages):
        enfant = (t in ["couple avec enfants", "famille monoparentale"] and i >= (2 if t.startswith("couple") else 1)) \
                 or (t == "autre" and i == 2)
        sexe = rng.choice(["H", "F"]) if not (t == "famille monoparentale" and i == 0) else \
               rng.choice(["H", "F"], p=[.17, .83])
        if t.startswith("couple") and i == 1:
            sexe = "F" if personnes[-1]["sexe"] == "H" else "H"
        personnes.append({"id_menage": f"M{h + 1:05d}", "region": reg, "code_ins": com["code_ins"],
                          "commune": com["commune"], "province": com["province"],
                          "type_menage": t, "age": age, "sexe": sexe, "enfant": enfant})
p = pd.DataFrame(personnes)

# --- Diplôme et statut d'activité -----------------------------------------
n = len(p)
p["diplome"] = [rng.choice(["faible", "moyen", "élevé"], p=p_dipl[r]) if a >= 25 else None
                for r, a in zip(p["region"], p["age"])]
statut = []
for r, a, d, s in zip(p["region"], p["age"], p["diplome"], p["sexe"]):
    if a < 15:
        statut.append("moins de 15 ans"); continue
    if a < 25:
        pe = {"Bruxelles": .22, "Flandre": .36, "Wallonie": .24}[r]
        u = rng.random()
        if u < .55: statut.append("étudiant")
        elif u < .55 + pe: statut.append("en emploi")
        elif u < .55 + pe + chomage[r] * 2.2: statut.append("chômeur")
        else: statut.append("inactif")
        continue
    if a >= 65:
        statut.append("retraité"); continue
    k = ["faible", "moyen", "élevé"].index(d)
    pe = p_emploi[r][k] * (.93 if s == "F" else 1.0) * (.72 if a >= 60 else 1.0)
    u = rng.random()
    if u < pe:
        statut.append("en emploi")
    elif u < pe + pe * chomage[r] / (1 - chomage[r]) * (1.6 if d == "faible" else .8):
        statut.append("chômeur")
    elif a >= 60 and u < pe + .55 * (1 - pe):
        statut.append("retraité")
    else:
        statut.append("inactif")
p["statut"] = statut

# --- Revenus --------------------------------------------------------------
def revenu_individuel(st, d):
    if st == "en emploi":
        med = {"faible": 25000, "moyen": 30500, "élevé": 41000}.get(d, 18000)
        return med * np.exp(rng.normal(0, .33)) * (.7 if rng.random() < .22 else 1)
    if st == "chômeur":
        return 14500 * np.exp(rng.normal(0, .2))
    if st == "retraité":
        return max(15000, 21000 * np.exp(rng.normal(0, .28)))
    if st == "inactif":
        return 15500 * np.exp(rng.normal(0, .2)) if rng.random() < .5 else 2500 * rng.random()
    if st == "étudiant":
        return 1500 * rng.random()
    return 0
p["revenu_individuel"] = [revenu_individuel(s, d) for s, d in zip(p["statut"], p["diplome"])]
p["allocations_familiales"] = np.where(p["age"] < 18, 2100, 0)
men = p.groupby("id_menage").agg(rev=("revenu_individuel", "sum"), alloc=("allocations_familiales", "sum"),
                                 taille=("age", "size"), moins14=("age", lambda a: (a < 14).sum()))
men["revenu_menage"] = np.round((men["rev"] + men["alloc"]) / 10) * 10
men["uc"] = 1 + .5 * (men["taille"] - men["moins14"] - 1) + .3 * men["moins14"]
p = p.merge(men[["revenu_menage", "uc", "taille"]].rename(columns={"taille": "taille_menage"}),
            left_on="id_menage", right_index=True)
p["revenu_equivalent"] = np.round(p["revenu_menage"] / p["uc"])

# --- Classes d'âge et pondérations ------------------------------------------
p["classe_age"] = pd.cut(p["age"], [-1, 17, 24, 49, 64, 120],
                         labels=["0-17", "18-24", "25-49", "50-64", "65+"]).astype(str)
struct_age = {"0-17": .20, "18-24": .08, "25-49": .33, "50-64": .20, "65+": .19}
cellule = p.groupby(["region", "classe_age"])["age"].transform("size")
p["poids"] = np.round([POP[r] * struct_age[a] / c for r, a, c in zip(p["region"], p["classe_age"], cellule)], 1)

p["id_personne"] = [f"P{i + 1:05d}" for i in range(len(p))]
p["id_pseudo"] = [f"{x:016x}" for x in rng.integers(0, 2**63, len(p))]
personnes = p[["id_personne", "id_menage", "id_pseudo", "region", "province", "code_ins", "commune",
               "sexe", "age", "classe_age", "statut", "diplome", "type_menage", "taille_menage",
               "revenu_menage", "revenu_equivalent", "poids"]].reset_index(drop=True)

# --- Fichiers administratifs (pseudonymisés) ---------------------------------
fus = [("11007", "Borsbeek", "11002", "Anvers"), ("11056", "Zwijndrecht", "46030", "Beveren-Kruibeke-Zwijndrecht"),
       ("46003", "Beveren", "46030", "Beveren-Kruibeke-Zwijndrecht"), ("46013", "Kruibeke", "46030", "Beveren-Kruibeke-Zwijndrecht"),
       ("71022", "Hasselt", "71072", "Hasselt"), ("73040", "Kortessem", "71072", "Hasselt"),
       ("71057", "Tessenderlo", "71071", "Tessenderlo-Ham"), ("71069", "Ham", "71071", "Tessenderlo-Ham"),
       ("73006", "Bilzen", "73110", "Bilzen-Hoeselt"), ("73032", "Hoeselt", "73110", "Bilzen-Hoeselt"),
       ("73009", "Looz", "73111", "Tongres-Looz"), ("73083", "Tongres", "73111", "Tongres-Looz"),
       ("44012", "De Pinte", "44086", "Nazareth-De Pinte"), ("44048", "Nazareth", "44086", "Nazareth-De Pinte"),
       ("44034", "Lochristi", "44087", "Lochristi"), ("44073", "Wachtebeke", "44087", "Lochristi"),
       ("44040", "Melle", "44088", "Merelbeke-Melle"), ("44043", "Merelbeke", "44088", "Merelbeke-Melle"),
       ("44045", "Moerbeke", "46029", "Lokeren"), ("46014", "Lokeren", "46029", "Lokeren"),
       ("23023", "Gammerages", "23106", "Pajottegem"), ("23024", "Gooik", "23106", "Pajottegem"),
       ("23032", "Herne", "23106", "Pajottegem"),
       ("37007", "Meulebeke", "37022", "Tielt"), ("37015", "Tielt", "37022", "Tielt"),
       ("37012", "Ruiselede", "37021", "Wingene"), ("37018", "Wingene", "37021", "Wingene")]
fusions = pd.DataFrame(fus, columns=["code_ancien", "commune_ancienne", "code_nouveau", "commune_nouvelle"])
fusions.to_csv(D + "referentiels/fusions_communes_2025.csv", sep=";", index=False, encoding="utf-8")
anciens = fusions.groupby("code_nouveau")["code_ancien"].apply(list).to_dict()

# 1. Registre national : une ligne par personne retrouvée, + un historique d'adresses
naiss = [pd.Timestamp(2025 - a, 1, 1) + pd.Timedelta(days=int(rng.integers(-365, 0)))
         for a in p["age"]]   # âge au 1er janvier 2025... à un an près
rn = pd.DataFrame({"id_pseudo": p["id_pseudo"], "date_naissance": [d.strftime("%Y-%m-%d") for d in naiss],
                   "sexe": p["sexe"].map({"H": 1, "F": 2}), "code_ins": p["code_ins"],
                   "date_debut_adresse": "2020-01-01", "date_deces": ""})
rn["date_debut_adresse"] = [f"{rng.integers(1990, 2025)}-{rng.integers(1, 13):02d}-01" for _ in range(len(rn))]
# anciennes adresses dans les communes fusionnées : le registre n'a pas toujours été recodé
for i in rn.index:
    if rn.at[i, "code_ins"] in anciens and rng.random() < .6:
        rn.at[i, "code_ins"] = rng.choice(anciens[rn.at[i, "code_ins"]])
# 1,5 % des personnes ne sont pas retrouvées (pas de pseudonyme correspondant)
absents = rng.choice(rn.index, int(len(rn) * .015), replace=False)
rn = rn.drop(index=absents)
# déménagements en 2025 : une ligne de plus, plus récente
dem = rn.sample(150, random_state=1).copy()
dem["date_debut_adresse"] = [f"2025-{m:02d}-01" for m in rng.integers(2, 12, len(dem))]
dem["code_ins"] = rng.choice(communes["code_ins"], len(dem))
rn = pd.concat([rn, dem], ignore_index=True)
# quelques décès en 2025, après l'enquête
dec = rn[(rn["date_debut_adresse"] < "2025") & ~rn["id_pseudo"].isin(dem["id_pseudo"])].sample(40, random_state=2).index
rn.loc[dec, "date_deces"] = [f"2025-{m:02d}-{d:02d}" for m, d in zip(rng.integers(6, 13, 40), rng.integers(1, 29, 40))]
# des dates écrites à la française dans une partie du fichier (une autre chaîne de traitement)
fr = rn.sample(frac=.1, random_state=3).index
rn.loc[fr, "date_naissance"] = pd.to_datetime(rn.loc[fr, "date_naissance"]).dt.strftime("%d/%m/%Y")
# deux incohérences de sexe entre l'enquête et le registre
inc = rn.sample(2, random_state=4).index
rn.loc[inc, "sexe"] = 3 - rn.loc[inc, "sexe"]
rn = rn.sample(frac=1, random_state=5).reset_index(drop=True)
rn.to_csv(D + "donnees/registre_national_2026.csv", sep=";", index=False, encoding="utf-8")

# 2. ONEM : allocations de chômage 2025
lignes = []
for _, r in p.iterrows():
    if r["statut"] == "chômeur" and rng.random() < .82:
        mois = int(rng.integers(3, 13)); lignes.append((r["id_pseudo"], "chômage complet", mois, round(mois * 1250 * np.exp(rng.normal(0, .15)), 2)))
    elif r["statut"] == "en emploi" and rng.random() < .04:
        mois = int(rng.integers(1, 4)); lignes.append((r["id_pseudo"], "chômage temporaire", mois, round(mois * 900 * np.exp(rng.normal(0, .2)), 2)))
    elif r["statut"] == "inactif" and 25 <= r["age"] < 65 and rng.random() < .07:
        mois = int(rng.integers(6, 13)); lignes.append((r["id_pseudo"], "dispense de recherche", mois, round(mois * 1150, 2)))
onem = pd.DataFrame(lignes, columns=["id_pseudo", "type_allocation", "mois_indemnises", "montant_annuel"])
with pd.ExcelWriter(D + "donnees/onem_allocations_2025.xlsx") as w:
    pd.DataFrame([["Allocations de chômage 2025 — extrait pseudonymisé (données fictives)"], [""]]).to_excel(
        w, index=False, header=False)
    onem.to_excel(w, index=False, startrow=2)

# 3. SPF Finances : revenus imposables 2024 (une ligne par contribuable adulte)
adultes = p[(p["age"] >= 18) & (p["revenu_individuel"] > 2000)]
fisc = pd.DataFrame({"id_pseudo": adultes["id_pseudo"],
                     "revenu_imposable": np.round(adultes["revenu_individuel"] * 1.35 * np.exp(rng.normal(0, .08, len(adultes))) / 1.02, 2)})
fisc = fisc.sample(frac=.97, random_state=6)    # 3 % n'ont pas (encore) de déclaration enrôlée
fisc["revenu_imposable"] = fisc["revenu_imposable"].map(lambda x: f"{x:,.2f}".replace(",", " ").replace(".", ",").replace(" ", "."))
fisc.to_csv(D + "donnees/spf_finances_revenus_2024.txt", sep="\t", index=False, encoding="utf-8")

# 4. Revenu d'intégration (CPAS), un fichier par région
pauvre = p["revenu_equivalent"] < .6 * np.median(np.repeat(p["revenu_equivalent"], 1))
ris = p[(p["age"] >= 18) & pauvre & p["statut"].isin(["inactif", "chômeur", "étudiant"])]
ris = ris[rng.random(len(ris)) < .45]
ris = pd.DataFrame({"id_pseudo": ris["id_pseudo"], "region": ris["region"],
                    "mois_ris": rng.integers(2, 13, len(ris))})
ris["montant_ris"] = np.round(ris["mois_ris"] * 1300 * np.exp(rng.normal(0, .1, len(ris))), 2)
ris[ris["region"] == "Bruxelles"].drop(columns="region").to_csv(D + "donnees/ris_2025_bruxelles.csv", sep=";", decimal=",", index=False)
with pd.ExcelWriter(D + "donnees/ris_2025_flandre.xlsx") as w:
    ris[ris["region"] == "Flandre"].drop(columns="region").to_excel(w, index=False)
ris[ris["region"] == "Wallonie"].drop(columns="region").to_csv(D + "donnees/ris_2025_wallonie.txt", sep="\t", index=False)

shutil.copyfile("bases/communes_py/fichiers/referentiels/nuts_lau_2027.txt", D + "referentiels/nuts_lau_2027.txt")
personnes.to_parquet(D + "donnees/personnes_2025.parquet", index=False)
personnes.to_csv(D + "donnees/personnes_2025.csv", sep=";", index=False, encoding="utf-8")

# --- Contrôles ----------------------------------------------------------------
def med_p(x, w):
    o = np.argsort(x); x, w = np.asarray(x)[o], np.asarray(w)[o]
    return x[np.searchsorted(np.cumsum(w), w.sum() / 2)]
seuil = .6 * med_p(personnes["revenu_equivalent"], personnes["poids"])
personnes["pauvre"] = personnes["revenu_equivalent"] < seuil
print(personnes.shape, "population", round(personnes["poids"].sum()), "seuil", seuil)
print(personnes.groupby("region").apply(lambda d: np.average(d["pauvre"], weights=d["poids"]), include_groups=False).round(3))
print("Belgique", round(np.average(personnes["pauvre"], weights=personnes["poids"]), 3))
print(personnes.groupby("classe_age").apply(lambda d: np.average(d["pauvre"], weights=d["poids"]), include_groups=False).round(3))
act = personnes[(personnes["age"] >= 15) & (personnes["age"] < 65) & personnes["statut"].isin(["en emploi", "chômeur"])]
print(act.groupby("region").apply(lambda d: np.average(d["statut"] == "chômeur", weights=d["poids"]), include_groups=False).round(3))
print("taux de chômage BE", round(np.average(act["statut"] == "chômeur", weights=act["poids"]), 3))
e = personnes[(personnes["age"] >= 20) & (personnes["age"] < 65)]
print("taux d'emploi 20-64", e.groupby("region").apply(lambda d: np.average(d["statut"] == "en emploi", weights=d["poids"]), include_groups=False).round(3))
print(len(rn), len(onem), len(fisc), len(ris))
