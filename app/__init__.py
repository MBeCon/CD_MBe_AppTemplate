"""Flask-Application-Factory.

Konfiguration kommt ausschließlich aus Umgebungsvariablen (siehe .env.example).
Secrets werden niemals im Code abgelegt.
"""

import logging
import os

from flask import Flask, render_template


def _env_bool(name: str, default: bool = False) -> bool:
    value = os.environ.get(name)
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}


def create_app(test_config: dict | None = None) -> Flask:
    app = Flask(__name__)

    app.config.update(
        SECRET_KEY=os.environ.get("SECRET_KEY"),
        APP_ENV=os.environ.get("APP_ENV", "production"),
        SESSION_COOKIE_HTTPONLY=True,
        SESSION_COOKIE_SAMESITE="Lax",
        SESSION_COOKIE_SECURE=_env_bool("SESSION_COOKIE_SECURE", default=True),
    )
    if test_config:
        app.config.update(test_config)

    if not app.config["SECRET_KEY"]:
        raise RuntimeError(
            "SECRET_KEY ist nicht gesetzt. Lokal: .env aus .env.example anlegen. "
            "Produktion: über die Deployment-Pipeline als Secret bereitstellen."
        )

    logging.basicConfig(
        level=os.environ.get("LOG_LEVEL", "INFO"),
        format="%(asctime)s %(levelname)s %(name)s: %(message)s",
    )

    from app.routes import bp

    app.register_blueprint(bp)

    @app.after_request
    def set_security_headers(response):
        response.headers.setdefault("X-Content-Type-Options", "nosniff")
        response.headers.setdefault("X-Frame-Options", "DENY")
        response.headers.setdefault("Referrer-Policy", "same-origin")
        response.headers.setdefault(
            "Content-Security-Policy",
            "default-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline'",
        )
        return response

    @app.errorhandler(404)
    def not_found(_error):
        return render_template("404.html"), 404

    @app.errorhandler(500)
    def internal_error(error):
        app.logger.exception("Unbehandelter Fehler: %s", error)
        return render_template("500.html"), 500

    return app
