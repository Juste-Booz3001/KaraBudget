import time
import uuid

from sqlalchemy import JSON, BigInteger, Boolean, ForeignKey, Integer, LargeBinary, String
from sqlalchemy.orm import Mapped, mapped_column

from .db import Base


def now_ms() -> int:
    return int(time.time() * 1000)


def new_id() -> str:
    return str(uuid.uuid4())


class User(Base):
    __tablename__ = "users"
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_id)
    email: Mapped[str] = mapped_column(String(254), unique=True, index=True)
    password_hash: Mapped[str] = mapped_column(String(300))
    created_at: Mapped[int] = mapped_column(BigInteger, default=now_ms)


class Space(Base):
    """Espace de budget : un par utilisateur (personnel) + des espaces partagés (couple, coloc)."""

    __tablename__ = "spaces"
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_id)
    name: Mapped[str] = mapped_column(String(60))
    invite_code: Mapped[str] = mapped_column(String(16), unique=True, index=True)
    is_personal: Mapped[bool] = mapped_column(Boolean, default=False)
    owner_id: Mapped[str] = mapped_column(ForeignKey("users.id"))
    rev: Mapped[int] = mapped_column(Integer, default=0)  # curseur de sync, +1 à chaque changement
    created_at: Mapped[int] = mapped_column(BigInteger, default=now_ms)


class Member(Base):
    __tablename__ = "members"
    space_id: Mapped[str] = mapped_column(ForeignKey("spaces.id"), primary_key=True)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id"), primary_key=True)
    # owner | editor | viewer  ("member" = ancien nom de editor, toujours accepté)
    role: Mapped[str] = mapped_column(String(10), default="editor")


WRITE_ROLES = {"owner", "editor", "member"}


def can_write(role: str) -> bool:
    return role in WRITE_ROLES


class ProcessedOp(Base):
    """Journal d'idempotence : un op_id déjà vu n'est jamais rejoué."""

    __tablename__ = "processed_ops"
    op_id: Mapped[str] = mapped_column(String(64), primary_key=True)
    space_id: Mapped[str] = mapped_column(String(36), index=True)
    created_at: Mapped[int] = mapped_column(BigInteger, default=now_ms)


class SyncMixin:
    # Clé composite (space_id, id) : deux espaces peuvent partager le même UUID (catégories par défaut).
    space_id: Mapped[str] = mapped_column(String(36), primary_key=True)
    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    rev: Mapped[int] = mapped_column(Integer, index=True, default=0)
    field_ts: Mapped[dict] = mapped_column(JSON, default=dict)  # horodatage LWW par champ
    deleted_at: Mapped[int | None] = mapped_column(BigInteger, nullable=True)  # suppression logique
    created_by: Mapped[str] = mapped_column(String(36), default="")
    created_at: Mapped[int] = mapped_column(BigInteger, default=now_ms)
    updated_at: Mapped[int] = mapped_column(BigInteger, default=now_ms)


class Category(SyncMixin, Base):
    __tablename__ = "categories"
    name: Mapped[str] = mapped_column(String(80), default="")
    color: Mapped[int] = mapped_column(BigInteger, default=0xFF607D8B)
    icon: Mapped[str] = mapped_column(String(40), default="label")


class Expense(SyncMixin, Base):
    __tablename__ = "expenses"
    amount_minor: Mapped[int] = mapped_column(BigInteger, default=0)  # entier, jamais de float
    currency: Mapped[str] = mapped_column(String(3), default="USD")
    category_id: Mapped[str | None] = mapped_column(String(64), nullable=True)
    note: Mapped[str] = mapped_column(String(500), default="")
    spent_at: Mapped[int] = mapped_column(BigInteger, default=0, index=True)
    tags: Mapped[str] = mapped_column(String(300), default="")  # "courses,resto" (minuscules, séparées par des virgules)
    paid_by: Mapped[str | None] = mapped_column(String(36), nullable=True)  # user_id du payeur (partage)
    split_json: Mapped[str] = mapped_column(String(4000), default="")  # {"mode":"equal","with":[ids]} | {"mode":"exact","shares":{id:minor}}
    attachment_id: Mapped[str | None] = mapped_column(String(64), nullable=True)  # photo du reçu


