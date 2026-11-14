/* app.js – gemeinsame Oberflächen-Logik des MBe-Designs (Referenz: MBeTradingHub base.html,
   Skill mbe-design). Liegt bewusst als Datei vor: Die Content-Security-Policy der App erlaubt
   kein Inline-JavaScript (kein <script>…</script>, kein onclick="…").

   Statt onclick werden data-Attribute verwendet und hier zentral ausgewertet:
     data-action="toggle-sidebar"   Menüleiste ein-/ausklappen
     data-open-modal="xyzModal"     Popup öffnen
     data-close-modal="xyzModal"    Popup schließen (auch: Klick auf den dunklen Hintergrund)
     data-hide-on-error             Bild ausblenden, wenn es nicht geladen werden kann
   Seitenspezifische Logik gehört in eine eigene Datei app/static/js/<seite>.js,
   eingebunden über {% block scripts %}. Die Helfer unten nicht pro Seite neu definieren. */

'use strict';

// ---- Gemeinsame Helfer (auf allen Seiten verfügbar) -------------------------
function escHtml(s) {
    return (s === null || s === undefined) ? ''
        : String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
}
function fmtNum(v, dec) {
    return (v === null || v === undefined || v === '') ? '–'
        : Number(v).toLocaleString('de-AT', { minimumFractionDigits: dec, maximumFractionDigits: dec });
}
function fmtChangeClass(v) { return v > 0 ? 'change-pos' : (v < 0 ? 'change-neg' : 'change-neu'); }

function openModal(id)  { const m = document.getElementById(id); if (m) m.classList.add('open'); }
function closeModal(id) { const m = document.getElementById(id); if (m) m.classList.remove('open'); }

// Button während einer Aktion sperren + Spinner zeigen, danach Originaltext zurück
function withBusy(btn, busyText, promiseFn) {
    const orig = btn.innerHTML;
    btn.disabled = true;
    btn.innerHTML = '<span class="spinner spinner-green"></span> ' + escHtml(busyText || 'Bitte warten...');
    return Promise.resolve().then(promiseFn).finally(() => { btn.disabled = false; btn.innerHTML = orig; });
}
function loadingRow(colspan, text) {
    return `<tr><td colspan="${colspan}" class="table-loading-cell"><span class="spinner spinner-green"></span> ${escHtml(text || 'Lade Daten...')}</td></tr>`;
}
function emptyRow(colspan, text) {
    return `<tr><td colspan="${colspan}" class="td-center text-muted" style="padding:16px;">${escHtml(text)}</td></tr>`;
}

// Seitenübergreifend gemerkte Auswahl (z.B. Kachel, gewählte Liste, Filter)
function getSaved(key, valid, fallback) {
    try {
        const v = localStorage.getItem(key);
        return (v && (!valid || valid.includes(v))) ? v : fallback;
    } catch (e) { return fallback; }
}
function save(key, v) { try { localStorage.setItem(key, v); } catch (e) { /* ohne Speicher */ } }

// ---- Menüleiste --------------------------------------------------------------
const SIDEBAR_KEY = 'mbeSidebarCollapsed';
function setSidebarCollapsed(collapsed) {
    document.getElementById('appLayout').classList.toggle('sidebar-collapsed', collapsed);
    document.getElementById('appSidebar').classList.toggle('sidebar-collapsed', collapsed);
    save(SIDEBAR_KEY, collapsed ? '1' : '0');
}
function toggleSidebar() {
    setSidebarCollapsed(!document.getElementById('appLayout').classList.contains('sidebar-collapsed'));
}

// ---- Fußzeile: Server-Status und Uhr ---------------------------------------
function updateServerStatus() {
    const dot = document.getElementById('serverStatusDot');
    const text = document.getElementById('serverStatusText');
    if (!dot || !text) return;
    fetch('/health', { cache: 'no-store' })
        .then(r => r.json())
        .then(d => {
            const ok = d && d.status === 'ok';
            dot.className = 'status-dot ' + (ok ? 'green' : 'orange');
            text.textContent = ok ? 'Server: verbunden' : 'Server: eingeschränkt';
        })
        .catch(() => { dot.className = 'status-dot red'; text.textContent = 'Server: keine Verbindung'; });
}
function updateClock() {
    const el = document.getElementById('footerTime');
    if (el) el.textContent = new Date().toLocaleString('de-AT', { hour12: false });
}

// ---- Zentrale Ereignisbehandlung (ersetzt onclick=) ------------------------
document.addEventListener('click', (e) => {
    const t = e.target;
    const actionEl = t.closest('[data-action="toggle-sidebar"]');
    if (actionEl) { toggleSidebar(); return; }
    const openEl = t.closest('[data-open-modal]');
    if (openEl) { openModal(openEl.dataset.openModal); return; }
    const closeEl = t.closest('[data-close-modal]');
    if (closeEl) { closeModal(closeEl.dataset.closeModal); return; }
    // Klick auf den abgedunkelten Hintergrund schließt das Popup
    if (t.classList && t.classList.contains('modal-overlay')) t.classList.remove('open');
});
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') document.querySelectorAll('.modal-overlay.open').forEach(m => m.classList.remove('open'));
});
// Bilder mit data-hide-on-error ausblenden, wenn sie fehlen (ersetzt onerror=)
document.addEventListener('error', (e) => {
    const el = e.target;
    if (el && el.tagName === 'IMG' && el.hasAttribute('data-hide-on-error')) el.style.display = 'none';
}, true);

window.addEventListener('DOMContentLoaded', () => {
    if (getSaved(SIDEBAR_KEY, ['0', '1'], '0') === '1') setSidebarCollapsed(true);
    updateServerStatus();
    updateClock();
    setInterval(updateServerStatus, 30000);
    setInterval(updateClock, 1000);
});
