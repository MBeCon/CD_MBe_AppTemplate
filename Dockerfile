# Basis-Image mit fester Minor-Version. Für maximale Reproduzierbarkeit zusätzlich
# per Digest pinnen (python:3.13-slim@sha256:...) – Renovate hält ihn aktuell.
FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# Eigener, unprivilegierter Benutzer – Container läuft nie als root
RUN groupadd --system app && useradd --system --gid app --no-create-home app

COPY requirements.txt .
# Laufzeitpakete installieren, danach pip entfernen: wird im Betrieb nicht gebraucht und
# verkleinert die Angriffsfläche (im Container lassen sich so keine Pakete nachinstallieren).
RUN pip install --no-cache-dir -r requirements.txt \
    && pip uninstall --yes pip

COPY app/ app/
COPY wsgi.py .

USER app

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=3)"]

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "2", "--access-logfile", "-", "wsgi:app"]
