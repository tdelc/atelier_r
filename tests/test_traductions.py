# ============================================================================
# État des traductions de l'atelier
#
#   python tests/test_traductions.py              rapport complet
#   python tests/test_traductions.py --marquer nl bases/communes_py cours/05-par-groupe.md
#        enregistre qu'un fichier traduit est à jour avec sa source française
#        (après une traduction ou une relecture)
#   python tests/test_traductions.py --marquer nl bases/communes_py --tout
#        idem pour tous les fichiers traduits de la base
#
# Ce qui est contrôlé :
#  1. L'interface (i18n/interface.csv) : textes non traduits ; clés utilisées
#     dans le code (tr("…"), T("…")) mais absentes du fichier.
#  2. Le contenu de chaque base (bases/<base>/<langue>/) :
#     - les fichiers pas encore traduits (ils s'affichent en français) ;
#     - la STRUCTURE : même nombre de cartes, mêmes blocs de code (et mêmes
#       options : norun, setup, erreur), même nombre d'exercices, mêmes
#       niveaux et mêmes vérifications. Une traduction ne doit changer que
#       le texte (et, dans le code, les noms et les libellés) ;
#     - la FRAÎCHEUR : <langue>/sources.txt garde l'empreinte du fichier
#       français au moment de la traduction. Si le français a changé depuis,
#       la traduction est signalée « à revoir ».
#
# Code de sortie : 1 si une erreur de structure ou une clé manque dans le
# fichier d'interface ; les fichiers non traduits ou à revoir sont signalés
# sans faire échouer le test (sauf avec --strict).
# ============================================================================

import csv, glob, hashlib, os, re, sys

APP = os.path.abspath(os.path.dirname(os.path.dirname(__file__)))
sys.path.insert(0, os.path.join(APP, "tests"))
from test_python import sections, code_blocks, read  # noqa: E402

LANGUES = ["nl", "en"]
CONTENUS = ["base.txt", "dictionnaire.csv", "decouverte.md", "exercices.md"]


def empreinte(path):
    return hashlib.sha1(open(path, "rb").read()).hexdigest()[:12]


def lire_sources(d):
    f = os.path.join(d, "sources.txt")
    out = {}
    if os.path.exists(f):
        for l in open(f, encoding="utf-8"):
            if ":" in l and not l.startswith("#"):
                k, v = l.split(":", 1)
                out[k.strip()] = v.strip()
    return out


def ecrire_sources(d, sources):
    with open(os.path.join(d, "sources.txt"), "w", encoding="utf-8") as f:
        f.write("# Empreinte du fichier français au moment de la traduction (ne pas modifier :\n"
                "# python tests/test_traductions.py --marquer <langue> <base> <fichier>)\n")
        for k in sorted(sources):
            f.write(f"{k}: {sources[k]}\n")


def fichiers_source(base):
    rel = [c for c in CONTENUS if os.path.exists(os.path.join(base, c))]
    rel += [os.path.relpath(p, base) for p in sorted(glob.glob(os.path.join(base, "cours", "*.md")))]
    return rel


def structure_lecon(path):
    out = []
    for card in sections(read(path)):
        out.append([m for _, m in code_blocks(card["lines"])])
    return out


def meta_exercice(lines):
    m = {}
    for l in lines:
        r = re.match(r"^(niveau|verif|groupe):\s*(.*)$", l)
        if r:
            m[r.group(1)] = r.group(2).strip()
        if l.startswith("## "):
            break
    return m


def comparer(base, lang, rel, erreurs):
    fr, tr_ = os.path.join(base, rel), os.path.join(base, lang, rel)
    nom = f"{os.path.basename(base)}/{lang}/{rel}"
    if rel.startswith("cours/"):
        a, b = structure_lecon(fr), structure_lecon(tr_)
        if len(a) != len(b):
            erreurs.append(f"{nom} : {len(b)} cartes, {len(a)} en français")
        else:
            for k, (x, y) in enumerate(zip(a, b), 1):
                if x != y:
                    erreurs.append(f"{nom}, carte {k} : blocs de code {y}, en français {x}")
    elif rel == "exercices.md":
        a, b = sections(read(fr)), sections(read(tr_))
        if len(a) != len(b):
            erreurs.append(f"{nom} : {len(b)} exercices, {len(a)} en français")
        for i, (x, y) in enumerate(zip(a, b), 1):
            mx, my = meta_exercice(x["lines"]), meta_exercice(y["lines"])
            for k in ("niveau", "verif"):
                if mx.get(k) != my.get(k):
                    erreurs.append(f"{nom}, exercice {i} : {k} = {my.get(k)}, en français {mx.get(k)}")
            if ("groupe" in mx) != ("groupe" in my):
                erreurs.append(f"{nom}, exercice {i} : clé groupe présente d'un seul côté")
            subs = {s["title"].lower() for s in sections(y["lines"], 2)}
            if "énoncé" not in subs or "correction" not in subs:
                erreurs.append(f"{nom}, exercice {i} : il manque « ## Énoncé » ou « ## Correction » "
                               "(les titres de structure restent en français)")
    elif rel == "decouverte.md":
        a, b = sections(read(fr)), sections(read(tr_))
        if len(a) != len(b):
            erreurs.append(f"{nom} : {len(b)} pistes, {len(a)} en français")


