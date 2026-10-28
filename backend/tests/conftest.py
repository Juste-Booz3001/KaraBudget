import os

os.environ["KARA_DATABASE_URL"] = "sqlite://"

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import sessionmaker

from app.db import Base, get_db, make_engine
from app.main import app


@pytest.fixture()
def client():
    engine = make_engine("sqlite://")
    Base.metadata.create_all(engine)
    Session = sessionmaker(engine, autoflush=False, expire_on_commit=False)

    def override():
        db = Session()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.clear()


class Account:
    def __init__(self, client, email):
        r = client.post("/auth/register", json={"email": email, "password": "motdepasse123"})
        assert r.status_code == 201, r.text
        body = r.json()
        self.client = client
        self.headers = {"Authorization": f"Bearer {body['access_token']}"}
        self.space = body["personal_space_id"]
        self.tokens = body

    def push(self, ops, space=None, device="dev-1"):
        r = self.client.post(
            f"/spaces/{space or self.space}/sync/push", json={"device_id": device, "ops": ops}, headers=self.headers
        )
        return r

    def pull(self, since=0, limit=200, space=None):
        r = self.client.get(
            f"/spaces/{space or self.space}/sync/pull", params={"since": since, "limit": limit}, headers=self.headers
        )
        assert r.status_code == 200, r.text
        return r.json()


@pytest.fixture()
def alice(client):
    return Account(client, "alice@example.com")


@pytest.fixture()
def bob(client):
    return Account(client, "bob@example.com")


_counter = {"n": 0}


def op(entity_id, ts, fields=None, entity="expense", action="upsert"):
    _counter["n"] += 1
    return {
        "op_id": f"op-{_counter['n']:08d}",
        "entity": entity,
        "entity_id": entity_id,
        "action": action,
        "fields": fields or {},
        "ts": ts,
    }