class Budget(SyncMixin, Base):
    __tablename__ = "budgets"
    category_id: Mapped[str] = mapped_column(String(64), default="")
    month: Mapped[str] = mapped_column(String(7), default="")  # "2026-10"
    limit_minor: Mapped[int] = mapped_column(BigInteger, default=0)
    rollover: Mapped[int] = mapped_column(Integer, default=0)  # 1 = reporte le reste/dépassement du mois précédent


class Recurring(SyncMixin, Base):
    __tablename__ = "recurrings"
    amount_minor: Mapped[int] = mapped_column(BigInteger, default=0)
    currency: Mapped[str] = mapped_column(String(3), default="USD")
    category_id: Mapped[str | None] = mapped_column(String(64), nullable=True)
    note: Mapped[str] = mapped_column(String(500), default="")
    period: Mapped[str] = mapped_column(String(10), default="monthly")
    next_due: Mapped[int] = mapped_column(BigInteger, default=0)


class Rate(SyncMixin, Base):
    """Taux de change saisi à la main : 1 unité de from_currency = rate_ppm / 1_000_000 unités de to_currency."""

    __tablename__ = "rates"
    from_currency: Mapped[str] = mapped_column(String(3), default="")
    to_currency: Mapped[str] = mapped_column(String(3), default="")
    rate_ppm: Mapped[int] = mapped_column(BigInteger, default=1_000_000)


class Goal(SyncMixin, Base):
    __tablename__ = "goals"
    name: Mapped[str] = mapped_column(String(80), default="")
    target_minor: Mapped[int] = mapped_column(BigInteger, default=0)
    currency: Mapped[str] = mapped_column(String(3), default="USD")
    due_at: Mapped[int] = mapped_column(BigInteger, default=0)  # 0 = pas de date cible
    color: Mapped[int] = mapped_column(BigInteger, default=0xFF009688)


class Contribution(SyncMixin, Base):
    """Versement vers un objectif. Une ligne par versement (et non un total) : deux appareils qui
    épargnent en même temps ne s'écrasent pas (le solde = somme des versements)."""

    __tablename__ = "contributions"
    goal_id: Mapped[str] = mapped_column(String(64), default="")
    amount_minor: Mapped[int] = mapped_column(BigInteger, default=0)  # négatif = retrait
    at: Mapped[int] = mapped_column(BigInteger, default=0)
    note: Mapped[str] = mapped_column(String(500), default="")


class Settlement(SyncMixin, Base):
    """Remboursement entre deux membres (solde d'un partage de dépenses)."""

    __tablename__ = "settlements"
    from_user: Mapped[str] = mapped_column(String(36), default="")
    to_user: Mapped[str] = mapped_column(String(36), default="")
    amount_minor: Mapped[int] = mapped_column(BigInteger, default=0)
    currency: Mapped[str] = mapped_column(String(3), default="USD")
    at: Mapped[int] = mapped_column(BigInteger, default=0)


class ActivityLog(Base):
    """Journal d'activité d'un espace : qui a changé quoi, et quand (écrit par le serveur)."""

    __tablename__ = "activity_log"
    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    space_id: Mapped[str] = mapped_column(String(36), index=True)
    user_id: Mapped[str] = mapped_column(String(36))
    entity: Mapped[str] = mapped_column(String(20))
    entity_id: Mapped[str] = mapped_column(String(64))
    action: Mapped[str] = mapped_column(String(10))  # create | update | delete
    label: Mapped[str] = mapped_column(String(100), default="")
    changed: Mapped[str] = mapped_column(String(200), default="")  # noms des champs modifiés
    ts: Mapped[int] = mapped_column(BigInteger, default=now_ms)


class Attachment(Base):
    """Pièce jointe (photo de reçu) liée à une dépense via expense.attachment_id."""

    __tablename__ = "attachments"
    space_id: Mapped[str] = mapped_column(String(36), primary_key=True)
    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    content_type: Mapped[str] = mapped_column(String(40))
    data: Mapped[bytes] = mapped_column(LargeBinary)
    created_by: Mapped[str] = mapped_column(String(36), default="")
    created_at: Mapped[int] = mapped_column(BigInteger, default=now_ms)