def interface(erreurs, avertissements):
    t = list(csv.DictReader(open(os.path.join(APP, "i18n", "interface.csv"), encoding="utf-8")))
    cles = {r["cle"] for r in t}
    for l in LANGUES:
        manq = [r["cle"] for r in t if not r.get(l, "").strip()]
        if manq:
            avertissements.append(f"interface ({l}) : {len(manq)} texte(s) non traduit(s) : {', '.join(manq[:8])}"
                                  + (" …" if len(manq) > 8 else ""))
    utilisees = set()
    for f in glob.glob(os.path.join(APP, "R", "*.R")) + [os.path.join(APP, "app.R")]:
        utilisees |= set(re.findall(r'\btr\("([\w.]+)"', open(f, encoding="utf-8").read()))
    for f in glob.glob(os.path.join(APP, "www", "**", "*.js"), recursive=True):
        utilisees |= set(re.findall(r'\bT\(\s*["\']([\w.]+)["\']\)', open(f, encoding="utf-8").read()))
        utilisees |= set(re.findall(r'status\("([\w.]+)"\)', open(f, encoding="utf-8").read()))
    dyn = {"ex.niveau", "accueil.bases"}           # clés construites (ex.niveau1…)
    absentes = sorted(c for c in utilisees if c not in cles and c not in dyn)
    for c in absentes:
        erreurs.append(f"interface : la clé « {c} » est utilisée dans le code mais absente de i18n/interface.csv")
    return len(t)


def main():
    args = sys.argv[1:]
    if args and args[0] == "--marquer":
        lang, base = args[1], os.path.join(APP, args[2]) if not os.path.isabs(args[2]) else args[2]
        d = os.path.join(base, lang)
        sources = lire_sources(d)
        rels = fichiers_source(base) if "--tout" in args else args[3:]
        for rel in rels:
            if os.path.exists(os.path.join(d, rel)):
                sources[rel] = empreinte(os.path.join(base, rel))
                print("à jour :", rel)
        ecrire_sources(d, sources)
        return

    erreurs, avertissements = [], []
    n = interface(erreurs, avertissements)
    print(f"Interface : {n} textes")
    for base in sorted(glob.glob(os.path.join(APP, "bases", "*"))):
        if not os.path.exists(os.path.join(base, "base.txt")):
            continue
        for lang in LANGUES:
            d = os.path.join(base, lang)
            if not os.path.isdir(d):
                continue
            sources = lire_sources(d)
            rels = fichiers_source(base)
            trad = [r for r in rels if os.path.exists(os.path.join(d, r))]
            non = [r for r in rels if r not in trad]
            perimes = [r for r in trad if sources.get(r) != empreinte(os.path.join(base, r))]
            for r in trad:
                comparer(base, lang, r, erreurs)
            orphelins = [os.path.relpath(p, d) for p in glob.glob(os.path.join(d, "cours", "*.md"))
                         if not os.path.exists(os.path.join(base, os.path.relpath(p, d)))]
            print(f"{os.path.basename(base)} ({lang}) : {len(trad)}/{len(rels)} fichiers traduits")
            if non:
                avertissements.append(f"{os.path.basename(base)} ({lang}) non traduits : {', '.join(non)}")
            if perimes:
                avertissements.append(f"{os.path.basename(base)} ({lang}) à revoir (le français a changé "
                                      f"depuis la traduction) : {', '.join(perimes)}")
            for o in orphelins:
                erreurs.append(f"{os.path.basename(base)} ({lang}) : {o} n'a pas de leçon française du même nom")

    for a in avertissements:
        print("⚠", a)
    for e in erreurs:
        print("✗", e)
    print(f"\n{len(erreurs)} erreur(s), {len(avertissements)} avertissement(s)")
    sys.exit(1 if erreurs or ("--strict" in args and avertissements) else 0)


if __name__ == "__main__":
    main()
