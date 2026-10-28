"""Einstiegspunkt für gunicorn (Produktion) und `flask --app wsgi run` (lokal)."""

from app import create_app

app = create_app()
