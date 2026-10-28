from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..db import get_db
from ..deps import current_user, member_space
from ..models import Member, Space, User
from ..schemas import JoinIn, MemberOut, RoleIn, SpaceIn, SpaceOut
from .auth import invite_code

router = APIRouter(prefix="/spaces", tags=["spaces"])


def to_out(space: Space, role: str) -> SpaceOut:
    return SpaceOut(
        id=space.id, name=space.name, invite_code=space.invite_code, is_personal=space.is_personal, role=role
    )


@router.get("", response_model=list[SpaceOut])
def list_spaces(db: Session = Depends(get_db), user: User = Depends(current_user)):
    rows = db.execute(
        select(Space, Member.role).join(Member, Member.space_id == Space.id).where(Member.user_id == user.id)
    ).all()
    return [to_out(space, role) for space, role in rows]


@router.post("", response_model=SpaceOut, status_code=201)
def create_space(body: SpaceIn, db: Session = Depends(get_db), user: User = Depends(current_user)):
    space = Space(name=body.name.strip(), invite_code=invite_code(), is_personal=False, owner_id=user.id)
    db.add(space)
    db.flush()
    db.add(Member(space_id=space.id, user_id=user.id, role="owner"))
    db.commit()
    return to_out(space, "owner")


@router.post("/join", response_model=SpaceOut)
def join_space(body: JoinIn, db: Session = Depends(get_db), user: User = Depends(current_user)):
    space = db.execute(
        select(Space).where(Space.invite_code == body.invite_code.strip().upper(), Space.is_personal.is_(False))
    ).scalar_one_or_none()
    if space is None:
        raise HTTPException(404, "Invalid invite code")
    member = db.get(Member, (space.id, user.id))
    if member is None:
        member = Member(space_id=space.id, user_id=user.id, role="editor")
        db.add(member)
        db.commit()
    return to_out(space, member.role)


@router.get("/{space_id}/members", response_model=list[MemberOut])
def members(space_id: str, db: Session = Depends(get_db), user: User = Depends(current_user)):
    member_space(db, user, space_id)
    rows = db.execute(
        select(Member.user_id, User.email, Member.role)
        .join(User, User.id == Member.user_id)
        .where(Member.space_id == space_id)
    ).all()
    return [MemberOut(user_id=u, email=e, role=r) for u, e, r in rows]


@router.delete("/{space_id}/membership", status_code=204)
def leave(space_id: str, db: Session = Depends(get_db), user: User = Depends(current_user)):
    space = member_space(db, user, space_id)
    if space.is_personal or space.owner_id == user.id:
        raise HTTPException(400, "Owner or personal space cannot be left")
    db.delete(db.get(Member, (space.id, user.id)))
    db.commit()


def _owned_shared_space(db: Session, user: User, space_id: str) -> Space:
    space = member_space(db, user, space_id)
    if space.is_personal:
        raise HTTPException(400, "Personal space has no members")
    if space.owner_id != user.id:
        raise HTTPException(403, "Only the owner can do this")
    return space


@router.patch("/{space_id}/members/{user_id}", response_model=MemberOut)
def set_role(
    space_id: str, user_id: str, body: RoleIn, db: Session = Depends(get_db), user: User = Depends(current_user)
):
    space = _owned_shared_space(db, user, space_id)
    member = db.get(Member, (space.id, user_id))
    if member is None:
        raise HTTPException(404, "Member not found")
    if user_id == space.owner_id:
        raise HTTPException(400, "The owner's role cannot be changed")
    member.role = body.role
    db.commit()
    email = db.get(User, user_id).email
    return MemberOut(user_id=user_id, email=email, role=member.role)


@router.delete("/{space_id}/members/{user_id}", status_code=204)
def remove_member(space_id: str, user_id: str, db: Session = Depends(get_db), user: User = Depends(current_user)):
    space = _owned_shared_space(db, user, space_id)
    if user_id == space.owner_id:
        raise HTTPException(400, "The owner cannot be removed")
    member = db.get(Member, (space.id, user_id))
    if member is None:
        raise HTTPException(404, "Member not found")
    db.delete(member)
    db.commit()


@router.post("/{space_id}/invite/rotate", response_model=SpaceOut)
def rotate_invite(space_id: str, db: Session = Depends(get_db), user: User = Depends(current_user)):
    """Nouveau code d'invitation : un membre retiré ne peut plus rejoindre avec l'ancien."""
    space = _owned_shared_space(db, user, space_id)
    space.invite_code = invite_code()
    db.commit()
    return to_out(space, "owner")


@router.delete("/{space_id}/membership", status_code=204)
def leave_space(space_id: str, db: Session = Depends(get_db), user: User = Depends(current_user)):
    """Un membre quitte l'espace (le propriétaire ne peut pas : il doit supprimer ou transférer l'espace)."""
    space = member_space(db, user, space_id)
    if space.is_personal:
        raise HTTPException(400, "Cannot leave a personal space")
    if space.owner_id == user.id:
        raise HTTPException(400, "The owner cannot leave the space")
    db.delete(db.get(Member, (space.id, user.id)))
    db.commit()
