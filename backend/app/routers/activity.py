from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..db import get_db
from ..deps import current_user, member_space
from ..models import ActivityLog, User
from ..schemas import ActivityOut

router = APIRouter(prefix="/spaces/{space_id}/activity", tags=["activity"])


@router.get("", response_model=list[ActivityOut])
def activity(
    space_id: str,
    limit: int = Query(50, ge=1, le=200),
    before: int | None = Query(None, ge=1, description="id du dernier élément déjà reçu (pagination)"),
    db: Session = Depends(get_db),
    user: User = Depends(current_user),
):
    member_space(db, user, space_id)
    stmt = (
        select(ActivityLog, User.email)
        .join(User, User.id == ActivityLog.user_id)
        .where(ActivityLog.space_id == space_id)
    )
    if before is not None:
        stmt = stmt.where(ActivityLog.id < before)
    rows = db.execute(stmt.order_by(ActivityLog.id.desc()).limit(limit)).all()
    return [
        ActivityOut(
            id=a.id, user_id=a.user_id, email=email, entity=a.entity, entity_id=a.entity_id, action=a.action,
            label=a.label, changed=[c for c in a.changed.split(",") if c], ts=a.ts,
        )
        for a, email in rows
    ]
