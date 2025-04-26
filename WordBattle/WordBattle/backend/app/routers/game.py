# backend/app/routers/game.py

from fastapi import APIRouter, Depends, HTTPException, Request, Query
from sqlalchemy.orm import Session
from app import models, database

router = APIRouter(
    prefix="/game",
    tags=["Game"]
)

def get_db():
    db = database.SessionLocal()
    try:
        yield db
    finally:
        db.close()


@router.post("/create")
async def create_game(request: Request, user_id: int = Query(...), db: Session = Depends(get_db)):
    print(f"✅ Yeni oyun oluşturma isteği geldi. Kullanıcı ID: {user_id}")
    body = await request.json()
    print(f"📦 Gelen body verisi: {body}")
    """Yeni bir oyun başlatır (status = waiting) ve seçilen süreyi kaydeder."""
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı.")

    body = await request.json()
    duration = body.get("duration")
    if not duration:
        raise HTTPException(status_code=400, detail="Süre bilgisi eksik.")

    new_game = models.Game(
        player1_id=user_id,
        player2_id=None,
        status="active",
        duration=duration  # ⬅ Burada süreyi kaydediyoruz
    )
    db.add(new_game)
    db.commit()
    db.refresh(new_game)

    return {"message": "Oyun oluşturuldu.", "game_id": new_game.id}

@router.get("/active")
async def list_active_games(user_id: int, db: Session = Depends(get_db)):
    """Kullanıcının aktif (devam eden) oyunlarını listeler."""
    active_games = db.query(models.Game).filter(
        ((models.Game.player1_id == user_id) | (models.Game.player2_id == user_id)) &
        (models.Game.status == "active")
    ).all()
    return active_games

@router.get("/finished")
async def list_finished_games(user_id: int, db: Session = Depends(get_db)):
    """Kullanıcının biten (tamamlanan) oyunlarını listeler."""
    finished_games = db.query(models.Game).filter(
        ((models.Game.player1_id == user_id) | (models.Game.player2_id == user_id)) &
        (models.Game.status == "finished")
    ).all()
    return finished_games



@router.post("/finish")
async def finish_game(game_id: int, db: Session = Depends(get_db)):
    """Bir oyunun durumunu 'finished' yapar."""
    game = db.query(models.Game).filter(models.Game.id == game_id).first()
    if not game:
        raise HTTPException(status_code=404, detail="Oyun bulunamadı.")

    if game.status != "active":
        raise HTTPException(status_code=400, detail="Sadece aktif bir oyun bitirilebilir.")

    game.status = "finished"
    db.commit()
    db.refresh(game)

    return {"message": "Oyun başarıyla bitirildi.", "game_id": game.id}
