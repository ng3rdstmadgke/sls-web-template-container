from fastapi.testclient import TestClient
import pytest

from api.main import app
from api.models import Base
from api.session import engine, SessionLocal
from api.test.lib import utils as test_utils


client = TestClient(app)

@pytest.fixture(scope="module", autouse=True)
def pre_module():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    test_utils.create_user(
        session_factory=SessionLocal,
        is_superuser=True,
    )
    yield
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)

def test_create_success():
    token = test_utils.get_token(client)
    response = client.post(
        "/api/v1/users/",
        json={
            "username": "test_1",
            "password": "test1234",
        },
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200
    body = response.json()
    expected = {
        'id': 2,
        'username': "test_1",
        'is_superuser': False,
        'is_active': True,
    }
    assert body == expected


def test_create_error_alreadyExists():
    token = test_utils.get_token(client)
    response = client.post(
        "/api/v1/users/",
        json={
            "username": "test_1",
            "password": "test1234",
        },
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 400
    assert response.json() == {"detail": "Username already registerd"}


def test_read_success_getAll():
    token = test_utils.get_token(client)
    response = client.get(
        "/api/v1/users/",
        json={"skip": 0, "limit": 10},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200
    assert len(response.json()) == 2

def test_read_success_me():
    token = test_utils.get_token(client)
    response = client.get(
        f"/api/v1/users/me",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200
    expected = {
        'id': 1,
        'username': "admin",
        'is_superuser': True,
        'is_active': True,
    }
    assert response.json() == expected

def test_read_success_getById():
    id = 2
    token = test_utils.get_token(client)
    response = client.get(
        f"/api/v1/users/{id}",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200
    expected = {
        'id': id,
        'username': "test_1",
        'is_superuser': False,
        'is_active': True,
    }
    assert response.json() == expected

def test_read_error_notFound():
    id = 10000
    token = test_utils.get_token(client)
    response = client.get(
        f"/api/v1/users/{id}",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 404

def test_update_success():
    id = 2
    token = test_utils.get_token(client)
    response = client.put(
        f"/api/v1/users/{id}",
        json={
            'username': 'test_1',
            'is_superuser': True,
            'is_active': False,
        },
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200
    expected ={
        'id': id,
        'username': "test_1",
        'is_superuser': True,
        'is_active': False,
    }
    assert response.json() == expected
    actual = test_utils.http_get(client, f"/api/v1/users/{id}")
    assert actual == expected

def test_update_error_notFound():
    id = 10000
    token = test_utils.get_token(client)
    response = client.put(
        f"/api/v1/users/{id}",
        json={
            'username': 'test_1',
            'is_superuser': True,
            'is_active': False,
        },
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 404

def test_delete_success():
    id = 2
    token = test_utils.get_token(client)
    response = client.delete(
        f"/api/v1/users/{id}",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200
    assert response.json() == {"user_id": id}

def test_delete_error_notFound():
    id = 10000
    token = test_utils.get_token(client)
    response = client.delete(
        f"/api/v1/users/10000",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 404
