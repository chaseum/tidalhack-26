from fastapi import FastAPI

from app.api.health import router as health_router
from app.api.predict import router as predict_router

app = FastAPI(title="ML Service")
app.include_router(health_router)
app.include_router(predict_router)
