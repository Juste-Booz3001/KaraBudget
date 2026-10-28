import itertools
import time

import pytest

from .conftest import Account, op

E = "11111111-1111-1111-1111-111111111111"


def by_id(pull, entity_id):
    return next(c for c in pull["changes"] if c["id"] == entity_id)


def test_push_then_pull(alice):
    r = alice.push([op(E, 100, {"amount_minor": 1250, "currency": "EUR", "note": "café", "spent_at": 5})])
    assert r.status_code == 200
    assert r.json()["results"][0]["status"] == "applied"
    pulled = alice.pull()
    change = by_id(pulled, E)
    assert change["fields"]["amount_minor"] == 1250 and change["fields"]["note"] == "café"
    assert change["deleted_at"] is None
    assert pulled["next_cursor"] == change["rev"] and not pulled["has_more"]
    assert alice.pull(since=pulled["next_cursor"])["changes"] == []


def test_idempotent_replay(alice):
    first = op(E, 100, {"amount_minor": 500})
    assert alice.push([first]).json()["results"][0]["status"] == "applied"
    rev = alice.pull()["next_cursor"]
    again = alice.push([first]).json()
    assert again["results"][0]["status"] == "duplicate"
    assert alice.pull()["next_cursor"] == rev  # aucun effet de bord


@pytest.mark.parametrize("a_first", [True, False])
def test_two_devices_offline_edits_merge_per_field(alice, a_first):
    alice.push([op(E, 100, {"amount_minor": 1000, "note": "base"})])
    # appareil A (hors-ligne) modifie la note à t=300 ; appareil B modifie montant (t=200) et note (t=250)
    a = op(E, 300, {"note": "note de A"})
    b = op(E, 250, {"note": "note de B"})
    b2 = op(E, 200, {"amount_minor": 2000})
    batches = [([a], "A"), ([b, b2], "B")]
    for ops, dev in batches if a_first else reversed(batches):
        assert alice.push(ops, device=dev).status_code == 200
    fields = by_id(alice.pull(), E)["fields"]
    assert fields["note"] == "note de A"  # plus récent
    assert fields["amount_minor"] == 2000  # champs disjoints : les deux éditions sont conservées


def test_equal_timestamp_keeps_existing(alice):
    alice.push([op(E, 100, {"note": "premier"})])
    r = alice.push([op(E, 100, {"note": "second"})]).json()
    assert r["results"][0]["status"] == "noop"
    assert by_id(alice.pull(), E)["fields"]["note"] == "premier"


def test_delete_is_tombstone_and_not_resurrected(alice):
    alice.push([op(E, 100, {"amount_minor": 1, "note": "x"})])
    alice.push([op(E, 500, action="delete")])
    alice.push([op(E, 400, {"note": "édition tardive d'un autre appareil"})])
    change = by_id(alice.pull(), E)
    assert change["deleted_at"] == 500  # la ligne reste visible pour propager la suppression


def test_delete_unknown_entity_creates_tombstone(alice):
    alice.push([op(E, 500, action="delete")])
    alice.push([op(E, 100, {"note": "arrive après"})])
    assert by_id(alice.pull(), E)["deleted_at"] == 500


def test_future_timestamp_is_clamped(alice):
    far = int(time.time() * 1000) + 10 * 24 * 3600 * 1000
    alice.push([op(E, far, {"note": "futur"})])
    ts = by_id(alice.pull(), E)["field_ts"]["note"]
    assert ts < far and ts <= int(time.time() * 1000) + 5 * 60 * 1000 + 1000
    # une édition légitime juste après ne doit pas être bloquée à vie par l'horloge fautive
    alice.push([op(E, int(time.time() * 1000) + 10 * 60 * 1000, {"note": "ok"})])


def test_pagination_cursor(alice):
    ids = [f"22222222-2222-2222-2222-22222222222{i}" for i in range(5)]
    alice.push([op(i, 100 + n, {"note": f"n{n}"}) for n, i in enumerate(ids)])
    seen, cursor = [], 0
    for _ in range(10):
        page = alice.pull(since=cursor, limit=2)
        seen += [c["id"] for c in page["changes"]]
        cursor = page["next_cursor"]
        if not page["has_more"]:
            break
    assert seen == ids


