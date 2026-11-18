// ===========================================================================
// atelier.js — petits comportements côté navigateur
//  - boutons « Copier » des blocs de code
//  - flèches du clavier dans le cours
//  - progression des exercices gardée dans le navigateur (localStorage)
//  - hauteur des cadres du Viewer (tableaux gt)
// ===========================================================================

(function () {
  var KEY = "atelierR_progression_v1";

  // --- Viewer : le cadre prend la hauteur du tableau ------------------------
  // (l'événement load ne remonte pas : on l'écoute en phase de capture)
  function fitViewer(f) {
    try {
      var d = f.contentDocument;
      if (d && d.documentElement) f.style.height = (d.documentElement.scrollHeight + 2) + "px";
    } catch (err) {}
  }
  document.addEventListener("load", function (e) {
    if (e.target && e.target.classList && e.target.classList.contains("viewer-frame")) fitViewer(e.target);
  }, true);
  // un cadre affiché dans un onglet caché mesure 0 : on le remesure à l'affichage
  document.addEventListener("shown.bs.tab", function () {
    document.querySelectorAll(".viewer-frame").forEach(fitViewer);
  });
  window.addEventListener("resize", function () {
    document.querySelectorAll(".viewer-frame").forEach(fitViewer);
  });

  // --- Copier le code -------------------------------------------------------
  document.addEventListener("click", function (e) {
    var b = e.target.closest(".btn-copier");
    if (!b) return;
    var txt = b.getAttribute("data-code") || "";
    var done = function () {
      b.classList.add("copied"); b.textContent = "Copié !";
      setTimeout(function () { b.classList.remove("copied"); b.textContent = "Copier"; }, 1400);
    };
    if (navigator.clipboard && window.isSecureContext) {
      navigator.clipboard.writeText(txt).then(done, function () {});
    } else {
      var ta = document.createElement("textarea");
      ta.value = txt; document.body.appendChild(ta); ta.select();
      try { document.execCommand("copy"); done(); } catch (err) {}
      document.body.removeChild(ta);
    }
  });

  // --- Exécuter : le code de l'éditeur part avec le clic ------------------
  function sendAce(btn) {
    var ed = ace.edit(btn.getAttribute("data-editor"));
    Shiny.setInputValue(btn.getAttribute("data-input"),
                        { code: ed.getValue(), ts: Date.now() }, { priority: "event" });
  }
  document.addEventListener("click", function (e) {
    var b = e.target.closest(".ace-send");
    if (b) sendAce(b);
  });
  // Ctrl + Entrée (ou Cmd + Entrée) dans un éditeur = bouton « Exécuter »
  document.addEventListener("keydown", function (e) {
    if (e.key !== "Enter" || !(e.ctrlKey || e.metaKey)) return;
    var ed = document.activeElement && document.activeElement.closest(".shiny-ace");
    if (!ed) return;
    var b = document.querySelector('.ace-send.ace-default[data-editor="' + ed.id + '"]');
    if (b) { e.preventDefault(); e.stopPropagation(); sendAce(b); }
  }, true);

  // --- Flèches du clavier dans le cours ----------------------------------------
  document.addEventListener("keydown", function (e) {
    if (e.key !== "ArrowRight" && e.key !== "ArrowLeft") return;
    var tag = (document.activeElement && document.activeElement.tagName) || "";
    if (/INPUT|TEXTAREA|SELECT/.test(tag)) return;
    if (document.activeElement && document.activeElement.closest(".ace_editor")) return;
    if (document.querySelector(".tour-box") && document.querySelector(".tour-box").style.display === "block") return;
    if (document.querySelector(".modal.show")) return;
    var active = document.querySelector(".navbar .nav-link.active");
    if (!active || active.getAttribute("data-value") !== "cours") return;
    Shiny.setInputValue("cours_key", { dir: e.key === "ArrowRight" ? "next" : "prev", ts: Date.now() },
                        { priority: "event" });
  });

  // --- Progression des exercices -----------------------------------------------
  function readProgress() {
    try { return window.localStorage.getItem(KEY) || "{}"; } catch (err) { return "{}"; }
  }
  $(document).on("shiny:connected", function () {
    Shiny.setInputValue("progress_init", readProgress());
    Shiny.addCustomMessageHandler("atelier_save_progress", function (json) {
      try { window.localStorage.setItem(KEY, json); } catch (err) {}
    });
  });
})();
