import csv
import io
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, Response
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..db import get_db
from ..deps import current_user, member_space
from ..models import Category, Expense, User

router = APIRouter(prefix="/spaces/{space_id}/export", tags=["export"])

ZERO_DECIMALS = {"JPY", "KRW", "MGA", "XOF"}


def plain_amount(minor: int, currency: str) -> str:
    decimals = 0 if currency in ZERO_DECIMALS else 2
    sign = "-" if minor < 0 else ""
    whole, frac = divmod(abs(minor), 10**decimals)
    return f"{sign}{whole}" + (f".{frac:0{decimals}d}" if decimals else "")


def safe_cell(text: str) -> str:
    # protège contre l'injection de formules à l'ouverture dans Excel/Sheets
    return "'" + text if text[:1] in ("=", "+", "-", "@") else text


def month_range(month: str) -> tuple[int, int]:
    try:
        start = datetime.strptime(month, "%Y-%m").replace(tzinfo=timezone.utc)
    except ValueError:
        raise HTTPException(422, "month must be YYYY-MM")
    end = start.replace(year=start.year + (start.month == 12), month=start.month % 12 + 1)
    return int(start.timestamp() * 1000), int(end.timestamp() * 1000)


@router.get("/expenses.csv")
def expenses_csv(
    space_id: str,
    month: str | None = Query(None, description="YYYY-MM (UTC)"),
    db: Session = Depends(get_db),
    user: User = Depends(current_user),
):
    member_space(db, user, space_id)
    stmt = select(Expense).where(Expense.space_id == space_id, Expense.deleted_at.is_(None))
    if month:
        lo, hi = month_range(month)
        stmt = stmt.where(Expense.spent_at >= lo, Expense.spent_at < hi)
    expenses = db.execute(stmt.order_by(Expense.spent_at)).scalars().all()
    names = {
        c.id: c.name
        for c in db.execute(select(Category).where(Category.space_id == space_id)).scalars()
    }
    out = io.StringIO()
    writer = csv.writer(out)
    writer.writerow(["date", "category", "note", "amount", "currency", "tags"])
    for e in expenses:
        day = datetime.fromtimestamp(e.spent_at / 1000, tz=timezone.utc).strftime("%Y-%m-%d")
        writer.writerow(
            [day, safe_cell(names.get(e.category_id or "", "")), safe_cell(e.note), plain_amount(e.amount_minor, e.currency), e.currency, safe_cell(e.tags)]
        )
    return Response(
        out.getvalue(),
        media_type="text/csv; charset=utf-8",
        headers={"Content-Disposition": 'attachment; filename="expenses.csv"'},
    )
