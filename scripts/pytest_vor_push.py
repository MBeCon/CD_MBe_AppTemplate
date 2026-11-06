"""Führt die Tests vor dem Push mit dem Python der Projektumgebung (.venv) aus.

Der pre-commit-Hook "pytest (vor Push)" startet dieses Skript mit dem `python`, das im Terminal
gerade gefunden wird. Ist die .venv nicht aktiviert, ist das oft ein globales Python ohne pytest
und ohne die Pakete der Anwendung - der Push würde dann mit "No module named pytest" scheitern.
Deshalb wird hier, falls vorhanden, immer das Python aus .venv verwendet.
subprocess läuft nur mit fester Argumentliste, ohne shell=True.
"""

import os
import subprocess  # nosec B404
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KANDIDATEN = (
    os.path.join(ROOT, ".venv", "Scripts", "python.exe"),  # Windows
    os.path.join(ROOT, ".venv", "bin", "python"),  # macOS/Linux
)


def main() -> int:
    python = next((p for p in KANDIDATEN if os.path.isfile(p)), None)
    if python is None:
        print(
            "Keine .venv gefunden - Tests laufen mit dem aktuellen Python.\n"
            "Einrichten: scripts\\2_umgebung_einrichten.bat "
            "(macOS/Linux: bash scripts/setup-dev.sh)",
            file=sys.stderr,
        )
        python = sys.executable
    # Argumente fest vorgegeben (Pfad der .venv + pytest), keine Benutzereingabe
    return subprocess.call([python, "-m", "pytest", "-q"], cwd=ROOT)  # noqa: S603  # nosec B603


if __name__ == "__main__":
    sys.exit(main())
