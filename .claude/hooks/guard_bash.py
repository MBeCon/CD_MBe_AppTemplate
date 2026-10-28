"""PreToolUse-Hook: blockiert Shell-Befehle, die die Qualitätssicherung umgehen.

Exit-Code 2 = Befehl wird blockiert, die Meldung auf stderr geht an Claude zurück.
"""

import json
import re
import shlex
import sys

ENV_READERS = {"cat", "type", "less", "more", "head", "tail", "bat", "nano", "vim", "code"}
PROTECTED_BRANCHES = {"main", "master"}


def _segments(command: str) -> list[list[str]]:
    """Zerlegt verkettete Befehle (&&, ||, ;, |) in Token-Listen."""
    parts = re.split(r"&&|\|\||;|\|", command)
    result = []
    for part in parts:
        try:
            tokens = shlex.split(part, posix=True)
        except ValueError:
            tokens = part.split()
        if tokens:
            result.append(tokens)
    return result


def _check(tokens: list[str]) -> str | None:
    # Umgebungsvariablen-Präfixe (z. B. SKIP=ruff git commit ...) prüfen und entfernen
    while tokens and re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", tokens[0]):
        if tokens[0].startswith("SKIP="):
            return "pre-commit-Hooks dürfen nicht per SKIP= übersprungen werden."
        tokens = tokens[1:]
    if not tokens:
        return None

    if "--no-verify" in tokens:
        return "QS-Hooks dürfen nicht mit --no-verify umgangen werden."

    if tokens[0] in ENV_READERS and any(t == ".env" or t.endswith("/.env") for t in tokens[1:]):
        return "Die Datei .env darf nicht gelesen werden."

    if tokens[0] != "git" or len(tokens) < 2:
        return None
    sub, args = tokens[1], tokens[2:]

    if sub == "commit" and any(re.fullmatch(r"-[a-zA-Z]*n[a-zA-Z]*", a) for a in args):
        return "QS-Hooks dürfen nicht mit -n (no-verify) umgangen werden."

    if sub == "push":
        if any(a == "-f" or a.startswith("--force") for a in args):
            return "Force-Push ist nicht erlaubt."
        for arg in args:
            target = arg.split(":")[-1].removeprefix("refs/heads/").lstrip("+")
            if target in PROTECTED_BRANCHES:
                return "Kein direkter Push auf main. Branch pushen und Merge Request erstellen."
    return None


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except json.JSONDecodeError:
        return 0
    command = payload.get("tool_input", {}).get("command", "")
    for tokens in _segments(command):
        message = _check(tokens)
        if message:
            print(f"Blockiert durch QS-Regel: {message}", file=sys.stderr)
            return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
