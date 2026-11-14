import pytest

from app import create_app

SEITEN = ["/", "/beispiel", "/einstellungen"]


def test_health(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.get_json() == {"status": "ok"}


def test_index(client):
    response = client.get("/")
    assert response.status_code == 200
    assert b"MBe App" in response.data


@pytest.mark.parametrize("pfad", SEITEN)
def test_seiten_erreichbar(client, pfad):
    assert client.get(pfad).status_code == 200


def test_api_beispiel(client):
    response = client.get("/api/beispiel")
    assert response.status_code == 200
    eintraege = response.get_json()["eintraege"]
    assert eintraege
    assert {"id", "name", "status", "wert", "aenderung", "kategorie"} <= set(eintraege[0])


def test_404(client):
    response = client.get("/gibt-es-nicht")
    assert response.status_code == 404
    assert "Seite nicht gefunden" in response.get_data(as_text=True)


def test_500_zeigt_keinen_stacktrace(app):
    @app.get("/kaputt")
    def kaputt():
        raise ValueError("geheimes Detail")

    app.config["PROPAGATE_EXCEPTIONS"] = False
    response = app.test_client().get("/kaputt")
    html = response.get_data(as_text=True)
    assert response.status_code == 500
    assert "Fehler aufgetreten" in html
    assert "geheimes Detail" not in html


def test_security_headers(client):
    response = client.get("/")
    assert response.headers["X-Content-Type-Options"] == "nosniff"
    assert response.headers["X-Frame-Options"] == "DENY"
    assert "Content-Security-Policy" in response.headers


def test_missing_secret_key_fails(monkeypatch):
    monkeypatch.delenv("SECRET_KEY", raising=False)
    with pytest.raises(RuntimeError, match="SECRET_KEY"):
        create_app()


def test_layout_mbe_design(client):
    html = client.get("/").get_data(as_text=True)
    assert "images/MBe_Button_violett.png" in html
    assert "images/favicon.ico" in html
    assert "css/style.css" in html
    assert "js/app.js" in html
    for klasse in ("app-layout", "app-header", "app-sidebar", "app-main", "app-footer"):
        assert f'class="{klasse}"' in html


def test_aktiver_menuepunkt(client):
    html = client.get("/beispiel").get_data(as_text=True)
    assert 'href="/beispiel" class="active"' in html


@pytest.mark.parametrize(
    "pfad",
    [
        "/static/images/MBe_Button_violett.png",
        "/static/images/favicon.ico",
        "/static/css/style.css",
        "/static/js/app.js",
        "/static/js/beispiel.js",
        "/static/js/einstellungen.js",
    ],
)
def test_statische_dateien_vorhanden(client, pfad):
    response = client.get(pfad)
    assert response.status_code == 200
    assert len(response.data) > 0
    response.close()


@pytest.mark.parametrize("pfad", SEITEN)
def test_kein_inline_javascript(client, pfad):
    # Die CSP erlaubt kein Inline-JavaScript; Skripte nur als Datei einbinden.
    html = client.get(pfad).get_data(as_text=True)
    for verboten in ("onclick=", "onerror=", "oninput=", "onchange=", "<script>"):
        assert verboten not in html
