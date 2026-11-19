// ===========================================================================
// atelier_py.js — Python dans l'atelier (côté page)
//
// Pilote le Web Worker (py_worker.js) qui exécute Python dans le navigateur
// et affiche les résultats avec les mêmes styles que les résultats R.
//
// Messages envoyés par le serveur Shiny (session$sendCustomMessage) :
//   py_init    {base}                            préparer Python à l'avance
//   py_chunks  {base, key, chunks}               exécuter une leçon (ou une
//              correction) dans l'ordre ; les résultats remplissent les
//              emplacements <div class="py-out" data-key data-idx>
//   py_run     {base, ns, code, target, fresh, setup, objets, reply}
//   py_reset   {base, ns, setup, objets}
//   py_check   {base, key, prep, correction, code, target, reply}
// ===========================================================================

(function () {
  const workers = {};       // base -> {worker, pending, nextId, ready}
  // textes de l'interface dans la langue de la page (clés « js.* », injectés par le serveur)
  const T = (k) => (window.ATELIER_TXT || {})[k] || k;
  const chunkCache = {};    // key -> [html | undefined]  (résultats des leçons)
  const chunkRuns = {};     // key -> Promise
  const wurl = (document.currentScript && document.currentScript.src || "python/atelier_py.js")
    .replace(/atelier_py\.js.*$/, "py_worker.js");

  // --- Indicateur de chargement ---------------------------------------------
  function setStatus(text) {
    let el = document.getElementById("py-status");
    if (!el) {
      el = document.createElement("div");
      el.id = "py-status"; el.className = "py-status";
      document.body.appendChild(el);
    }
    el.textContent = text ? "🐍 " + text : "";
    el.style.display = text ? "block" : "none";
  }

  // --- Worker -------------------------------------------------------------------
  function getWorker(base) {
    if (workers[base]) return workers[base];
    const conf = (window.ATELIER_PY || {})[base];
    if (!conf) throw new Error("Base Python inconnue : " + base);
    const w = { worker: new Worker(wurl, { type: "module" }), pending: {}, nextId: 1 };
    w.worker.onmessage = (ev) => {
      const m = ev.data;
      if ("status" in m) { setStatus(m.status ? T(m.status) + " " + T("js.py_premiere_fois") : ""); return; }
      const p = w.pending[m.id]; delete w.pending[m.id];
      if (!p) return;
      m.ok ? p.resolve(m.result) : p.reject(new Error(m.error));
    };
    w.call = (cmd, payload) => new Promise((resolve, reject) => {
      const id = w.nextId++;
      w.pending[id] = { resolve, reject };
      w.worker.postMessage(Object.assign({ id: id, cmd: cmd }, payload || {}));
    });
    // adresses absolues : le worker résoudrait les adresses relatives
    // depuis son propre dossier (python/)
    const files = (conf.files || []).map((f) => ({ path: f.path, url: new URL(f.url, document.baseURI).href }));
    w.ready = w.call("init", { files: files, demarrage: conf.demarrage || null,
                               textes: window.ATELIER_PYTXT || null });
    w.ready.catch((e) => setStatus(T("js.py_echec") + " " + e.message));
    workers[base] = w;
    return w;
  }
  async function call(base, cmd, payload) {
    const w = getWorker(base);
    await w.ready;
    return w.call(cmd, payload);
  }

  // --- Affichage des résultats (mêmes classes CSS que render.R) -----------------
  const esc = (s) => String(s).replace(/[&<>"']/g, (c) =>
    ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));

  function renderItems(items) {
    return (items || []).map((it) => {
      switch (it.type) {
        case "output": return '<pre class="code-out py-text">' + esc(it.text) + "</pre>";
        case "table": return '<div class="py-table">' + it.html + "</div>";
        case "plot": return '<div class="code-plot"><img alt="' + esc(T("js.graphique")) + '" src="' + esc(it.src) + '"></div>';
        case "warning": return '<div class="res-warning"><strong>' + esc(T("js.avertissement")) + ' </strong>' + esc(it.text) + "</div>";
        case "error":
          return '<div class="res-error"><div class="res-msg"><strong>' + esc(T("js.erreur")) + ' </strong>' + esc(it.text) + "</div>" +
            ((it.where || []).length ? '<pre class="py-where">' + esc(it.where.join("\n")) + "</pre>" : "") +
            (it.hint ? '<div class="res-hint">' + esc(it.hint) + "</div>" : "") + "</div>";
        default: return "";
      }
    }).join("");
  }
  const waiting = (txt) => '<div class="py-wait"><span class="spinner-border spinner-border-sm"></span> ' +
    esc(txt || T("js.execution")) + "</div>";

  function setHtml(target, html) {
    const el = typeof target === "string" ? document.getElementById(target) : target;
    if (el) el.innerHTML = html;
  }

  // --- Leçons : exécution dans l'ordre, résultats gardés en mémoire -------------
  function fillPlaceholders(root) {
    (root || document).querySelectorAll(".py-out[data-key]").forEach((el) => {
      const res = (chunkCache[el.dataset.key] || [])[+el.dataset.idx];
      if (res !== undefined) { if (el.dataset.filled !== "1") { el.innerHTML = res; el.dataset.filled = "1"; } }
      else if (!el.innerHTML) el.innerHTML = waiting(T("js.py_prepare_resultat"));
    });
  }
  new MutationObserver((muts) => {
    for (const m of muts) for (const n of m.addedNodes)
      if (n.nodeType === 1 && (n.matches(".py-out") || n.querySelector(".py-out"))) { fillPlaceholders(); return; }
  }).observe(document.documentElement, { childList: true, subtree: true });

  function runChunks(msg) {
    if (chunkRuns[msg.key] && !msg.force) return chunkRuns[msg.key];
    chunkCache[msg.key] = [];
    chunkRuns[msg.key] = (async () => {
      await call(msg.base, "reset", { ns: msg.key });
      for (let i = 0; i < msg.chunks.length; i++) {
        const c = msg.chunks[i];
        let html;
        try {
          const r = await call(msg.base, "run", { ns: msg.key, code: c.code });
          html = renderItems(r.items);
        } catch (e) { html = '<div class="res-error">' + esc(e.message) + "</div>"; }
        chunkCache[msg.key][i] = c.mode === "setup" ? "" : html;
        document.querySelectorAll('.py-out[data-key="' + CSS.escape(msg.key) + '"][data-idx="' + i + '"]')
          .forEach((el) => { el.innerHTML = chunkCache[msg.key][i]; el.dataset.filled = "1"; });
      }
    })();
    return chunkRuns[msg.key];
  }

  // --- Objets disponibles -------------------------------------------------------
  async function showObjects(base, ns, target) {
    if (!target) return;
    const objs = await call(base, "objects", { ns: ns });
    setHtml(target, objs.length
      ? '<table class="table table-sm env-table"><tbody>' + objs.map((o) =>
          "<tr><td><code>" + esc(o.name) + '</code></td><td class="text-muted">' + esc(o.desc) + "</td></tr>").join("") +
        "</tbody></table>"
      : '<p class="text-muted small">' + esc(T("js.aucun_objet")) + '</p>');
  }

  async function resetNs(msg) {
    await call(msg.base, "reset", { ns: msg.ns });
    if (msg.setup) await call(msg.base, "run", { ns: msg.ns, code: msg.setup });
    await showObjects(msg.base, msg.ns, msg.objets);
  }

  async function runCode(msg) {
    setHtml(msg.target, waiting(workers[msg.base] ? null : T("js.py_se_prepare")));
    const t0 = performance.now();
    try {
      if (msg.fresh) await resetNs({ base: msg.base, ns: msg.ns, setup: msg.setup });
      const r = await call(msg.base, "run", { ns: msg.ns, code: msg.code });
      const sec = ((performance.now() - t0) / 1000).toFixed(2);
      setHtml(msg.target, r.items.length ? '<div class="run-output">' + renderItems(r.items) + "</div>"
        : '<div class="empty-result">' + esc(T("js.rien_affiche_valeur")) + '</div>');
      if (msg.reply) Shiny.setInputValue(msg.reply, { ok: r.ok, seconds: +sec, ts: Date.now() }, { priority: "event" });
      await showObjects(msg.base, msg.ns, msg.objets);
    } catch (e) {
      setHtml(msg.target, '<div class="res-error">' + esc(e.message) + "</div>");
    }
  }

  async function checkCode(msg) {
    setHtml(msg.target, waiting());
    try {
      const r = await call(msg.base, "check", msg);
      setHtml(msg.target, r.items.length ? '<div class="run-output">' + renderItems(r.items) + "</div>"
        : '<div class="empty-result">' + esc(T("js.rien_affiche")) + '</div>');
      Shiny.setInputValue(msg.reply, Object.assign({ ts: Date.now() }, r.feedback), { priority: "event" });
    } catch (e) {
      setHtml(msg.target, '<div class="res-error">' + esc(e.message) + "</div>");
    }
  }

  // Les gestionnaires ne renvoient JAMAIS de promesse : Shiny attendrait sa
  // fin avant de traiter les messages suivants, et l'interface resterait
  // figée pendant le chargement de Python.
  $(document).on("shiny:connected", function () {
    Shiny.addCustomMessageHandler("py_init", (m) => { try { getWorker(m.base); } catch (e) {} });
    Shiny.addCustomMessageHandler("py_chunks", (m) => { runChunks(m); fillPlaceholders(); });
    Shiny.addCustomMessageHandler("py_run", (m) => { runCode(m); });
    Shiny.addCustomMessageHandler("py_reset", (m) => { resetNs(m).catch(() => {}); });
    Shiny.addCustomMessageHandler("py_check", (m) => { checkCode(m); });
    Shiny.addCustomMessageHandler("py_clear", (ids) => [].concat(ids).forEach((id) => setHtml(id, "")));
  });

  window.AtelierPy = { call: call, renderItems: renderItems };
})();
