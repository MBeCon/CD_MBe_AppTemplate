import os

from flask import Blueprint, jsonify, render_template

bp = Blueprint("main", __name__)

# Beispieldaten für die Musterseite. In einer echten Anwendung kommen die Daten aus der
# Datenbank (parametrisierte Abfragen bzw. ORM, siehe CLAUDE.md).
BEISPIEL_EINTRAEGE = [
    {"id": i, "name": n, "status": s, "wert": w, "aenderung": a, "kategorie": k}
    for i, n, s, w, a, k in (
        (1, "Eintrag Alpha", "AKTIV", 1234.5, 2.4, "A"),
        (2, "Eintrag Beta", "PRÜFEN", 87.25, -1.1, "A"),
        (3, "Eintrag Gamma", "INAKTIV", 0, 0, "A"),
        (4, "Eintrag Delta", "AKTIV", 5400, 12.4, "B"),
        (5, "Eintrag Epsilon", "AKTIV", 19.99, -3.1, "C"),
    )
]


@bp.get("/")
def index():
    return render_template("index.html")


@bp.get("/beispiel")
def beispiel():
    """Musterseite im MBe-Design (Kacheln, Seitenkopf, Tabelle, Popups)."""
    return render_template("beispiel.html")


@bp.get("/einstellungen")
def einstellungen():
    return render_template("einstellungen.html", log_level=os.environ.get("LOG_LEVEL", "INFO"))


@bp.get("/api/beispiel")
def api_beispiel():
    """Liefert die Beispieldaten für die Tabelle der Musterseite."""
    return jsonify(eintraege=BEISPIEL_EINTRAEGE)


@bp.get("/health")
def health():
    """Health-Check für Docker, Deployment-Pipeline und Statusanzeige in der Fußzeile.
    Keine sensiblen Daten ausgeben."""
    return jsonify(status="ok")
