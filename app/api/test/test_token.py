from fastapi.testclient import TestClient
from jose import jwt
import pytest

from api.main import app
from api.models import Base
from api.session import engine, SessionLocal
from api.lib.secrets import get_jwt_secret
from api.test.lib import utils as test_utils
from api.env import get_env

Base.metadata.drop_all(bind=engine)


client = TestClient(app)

@pytest.fixture(scope="module", autouse=True)
def pre_module():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    test_utils.create_user(SessionLocal)
    yield
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)

def test_create_token():
    response = client.post(
        "/api/v1/token",
        {"username": "admin", "password": "admin1234"}
    )
    assert response.status_code == 200
    body = response.json()
    assert body["token_type"] == "bearer"
    secret_key = get_jwt_secret().secret_key
    payload = jwt.decode(body["access_token" ], secret_key, algorithms=["HS256"])
    assert payload["sub"] == "admin"
    assert payload["scopes"] == []
    assert payload["is_superuser"] == False

def test_create_token_incorrect_username():
    response = client.post(
        "/api/v1/token",
        {"username": "unknown", "password": "admin1234"}
    )
    assert response.status_code == 401
    body = response.json()
    assert body == {"detail": "Incorrect username or password"}

def test_create_token_incorrect_password():
    response = client.post(
        "/api/v1/token",
        {"username": "admin", "password": "hogehoge"}
    )
    assert response.status_code == 401
    body = response.json()
    assert body == {"detail": "Incorrect username or password"}
