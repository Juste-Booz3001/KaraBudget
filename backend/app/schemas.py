from typing import Any, Literal

from pydantic import BaseModel, Field

EMAIL = r"^[^@\s]+@[^@\s]+\.[^@\s]+$"


class Credentials(BaseModel):
    email: str = Field(pattern=EMAIL, max_length=254)
    password: str = Field(min_length=8, max_length=128)


class RefreshIn(BaseModel):
    refresh_token: str


class TokenPair(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    personal_space_id: str
    user_id: str


class SpaceIn(BaseModel):
    name: str = Field(min_length=1, max_length=60)


class JoinIn(BaseModel):
    invite_code: str = Field(min_length=4, max_length=16)


class SpaceOut(BaseModel):
    id: str
    name: str
    invite_code: str
    is_personal: bool
    role: str


class MemberOut(BaseModel):
    user_id: str
    email: str
    role: str


class Op(BaseModel):
    op_id: str = Field(min_length=8, max_length=64)
    entity: Literal["category", "expense", "budget", "recurring", "rate", "goal", "contribution", "settlement"]
    entity_id: str = Field(min_length=8, max_length=64)
    action: Literal["upsert", "delete"]
    fields: dict[str, Any] = Field(default_factory=dict)
    ts: int = Field(ge=0)  # horodatage client (ms epoch) de l'édition


class PushIn(BaseModel):
    device_id: str = Field(min_length=1, max_length=64)
    ops: list[Op] = Field(max_length=500)


class OpResult(BaseModel):
    op_id: str
    status: Literal["applied", "duplicate", "noop", "rejected"]
    error: str | None = None


class PushOut(BaseModel):
    results: list[OpResult]
    server_rev: int


class ChangeOut(BaseModel):
    entity: str
    id: str
    rev: int
    deleted_at: int | None
    fields: dict[str, Any]
    field_ts: dict[str, int]


class PullOut(BaseModel):
    changes: list[ChangeOut]
    next_cursor: int
    has_more: bool
    server_time: int


class RoleIn(BaseModel):
    role: Literal["editor", "viewer"]


class ActivityOut(BaseModel):
    id: int
    user_id: str
    email: str
    entity: str
    entity_id: str
    action: str
    label: str
    changed: list[str]
    ts: int
