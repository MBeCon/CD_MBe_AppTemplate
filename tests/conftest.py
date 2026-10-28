import pytest

from app import create_app


@pytest.fixture
def app():
    return create_app({"TESTING": True, "SECRET_KEY": "test-only", "APP_ENV": "test"})


@pytest.fixture
def client(app):
    return app.test_client()
