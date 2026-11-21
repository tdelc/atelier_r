# ============================================================================
# preparer_entreprises_py.py — fichiers de la base « entreprises_py » (cours
# Python « par la table », côté entreprises). À lancer depuis le dossier de
# l'application, après preparer_communes_py.py :
#   python data-raw/preparer_entreprises_py.py
#
# LES ENTREPRISES SONT FICTIVES. Elles sont simulées pour l'atelier, avec des
# ordres de grandeur plausibles, mais aucun chiffre ne décrit une entreprise
# réelle. Ce qui est réel : les communes (Statbel), la nomenclature NUTS et
# les classes NACE utilisées (libellés abrégés).
# Les numéros d'entreprise commencent par 9 : un vrai numéro BCE commence par
# 0 ou 1, ils ne peuvent donc jamais désigner une vraie entreprise. Ils
# respectent la clé de contrôle modulo 97, comme les vrais.
#
# Tables et fichiers produits (bases/entreprises_py/fichiers/) :
#   donnees/entreprises_2025.parquet / .csv   une ligne par entreprise (table
#           préchargée « entreprises ») : NACE principale selon la BCE,
#           localisation, forme, création, emploi salarié, chiffre d'affaires
#   donnees/tva_2025_T1.csv, T2.xlsx, T3.txt, T4.csv   déclarations TVA
#           trimestrielles, chacune dans un format différent, avec anomalies
#   donnees/onss_emploi_2025.csv   emploi déclaré à l'ONSS (postes, ETP, NACE ONSS)
#   referentiels/nace_bel_2008.csv  classes NACE utilisées (encodage Windows-1252)
#   referentiels/correspondance_nace_2008_2025.csv  extrait simplifié
#   referentiels/nuts_lau_2027.txt  nomenclature des territoires (Statbel)
# ============================================================================

import shutil
import numpy as np
import pandas as pd

rng = np.random.default_rng(2025)
D = "bases/entreprises_py/fichiers/"
communes = pd.read_parquet("bases/communes_py/fichiers/donnees/communes_2026.parquet")

SECTIONS = {
    "A": "Agriculture, sylviculture et pêche",
    "C": "Industrie manufacturière",
    "D": "Électricité et gaz",
    "E": "Eau, déchets et dépollution",
    "F": "Construction",
    "G": "Commerce",
    "H": "Transports et entreposage",
    "I": "Hébergement et restauration",
    "J": "Information et communication",
    "K": "Activités financières et d'assurance",
    "L": "Activités immobilières",
    "M": "Activités spécialisées, scientifiques et techniques",
    "N": "Services administratifs et de soutien",
    "P": "Enseignement",
    "Q": "Santé humaine et action sociale",
    "R": "Arts, spectacles et activités récréatives",
    "S": "Autres activités de services",
}

