## Was ändert sich?

<!-- Kurz beschreiben: Was und warum? Ticket/Anforderung verlinken. -->

## Wie wurde getestet?

<!-- Neue/angepasste Tests, manuelle Prüfung im Browser, Container lokal gestartet … -->

## Definition of Done

- [ ] Die Pipeline ist grün (lint, test, security, secrets, docker, docker-scan)
- [ ] Neue Funktionen haben Tests, Coverage ist nicht gesunken
- [ ] Keine Secrets, Passwörter oder Tokens im Code (nur über Umgebungsvariablen)
- [ ] Neue Abhängigkeiten sind bewusst gewählt, existieren auf PyPI und sind gepinnt
- [ ] Eingaben werden validiert, Datenbankzugriffe sind parametrisiert
- [ ] Fehler werden behandelt und geloggt (ohne sensible Daten im Log)
- [ ] README / `APP_INFO.md` aktualisiert, falls sich Funktion, Daten oder Betrieb ändern
- [ ] Bei personenbezogenen Daten: Datenklassifizierung in `APP_INFO.md` geprüft

## Hinweise für die Reviewerin / den Reviewer

<!-- Worauf soll besonders geachtet werden? Mit Claude generierte Teile kennzeichnen. -->
