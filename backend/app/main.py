from fastapi import FastAPI

app = FastAPI(title="Gestionale Personale")

@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}