"""PostToolUse-Hook: formatiert und prüft jede von Claude geänderte Python-Datei mit ruff.

Verbleibende Probleme werden mit Exit-Code 2 an Claude zurückgemeldet, damit es sie
sofort behebt. Ist ruff nicht installiert, wird still übersprungen.
"""

import json
import shutil
import subprocess  # nosec B404 - feste Argumentliste, kein shell=True
import sys
from pathlib import Path


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except json.JSONDecodeError:
        return 0

    file_path = payload.get("tool_input", {}).get("file_path", "")
    if not file_path.endswith(".py") or not Path(file_path).exists():
        return 0

    ruff = shutil.which("ruff")
    cmd = [ruff] if ruff else [sys.executable, "-m", "ruff"]
    try:
        subprocess.run([*cmd, "format", file_path], capture_output=True, check=False)  # noqa: S603  # nosec B603
        result = subprocess.run(  # noqa: S603  # nosec B603
            [*cmd, "check", "--fix", file_path], capture_output=True, text=True, check=False
        )
    except (FileNotFoundError, OSError):
        return 0

    if result.returncode == 1:
        print(f"ruff meldet Probleme in {file_path}:\n{result.stdout}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
