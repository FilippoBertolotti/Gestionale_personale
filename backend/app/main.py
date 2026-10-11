from fastapi import FastAPI

app = FastAPI(title="Gestionale Personale")

@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}

@app.get("/")
def home() -> dict[str, str]:
    return {"status": "ok", "message": "Welcome to the Gestionale Personale!"}