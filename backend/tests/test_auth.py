def test_register_login_refresh(client):
    r = client.post("/auth/register", json={"email": "Zed@Example.com", "password": "motdepasse123"})
    assert r.status_code == 201
    assert r.json()["personal_space_id"] and r.json()["user_id"]

    assert client.post("/auth/register", json={"email": "zed@example.com", "password": "motdepasse123"}).status_code == 409

    ok = client.post("/auth/login", json={"email": "zed@example.com", "password": "motdepasse123"})
    assert ok.status_code == 200
    bad = client.post("/auth/login", json={"email": "zed@example.com", "password": "mauvaismdp1"})
    assert bad.status_code == 401

    refreshed = client.post("/auth/refresh", json={"refresh_token": ok.json()["refresh_token"]})
    assert refreshed.status_code == 200
    # un access token n'est pas accepté comme refresh token
    assert client.post("/auth/refresh", json={"refresh_token": ok.json()["access_token"]}).status_code == 401


def test_validation_and_protection(client):
    assert client.post("/auth/register", json={"email": "pas-un-mail", "password": "motdepasse123"}).status_code == 422
    assert client.post("/auth/register", json={"email": "a@b.co", "password": "court"}).status_code == 422
    assert client.get("/spaces").status_code == 401
    # un refresh token ne donne pas accès à l'API
    r = client.post("/auth/register", json={"email": "t@t.io", "password": "motdepasse123"}).json()
    assert client.get("/spaces", headers={"Authorization": f"Bearer {r['refresh_token']}"}).status_code == 401
