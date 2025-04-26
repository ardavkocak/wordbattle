# app/main.py
from fastapi import FastAPI
from app.routers import auth
from app import models, database
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()
app.include_router(auth.router)
app.include_router(game.router)



app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # geliştirme aşamasında herkes erişebilsin
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Tabloları oluştur (manuel migration yerine başlangıç için kullanabiliriz)
models.Base.metadata.create_all(bind=database.engine)
app.include_router(auth.router)