# classe, libellé, section, poids, part sans salarié, emploi médian (employeurs),
# CA par emploi (k€), exonéré de TVA, facteur Bruxelles, part à temps plein (ETP/poste)
C = [
    ("01.11", "Culture de céréales, de légumineuses et de graines oléagineuses", "A", 3, .80, 2, 150, 0, 0, .9),
    ("01.41", "Élevage de vaches laitières", "A", 3, .80, 2, 200, 0, 0, .9),
    ("10.51", "Exploitation de laiteries et fabrication de fromage", "C", .3, .10, 25, 600, 0, .2, .95),
    ("10.71", "Fabrication de pain et de pâtisserie fraîche", "C", 2.5, .30, 4, 120, 0, .6, .8),
    ("20.14", "Fabrication d'autres produits chimiques organiques de base", "C", .15, 0, 120, 1800, 0, .1, .97),
    ("21.20", "Fabrication de préparations pharmaceutiques", "C", .15, .05, 150, 1200, 0, .3, .96),
    ("24.10", "Sidérurgie", "C", .05, 0, 400, 900, 0, 0, .97),
    ("25.62", "Usinage", "C", 1, .20, 8, 140, 0, .2, .95),
    ("29.10", "Construction de véhicules automobiles", "C", .03, 0, 1500, 1100, 0, .3, .97),
    ("35.11", "Production d'électricité", "D", .4, .60, 20, 2500, 0, .5, .95),
    ("38.11", "Collecte des déchets non dangereux", "E", .3, .10, 20, 250, 0, .5, .95),
    ("41.20", "Construction de bâtiments résidentiels et non résidentiels", "F", 6, .45, 5, 220, 0, .7, .96),
    ("43.21", "Installation électrique", "F", 4, .50, 4, 150, 0, .7, .96),
    ("43.31", "Travaux de plâtrerie", "F", 2, .70, 3, 110, 0, .7, .96),
    ("45.20", "Entretien et réparation de véhicules automobiles", "G", 2.5, .45, 4, 200, 0, .6, .93),
    ("46.90", "Commerce de gros non spécialisé", "G", 3, .50, 6, 1100, 0, 1.2, .9),
    ("47.11", "Commerce de détail en magasin non spécialisé à prédominance alimentaire", "G", 3, .30, 12, 330, 0, 1, .68),
    ("47.30", "Commerce de détail de carburants en magasin spécialisé", "G", .5, .30, 5, 900, 0, .5, .8),
    ("47.71", "Commerce de détail d'habillement en magasin spécialisé", "G", 2.5, .50, 3, 180, 0, 1.3, .65),
    ("47.73", "Commerce de détail de produits pharmaceutiques en magasin spécialisé", "G", 1.5, .10, 5, 350, 0, 1, .75),
    ("47.91", "Vente à distance", "G", 1.5, .70, 3, 400, 0, 1.3, .85),
    ("49.41", "Transports routiers de fret", "H", 2, .30, 8, 160, 0, .5, .95),
    ("52.29", "Autres services auxiliaires des transports", "H", .6, .30, 10, 500, 0, 1.2, .93),
    ("55.10", "Hôtels et hébergement similaire", "I", 1, .35, 10, 90, 0, 1.8, .75),
    ("56.10", "Restaurants et services de restauration mobile", "I", 6, .35, 4, 75, 0, 1.5, .6),
    ("56.30", "Débits de boissons", "I", 3.5, .50, 2, 70, 0, 1.3, .55),
    ("58.13", "Édition de journaux", "J", .1, .20, 40, 220, 0, 2.5, .9),
    ("62.01", "Programmation informatique", "J", 3, .65, 6, 160, 0, 1.8, .93),
    ("62.02", "Conseil informatique", "J", 3, .70, 5, 170, 0, 1.8, .93),
    ("64.19", "Autres intermédiations monétaires", "K", .2, .10, 300, 600, 1, 8, .9),
    ("64.20", "Activités des sociétés holding", "K", 3, .95, 2, 300, 0, 2, .9),
    ("66.22", "Activités des agents et courtiers d'assurances", "K", 1.5, .50, 3, 150, 1, 1.3, .85),
    ("68.20", "Location et exploitation de biens immobiliers propres ou loués", "L", 6, .90, 2, 250, 0, 1.5, .85),
    ("69.10", "Activités juridiques", "M", 2.5, .65, 3, 140, 0, 2.5, .9),
    ("69.20", "Activités comptables", "M", 2.5, .50, 4, 120, 0, 1.3, .85),
    ("70.22", "Conseil pour les affaires et autres conseils de gestion", "M", 6, .85, 3, 200, 0, 2, .9),
    ("71.11", "Activités d'architecture", "M", 1.5, .70, 3, 120, 0, 1.3, .88),
    ("71.12", "Activités d'ingénierie et de conseils techniques", "M", 2, .60, 5, 160, 0, 1.3, .93),
    ("73.11", "Activités des agences de publicité", "M", 1, .60, 4, 250, 0, 2, .9),
    ("78.20", "Activités des agences de travail temporaire", "N", .3, 0, 150, 55, 0, 1.5, .6),
    ("81.21", "Nettoyage courant des bâtiments", "N", 1.2, .40, 10, 40, 0, 1.5, .55),
    ("85.59", "Enseignement divers", "P", 1.5, .70, 3, 80, 1, 1.5, .7),
    ("86.21", "Activité des médecins généralistes", "Q", 3, .85, 2, 150, 1, 1.1, .75),
    ("86.90", "Autres activités pour la santé humaine", "Q", 3, .80, 2, 90, 1, 1.1, .75),
    ("87.10", "Hébergement médicalisé", "Q", .4, 0, 60, 60, 1, .8, .78),
    ("88.10", "Action sociale sans hébergement pour personnes âgées et handicapées", "Q", .6, .10, 25, 50, 1, 1, .7),
    ("93.12", "Activités de clubs de sports", "R", 1.5, .80, 3, 60, 1, .9, .5),
    ("96.02", "Coiffure et soins de beauté", "S", 4, .70, 2, 60, 0, 1.2, .7),
]
nace = pd.DataFrame(C, columns=["classe", "libelle", "section", "poids", "p0", "med", "prod",
                                "exonere", "bxl", "tp"])
