// ===========================================================================
// Exécute TOUT le contenu des bases en Python dans un vrai navigateur, avec
// Pyodide : la version de Python, pandas, DuckDB… qu'utilisent les étudiants.
// Ce test a trouvé des différences que le Python du poste ne montre pas.
//
// 1. lancer l'application :  Rscript -e 'shiny::runApp(".", port = 8765)'
// 2. dans un autre terminal : node tests/test_python_navigateur.js
//
// Il faut Node.js, le paquet playwright (npm install playwright) et un
// Python 3 (sans paquet particulier) pour lire le contenu. Adresse de
// l'application : variable ATELIER_URL (par défaut http://127.0.0.1:8765).
// ===========================================================================

const { execFileSync } = require("child_process");
const path = require("path");
const { chromium } = require("playwright");

const url = process.env.ATELIER_URL || "http://127.0.0.1:8765";
const python = process.env.PYTHON || "python3";
const contenu = JSON.parse(execFileSync(python,
  [path.join(__dirname, "test_python.py"), "--json"], { encoding: "utf8", maxBuffer: 1e8 }));

(async () => {
  const navigateur = await chromium.launch();
  const page = await navigateur.newPage();
  await page.goto(url);
  await page.waitForFunction(() => window.AtelierPy, null, { timeout: 60000 });
  let echecs = 0;
  for (const B of contenu) {
    const res = await page.evaluate(async (B) => {
      const out = []; let n = 0; const t0 = performance.now();
      for (const lecon of B.lecons) {
        await AtelierPy.call(B.base, "reset", { ns: "test" });
        for (const c of lecon) {
          n++;
          const r = await AtelierPy.call(B.base, "run", { ns: "test", code: c.code });
          const err = r.items.filter((i) => i.type === "error").map((i) => i.text);
          if ((c.mode === "erreur") !== (err.length > 0))
            out.push("✗ [cours] " + c.where + " : " + (err[0] || "une erreur volontaire était attendue"));
        }
      }
      for (const e of B.exercices) {
        n++;
        const r = await AtelierPy.call(B.base, "check", { key: "test/" + e.id, prep: e.prep,
                                                          correction: e.correction, code: e.correction });
        const err = r.items.filter((i) => i.type === "error").map((i) => i.text);
        if (err.length || (e.verif === "valeur" && r.feedback.status !== "ok"))
          out.push("✗ [exercice] " + e.id + " " + e.titre + " : " + (err[0] || r.feedback.message));
      }
      return { out, n, s: ((performance.now() - t0) / 1000).toFixed(1) };
    }, B);
    console.log(`========== Base : ${B.base} ==========`);
    res.out.forEach((l) => console.log(l));
    console.log(`${res.n} exécutions dans le navigateur, ${res.out.length} échecs, ${res.s} s`);
    echecs += res.out.length;
  }
  await navigateur.close();
  process.exit(echecs ? 1 : 0);
})();
