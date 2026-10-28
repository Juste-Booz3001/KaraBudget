import secrets

import jwt
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..config import settings
from ..db import get_db
from ..models import Member, Space, User
from ..schemas import Credentials, RefreshIn, TokenPair
from ..security import decode_token, hash_password, make_token, verify_password

router = APIRouter(prefix="/auth", tags=["auth"])


def invite_code() -> str:
    return secrets.token_hex(4).upper()


def personal_space_id(db: Session, user: User) -> str:
    stmt = select(Space.id).where(Space.owner_id == user.id, Space.is_personal.is_(True))
    return db.execute(stmt).scalar_one()


def tokens_for(db: Session, user: User) -> TokenPair:
    return TokenPair(
        access_token=make_token(user.id, "access", settings.access_minutes),
        refresh_token=make_token(user.id, "refresh", settings.refresh_days * 24 * 60),
        personal_space_id=personal_space_id(db, user),
        user_id=user.id,
    )


@router.post("/register", response_model=TokenPair, status_code=201)
def register(body: Credentials, db: Session = Depends(get_db)):
    email = body.email.strip().lower()
    user = User(email=email, password_hash=hash_password(body.password))
    db.add(user)
    try:
        db.flush()
    except IntegrityError:
        db.rollback()
        raise HTTPException(409, "Email already registered")
    space = Space(name="Personnel", invite_code=invite_code(), is_personal=True, owner_id=user.id)
    db.add(space)
    db.flush()
    db.add(Member(space_id=space.id, user_id=user.id, role="owner"))
    db.commit()
    return tokens_for(db, user)


@router.post("/login", response_model=TokenPair)
def login(body: Credentials, db: Session = Depends(get_db)):
    user = db.execute(select(User).where(User.email == body.email.strip().lower())).scalar_one_or_none()
    if user is None or not verify_password(body.password, user.password_hash):
        raise HTTPException(401, "Invalid credentials")
    return tokens_for(db, user)


@router.post("/refresh", response_model=TokenPair)
def refresh(body: RefreshIn, db: Session = Depends(get_db)):
    try:
        payload = decode_token(body.refresh_token, "refresh")
    except jwt.PyJWTError:
        raise HTTPException(401, "Invalid refresh token")
    user = db.get(User, payload["sub"])
    if user is None:
        raise HTTPException(401, "Unknown user")
    return tokens_for(db, user)
