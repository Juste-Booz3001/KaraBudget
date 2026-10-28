"""Fonctions v2 : rôles, partage de dépenses, activité, pièces jointes, nouvelles entités, mise à niveau du schéma."""
import json

from sqlalchemy import create_engine, inspect, text

from app.db import upgrade_schema

from .conftest import Account, op

E = "11111111-1111-1111-1111-111111111111"
G = "gggggggg-gggg-gggg-gggg-gggggggggggg"


def make_shared(client, owner, *others):
    shared = client.post("/spaces", json={"name": "Coloc"}, headers=owner.headers).json()
    for o in others:
        assert client.post("/spaces/join", json={"invite_code": shared["invite_code"]}, headers=o.headers).status_code == 200
    return shared["id"], shared["invite_code"]


# ---------- rôles ----------
def test_viewer_cannot_push_but_can_read_and_owner_manages_members(client, alice, bob):
    space, code = make_shared(client, alice, bob)
    members = {m["email"]: m for m in client.get(f"/spaces/{space}/members", headers=alice.headers).json()}
    bob_id = members["bob@example.com"]["user_id"]
    assert members["alice@example.com"]["role"] == "owner" and members["bob@example.com"]["role"] == "editor"

    assert bob.push([op(E, 100, {"note": "ok"})], space=space).status_code == 200
    # bob n'est pas propriétaire
    assert client.patch(f"/spaces/{space}/members/{bob_id}", json={"role": "viewer"}, headers=bob.headers).status_code == 403

    r = client.patch(f"/spaces/{space}/members/{bob_id}", json={"role": "viewer"}, headers=alice.headers)
    assert r.status_code == 200 and r.json()["role"] == "viewer"
    assert bob.push([op(E, 200, {"note": "interdit"})], space=space).status_code == 403
    assert bob.pull(space=space)["changes"][0]["fields"]["note"] == "ok"  # lecture toujours permise
    assert client.get(f"/spaces", headers=bob.headers).json()[-1]["role"] in ("viewer", "owner")

    assert client.patch(f"/spaces/{space}/members/{bob_id}", json={"role": "boss"}, headers=alice.headers).status_code == 422


def test_owner_removes_member_and_rotates_code(client, alice, bob):
    space, code = make_shared(client, alice, bob)
    bob_id = next(m for m in client.get(f"/spaces/{space}/members", headers=alice.headers).json() if m["email"].startswith("bob"))["user_id"]
    alice_id = next(m for m in client.get(f"/spaces/{space}/members", headers=alice.headers).json() if m["email"].startswith("alice"))["user_id"]

    assert client.delete(f"/spaces/{space}/members/{alice_id}", headers=alice.headers).status_code == 400  # pas le propriétaire
    assert client.delete(f"/spaces/{space}/members/{bob_id}", headers=bob.headers).status_code == 403
    assert client.delete(f"/spaces/{space}/members/{bob_id}", headers=alice.headers).status_code == 204
    assert client.get(f"/spaces/{space}/sync/pull", headers=bob.headers).status_code == 404

    new = client.post(f"/spaces/{space}/invite/rotate", headers=alice.headers).json()
    assert new["invite_code"] != code
    assert client.post("/spaces/join", json={"invite_code": code}, headers=bob.headers).status_code == 404
    assert client.post("/spaces/join", json={"invite_code": new["invite_code"]}, headers=bob.headers).status_code == 200
    # l'espace personnel n'a pas de membres à gérer
    assert client.post(f"/spaces/{alice.space}/invite/rotate", headers=alice.headers).status_code == 400


# ---------- partage de dépenses ----------
def test_split_and_settlement_validation(client, alice, bob):
    space, _ = make_shared(client, alice, bob)
    ids = {m["email"]: m["user_id"] for m in client.get(f"/spaces/{space}/members", headers=alice.headers).json()}
    a, b = ids["alice@example.com"], ids["bob@example.com"]
    equal = json.dumps({"mode": "equal", "with": [a, b]})
    exact = json.dumps({"mode": "exact", "shares": {a: 300, b: 700}})

    ok = alice.push([op(E, 100, {"amount_minor": 1000, "paid_by": a, "split_json": equal})], space=space).json()
    assert ok["results"][0]["status"] == "applied"
    assert alice.push([op(E, 200, {"split_json": exact})], space=space).json()["results"][0]["status"] == "applied"

    bad = [
        op(E, 300, {"paid_by": "inconnu-0000"}),  # payeur hors espace
        op(E, 300, {"split_json": json.dumps({"mode": "equal", "with": [a, "inconnu"]})}),
        op(E, 300, {"split_json": "pas du json"}),
        op(E, 300, {"split_json": json.dumps({"mode": "exact", "shares": {a: -5}})}),
        op(E, 300, {"split_json": json.dumps({"mode": "weird"})}),
    ]
    assert [r["status"] for r in alice.push(bad, space=space).json()["results"]] == ["rejected"] * 5

    S = "ssssssss-ssss-ssss-ssss-ssssssssssss"
    r = bob.push([op(S, 100, {"from_user": b, "to_user": a, "amount_minor": 350, "currency": "EUR", "at": 5}, entity="settlement")], space=space)
    assert r.json()["results"][0]["status"] == "applied"
    same = alice.push([op(S, 200, {"from_user": a, "to_user": a}, entity="settlement")], space=space).json()
    assert same["results"][0]["status"] == "rejected"
    assert any(c["entity"] == "settlement" for c in alice.pull(space=space)["changes"])


