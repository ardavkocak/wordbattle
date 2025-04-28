from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# 👉 Burada database URL'ini SQLite'a göre ayarlıyoruz
SQLALCHEMY_DATABASE_URL = "sqlite:///./wordbattle.db"

# Eğer db dosyası başka yerdeyse ona göre ./ yerine ../backend/wordbattle.db gibi ayarlanır

engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()
