import jwt
from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.orm import Session

from .db import get_db
from .models import Member, Space, User, can_write
from .security import decode_token

bearer = HTTPBearer(auto_error=False)


def current_user(
    creds: HTTPAuthorizationCredentials | None = Depends(bearer), db: Session = Depends(get_db)
) -> User:
    if creds is None:
        raise HTTPException(401, "Not authenticated")
    try:
        payload = decode_token(creds.credentials, "access")
    except jwt.PyJWTError:
        raise HTTPException(401, "Invalid or expired token")
    user = db.get(User, payload["sub"])
    if user is None:
        raise HTTPException(401, "Unknown user")
    return user


def member_space(db: Session, user: User, space_id: str, lock: bool = False) -> Space:
    stmt = (
        select(Space)
        .join(Member, Member.space_id == Space.id)
        .where(Space.id == space_id, Member.user_id == user.id)
    )
    if lock:
        stmt = stmt.with_for_update()  # sérialise les push concurrents sur un même espace (Postgres)
    space = db.execute(stmt).scalar_one_or_none()
    if space is None:
        raise HTTPException(404, "Space not found")  # 404 et non 403 : on ne révèle pas l'existence
    return space


def member_space_role(db: Session, user: User, space_id: str, lock: bool = False) -> tuple[Space, str]:
    space = member_space(db, user, space_id, lock=lock)
    role = db.get(Member, (space.id, user.id)).role
    return space, role


def writable_space(db: Session, user: User, space_id: str, lock: bool = False) -> Space:
    """Espace dans lequel l'utilisateur peut écrire (owner/editor). Lecteur => 403."""
    space, role = member_space_role(db, user, space_id, lock=lock)
    if not can_write(role):
        raise HTTPException(403, "Read-only access")
    return space
