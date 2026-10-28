from flask import Blueprint, current_app, jsonify, render_template

bp = Blueprint("main", __name__)


@bp.get("/")
def index():
    return render_template("index.html", app_env=current_app.config["APP_ENV"])


@bp.get("/health")
def health():
    """Health-Check für Docker und Deployment-Pipeline. Keine sensiblen Daten ausgeben."""
    return jsonify(status="ok")
