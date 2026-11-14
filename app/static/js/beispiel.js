/* beispiel.js – Seitenlogik der Beispielseite (Muster für eigene Seiten).
   Nutzt die gemeinsamen Helfer aus app.js (escHtml, fmtNum, openModal, withBusy …).
   Ereignisse werden per addEventListener bzw. data-Attributen verdrahtet (CSP: kein onclick=). */

'use strict';

const KATEGORIE_KEY = 'mbeSelectedKategorie';
const KATEGORIEN = ['A', 'B', 'C'];
const COLSPAN = 5; // Spaltenanzahl der Tabelle – bei Änderungen überall anpassen

let _eintraege = [];
let _kategorie = 'A';
let _editId = null;
let _suche = '';

function statusBadge(status) {
    const cls = status === 'AKTIV' ? 'badge-success' : (status === 'INAKTIV' ? 'badge-error' : 'badge-warning');
    return `<span class="badge ${cls}">${escHtml(status)}</span>`;
}

function renderRow(r) {
    return `<tr>
      <td><div class="cell-primary">${escHtml(r.name)}</div><div class="cell-secondary">Kategorie ${escHtml(r.kategorie)}</div></td>
      <td class="td-center">${statusBadge(r.status)}</td>
      <td class="td-right">${fmtNum(r.wert, 2)}</td>
      <td class="td-right ${fmtChangeClass(r.aenderung)}">${fmtNum(r.aenderung, 2)}</td>
      <td class="td-center"><div class="btn-stack">
        <button type="button" class="btn btn-sm" data-edit="${r.id}" title="Eintrag bearbeiten">Bearbeiten</button>
        <button type="button" class="btn btn-sm btn-danger" data-delete="${r.id}" title="Eintrag löschen">&#128465;</button>
      </div></td>
    </tr>`;
}

function renderList() {
    const body = document.getElementById('listBody');
    const q = _suche.trim().toLowerCase();
    const rows = _eintraege.filter(r => r.kategorie === _kategorie && (!q || r.name.toLowerCase().includes(q)));
    document.getElementById('listInfo').textContent = `(${rows.length} Einträge)`;
    body.innerHTML = rows.length
        ? rows.map(renderRow).join('')
        : emptyRow(COLSPAN, 'Noch keine Einträge – „+ Neuer Eintrag“ klicken.');
}

function loadList() {
    document.getElementById('listBody').innerHTML = loadingRow(COLSPAN);
    return fetch('/api/beispiel')
        .then(r => { if (!r.ok) throw new Error(r.status); return r.json(); })
        .then(d => { _eintraege = d.eintraege || []; renderList(); })
        .catch(() => {
            document.getElementById('listBody').innerHTML =
                `<tr><td colspan="${COLSPAN}" class="td-center change-neg" style="padding:16px;">Daten konnten nicht geladen werden.</td></tr>`;
        });
}

function switchKategorie(k) {
    _kategorie = k;
    save(KATEGORIE_KEY, k);
    document.querySelectorAll('#kategorieTiles .tile-btn').forEach(b =>
        b.classList.toggle('btn-primary', b.dataset.kategorie === k));
    renderList();
}

function openEdit(id) {
    _editId = id;
    const r = _eintraege.find(e => e.id === id);
    document.getElementById('editModalTitle').textContent = r ? '✎ Eintrag bearbeiten' : '+ Neuen Eintrag hinzufügen';
    document.getElementById('fName').value = r ? r.name : '';
    document.getElementById('fWert').value = r ? r.wert : '';
    document.getElementById('fStatus').value = r ? r.status : '';
    openModal('editModal');
    document.getElementById('fName').focus();
}

function speichern() {
    const name = document.getElementById('fName').value.trim();
    const wert = parseFloat(document.getElementById('fWert').value);
    const status = document.getElementById('fStatus').value;
    if (!name || Number.isNaN(wert) || !status) { alert('Bitte Name, Wert und Status angeben.'); return; }
    if (_editId !== null) {
        Object.assign(_eintraege.find(e => e.id === _editId), { name, wert, status });
    } else {
        const id = Math.max(0, ..._eintraege.map(e => e.id)) + 1;
        _eintraege.push({ id, name, wert, status, aenderung: 0, kategorie: _kategorie });
    }
    closeModal('editModal');
    renderList();
}

function loeschen(id) {
    const r = _eintraege.find(e => e.id === id);
    if (!r || !confirm(`'${r.name}' wirklich löschen?`)) return;
    _eintraege = _eintraege.filter(e => e.id !== id);
    renderList();
}

window.addEventListener('DOMContentLoaded', () => {
    document.querySelectorAll('#kategorieTiles .tile-btn').forEach(b =>
        b.addEventListener('click', () => switchKategorie(b.dataset.kategorie)));
    document.getElementById('searchInput').addEventListener('input', e => { _suche = e.target.value; renderList(); });
    document.getElementById('newBtn').addEventListener('click', () => openEdit(null));
    document.getElementById('saveBtn').addEventListener('click', speichern);
    document.getElementById('refreshBtn').addEventListener('click', loadList);
    const reloadBtn = document.getElementById('reloadBtn');
    reloadBtn.addEventListener('click', () => withBusy(reloadBtn, 'Aktualisiere...', loadList));
    document.getElementById('listBody').addEventListener('click', e => {
        const edit = e.target.closest('[data-edit]');
        if (edit) { openEdit(Number(edit.dataset.edit)); return; }
        const del = e.target.closest('[data-delete]');
        if (del) loeschen(Number(del.dataset.delete));
    });

    _kategorie = getSaved(KATEGORIE_KEY, KATEGORIEN, 'A');
    switchKategorie(_kategorie);
    loadList();
});
