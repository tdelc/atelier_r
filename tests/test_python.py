# ============================================================================
# Exécute TOUT le contenu des bases en Python, avec le même moteur que dans
# le navigateur (www/python/runner.py), mais avec le Python de votre poste :
#  - chaque bloc de chaque leçon, dans l'ordre (```python erreur : le bloc
#    DOIT produire une erreur, c'est une erreur volontaire du cours) ;
#  - chaque piste de découverte ;
#  - chaque correction d'exercice, qui doit être acceptée par la vérification.
#
#   python tests/test_python.py            (depuis le dossier de l'application)
#
# Le même contenu s'exécute aussi dans un vrai navigateur, avec Pyodide
# (la version utilisée par les étudiants) : tests/test_python_navigateur.js.
#
# Paquets nécessaires : pandas, pyarrow, numpy, matplotlib, seaborn, openpyxl,
# duckdb (les mêmes que dans le navigateur).
# ============================================================================

import glob, json, os, re, shutil, sys, tempfile

APP = os.path.abspath(os.path.dirname(os.path.dirname(__file__)))
sys.path.insert(0, os.path.join(APP, "www", "python"))
os.environ.setdefault("MPLBACKEND", "Agg")


def base_txt(path):
    meta = {}
    for l in open(path, encoding="utf-8"):
        if re.match(r"^\s*[A-Za-z_]\w*\s*:", l) and not l.lstrip().startswith("#"):
            k, v = l.split(":", 1)
            meta[k.strip()] = v.strip()
    return meta


def sections(lines, level=1):
    """Découpe selon les titres « # » (ou « ## »), hors blocs de code."""
    out, cur, in_code = [], None, False
    pat = re.compile(r"^" + "#" * level + r"\s+\S")
    for l in lines:
        if l.startswith("```"):
            in_code = not in_code
        if not in_code and pat.match(l) and not l.startswith("#" * (level + 1)):
            cur = {"title": l[level:].strip(), "lines": []}
            out.append(cur)
        elif cur is not None:
            cur["lines"].append(l)
    return out


def code_blocks(lines):
    """[(code, mode)] : mode = run, setup, norun ou erreur."""
    blocks, code, mode = [], None, None
    for l in lines:
        m = re.match(r"^```\s*\{?(python|py)\b(.*)$", l)
        if code is None and m:
            opts = m.group(2)
            mode = next((o for o in ("norun", "setup", "erreur") if o in opts), "run")
            code = []
        elif code is not None and re.match(r"^```\s*$", l):
            blocks.append(("\n".join(code), mode))
            code = None
        elif code is not None:
            code.append(l)
    return blocks


def read(path):
    lines = open(path, encoding="utf-8").read().split("\n")
    if lines and lines[0].strip() == "---":
        end = lines.index("---", 1) if "---" in lines[1:] else 0
        lines = lines[end + 1:]
    return lines


LANGUES = ["fr", "nl", "en"]


def cibles():
    """(base, langue, dossier du contenu, base.txt fusionné) pour chaque base
    Python et chaque langue disponible : le français dans le dossier de la
    base, les traductions dans bases/<base>/<langue>/ (seuls les fichiers
    traduits sont exécutés ; ce qui manque est le contenu français, déjà testé)."""
    for dir in sorted(glob.glob(os.path.join(APP, "bases", "*"))):
        f = os.path.join(dir, "base.txt")
        if not os.path.exists(f) or base_txt(f).get("langage", "r").lower() != "python":
            continue
        meta = base_txt(f)
        yield os.path.basename(dir), "fr", dir, dir, meta
        for lang in LANGUES[1:]:
            d = os.path.join(dir, lang)
            if os.path.isdir(d):
                m = dict(meta)
                if os.path.exists(os.path.join(d, "base.txt")):
                    m.update(base_txt(os.path.join(d, "base.txt")))
                yield os.path.basename(dir), lang, d, dir, m


SOUS_TITRES = {"énoncé": ["opgave", "question"], "indice": ["hint"],
               "préparation": ["voorbereiding", "preparation"],
               "code de départ": ["startcode", "starting code"],
               "correction": ["oplossing", "solution"], "commentaire": ["commentaar", "comment"]}


def sous_sections(lines):
    """Les sous-sections « ## » d'un exercice, sous leur nom français."""
    out = {}
    for s in sections(lines, 2):
        t = s["title"].lower()
        for fr, autres in SOUS_TITRES.items():
            if t in autres:
                t = fr
        out[t] = s["lines"]
    return out


