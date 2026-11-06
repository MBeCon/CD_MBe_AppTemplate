/* app.js – generische Oberflächen-Logik des technosert-App-Designs
   (übernommen aus teProductionPlanning/base.html, Skill te-appdesign).
   Liegt bewusst als Datei vor: Die Content-Security-Policy der App erlaubt
   kein Inline-JavaScript (kein <script>…</script>, kein onclick="…"). */

// Menüspalte ein-/ausklappen (Klick auf .sidebar-toggle), Zustand im Browser merken
function toggleSidebar() {
    const sb = document.getElementById('appSidebar');
    const icon = document.getElementById('sidebarToggleIcon');
    if (!sb || !icon) return;
    sb.classList.toggle('collapsed');
    icon.textContent = sb.classList.contains('collapsed') ? '▶' : '◀';
    document.querySelectorAll('.sidebar-text').forEach(el => {
        el.style.display = sb.classList.contains('collapsed') ? 'none' : '';
    });
    try { localStorage.setItem('sidebarCollapsed', sb.classList.contains('collapsed')); } catch (e) { /* ohne Speicher */ }
}
window.addEventListener('DOMContentLoaded', () => {
    const toggle = document.querySelector('.sidebar-toggle');
    if (toggle) toggle.addEventListener('click', toggleSidebar);
    let collapsed = false;
    try { collapsed = localStorage.getItem('sidebarCollapsed') === 'true'; } catch (e) { /* ohne Speicher */ }
    if (collapsed) toggleSidebar();

    // Flash-Meldungen: Schließen-Button und automatisch nach 6 Sekunden ausblenden
    document.querySelectorAll('.flash-close').forEach(btn => {
        btn.addEventListener('click', () => btn.parentElement.remove());
    });
    setTimeout(() => document.querySelectorAll('.flash-msg').forEach(el => el.remove()), 6000);
});

// Auto-wachsende Informationsfelder (.auto-textarea, siehe style.css):
// Höhe wird an den Inhalt angepasst (bis max-height ~3 Zeilen, siehe CSS),
// darüber übernimmt overflow-y:auto das Scrollen innerhalb des Feldes.
function autoResizeTextarea(el) {
    el.style.height = 'auto';
    const maxH = parseInt(getComputedStyle(el).maxHeight, 10) || 999;
    el.style.height = Math.min(el.scrollHeight, maxH) + 'px';
}
document.addEventListener('input', (e) => {
    if (e.target.classList && e.target.classList.contains('auto-textarea')) {
        autoResizeTextarea(e.target);
    }
}, true);
window.addEventListener('DOMContentLoaded', () => {
    document.querySelectorAll('.auto-textarea').forEach(autoResizeTextarea);
});

// PopUps verschieben & Größe ändern (ganze Anwendung, siehe style.css
// .modal-header/.modal-resize-handle): jedes PopUp (.modal-box) kann per
// Klick+Halten auf die Kopfzeile verschoben und per Ziehen an der Ecke
// unten rechts in der Größe verändert werden. Generisch für ALLE PopUps
// (aktuelle und künftige) - es werden nur die gemeinsamen CSS-Klassen
// vorausgesetzt, keine Änderung an den einzelnen PopUp-Templates nötig.
function initModalDragAndResize() {
    // Größenänderungs-Griff einmalig in jede .modal-box einfügen.
    document.querySelectorAll('.modal-box').forEach(box => {
        if (!box.querySelector(':scope > .modal-resize-handle')) {
            const handle = document.createElement('div');
            handle.className = 'modal-resize-handle';
            handle.title = 'Größe ändern';
            box.appendChild(handle);
        }
    });

    // Vor dem ersten Verschieben/Vergrößern sitzt eine .modal-box noch mittig
    // im flex-zentrierten .modal-backdrop (unverändertes Standardverhalten).
    // Erst beim ersten Ziehen wird sie auf feste Bildschirmkoordinaten
    // ("position:fixed") umgestellt, exakt an ihrer aktuellen Position -
    // dadurch gibt es keinen sichtbaren Sprung.
    function toFixedPosition(box) {
        if (box.dataset.ekeyFixed === '1') return;
        const rect = box.getBoundingClientRect();
        box.style.position = 'fixed';
        box.style.left = rect.left + 'px';
        box.style.top = rect.top + 'px';
        box.style.margin = '0';
        box.style.maxWidth = 'none';
        box.style.maxHeight = 'none';
        box.style.width = rect.width + 'px';
        box.style.height = rect.height + 'px';
        box.dataset.ekeyFixed = '1';
    }

    let dragBox = null, dragOffsetX = 0, dragOffsetY = 0;
    let resizeBox = null, resizeStartW = 0, resizeStartH = 0, resizeStartX = 0, resizeStartY = 0;
    const MIN_VISIBLE = 40, MIN_W = 280, MIN_H = 120;

    document.addEventListener('mousedown', (e) => {
        const header = e.target.closest('.modal-header');
        if (header && !e.target.closest('button, a, input, select, textarea')) {
            const box = header.closest('.modal-box');
            if (!box) return;
            toFixedPosition(box);
            const rect = box.getBoundingClientRect();
            dragBox = box;
            dragOffsetX = e.clientX - rect.left;
            dragOffsetY = e.clientY - rect.top;
            box.classList.add('ekey-dragging');
            document.body.style.userSelect = 'none';
            e.preventDefault();
            return;
        }
        const handle = e.target.closest('.modal-resize-handle');
        if (handle) {
            const box = handle.closest('.modal-box');
            if (!box) return;
            toFixedPosition(box);
            const rect = box.getBoundingClientRect();
            resizeBox = box;
            resizeStartW = rect.width;
            resizeStartH = rect.height;
            resizeStartX = e.clientX;
            resizeStartY = e.clientY;
            box.classList.add('ekey-resizing');
            document.body.style.userSelect = 'none';
            e.preventDefault();
        }
    });

    document.addEventListener('mousemove', (e) => {
        if (dragBox) {
            const rect = dragBox.getBoundingClientRect();
            let left = e.clientX - dragOffsetX;
            let top = e.clientY - dragOffsetY;
            // Im sichtbaren Bereich halten, damit die Kopfzeile (zum
            // Zurückholen) immer erreichbar bleibt.
            left = Math.max(MIN_VISIBLE - rect.width, Math.min(left, window.innerWidth - MIN_VISIBLE));
            top = Math.max(0, Math.min(top, window.innerHeight - MIN_VISIBLE));
            dragBox.style.left = left + 'px';
            dragBox.style.top = top + 'px';
        } else if (resizeBox) {
            const newW = Math.max(MIN_W, resizeStartW + (e.clientX - resizeStartX));
            const newH = Math.max(MIN_H, resizeStartH + (e.clientY - resizeStartY));
            resizeBox.style.width = newW + 'px';
            resizeBox.style.height = newH + 'px';
        }
    });

    document.addEventListener('mouseup', () => {
        if (dragBox) { dragBox.classList.remove('ekey-dragging'); dragBox = null; }
        if (resizeBox) { resizeBox.classList.remove('ekey-resizing'); resizeBox = null; }
        document.body.style.userSelect = '';
    });
}
window.addEventListener('DOMContentLoaded', initModalDragAndResize);
