from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from ..db import get_db
from ..deps import current_user, member_space, writable_space
from ..models import User
from ..schemas import PullOut, PushIn, PushOut
from ..sync import apply_ops, pull_changes

router = APIRouter(prefix="/spaces/{space_id}/sync", tags=["sync"])


@router.post("/push", response_model=PushOut)
def push(space_id: str, body: PushIn, db: Session = Depends(get_db), user: User = Depends(current_user)):
    space = writable_space(db, user, space_id, lock=True)  # lecteur => 403
    result = apply_ops(db, space, user, body.ops)
    db.commit()
    return result


@router.get("/pull", response_model=PullOut)
def pull(
    space_id: str,
    since: int = Query(0, ge=0),
    limit: int = Query(200, ge=1, le=1000),
    db: Session = Depends(get_db),
    user: User = Depends(current_user),
):
    space = member_space(db, user, space_id)
    return pull_changes(db, space, since, limit)