def lire_exercices(contenu):
    fx = os.path.join(contenu, "exercices.md")
    out = []
    for i, e in enumerate(sections(read(fx)) if os.path.exists(fx) else [], 1):
        subs = sous_sections(e["lines"])
        code_of = lambda n, subs=subs: "\n".join(c for c, _ in code_blocks(subs.get(n, [])))
        verif = "aucune" if re.search(r"^verif:\s*aucune", "\n".join(e["lines"]), re.M) else "valeur"
        out.append({"id": f"ex{i:02d}", "titre": e["title"], "verif": verif,
                    "prep": code_of("préparation"), "correction": code_of("correction"),
                    "complet": bool(code_of("correction")) and "énoncé" in subs})
    return out


def export_json():
    """Le contenu à exécuter, pour tests/test_python_navigateur.js."""
    out = []
    for base, lang, contenu, dir, meta in cibles():
        B = {"base": base, "lang": lang, "lecons": [], "exercices": lire_exercices(contenu)}
        for path in sorted(glob.glob(os.path.join(contenu, "cours", "*.md"))):
            B["lecons"].append([{"code": c, "mode": m, "where": f"{os.path.basename(path)} carte {k}"}
                                for k, card in enumerate(sections(read(path)), 1)
                                for c, m in code_blocks(card["lines"]) if m != "norun"])
        out.append(B)
    print(json.dumps(out))


def main():
    if "--json" in sys.argv:
        return export_json()
    import runner
    fails, n = 0, 0

    def report(where, res, expect_error=False):
        nonlocal fails, n
        n += 1
        errs = [i["text"] for i in res["items"] if i["type"] == "error"]
        if expect_error and not errs:
            fails += 1
            print("✗", where, ": une erreur volontaire était attendue")
        elif errs and not expect_error:
            fails += 1
            print("✗", where, ":", errs[0])

    for base, lang, contenu, dir, meta in cibles():
        # copie temporaire des fichiers : les écritures (sortie/) ne
        # touchent pas au dépôt, comme dans le navigateur
        travail = tempfile.mkdtemp(prefix="atelier_py_")
        shutil.copytree(os.path.join(dir, meta.get("dossier_python", "fichiers")), travail,
                        dirs_exist_ok=True)
        os.chdir(travail)
        sys.path.insert(0, travail)              # import outils_cours
        for mod in [m for m in sys.modules if m.startswith("outils_")]:
            sys.modules.pop(mod, None)
        runner.DEMARRAGE = None                  # tables préchargées de la base
        if meta.get("demarrage_python"):
            runner.set_demarrage(meta["demarrage_python"])
        runner.NAMESPACES.clear(); runner.SOLUTIONS.clear()
        for d in ["sortie", "uitvoer", "output"]:
            os.makedirs(d, exist_ok=True)
        print(f"\n========== Base : {base} ({lang}) ==========")

        lecons = sorted(glob.glob(os.path.join(contenu, "cours", "*.md")))
        for path in lecons:
            ns = "cours:" + path
            runner.reset(ns)
            for k, card in enumerate(sections(read(path)), 1):
                for code, mode in code_blocks(card["lines"]):
                    if mode == "norun":
                        continue
                    res = json.loads(runner.run(ns, code))
                    report(f"[cours] {os.path.basename(path)} / carte {k} « {card['title']} »",
                           res, expect_error=(mode == "erreur"))

        fp = os.path.join(contenu, "decouverte.md")
        pistes = sections(read(fp)) if os.path.exists(fp) else []
        for p in pistes:
            runner.reset("piste")
            for code, mode in code_blocks(p["lines"]):
                if mode != "norun":
                    report(f"[découverte] {p['title']}", json.loads(runner.run("piste", code)))
                    break

        exs = lire_exercices(contenu)
        for e in exs:
            if not e["complet"]:
                fails += 1; print("✗ exercice incomplet :", e["titre"]); continue
            res = json.loads(runner.check(f"{base}/{lang}/{e['id']}", e["prep"], e["correction"], e["correction"]))
            report(f"[exercice] {e['id']} {e['titre']}", res)
            if e["verif"] == "valeur" and res["feedback"]["status"] != "ok":
                fails += 1
                print(f"✗ [exercice] {e['id']} {e['titre']} : correction refusée par la vérification "
                      f"({res['feedback']['message']})")
        print(f"{base} ({lang}) : {len(lecons)} leçons, {len(pistes)} pistes, {len(exs)} exercices")

    print(f"\n{n} exécutions, {fails} échecs")
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
