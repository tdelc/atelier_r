# ============================================================================
# runner.py — exécution d'une « cellule » Python, comme dans un notebook
#
# Ce fichier tourne DANS LE NAVIGATEUR de l'étudiant (Pyodide, dans un Web
# Worker : voir py_worker.js). Il n'a aucun accès au serveur.
#
#   run(ns, code)          exécute le code dans l'espace de noms `ns` et
#                          renvoie la liste des sorties : texte affiché,
#                          valeur de la dernière ligne, graphiques, erreur
#   reset(ns)              efface un espace de noms
#   objects(ns)            les objets créés (pour « Objets disponibles »)
#   check(key, prep, correction, code)
#                          vérifie un exercice : compare la valeur de la
#                          dernière ligne à celle de la correction
# ============================================================================

import ast, base64, io, json, math, re, sys, traceback, warnings

NAMESPACES = {}
SOLUTIONS = {}
MAX_TEXT = 20000


# Code exécuté en silence au début de chaque espace de noms : il précharge
# les tables de la base (clé « demarrage_python » de base.txt), comme les
# bases R sont déjà chargées dans le bac à sable.
DEMARRAGE = None


def set_demarrage(chemin):
    global DEMARRAGE
    with open(chemin, encoding="utf-8") as f:
        DEMARRAGE = f.read()


def _ns(name):
    if name not in NAMESPACES:
        g = {"__name__": "__main__"}
        NAMESPACES[name] = g
        if DEMARRAGE:
            old = sys.stdout, sys.stderr
            sys.stdout = sys.stderr = io.StringIO()
            try:
                exec(compile(DEMARRAGE, "<demarrage>", "exec"), g)
            finally:
                sys.stdout, sys.stderr = old
    return NAMESPACES[name]


def reset(name):
    NAMESPACES.pop(name, None)


# --- Affichage d'une valeur -----------------------------------------------------

def _display(value):
    """Une sortie à afficher pour la valeur de la dernière ligne."""
    if value is None:
        return None
    # objets de graphique (Axes, Figure, listes de tracés) : le graphique
    # lui-même est affiché, pas sa description « <Axes: ...> »
    probe = value[0] if isinstance(value, (list, tuple)) and value else value
    if type(probe).__module__.startswith(("matplotlib", "seaborn")):
        return None
    # nombres NumPy (np.int64(42)) : affichés comme des nombres ordinaires
    if type(value).__module__ == "numpy" and hasattr(value, "item") and getattr(value, "ndim", 1) == 0:
        value = value.item()
    # valeurs uniques d'une colonne (pandas .unique()) : une liste lisible
    try:
        import pandas as pd
        if isinstance(value, pd.api.extensions.ExtensionArray):
            return {"type": "output", "text": (repr(value.tolist()) + "\n(" + _t("py.valeurs", "{n} valeurs", n=len(value)) + ")")[:MAX_TEXT]}
    except ImportError:
        pass
    # tableaux pandas : HTML échappé (les textes ne peuvent pas injecter de HTML)
    if hasattr(value, "_repr_html_") and type(value).__module__.startswith("pandas"):
        try:
            html = value._repr_html_()
            if html:
                html = re.sub(r"<style scoped>.*?</style>", "", html, flags=re.S)
                return {"type": "table", "html": html}
        except Exception:
            pass
    if type(value).__module__.startswith("duckdb"):
        try:
            return {"type": "output", "text": str(value)[:MAX_TEXT]}
        except Exception:
            pass
    return {"type": "output", "text": repr(value)[:MAX_TEXT]}


