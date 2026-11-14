/* einstellungen.js – Anzeige-Einstellungen im Browser (localStorage), siehe app.js. */

'use strict';

window.addEventListener('DOMContentLoaded', () => {
    const cb = document.getElementById('optSidebarCollapsed');
    cb.checked = getSaved(SIDEBAR_KEY, ['0', '1'], '0') === '1';
    const btn = document.getElementById('saveSettingsBtn');
    btn.addEventListener('click', () => {
        setSidebarCollapsed(cb.checked);
        const msg = document.getElementById('settingsSaved');
        msg.style.display = '';
        setTimeout(() => { msg.style.display = 'none'; }, 3000);
    });
});
