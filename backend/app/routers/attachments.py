import re

from fastapi import APIRouter, Depends, HTTPException, Request, Response
from sqlalchemy.orm import Session

from ..config import settings
from ..db import get_db
from ..deps import current_user, member_space, writable_space
from ..models import Attachment, User

router = APIRouter(prefix="/spaces/{space_id}/attachments", tags=["attachments"])

ALLOWED_TYPES = {"image/jpeg", "image/png", "image/webp", "application/pdf"}
ID_RE = re.compile(r"^[A-Za-z0-9-]{8,64}$")


def _check_id(att_id: str) -> None:
    if not ID_RE.match(att_id):
        raise HTTPException(422, "Invalid attachment id")


@router.put("/{att_id}", status_code=201)
async def upload(
    space_id: str,
    att_id: str,
    request: Request,
    db: Session = Depends(get_db),
    user: User = Depends(current_user),
):
    """Corps = octets bruts de l'image. Idempotent : un id déjà présent n'est pas écrasé."""
    _check_id(att_id)
    writable_space(db, user, space_id)
    ctype = (request.headers.get("content-type") or "").split(";")[0].strip().lower()
    if ctype not in ALLOWED_TYPES:
        raise HTTPException(415, "Unsupported content type")
    declared = request.headers.get("content-length")
    if declared and declared.isdigit() and int(declared) > settings.max_attachment_bytes:
        raise HTTPException(413, "File too large")
    data = await request.body()
    if not data or len(data) > settings.max_attachment_bytes:
        raise HTTPException(413 if data else 422, "File too large" if data else "Empty body")
    if db.get(Attachment, (space_id, att_id)) is None:
        db.add(Attachment(space_id=space_id, id=att_id, content_type=ctype, data=data, created_by=user.id))
        db.commit()
    return {"id": att_id, "size": len(data)}


@router.get("/{att_id}")
def download(space_id: str, att_id: str, db: Session = Depends(get_db), user: User = Depends(current_user)):
    _check_id(att_id)
    member_space(db, user, space_id)
    att = db.get(Attachment, (space_id, att_id))
    if att is None:
        raise HTTPException(404, "Attachment not found")
    return Response(
        att.data,
        media_type=att.content_type,
        headers={"Cache-Control": "private, max-age=31536000, immutable"},
    )
