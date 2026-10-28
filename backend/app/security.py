import base64
import hashlib
import hmac
import os
import time
import uuid

import jwt

from .config import settings

_ITER = 240_000


def hash_password(password: str) -> str:
    salt = os.urandom(16)
    dk = hashlib.pbkdf2_hmac("sha256", password.encode(), salt, _ITER)
    return f"pbkdf2_sha256${_ITER}${base64.b64encode(salt).decode()}${base64.b64encode(dk).decode()}"


def verify_password(password: str, stored: str) -> bool:
    try:
        _, iters, salt, digest = stored.split("$")
        dk = hashlib.pbkdf2_hmac("sha256", password.encode(), base64.b64decode(salt), int(iters))
        return hmac.compare_digest(dk, base64.b64decode(digest))
    except (ValueError, TypeError):
        return False


def make_token(user_id: str, kind: str, minutes: int) -> str:
    now = int(time.time())
    payload = {"sub": user_id, "typ": kind, "iat": now, "exp": now + minutes * 60, "jti": str(uuid.uuid4())}
    return jwt.encode(payload, settings.secret_key, algorithm="HS256")


def decode_token(token: str, kind: str) -> dict:
    payload = jwt.decode(token, settings.secret_key, algorithms=["HS256"])
    if payload.get("typ") != kind:
        raise jwt.InvalidTokenError("wrong token type")
    return payload
