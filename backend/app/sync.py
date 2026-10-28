"""Moteur de synchronisation : push idempotent + LWW par champ, pull par curseur.

Règles :
- chaque op a un op_id ; un op_id déjà traité est ignoré (réseau coupé en plein envoi)
- chaque champ porte son horodatage ; une op ne gagne que si ts > field_ts[champ]
  (égalité : la valeur déjà en base est conservée)
- le ts client est borné à now + max_clock_skew : le serveur reste l'arbitre du temps
- supprimer = poser deleted_at (LWW aussi) ; la ligne reste comme "tombstone"
- chaque changement incrémente space.rev ; pull renvoie les lignes avec rev > curseur
"""
import json
from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from .config import settings
from .models import (
    ActivityLog,
    Budget,
    Category,
    Contribution,
    Expense,
    Goal,
    Member,
    ProcessedOp,
    Rate,
    Recurring,
    Settlement,
    Space,
    User,
    now_ms,
)
from .schemas import ChangeOut, Op, OpResult, PullOut, PushOut

MODELS = {
    "category": Category,
    "expense": Expense,
    "budget": Budget,
    "recurring": Recurring,
    "rate": Rate,
    "goal": Goal,
    "contribution": Contribution,
    "settlement": Settlement,
}

# champ -> (type attendu, nullable)
FIELDS: dict[str, dict[str, tuple[type, bool]]] = {
    "category": {"name": (str, False), "color": (int, False), "icon": (str, False)},
    "expense": {
        "amount_minor": (int, False),
        "currency": (str, False),
        "category_id": (str, True),
        "note": (str, False),
        "spent_at": (int, False),
        "tags": (str, False),
        "paid_by": (str, True),
        "split_json": (str, False),
        "attachment_id": (str, True),
    },
    "budget": {
        "category_id": (str, False),
        "month": (str, False),
        "limit_minor": (int, False),
        "rollover": (int, False),
    },
    "recurring": {
        "amount_minor": (int, False),
        "currency": (str, False),
        "category_id": (str, True),
        "note": (str, False),
        "period": (str, False),
        "next_due": (int, False),
    },
    "rate": {"from_currency": (str, False), "to_currency": (str, False), "rate_ppm": (int, False)},
    "goal": {
        "name": (str, False),
        "target_minor": (int, False),
        "currency": (str, False),
        "due_at": (int, False),
        "color": (int, False),
    },
    "contribution": {
        "goal_id": (str, False),
        "amount_minor": (int, False),
        "at": (int, False),
        "note": (str, False),
    },
    "settlement": {
        "from_user": (str, False),
        "to_user": (str, False),
        "amount_minor": (int, False),
        "currency": (str, False),
        "at": (int, False),
    },
}
MAX_STR = 500
MAX_LEN = {"split_json": 4000, "tags": 300}
MAX_INT = 10**15
ALLOWED_VALUES = {"rollover": {0, 1}}


def validate_fields(entity: str, fields: dict[str, Any]) -> str | None:
    spec = FIELDS[entity]
    for key, value in fields.items():
        if key == "deleted_at":  # seule valeur permise : null = « ressusciter » (ré-ajout d'une ligne à id déterministe)
            if value is not None:
                return "field 'deleted_at' can only be null"
            continue
        if key not in spec:
            return f"unknown field '{key}'"
        typ, nullable = spec[key]
        if value is None:
            if not nullable:
                return f"field '{key}' cannot be null"
            continue
        if isinstance(value, bool) or not isinstance(value, typ):
            return f"field '{key}' must be {typ.__name__}"
        if typ is int and abs(value) > MAX_INT:
            return f"field '{key}' out of range"
        if typ is str and len(value) > MAX_LEN.get(key, MAX_STR):
            return f"field '{key}' too long"
        if key in ALLOWED_VALUES and value not in ALLOWED_VALUES[key]:
            return f"field '{key}' has an invalid value"
        if key == "rate_ppm" and value <= 0:
            return "rate_ppm must be positive"
        if key in ("from_currency", "to_currency", "currency") and value and len(value) != 3:
            return f"field '{key}' must be a 3-letter code"
    return None