N = 12000

# --- Les entreprises ---------------------------------------------------------
k = rng.choice(len(nace), size=N, p=nace["poids"] / nace["poids"].sum())
e = nace.iloc[k].reset_index(drop=True)

# emploi salarié (postes de travail au 31 décembre)
employeur = rng.random(N) >= e["p0"]
emp = np.exp(rng.normal(np.log(e["med"]), 0.9))
e["emploi"] = np.where(employeur, np.clip(np.round(emp), 1, 4500), 0).astype(int)

# région, puis commune selon la population (Bruxelles sur- ou sous-représentée
# selon l'activité ; les grandes entreprises plutôt dans les grandes communes)
pop_reg = communes.groupby("region")["total"].sum()
regions = []
for f in e["bxl"]:
    w = pop_reg * pd.Series({"Bruxelles": f, "Flandre": 1.05, "Wallonie": .95})
    regions.append(rng.choice(w.index, p=w / w.sum()))
e["region"] = regions
code = []
for r, n in zip(e["region"], e["emploi"]):
    c = communes[communes["region"] == r]
    w = c["total"] ** (1.8 if n >= 100 else 1.0)
    code.append(rng.choice(c["code_ins"].to_numpy(), p=(w / w.sum()).to_numpy()))
e["code_ins"] = code
e = e.merge(communes[["code_ins", "commune", "arrondissement", "province"]], on="code_ins", how="left")

# année de création : les grandes entreprises sont plus anciennes
age = rng.exponential(12, N) + np.log1p(e["emploi"]) * 4
e["creation"] = np.clip(2025 - np.floor(age), 1950, 2025).astype(int)

# forme juridique
forme = np.where(e["emploi"] >= 50, "SA", "SRL")
petite = (e["emploi"] == 0) & (rng.random(N) < .45)
forme = np.where(petite & ~e["section"].isin(["K", "C", "D"]), "Personne physique", forme)
forme = np.where((e["emploi"] > 0) & (e["emploi"] < 50) & (rng.random(N) < .06), "SC", forme)
asbl = e["classe"].isin(["87.10", "88.10", "93.12"]) | ((e["classe"] == "85.59") & (rng.random(N) < .5))
e["forme"] = np.where(asbl, "ASBL", forme)

# chiffre d'affaires 2025 (k€), d'après les déclarations TVA ; vide si exonéré
base_ca = np.where(e["emploi"] > 0, e["emploi"] * e["prod"], e["prod"] * .45)
sig = np.where(e["emploi"] > 0, .45, .9)
ca = base_ca * np.exp(rng.normal(0, sig))
ca = np.where(e["classe"] == "64.20", ca * .3, ca)
e["ca"] = np.where(e["exonere"] == 1, np.nan, np.round(ca, 1))

# numéro d'entreprise fictif : 9 + 7 chiffres + clé modulo 97
corps = rng.choice(np.arange(9_000_0000, 9_999_9999), size=N, replace=False)
e["num_entreprise"] = [f"{c:08d}{97 - c % 97:02d}" for c in corps]

e["nace"] = e["classe"]
e["secteur"] = e["section"].map(SECTIONS)
entreprises = (e[["num_entreprise", "nace", "section", "secteur", "forme", "creation",
                  "code_ins", "commune", "arrondissement", "province", "region",
                  "emploi", "ca"]]
               .sort_values("num_entreprise").reset_index(drop=True))
assert entreprises["num_entreprise"].is_unique

# --- Déclarations TVA trimestrielles (en euros) -------------------------------
saison = {"I": [.20, .26, .32, .22], "G": [.23, .24, .23, .30], "F": [.20, .27, .28, .25],
          "A": [.18, .25, .35, .22]}
tva = entreprises[entreprises["ca"].notna()].copy()
lignes = []
for _, r in tva.iterrows():
    s = np.array(saison.get(r["section"], [.25, .25, .25, .25])) * np.exp(rng.normal(0, .08, 4))
    s = s / s.sum()
    q = np.round(r["ca"] * 1000 * s).astype(int)
    q[-1] = int(round(r["ca"] * 1000)) - q[:3].sum()      # la somme = le CA annuel
    nace_tva = r["nace"] if rng.random() > .04 else rng.choice(nace["classe"][nace["section"] == r["section"]])
    for t in range(4):
        jour = rng.integers(1, 20)
        mois = [4, 7, 10, 1][t]
        annee = 2026 if t == 3 else 2025
        lignes.append({"numero_tva": r["num_entreprise"], "trimestre": f"2025-T{t + 1}",
                       "chiffre_affaires": int(q[t]), "nace_tva": nace_tva,
                       "date_depot": f"{annee}-{mois:02d}-{jour:02d}"})
