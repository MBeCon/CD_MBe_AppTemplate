import pytest

from app import create_app


def test_health(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.get_json() == {"status": "ok"}


def test_index(client):
    response = client.get("/")
    assert response.status_code == 200
    assert b"te App" in response.data


def test_404(client):
    response = client.get("/gibt-es-nicht")
    assert response.status_code == 404


def test_security_headers(client):
    response = client.get("/")
    assert response.headers["X-Content-Type-Options"] == "nosniff"
    assert response.headers["X-Frame-Options"] == "DENY"
    assert "Content-Security-Policy" in response.headers


def test_missing_secret_key_fails(monkeypatch):
    monkeypatch.delenv("SECRET_KEY", raising=False)
    with pytest.raises(RuntimeError, match="SECRET_KEY"):
        create_app()


def test_layout_mit_logo_und_design(client):
    response = client.get("/")
    html = response.get_data(as_text=True)
    assert "images/technosert_logo_white.png" in html
    assert "css/style.css" in html
    assert "js/app.js" in html
    assert 'class="app-header"' in html


@pytest.mark.parametrize(
    "pfad",
    ["/static/images/technosert_logo_white.png", "/static/css/style.css", "/static/js/app.js"],
)
def test_statische_dateien_vorhanden(client, pfad):
    response = client.get(pfad)
    assert response.status_code == 200
    assert len(response.data) > 0
    response.close()


def test_kein_inline_javascript(client):
    # Die CSP erlaubt kein Inline-JavaScript; Skripte nur als Datei einbinden.
    html = client.get("/").get_data(as_text=True)
    assert "onclick=" not in html
    assert "<script>" not in html