def test_modified_row_reappears_in_pull(alice):
    alice.push([op(E, 100, {"note": "v1"})])
    cur = alice.pull()["next_cursor"]
    alice.push([op(E, 200, {"note": "v2"})])
    changes = alice.pull(since=cur)["changes"]
    assert [c["fields"]["note"] for c in changes] == ["v2"]


def test_invalid_ops_are_rejected_not_fatal(alice):
    good = op(E, 100, {"note": "ok"})
    ops = [
        op(E, 100, {"amount_minor": "12"}),  # mauvais type
        op(E, 100, {"amount_minor": 1.5}),  # float interdit pour les montants
        op(E, 100, {"nope": 1}),  # champ inconnu
        op(E, 100, {"note": None}),  # non nullable
        good,
    ]
    res = alice.push(ops).json()["results"]
    assert [r["status"] for r in res] == ["rejected"] * 4 + ["applied"]
    assert alice.push([{**op(E, 1), "entity": "virus"}]).status_code == 422


def test_category_can_be_null_on_expense(alice):
    alice.push([op(E, 100, {"category_id": "cat-aaaaaaaa"})])
    alice.push([op(E, 200, {"category_id": None})])
    assert by_id(alice.pull(), E)["fields"]["category_id"] is None


def test_spaces_are_isolated_and_shared_space_works(client, alice, bob):
    alice.push([op(E, 100, {"note": "privé"})])
    # bob ne voit rien de l'espace d'alice, et n'apprend même pas qu'il existe
    assert client.get(f"/spaces/{alice.space}/sync/pull", headers=bob.headers).status_code == 404
    assert bob.push([op(E, 100, {"note": "x"})], space=alice.space).status_code == 404

    shared = client.post("/spaces", json={"name": "Coloc"}, headers=alice.headers).json()
    assert shared["role"] == "owner"
    # même UUID dans deux espaces : pas de collision (clé composite)
    alice.push([op(E, 100, {"note": "dans la coloc"})], space=shared["id"])
    assert by_id(alice.pull(space=shared["id"]), E)["fields"]["note"] == "dans la coloc"
    assert by_id(alice.pull(), E)["fields"]["note"] == "privé"

    joined = client.post("/spaces/join", json={"invite_code": shared["invite_code"].lower()}, headers=bob.headers)
    assert joined.status_code == 200 and joined.json()["role"] == "editor"
    assert by_id(bob.pull(space=shared["id"]), E)["fields"]["note"] == "dans la coloc"
    bob.push([op("33333333-3333-3333-3333-333333333333", 200, {"note": "de bob"})], space=shared["id"])
    assert len(alice.pull(space=shared["id"])["changes"]) == 2

    members = client.get(f"/spaces/{shared['id']}/members", headers=alice.headers).json()
    assert {m["email"] for m in members} == {"alice@example.com", "bob@example.com"}
    assert client.delete(f"/spaces/{shared['id']}/membership", headers=bob.headers).status_code == 204
    assert client.get(f"/spaces/{shared['id']}/sync/pull", headers=bob.headers).status_code == 404
    # l'espace personnel n'est pas joignable par code
    personal_code = next(s for s in client.get("/spaces", headers=alice.headers).json() if s["is_personal"])["invite_code"]
    assert client.post("/spaces/join", json={"invite_code": personal_code}, headers=bob.headers).status_code == 404


def test_csv_export(client, alice):
    cat = "cccccccc-cccc-cccc-cccc-cccccccccccc"
    alice.push([op(cat, 1, {"name": "Alimentation"}, entity="category")])
    day = 1760832000000  # 2025-10-19 UTC
    alice.push(
        [
            op(E, 100, {"amount_minor": 1250, "currency": "EUR", "category_id": cat, "note": "=HYPERLINK(1)", "spent_at": day}),
            op("44444444-4444-4444-4444-444444444444", 100, {"amount_minor": 7000, "currency": "MGA", "spent_at": 0}),
        ]
    )
    r = client.get(f"/spaces/{alice.space}/export/expenses.csv", params={"month": "2025-10"}, headers=alice.headers)
    assert r.status_code == 200 and r.headers["content-type"].startswith("text/csv")
    lines = r.text.strip().splitlines()
    assert lines[0] == "date,category,note,amount,currency,tags"
    assert len(lines) == 2 and lines[1].startswith("2025-10-19,Alimentation,'=HYPERLINK(1),12.50,EUR")
    assert client.get(f"/spaces/{alice.space}/export/expenses.csv", params={"month": "oops"}, headers=alice.headers).status_code == 422
