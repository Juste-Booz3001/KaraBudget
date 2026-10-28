from sqlalchemy import create_engine, inspect, text
from sqlalchemy.orm import DeclarativeBase, sessionmaker
from sqlalchemy.pool import StaticPool

from .config import settings


def make_engine(url: str):
    kwargs: dict = {}
    if url.startswith("sqlite"):
        kwargs["connect_args"] = {"check_same_thread": False}
        if url in ("sqlite://", "sqlite:///:memory:"):
            kwargs["poolclass"] = StaticPool
    return create_engine(url, **kwargs)


engine = make_engine(settings.database_url)
SessionLocal = sessionmaker(engine, autoflush=False, expire_on_commit=False)


class Base(DeclarativeBase):
    pass


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# Colonnes ajoutées après la v1 : create_all() ne modifie pas une table existante, on les ajoute ici.
# (À remplacer par de vraies migrations Alembic en production.)
ADDED_COLUMNS: list[tuple[str, str, str]] = [
    ("expenses", "tags", "VARCHAR(300) NOT NULL DEFAULT ''"),
    ("expenses", "paid_by", "VARCHAR(36)"),
    ("expenses", "split_json", "VARCHAR(4000) NOT NULL DEFAULT ''"),
    ("expenses", "attachment_id", "VARCHAR(64)"),
    ("budgets", "rollover", "INTEGER NOT NULL DEFAULT 0"),
]


def upgrade_schema(engine) -> None:
    """Crée les tables manquantes puis ajoute les colonnes manquantes des tables existantes."""
    Base.metadata.create_all(engine)
    insp = inspect(engine)
    with engine.begin() as conn:
        for table, column, ddl in ADDED_COLUMNS:
            if table in insp.get_table_names() and column not in {c["name"] for c in insp.get_columns(table)}:
                conn.execute(text(f"ALTER TABLE {table} ADD COLUMN {column} {ddl}"))
