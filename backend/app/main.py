from contextlib import asynccontextmanager

from fastapi import FastAPI

from .db import engine, upgrade_schema
from .routers import activity, attachments, auth, export, spaces, sync


@asynccontextmanager
async def lifespan(_: FastAPI):
    upgrade_schema(engine)  # prod : remplacer par des migrations Alembic
    yield


app = FastAPI(title="KaraBudget API", version="2.0.0", lifespan=lifespan)
app.include_router(auth.router)
app.include_router(spaces.router)
app.include_router(sync.router)
app.include_router(export.router)
app.include_router(activity.router)
app.include_router(attachments.router)


@app.get("/health", tags=["meta"])
def health():
    return {"status": "ok"}
