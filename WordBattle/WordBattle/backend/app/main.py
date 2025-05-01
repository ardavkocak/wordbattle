# app/main.py
from fastapi import FastAPI
from app.routers import game
from app import models, database, auth
from app.word_utils import kelime_listesini_yukle
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()
app.include_router(game.router)
app.include_router(auth.router)


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # geliştirme aşamasında herkes erişebilsin
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Tabloları oluştur (manuel migration yerine başlangıç için kullanabiliriz)
models.Base.metadata.create_all(bind=database.engine)
kelime_listesini_yukle()
