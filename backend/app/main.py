from fastapi import FastAPI
from app.api.v1.router import api_router

app = FastAPI(title="Gestionale Personale", version="0.0.1")

@app.get("/")
def home() -> dict[str, str]:
    return {"status": "ok", "message": "Welcome to the Gestionale Personale!"}

app.include_router(api_router, prefix="/api/v1")