decl = pd.DataFrame(lignes)

# anomalies, comme dans de vraies livraisons
idx = rng.choice(decl.index, 9, replace=False)
# 1. deux notes de crédit : un trimestre négatif (c'est légitime)
for i in idx[:2]:
    decl.loc[i, "chiffre_affaires"] = -abs(int(decl.loc[i, "chiffre_affaires"] * .15)) - 500
# le chiffre d'affaires annuel de la table tient compte de ces notes de crédit
for n in decl.loc[idx[:2], "numero_tva"]:
    total = decl.loc[decl["numero_tva"] == n, "chiffre_affaires"].sum()
    entreprises.loc[entreprises["num_entreprise"] == n, "ca"] = round(total / 1000, 1)
# 2. déclarations rectificatives : une seconde ligne, déposée plus tard, qui remplace la première
rect = decl.loc[idx[2:5]].copy()
decl.loc[idx[2:5], "chiffre_affaires"] = (decl.loc[idx[2:5], "chiffre_affaires"] * 1.4).astype(int)
rect["date_depot"] = rect["trimestre"].map({"2025-T1": "2025-06-15", "2025-T2": "2025-09-15",
                                            "2025-T3": "2025-12-15", "2025-T4": "2026-03-15"})
decl = pd.concat([decl, rect], ignore_index=True)
# 3. un montant encodé en centimes (100 fois trop grand)
decl.loc[idx[5], "chiffre_affaires"] = decl.loc[idx[5], "chiffre_affaires"] * 100
# 4. une déclaration manquante (dépôt tardif) : supprimée
manquante = decl.loc[idx[6]].copy()
decl = decl.drop(index=idx[6])
# 5. une faute de frappe dans un numéro (la clé de contrôle ne correspond plus)
n = decl.loc[idx[7], "numero_tva"]
decl.loc[idx[7], "numero_tva"] = n[:5] + str((int(n[5]) + 1) % 10) + n[6:]

# formats différents d'un trimestre à l'autre
def fmt(n, style):
    if style == "be_points":
        return f"BE{n[:4]}.{n[4:7]}.{n[7:]}"
    if style == "brut":
        return n
    if style == "be_espace":
        return f"BE {n[:4]} {n[4:7]} {n[7:]}"
    return f"BE{n}"

decl = decl.sort_values(["trimestre", "numero_tva", "date_depot"]).reset_index(drop=True)
styles = {"2025-T1": "be_points", "2025-T2": "brut", "2025-T3": "be_espace", "2025-T4": "be"}
decl["numero_tva"] = [fmt(n, styles[t]) for n, t in zip(decl["numero_tva"], decl["trimestre"])]
# deux numéros mal saisis : minuscules et espaces autour
decl.loc[decl.index[decl["trimestre"] == "2025-T4"][:2], "numero_tva"] = \
    [" " + x.lower() + " " for x in decl.loc[decl.index[decl["trimestre"] == "2025-T4"][:2], "numero_tva"]]

def euros_fr(x):
    """1234567 -> '1.234.567,00' (format belge)"""
    return f"{x:,.2f}".replace(",", " ").replace(".", ",").replace(" ", ".")

T = {t: decl[decl["trimestre"] == t].drop(columns="trimestre").reset_index(drop=True)
     for t in styles}
# T1 : CSV « ; » et montants à la belge (virgule décimale, point des milliers)
t1 = T["2025-T1"].copy(); t1["chiffre_affaires"] = t1["chiffre_affaires"].map(euros_fr)
t1.to_csv(D + "donnees/tva_2025_T1.csv", sep=";", index=False, encoding="utf-8")
# T2 : Excel, deux lignes de titre ; numéros sans « BE » (lus comme des nombres !)
with pd.ExcelWriter(D + "donnees/tva_2025_T2.xlsx") as w:
    pd.DataFrame([["Déclarations TVA — 2e trimestre 2025 (données fictives)"], [""]]).to_excel(
        w, index=False, header=False)
    T["2025-T2"].to_excel(w, index=False, startrow=2)
