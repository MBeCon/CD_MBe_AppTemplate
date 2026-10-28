# App-Steckbrief

Dieser Steckbrief ist Grundlage für das App-Register und die risikobasierte QS.
Bei jeder Änderung von Zweck, Daten oder Nutzerkreis aktualisieren.

| Feld | Angabe |
|---|---|
| **Name der Anwendung** | |
| **Zweck / Geschäftsprozess** | |
| **Verantwortlich (Owner)** | |
| **Stellvertretung** | |
| **Fachliche Ansprechperson** | |
| **Nutzerkreis** | z. B. Abteilung Qualität, ca. 10 Personen |
| **URL (Produktion)** | |
| **Status** | in Entwicklung / produktiv / außer Betrieb |

## Daten und Risiko

| Feld | Angabe |
|---|---|
| **Datenklassifizierung** | öffentlich / intern / vertraulich / streng vertraulich |
| **Personenbezogene Daten (DSGVO)?** | nein / ja → welche: |
| **Datenquellen / Schnittstellen** | z. B. ERP, SharePoint, Datei-Upload |
| **Schreibt die App in andere Systeme?** | nein / ja → welche: |
| **Kritikalität bei Ausfall** | niedrig (Workaround vorhanden) / mittel / hoch |
| **Authentifizierung** | keine (nur bei öffentlichen Daten) / SSO / sonstige |

### Zusätzliche Anforderungen nach Risiko

- **Personenbezogene oder vertrauliche Daten:** Authentifizierung über SSO verpflichtend,
  Eintrag ins Verarbeitungsverzeichnis prüfen, Backup und Löschkonzept festlegen.
- **Kritikalität hoch:** Monitoring/Alarmierung, dokumentierter Rollback, zweites Review.
- **Schreibzugriff auf andere Systeme:** Test gegen Testsystem, Freigabe durch System-Owner.

## Betrieb

| Feld | Angabe |
|---|---|
| **Server / Host** | |
| **Datenhaltung / Volumes** | |
| **Backup** | |
| **Logs** | |
| **Bekannte Einschränkungen** | |
