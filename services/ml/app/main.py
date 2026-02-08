from fastapi import FastAPI

from app.api.assess import router as assess_router
from app.api.chat import router as chat_router
from app.api.health import router as health_router
from app.api.pet import router as pet_router
from app.api.plan import router as plan_router
from app.api.predict import router as predict_router
from app.core.config import settings
from app.core.logging import configure_logging

configure_logging(settings.log_level)

app = FastAPI(title=settings.app_name)
app.include_router(health_router)
app.include_router(predict_router)
app.include_router(assess_router)
app.include_router(plan_router)
app.include_router(chat_router)
app.include_router(pet_router)
