# app/main.py
from fastapi import FastAPI
from app.routers import auth
from app import models, database

app = FastAPI()
app.include_router(auth.router)


# Tabloları oluştur (manuel migration yerine başlangıç için kullanabiliriz)
models.Base.metadata.create_all(bind=database.engine)
app.include_router(auth.router)