# ---------- nouvelles entités ----------
def test_new_entities_roundtrip_and_validation(alice):
    R, C = "rrrrrrrr-rrrr", "cccccccc-cccc"
    res = alice.push(
        [
            op(R, 10, {"from_currency": "EUR", "to_currency": "MGA", "rate_ppm": 4_800_000_000}, entity="rate"),
            op(G, 10, {"name": "Vacances", "target_minor": 100000, "currency": "EUR", "due_at": 0, "color": 0xFF009688}, entity="goal"),
            op(C, 10, {"goal_id": G, "amount_minor": 2500, "at": 5, "note": "janvier"}, entity="contribution"),
            op(E, 10, {"tags": "courses,resto", "attachment_id": "att-12345678"}),
            op("bbbbbbbb-bbbb", 10, {"category_id": "x" * 8, "month": "2026-10", "limit_minor": 1000, "rollover": 1}, entity="budget"),
        ]
    ).json()["results"]
    assert [r["status"] for r in res] == ["applied"] * 5
    by = {c["entity"]: c for c in alice.pull()["changes"]}
    assert by["rate"]["fields"]["rate_ppm"] == 4_800_000_000
    assert by["expense"]["fields"]["tags"] == "courses,resto"
    assert by["budget"]["fields"]["rollover"] == 1

    bad = alice.push(
        [
            op(R, 20, {"rate_ppm": 0}, entity="rate"),
            op(R, 20, {"rate_ppm": 1.5}, entity="rate"),
            op(R, 20, {"from_currency": "EURO"}, entity="rate"),
            op("bbbbbbbb-bbbb", 20, {"rollover": 2}, entity="budget"),
            op(E, 20, {"tags": "t" * 301}),
        ]
    ).json()["results"]
    assert [r["status"] for r in bad] == ["rejected"] * 5


def test_contributions_from_two_devices_do_not_overwrite(alice):
    # deux appareils épargnent en même temps : deux lignes distinctes, le total est la somme
    alice.push([op("c1111111-1", 100, {"goal_id": G, "amount_minor": 1000}, entity="contribution")], device="A")
    alice.push([op("c2222222-2", 100, {"goal_id": G, "amount_minor": 2000}, entity="contribution")], device="B")
    total = sum(c["fields"]["amount_minor"] for c in alice.pull()["changes"] if c["entity"] == "contribution")
    assert total == 3000


# ---------- journal d'activité ----------
def test_activity_log(client, alice, bob):
    space, _ = make_shared(client, alice, bob)
    alice.push([op(E, 100, {"amount_minor": 500, "note": "pizza"})], space=space)
    bob.push([op(E, 200, {"note": "pizza 4 fromages"})], space=space)
    bob.push([op(E, 300, action="delete")], space=space)
    alice.push([op("cat00000-1", 0, {"name": "Défaut"}, entity="category")], space=space)  # amorçage ts=0 : ignoré

    log = client.get(f"/spaces/{space}/activity", headers=alice.headers).json()
    assert [(a["email"], a["action"]) for a in log] == [
        ("bob@example.com", "delete"),
        ("bob@example.com", "update"),
        ("alice@example.com", "create"),
    ]
    assert log[1]["changed"] == ["note"] and log[1]["label"] == "pizza 4 fromages"
    page = client.get(f"/spaces/{space}/activity", params={"limit": 1, "before": log[0]["id"]}, headers=alice.headers).json()
    assert len(page) == 1 and page[0]["id"] == log[1]["id"]
    # un non-membre ne voit rien
    outsider = Account(client, "eve@example.com")
    assert client.get(f"/spaces/{space}/activity", headers=outsider.headers).status_code == 404


def test_recurring_next_due_advance_is_not_logged(client, alice):
    R = "rec00000-1"
    alice.push([op(R, 100, {"amount_minor": 5, "next_due": 1}, entity="recurring")])
    alice.push([op(R, 200, {"next_due": 2}, entity="recurring")])
    assert len(client.get(f"/spaces/{alice.space}/activity", headers=alice.headers).json()) == 1