# T3 : texte tabulé
T["2025-T3"].to_csv(D + "donnees/tva_2025_T3.txt", sep="\t", index=False, encoding="utf-8")
# T4 : CSV « , » classique
T["2025-T4"].to_csv(D + "donnees/tva_2025_T4.csv", sep=",", index=False, encoding="utf-8")

# --- Emploi ONSS ---------------------------------------------------------------
emp = entreprises[entreprises["emploi"] > 0].merge(nace[["classe", "tp"]], left_on="nace", right_on="classe")
autre = {"62.01": "62.02", "62.02": "62.01", "56.10": "56.30", "56.30": "56.10", "69.20": "70.22",
         "43.21": "41.20", "41.20": "43.21", "64.20": "70.22", "70.22": "64.20", "46.90": "47.11",
         "47.91": "46.90", "68.20": "41.20", "52.29": "49.41", "71.11": "71.12", "71.12": "71.11",
         "86.90": "86.21", "10.71": "47.11", "81.21": "78.20", "45.20": "47.30"}
def nace_onss(n):
    if n in autre and rng.random() < .18:
        return autre[n]
    return n
onss = pd.DataFrame({
    "num_entreprise": emp["num_entreprise"],
    "nace_onss": [nace_onss(n) for n in emp["nace"]],
    "postes": emp["emploi"],
    "etp": np.round(emp["emploi"] * np.clip(emp["tp"] * np.exp(rng.normal(0, .08, len(emp))), .3, 1), 1),
})
# employeurs absents de la table (radiés en cours d'année) et employeurs sans déclaration
radies = pd.DataFrame({"num_entreprise": [f"{c:08d}{97 - c % 97:02d}" for c in rng.choice(
    np.setdiff1d(np.arange(9_000_0000, 9_000_9999), corps), 6, replace=False)],
    "nace_onss": rng.choice(["56.10", "41.20", "47.71", "81.21", "62.01", "49.41"], 6),
    "postes": rng.integers(1, 12, 6)})
radies["etp"] = np.round(radies["postes"] * .8, 1)
onss = pd.concat([onss.drop(index=onss.sample(4, random_state=3).index), radies]).sort_values(
    "num_entreprise").reset_index(drop=True)
onss.to_csv(D + "donnees/onss_emploi_2025.csv", sep=";", index=False, encoding="utf-8", decimal=",")

# --- Référentiels ----------------------------------------------------------------
ref = nace[["classe", "libelle", "section"]].copy()
ref["division"] = ref["classe"].str.slice(0, 2)
ref["libelle_section"] = ref["section"].map(SECTIONS)
ref = ref[["classe", "libelle", "division", "section", "libelle_section"]]
ref.to_csv(D + "referentiels/nace_bel_2008.csv", sep=";", index=False, encoding="cp1252")

# NACE-BEL 2025 : extrait SIMPLIFIÉ de la correspondance, pour l'atelier
# (une classe peut se scinder en plusieurs, ou plusieurs se regrouper)
corr = [(c, c) for c in nace["classe"]]
eclat = {"56.10": ["56.11", "56.12"], "96.02": ["96.21", "96.22"], "35.11": ["35.11", "35.12"],
         "47.91": ["47.11", "47.71", "47.73"]}
regroup = {"62.01": "62.10", "62.02": "62.20", "70.22": "70.20", "41.20": "41.00"}
corr = []
for c in nace["classe"]:
    if c in eclat:
        corr += [(c, x) for x in eclat[c]]
    else:
        corr.append((c, regroup.get(c, c)))
corr = pd.DataFrame(corr, columns=["nace_2008", "nace_2025"])
corr.to_csv(D + "referentiels/correspondance_nace_2008_2025.csv", sep=";", index=False, encoding="utf-8")

shutil.copyfile("bases/communes_py/fichiers/referentiels/nuts_lau_2027.txt", D + "referentiels/nuts_lau_2027.txt")
entreprises.to_parquet(D + "donnees/entreprises_2025.parquet", index=False)
entreprises.to_csv(D + "donnees/entreprises_2025.csv", sep=";", decimal=",", index=False, encoding="utf-8")

print(entreprises.shape, decl.shape, onss.shape)
print("manquante :", manquante["numero_tva"], manquante["trimestre"])
print(entreprises.groupby("section").agg(n=("nace", "size"), emploi=("emploi", "sum"), ca=("ca", "sum")).round(0))
print(entreprises.groupby("region").agg(n=("nace", "size"), emploi=("emploi", "sum")))
print(entreprises["emploi"].describe())
