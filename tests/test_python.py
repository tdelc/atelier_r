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


def main():
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

    for dir in sorted(glob.glob(os.path.join(APP, "bases", "*"))):
        f = os.path.join(dir, "base.txt")
        if not os.path.exists(f) or base_txt(f).get("langage", "r").lower() != "python":
            continue
        meta = base_txt(f)
        base = os.path.basename(dir)
        # copie temporaire des fichiers : les écritures (sortie/) ne
        # touchent pas au dépôt, comme dans le navigateur
        travail = tempfile.mkdtemp(prefix="atelier_py_")
        shutil.copytree(os.path.join(dir, meta.get("dossier_python", "fichiers")), travail,
                        dirs_exist_ok=True)
        os.chdir(travail)
        os.makedirs("sortie", exist_ok=True)
        print(f"\n========== Base : {base} ==========")

        lecons = sorted(glob.glob(os.path.join(dir, "cours", "*.md")))
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

        pistes = sections(read(os.path.join(dir, "decouverte.md"))) \
            if os.path.exists(os.path.join(dir, "decouverte.md")) else []
        for p in pistes:
            runner.reset("piste")
            for code, mode in code_blocks(p["lines"]):
                if mode != "norun":
                    report(f"[découverte] {p['title']}", json.loads(runner.run("piste", code)))
                    break

        exs = sections(read(os.path.join(dir, "exercices.md"))) \
            if os.path.exists(os.path.join(dir, "exercices.md")) else []
        for i, e in enumerate(exs, 1):
            subs = {s["title"].lower(): s["lines"] for s in sections(e["lines"], 2)}
            code_of = lambda name: "\n".join(c for c, _ in code_blocks(subs.get(name, [])))
            prep, corr = code_of("préparation"), code_of("correction")
            verif = "aucune" if re.search(r"^verif:\s*aucune", "\n".join(e["lines"]), re.M) else "valeur"
            if not corr or "énoncé" not in subs:
                fails += 1; print("✗ exercice incomplet :", e["title"]); continue
            res = json.loads(runner.check(f"{base}/ex{i}", prep, corr, corr))
            report(f"[exercice] ex{i:02d} {e['title']}", res)
            if verif == "valeur" and res["feedback"]["status"] != "ok":
                fails += 1
                print(f"✗ [exercice] ex{i:02d} {e['title']} : correction refusée par la vérification "
                      f"({res['feedback']['message']})")
        print(f"{base} : {len(lecons)} leçons, {len(pistes)} pistes, {len(exs)} exercices")

    print(f"\n{n} exécutions, {fails} échecs")
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