# ---------- pièces jointes ----------
def test_attachments(client, alice, bob):
    space, _ = make_shared(client, alice, bob)
    url = f"/spaces/{space}/attachments/att-12345678"
    png = b"\x89PNG\r\n\x1a\n" + b"0" * 100
    h = {**alice.headers, "content-type": "image/png"}
    assert client.put(url, content=png, headers=h).status_code == 201
    assert client.put(url, content=b"autre", headers=h).status_code == 201  # idempotent, pas d'écrasement
    got = client.get(url, headers=bob.headers)
    assert got.status_code == 200 and got.content == png and got.headers["content-type"] == "image/png"

    assert client.put(url + "x", content=png, headers={**alice.headers, "content-type": "text/html"}).status_code == 415
    assert client.put(f"/spaces/{space}/attachments/a", content=png, headers=h).status_code == 422  # id invalide
    assert client.put(f"/spaces/{space}/attachments/big-1234567", content=b"0" * (4 * 1024 * 1024 + 1), headers=h).status_code == 413
    assert client.get(f"/spaces/{space}/attachments/inconnu-12345", headers=alice.headers).status_code == 404

    # lecteur : lecture oui, dépôt non ; non-membre : rien
    bob_id = next(m for m in client.get(f"/spaces/{space}/members", headers=alice.headers).json() if m["email"].startswith("bob"))["user_id"]
    client.patch(f"/spaces/{space}/members/{bob_id}", json={"role": "viewer"}, headers=alice.headers)
    assert client.put(f"/spaces/{space}/attachments/att-87654321", content=png, headers={**bob.headers, "content-type": "image/png"}).status_code == 403
    outsider = Account(client, "eve@example.com")
    assert client.get(url, headers=outsider.headers).status_code == 404


# ---------- mise à niveau d'un schéma v1 existant ----------
def test_upgrade_schema_adds_missing_columns():
    engine = create_engine("sqlite://")
    with engine.begin() as c:
        c.execute(text("CREATE TABLE expenses (space_id VARCHAR(36), id VARCHAR(64), note VARCHAR(500), PRIMARY KEY (space_id, id))"))
        c.execute(text("CREATE TABLE budgets (space_id VARCHAR(36), id VARCHAR(64), PRIMARY KEY (space_id, id))"))
        c.execute(text("INSERT INTO expenses VALUES ('s', 'e', 'ancienne ligne')"))
    upgrade_schema(engine)
    upgrade_schema(engine)  # idempotent
    cols = {c["name"] for c in inspect(engine).get_columns("expenses")}
    assert {"tags", "paid_by", "split_json", "attachment_id"} <= cols
    assert "rollover" in {c["name"] for c in inspect(engine).get_columns("budgets")}
    with engine.connect() as c:
        assert c.execute(text("SELECT tags, split_json FROM expenses")).one() == ("", "")


# ---------- ré-ajout après suppression (ids déterministes : budgets, taux) ----------
def test_upsert_with_null_deleted_at_resurrects_only_if_newer(alice):
    B = "bbbbbbbb-bbbb"
    alice.push([op(B, 100, {"category_id": "cat-aaaaaaaa", "month": "2026-10", "limit_minor": 500}, entity="budget")])
    alice.push([op(B, 200, action="delete", entity="budget")])
    # ré-ajout plus récent que la suppression : la ligne revit
    alice.push([op(B, 300, {"limit_minor": 800, "deleted_at": None}, entity="budget")])
    row = next(c for c in alice.pull()["changes"] if c["id"] == B)
    assert row["deleted_at"] is None and row["fields"]["limit_minor"] == 800
    # une suppression plus ancienne qui arrive en retard ne tue pas la ligne
    alice.push([op(B, 250, action="delete", entity="budget")])
    assert next(c for c in alice.pull()["changes"] if c["id"] == B)["deleted_at"] is None
    # une suppression plus récente gagne
    alice.push([op(B, 400, action="delete", entity="budget")])
    assert next(c for c in alice.pull()["changes"] if c["id"] == B)["deleted_at"] == 400
    # deleted_at ne peut valoir que null dans un upsert
    bad = alice.push([op(B, 500, {"deleted_at": 5}, entity="budget")]).json()["results"][0]
    assert bad["status"] == "rejected"


def test_member_can_leave_but_not_owner_or_personal(client, alice, bob):
    space, code = make_shared(client, alice, bob)
    assert client.delete(f"/spaces/{space}/membership", headers=alice.headers).status_code == 400  # propriétaire
    assert client.delete(f"/spaces/{alice.space}/membership", headers=alice.headers).status_code == 400  # espace perso
    assert client.delete(f"/spaces/{space}/membership", headers=bob.headers).status_code == 204
    assert client.get(f"/spaces/{space}/sync/pull", headers=bob.headers).status_code == 404
    assert client.post("/spaces/join", json={"invite_code": code}, headers=bob.headers).status_code == 200  # peut revenir
