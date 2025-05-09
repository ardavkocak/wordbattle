from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from . import models, schemas
from .database import SessionLocal
from app import utils
from app.word_utils import kelime_var_mi
from app.letter_pool import LetterPool

router = APIRouter()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/register")
def register(user: schemas.UserCreate, db: Session = Depends(get_db)):
    existing = db.query(models.User).filter(models.User.username == user.username).first()
    if existing:
        raise HTTPException(status_code=400, detail="Kullanıcı adı alınmış.")
    hashed_pw = utils.hash_password(user.password)
    new_user = models.User(
    username=user.username,
    email=user.email,
    password=hashed_pw,         # BURAYA hashed password yaz
    hashed_password=hashed_pw
)
    db.add(new_user)
    db.commit()
    return {"message": "Kayıt başarılı"}

@router.post("/login")
def login(user: schemas.UserLogin, db: Session = Depends(get_db)):
    db_user = db.query(models.User).filter(models.User.username == user.username).first()
    if not db_user or not utils.verify_password(user.password, db_user.hashed_password):
        raise HTTPException(status_code=400, detail="Geçersiz bilgiler")
    token = utils.create_access_token(data={"sub": db_user.username})
    return {
    "access_token": token,
    "token_type": "bearer",
    "user_id": db_user.id  # 👈 Burası eklenecek
}