def _figures():
    """Les graphiques matplotlib ouverts, en PNG, puis fermés."""
    if "matplotlib.pyplot" not in sys.modules:
        return []
    plt = sys.modules["matplotlib.pyplot"]
    out = []
    for num in plt.get_fignums():
        fig = plt.figure(num)
        buf = io.BytesIO()
        fig.savefig(buf, format="png", dpi=110, bbox_inches="tight")
        out.append({"type": "plot",
                    "src": "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode()})
    plt.close("all")
    return out


# --- Messages d'erreur ------------------------------------------------------------

# Textes affichés à l'étudiant. Les valeurs ci-dessous (français) servent par
# défaut ; la page les remplace par ceux de sa langue au démarrage
# (set_textes(), avec les clés « py.* » de i18n/interface.csv).
TEXTES = {}


def set_textes(js):
    """Remplace les textes par ceux de la langue de la page (JSON)."""
    TEXTES.update(json.loads(js))
    for k, v in TEXTES.items():
        if k.startswith("py.aide."):
            AIDES[k[len("py.aide."):]] = v


def _t(cle, defaut, **kw):
    txt = TEXTES.get(cle, defaut)
    for k, v in kw.items():
        txt = txt.replace("{" + k + "}", str(v))
    return txt


AIDES = {
    "UnicodeDecodeError": "Le fichier n'est pas dans l'encodage supposé (UTF-8 par défaut) : essayez encoding=\"cp1252\" (Windows) ou \"latin-1\".",
    "FileNotFoundError": "Le fichier est introuvable : vérifiez le dossier (donnees/, referentiels/, sortie/) et l'orthographe du nom.",
    "NameError": "Ce nom n'existe pas (encore) : faute de frappe, ou cellule précédente pas exécutée ?",
    "KeyError": "Cette clé ou cette colonne n'existe pas : vérifiez l'orthographe exacte (majuscules, espaces) avec .columns ou .keys().",
    "IndentationError": "L'indentation (les espaces en début de ligne) délimite les blocs : 4 espaces après chaque « : ».",
    "SyntaxError": "Python ne comprend pas la phrase : parenthèse, guillemet ou « : » manquant ? Un = au lieu de == ?",
    "TypeError": "L'opération ne convient pas à ce type de valeur : vérifiez les types avec type() ou .dtypes.",
    "ValueError": "La valeur ne convient pas : par exemple un texte qui ne se convertit pas en nombre.",
    "IndexError": "Cette position n'existe pas : les positions commencent à 0 et la dernière est len(...) - 1.",
    "ZeroDivisionError": "Division par zéro.",
    "ModuleNotFoundError": "Ce module n'est pas disponible dans l'atelier.",
    "MergeError": "La jointure ne respecte pas validate= : une clé apparaît plusieurs fois. Repérez les doublons avec .duplicated(subset=...) et filtrez la table.",
    "AssertionError": "Un contrôle assert a échoué : la condition vérifiée est fausse (lisez le message après « AssertionError »).",
    "AttributeError": "Cet objet n'a pas cet attribut ou cette méthode : vérifiez l'orthographe et le type de l'objet avec type().",
    "BinderException": "DuckDB ne trouve pas une colonne ou une table de la requête : vérifiez les noms (SELECT, FROM, GROUP BY).",
    "ParserException": "La requête SQL est mal écrite : virgule, guillemet ou mot-clé manquant ?",
}


def _error(e):
    name = type(e).__name__
    msg = f"{name}: {e}"
    if isinstance(e, SyntaxError) and e.lineno:
        msg = f"{name}: {e.msg} (" + _t("py.ligne", "ligne {n}", n=e.lineno) + ")"
    tb = traceback.extract_tb(e.__traceback__)
    lines = [_t("py.ligne", "ligne {n}", n=fr.lineno) + f" : {fr.line}" for fr in tb if fr.filename == "<cellule>" and fr.line]
    aide = next((v for k, v in AIDES.items() if k == name), None)
    if aide is None:
        for cls in type(e).__mro__:
            if cls.__name__ in AIDES:
                aide = AIDES[cls.__name__]
                break
    return {"type": "error", "text": msg[:MAX_TEXT], "where": lines[-3:], "hint": aide or ""}


# --- Exécution ---------------------------------------------------------------------

class _Capture(io.StringIO):
    pass


def _execute(name, code):
    """Exécute `code` ; renvoie (sorties, valeur de la dernière ligne, ok)."""
    g = _ns(name)
    items, value, ok = [], None, True
    out, err = _Capture(), _Capture()
    old = sys.stdout, sys.stderr
    sys.stdout, sys.stderr = out, err
    caught = []
    old_show = warnings.showwarning

    def show(message, category, filename, lineno, file=None, line=None):
        caught.append(f"{category.__name__}: {message}")
    warnings.showwarning = show
    try:
        tree = ast.parse(code, filename="<cellule>")
        last = None
        if tree.body and isinstance(tree.body[-1], ast.Expr):
            last = ast.Expression(tree.body.pop().value)
        exec(compile(tree, "<cellule>", "exec"), g)
        if last is not None:
            value = eval(compile(last, "<cellule>", "eval"), g)
    except BaseException as e:   # SystemExit, KeyboardInterrupt compris
        ok = False
        failure = _error(e)
    finally:
        sys.stdout, sys.stderr = old
        warnings.showwarning = old_show
    text = out.getvalue()
    if text:
        items.append({"type": "output", "text": text[:MAX_TEXT]})
    if ok:
        d = _display(value)
        if d:
            items.append(d)
    items.extend(_figures())
    for w in caught:
        items.append({"type": "warning", "text": w[:2000]})
    if err.getvalue().strip():
        items.append({"type": "warning", "text": err.getvalue()[:2000]})
    if not ok:
        items.append(failure)
    return items, value, ok


def run(name, code):
    items, _, ok = _execute(name, code)
    return json.dumps({"ok": ok, "items": items})


def objects(name):
    g = _ns(name)
    res = []
    for k, v in g.items():
        if k.startswith("_") or type(v).__name__ == "module" or isinstance(v, type):
            continue                      # modules et classes importés
        if type(v).__name__ == "function":
            desc = _t("py.fonction", "fonction")
        elif callable(v):
            continue
        elif hasattr(v, "shape") and hasattr(v, "columns"):
            desc = f"DataFrame : {v.shape[0]:,} × {v.shape[1]}".replace(",", " ")
        elif hasattr(v, "shape") and hasattr(v, "dtype"):
            desc = f"{type(v).__name__} [{len(v):,}]".replace(",", " ")
        elif isinstance(v, (list, tuple, set, dict)):
            desc = f"{type(v).__name__} [{len(v)}]"
        else:
            desc = type(v).__name__
        res.append({"name": k, "desc": desc})
    return json.dumps(sorted(res, key=lambda x: x["name"].lower()))


# --- Vérification des exercices ---------------------------------------------------
# Même principe que compare.R : les noms de colonnes et l'ordre des lignes
# peuvent différer ; chaque colonne de la correction doit se retrouver dans le
# résultat de l'étudiant avec les mêmes valeurs (à 1e-6 près).

def _is_missing(x):
    try:
        import pandas as pd
        return x is None or bool(pd.isna(x))
    except Exception:
        return x is None


def _norm(x):
    if _is_missing(x):
        return None
    if hasattr(x, "item") and not isinstance(x, (str, bytes)):
        try:
            x = x.item()
        except Exception:
            pass
    if isinstance(x, bool):
        return float(x)
    if isinstance(x, (int, float)):
        return round(float(x), 6)
    return str(x)


def _comparable(x):
    """Liste de colonnes (listes de valeurs), ou None si non comparable."""
    if x is None:
        return None
    mod = type(x).__module__
    try:
        import pandas as pd
        if mod.startswith("duckdb"):
            x = x.df()
        if isinstance(x, pd.Series):
            x = x.to_frame()
        if isinstance(x, pd.DataFrame):
            idx = x.index
            keep_index = isinstance(idx, pd.MultiIndex) or idx.name is not None or \
                not pd.api.types.is_integer_dtype(idx.dtype)
            if keep_index:
                x = x.reset_index()
            return [[_norm(v) for v in x[c].tolist()] for c in x.columns]
        if hasattr(x, "tolist") and hasattr(x, "shape"):       # tableau NumPy
            x = x.tolist()
    except ImportError:
        pass
    if isinstance(x, dict):
        return [[_norm(k) for k in x.keys()], [_norm(v) for v in x.values()]]
    if isinstance(x, (set, frozenset)):
        return [sorted((_norm(v) for v in x), key=lambda v: (v is None, str(v)))]
    if isinstance(x, (list, tuple)):
        if x and all(isinstance(r, (list, tuple)) for r in x):
            return [[_norm(r[i]) if i < len(r) else None for r in x] for i in range(max(len(r) for r in x))]
        return [[_norm(v) for v in x]]
    if isinstance(x, (int, float, str, bool)) or hasattr(x, "item"):
        return [[_norm(x)]]
    return None


def _same(a, b):
    if len(a) != len(b):
        return False
    key = lambda v: (v is None, isinstance(v, str), v if not isinstance(v, str) else 0, str(v))
    a, b = sorted(a, key=key), sorted(b, key=key)
    for u, v in zip(a, b):
        if u is None or v is None:
            if u is not v:
                return False
        elif isinstance(u, float) and isinstance(v, float):
            if not math.isclose(u, v, abs_tol=1e-6):
                return False
        elif str(u) != str(v):
            return False
    return True


def compare(student, solution):
    sol = _comparable(solution)
    if sol is None:
        return {"status": "na", "message": _t("py.verif.na", "Ce résultat ne se vérifie pas automatiquement : comparez avec la correction.")}
    stu = _comparable(student)
    if stu is None:
        return {"status": "ko", "message": _t("py.verif.pas_de_valeur", "Votre code ne produit pas de valeur à comparer. La dernière ligne doit être le résultat demandé (sans print).")}
    if len(sol) == 1 and len(sol[0]) == 1 and len(stu) == 1 and len(stu[0]) == 1:
        if _same(stu[0], sol[0]):
            return {"status": "ok", "message": _t("py.verif.ok", "Bravo, votre résultat correspond à la correction !")}
        return {"status": "ko", "message": _t("py.verif.valeur", "La valeur obtenue n'est pas celle attendue. Relisez l'énoncé (calcul, arrondi, type).")}
    n_sol, n_stu = len(sol[0]), len(stu[0])
    if n_sol != n_stu:
        return {"status": "ko", "message": _t("py.verif.lignes", "Votre résultat a {eleve} ligne(s) ou élément(s), la correction en a {sol}.", eleve=n_stu, sol=n_sol)}
    used, missing = [False] * len(stu), 0
    for col in sol:
        hit = next((i for i, c in enumerate(stu) if not used[i] and _same(c, col)), None)
        if hit is None:
            missing += 1
        else:
            used[hit] = True
    if missing == 0:
        return {"status": "ok", "message": _t("py.verif.ok", "Bravo, votre résultat correspond à la correction !")}
    return {"status": "ko", "message": _t("py.verif.colonnes", "Le nombre de lignes est bon, mais {n} colonne(s) de la correction ne se retrouvent pas dans votre résultat.", n=missing)}


def check(key, prep, correction, code):
    """Exécute la correction (une fois) et le code de l'étudiant, puis compare."""
    if key not in SOLUTIONS:
        reset("__sol__")
        if prep:
            _execute("__sol__", prep)
        _, v, ok = _execute("__sol__", correction)
        SOLUTIONS[key] = v if ok else None
    reset("__ex__")
    if prep:
        _execute("__ex__", prep)
    items, value, ok = _execute("__ex__", code)
    if not ok:
        fb = {"status": "ko", "message": _t("py.verif.erreur", "Votre code produit une erreur : corrigez-la d'abord (voir le résultat ci-dessous).")}
    else:
        fb = compare(value, SOLUTIONS[key])
    return json.dumps({"ok": ok, "items": items, "feedback": fb})
