from typing import List, Dict, Any
from functools import lru_cache

from fastapi.testclient import TestClient

from api.schemas.user import UserCreateSchema
from api.crud import user as crud_user


@lru_cache()
def get_token(
    client: TestClient,
    username: str = "admin",
    password: str = "admin1234"
):
    response = client.post(
        "/api/v1/token",
        {"username": username, "password": password}
    )
    if response.status_code != 200:
        raise Exception(f"{response.status_code}: {response.content}")
    return response.json()["access_token"]

def create_user(
    session_factory,
    username: str = "admin",
    password: str = "admin1234",
    is_superuser: bool = False,
):
    with session_factory() as session:
        user = crud_user.create_user_if_not_exists(
            session,
            UserCreateSchema(username=username, password=password),
        )
        user.is_superuser = is_superuser
        session.add(user)
        session.commit()

def http_get(client, url: str) -> List[Dict[str, Any]]:
    token = get_token(client)
    response = client.get(
        url,
        headers={"Authorization": f"Bearer {token}"},
    )
    if response.status_code != 200:
        raise Exception(f"{response.status_code}: {response.content}")
    return response.json()