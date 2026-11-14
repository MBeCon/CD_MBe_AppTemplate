# Basis-Image mit fester Minor-Version. Für maximale Reproduzierbarkeit zusätzlich
# per Digest pinnen (python:3.13-slim@sha256:...) – Renovate hält ihn aktuell.
FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# Sicherheitsupdates der Debian-Pakete einspielen: Das Basis-Image wird nur periodisch neu
# gebaut, Trivy (CI-Job docker) meldet sonst behobene HIGH/CRITICAL-Lücken im Betriebssystem.
RUN apt-get update \
    && apt-get upgrade --yes --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Eigener, unprivilegierter Benutzer mit fester numerischer ID – Container läuft nie als root.
# Numerisch, damit Host/Orchestrierung "kein root" prüfen können (hadolint DL3066).
RUN groupadd --system --gid 10001 app && useradd --system --uid 10001 --gid app --no-create-home app

COPY requirements.txt .
# Laufzeitpakete installieren, danach pip entfernen: wird im Betrieb nicht gebraucht und
# verkleinert die Angriffsfläche (im Container lassen sich so keine Pakete nachinstallieren).
RUN pip install --no-cache-dir -r requirements.txt \
    && pip uninstall --yes pip

COPY app/ app/
COPY wsgi.py .

USER 10001:10001

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=3)"]

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "2", "--access-logfile", "-", "wsgi:app"]