def validate_members(db: Session, space: Space, entity: str, fields: dict[str, Any], cache: dict) -> str | None:
    """Les utilisateurs cités (payeur, parts, remboursement) doivent être membres de l'espace."""
    refs: list[str] = []
    if entity == "expense":
        if fields.get("paid_by"):
            refs.append(fields["paid_by"])
        raw = fields.get("split_json")
        if raw:
            try:
                data = json.loads(raw)
                mode = data["mode"]
                if mode == "equal":
                    users = data["with"]
                    if not isinstance(users, list) or not all(isinstance(u, str) for u in users):
                        return "split_json: 'with' must be a list of user ids"
                elif mode == "exact":
                    shares = data["shares"]
                    if not isinstance(shares, dict) or not all(
                        isinstance(v, int) and not isinstance(v, bool) and v >= 0 for v in shares.values()
                    ):
                        return "split_json: shares must be non-negative integers"
                    users = list(shares)
                else:
                    return "split_json: unknown mode"
            except (ValueError, KeyError, TypeError):
                return "split_json: invalid JSON"
            refs += users
    elif entity == "settlement":
        refs += [fields[k] for k in ("from_user", "to_user") if fields.get(k)]
        if fields.get("from_user") and fields.get("from_user") == fields.get("to_user"):
            return "settlement needs two different members"
    if not refs:
        return None
    if "members" not in cache:
        cache["members"] = set(db.execute(select(Member.user_id).where(Member.space_id == space.id)).scalars())
    if any(u not in cache["members"] for u in refs):
        return "unknown member"
    return None


def _log_activity(db: Session, space: Space, user: User, op: Op, row: Any, is_new: bool, now: int) -> None:
    # pas de bruit : amorçage des catégories par défaut (ts=0) et avance mécanique des récurrences
    if op.ts == 0 or (op.entity == "recurring" and set(op.fields) <= {"next_due"} and not is_new):
        return
    label = (getattr(row, "note", None) or getattr(row, "name", None) or "")[:100]
    if op.entity == "rate":
        label = f"{row.from_currency}→{row.to_currency}"
    action = "delete" if op.action == "delete" else ("create" if is_new else "update")
    changed = ",".join(sorted(op.fields))[:200] if op.action == "upsert" else ""
    db.add(
        ActivityLog(
            space_id=space.id, user_id=user.id, entity=op.entity, entity_id=op.entity_id,
            action=action, label=label, changed=changed, ts=now,
        )
    )


def apply_ops(db: Session, space: Space, user: User, ops: list[Op]) -> PushOut:
    now = now_ms()
    results: list[OpResult] = []
    cache: dict = {}
    for op in ops:
        if db.get(ProcessedOp, op.op_id) is not None:
            results.append(OpResult(op_id=op.op_id, status="duplicate"))
            continue

        error = None
        if op.action == "upsert":
            error = validate_fields(op.entity, op.fields) or validate_members(db, space, op.entity, op.fields, cache)
        if error:
            # on mémorise aussi les rejets : une op invalide ne doit pas être rejouée en boucle
            db.add(ProcessedOp(op_id=op.op_id, space_id=space.id))
            results.append(OpResult(op_id=op.op_id, status="rejected", error=error))
            continue

        model = MODELS[op.entity]
        row = db.get(model, (space.id, op.entity_id))
        is_new = row is None
        if row is None:
            row = model(space_id=space.id, id=op.entity_id, field_ts={}, created_by=user.id, created_at=now)
            db.add(row)

        ts = min(op.ts, now + settings.max_clock_skew_ms)
        field_ts = dict(row.field_ts or {})
        changed = False

        if op.action == "upsert":
            for key, value in op.fields.items():
                if ts > field_ts.get(key, -1):
                    setattr(row, key, value)  # key == "deleted_at" (valeur None) lève la suppression logique
                    field_ts[key] = ts
                    changed = True
        elif ts > field_ts.get("deleted_at", -1):
            row.deleted_at = ts
            field_ts["deleted_at"] = ts
            changed = True

        if changed:
            space.rev += 1
            row.rev = space.rev
            row.field_ts = field_ts  # nouvelle valeur => SQLAlchemy détecte la modification du JSON
            row.updated_at = now
            _log_activity(db, space, user, op, row, is_new, now)
        if is_new and not changed:
            db.expunge(row)  # op vide sur une ligne inconnue : rien à créer
        db.add(ProcessedOp(op_id=op.op_id, space_id=space.id))
        results.append(OpResult(op_id=op.op_id, status="applied" if changed else "noop"))
        db.flush()
    return PushOut(results=results, server_rev=space.rev)


def serialize(entity: str, row: Any) -> ChangeOut:
    return ChangeOut(
        entity=entity,
        id=row.id,
        rev=row.rev,
        deleted_at=row.deleted_at,
        fields={key: getattr(row, key) for key in FIELDS[entity]},
        field_ts=row.field_ts or {},
    )


def pull_changes(db: Session, space: Space, since: int, limit: int) -> PullOut:
    collected: list[tuple[int, str, Any]] = []
    for entity, model in MODELS.items():
        stmt = (
            select(model)
            .where(model.space_id == space.id, model.rev > since)
            .order_by(model.rev)
            .limit(limit + 1)
        )
        collected += [(row.rev, entity, row) for row in db.execute(stmt).scalars()]
    collected.sort(key=lambda item: item[0])
    has_more = len(collected) > limit
    page = collected[:limit]
    next_cursor = page[-1][0] if page else since
    return PullOut(
        changes=[serialize(entity, row) for _, entity, row in page],
        next_cursor=next_cursor,
        has_more=has_more,
        server_time=now_ms(),
    )
