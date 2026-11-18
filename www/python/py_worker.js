// ===========================================================================
// py_worker.js — Python (Pyodide) dans un Web Worker
//
// Le code des étudiants s'exécute ici, dans LEUR navigateur, à part de la
// page : un calcul long ne fige pas l'interface. Rien n'est exécuté sur le
// serveur. Pyodide et ses paquets (NumPy, pandas, PyArrow, DuckDB,
// Matplotlib) viennent du CDN jsdelivr ; Seaborn et openpyxl (Excel) sont
// fournis par l'application (www/python/wheels/).
//
// Messages reçus : {id, cmd, ...}
//   init    {files: [{path, url}]}   charge Python et copie les fichiers
//   run     {ns, code}               exécute une cellule
//   reset   {ns}                     efface un espace de noms
//   objects {ns}                     objets créés
//   check   {key, prep, correction, code}  vérifie un exercice
// Réponse : {id, ok, result | error}
// ===========================================================================

// Worker de type « module » (new Worker(url, {type: "module"})) : la
// version de Pyodide est fixée ici et dans l'URL de l'import ci-dessous.
import { loadPyodide } from "https://cdn.jsdelivr.net/pyodide/v314.0.8/full/pyodide.mjs";
const PYODIDE_URL = "https://cdn.jsdelivr.net/pyodide/v314.0.8/full/";

let py = null;
let runner = null;
let ready = null;
const base = self.location.href.replace(/py_worker\.js.*$/, "");

function status(text) { self.postMessage({ status: text }); }

async function init(files) {
  status("Chargement de Python…");
  py = await loadPyodide({ indexURL: PYODIDE_URL });
  status("Chargement de pandas, NumPy, PyArrow, Matplotlib…");
  await py.loadPackage(["numpy", "pandas", "pyarrow", "matplotlib", "micropip"]);
  const wheels = ["seaborn-0.13.2-py3-none-any.whl", "openpyxl-3.1.5-py2.py3-none-any.whl",
                  "et_xmlfile-2.0.0-py3-none-any.whl"].map(w => base + "wheels/" + w);
  py.globals.set("_wheels", py.toPy(wheels));
  await py.runPythonAsync("import micropip\nawait micropip.install(_wheels)\ndel _wheels");
  status("Copie des fichiers de données…");
  const home = "/home/pyodide";
  for (const f of files) {
    const buf = new Uint8Array(await (await fetch(f.url)).arrayBuffer());
    const parts = f.path.split("/");
    let dir = home;
    for (const p of parts.slice(0, -1)) {
      dir += "/" + p;
      try { py.FS.mkdir(dir); } catch (e) { /* existe déjà */ }
    }
    py.FS.writeFile(home + "/" + f.path, buf);
  }
  try { py.FS.mkdir(home + "/sortie"); } catch (e) {}
  py.FS.chdir(home);
  const src = await (await fetch(base + "runner.py")).text();
  py.FS.writeFile("/tmp/atelier_runner.py", src);
  await py.runPythonAsync(
    "import sys, os, matplotlib\nmatplotlib.use('Agg')\nsys.path.insert(0, '/tmp')\nimport atelier_runner\nos.environ['MPLBACKEND'] = 'Agg'");
  runner = py.pyimport("atelier_runner");
  status("");
}

// Charge à la demande les paquets importés par le code (duckdb…)
async function prepare(code) {
  if (code) await py.loadPackagesFromImports(code);
}

self.onmessage = async (ev) => {
  const m = ev.data;
  try {
    if (m.cmd === "init") {
      if (!ready) ready = init(m.files || []);
      await ready;
      self.postMessage({ id: m.id, ok: true, result: "ready" });
      return;
    }
    await ready;
    let result;
    if (m.cmd === "run") {
      await prepare(m.code);
      result = JSON.parse(runner.run(m.ns, m.code));
    } else if (m.cmd === "reset") {
      runner.reset(m.ns); result = null;
    } else if (m.cmd === "objects") {
      result = JSON.parse(runner.objects(m.ns));
    } else if (m.cmd === "check") {
      await prepare([m.prep, m.correction, m.code].join("\n"));
      result = JSON.parse(runner.check(m.key, m.prep || "", m.correction, m.code));
    }
    self.postMessage({ id: m.id, ok: true, result: result });
  } catch (e) {
    self.postMessage({ id: m.id, ok: false, error: String(e && e.message || e) });
  }
};
