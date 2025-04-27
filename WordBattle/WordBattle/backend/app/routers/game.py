# backend/app/routers/game.py

from fastapi import APIRouter, Depends, HTTPException, Request, Query, Body
from sqlalchemy.orm import Session
from app import models, database
import json
from typing import List

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
    """
    Kullanıcı oyun başlatmak istedi:
    - Aynı süreli waiting oyun varsa eşleşir.
    - Yoksa yeni bir waiting oyun oluşturulur.
    """
    print(f"✅ Yeni oyun başlatma isteği geldi. Kullanıcı ID: {user_id}")
    body = await request.json()
    print(f"📦 Gelen body verisi: {body}")

    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı.")

    duration = body.get("duration")
    if not duration:
        raise HTTPException(status_code=400, detail="Süre bilgisi eksik.")

    # 1. Önce aynı sürede waiting oyun var mı kontrol et
    waiting_game = db.query(models.Game).filter(
        (models.Game.status == "waiting") &
        (models.Game.duration == duration) &
        (models.Game.player1_id != user_id)  # Kendisiyle eşleşmesin
    ).first()

    if waiting_game:
        # Eğer bekleyen bir oyun varsa, eşleş
        waiting_game.player2_id = user_id
        waiting_game.status = "active"
        waiting_game.turn_user_id = waiting_game.player1_id  # 🛠️ İLK SIRA player1'da başlasın
        db.commit()
        db.refresh(waiting_game)
        print(f"✅ Eşleşme yapıldı! Oyun ID: {waiting_game.id}")
        return {
            "message": "Eşleşme bulundu! Oyun başladı.",
            "game_id": waiting_game.id,
            "player1_id": waiting_game.player1_id,
            "player2_id": waiting_game.player2_id
        }
    else:
        # Eğer bekleyen oyun yoksa yeni bir waiting oyun oluştur
        new_game = models.Game(
            player1_id=user_id,
            player2_id=None,
            status="waiting",
            duration=duration,
            turn_user_id=user_id  # 🛠️ Oyun başlatan kişi ilk başlar
        )
        db.add(new_game)
        db.commit()
        db.refresh(new_game)
        print(f"⏳ Beklemeye alındı. Yeni oyun ID: {new_game.id}")
        return {
            "message": "Başka bir oyuncu bekleniyor...",
            "game_id": new_game.id
        }


@router.get("/status")
async def get_game_status(game_id: int, db: Session = Depends(get_db)):
    """Belirtilen oyun ID için oyun durumunu döner."""
    game = db.query(models.Game).filter(models.Game.id == game_id).first()
    if not game:
        raise HTTPException(status_code=404, detail="Oyun bulunamadı.")
    
    return {"status": game.status}




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




@router.post("/update_board")
async def update_board(
    payload: dict = Body(...),
    db: Session = Depends(get_db)
):
    """
    Bir oyunun board_state'ini günceller.
    Flutter body olarak { "game_id": X, "board": [...] } gönderiyor.
    """
    game_id = payload.get("game_id")
    board = payload.get("board")

    if game_id is None or board is None:
        raise HTTPException(status_code=400, detail="Eksik bilgi gönderildi.")

    game = db.query(models.Game).filter(models.Game.id == game_id).first()

    if not game:
        raise HTTPException(status_code=404, detail="Oyun bulunamadı.")

    # Board'u JSON string'e çevirip kaydediyoruz
    import json
    game.board_state = json.dumps(board)
    db.commit()

    return {"message": "Tahta başarıyla güncellendi."}




# 🔥 OYUN TAHTASINI GETİREN API
@router.get("/get_board")
async def get_board(game_id: int, db: Session = Depends(get_db)):
    """
    Belirtilen game_id'ye sahip oyunun tahtasını döner.
    Eğer board_state yoksa boş döner.
    """
    game = db.query(models.Game).filter(models.Game.id == game_id).first()
    if not game:
        raise HTTPException(status_code=404, detail="Oyun bulunamadı.")

    if not game.board_state:
        return {"board": None}

    try:
        board = json.loads(game.board_state)
    except json.JSONDecodeError:
        raise HTTPException(status_code=500, detail="Tahta verisi bozuk.")

    return {"board": board}







@router.post("/make_move")
async def make_move(request: Request, game_id: int = Query(...), db: Session = Depends(get_db)):
    data = await request.json()
    board_state = data.get("board_state")

    if board_state is None:
        raise HTTPException(status_code=400, detail="Tahta bilgisi eksik.")

    game = db.query(models.Game).filter(models.Game.id == game_id).first()
    if not game:
        raise HTTPException(status_code=404, detail="Oyun bulunamadı.")

    # Tahta kaydediliyor
    game.board_state = json.dumps(board_state)

    # Sıra değiştirme
    if game.turn_user_id == game.player1_id:
        game.turn_user_id = game.player2_id
    else:
        game.turn_user_id = game.player1_id

    db.commit()
    db.refresh(game)

    return {
        "message": "Hamle yapıldı ve sıra değiştirildi.",
        "turn_user_id": game.turn_user_id
    }
    
    
    
    
@router.get("/turn")
async def get_turn(game_id: int, db: Session = Depends(get_db)):
    """
    Belirtilen game_id'ye sahip oyunun şu anda hangi oyuncunun sırası olduğunu döner.
    """
    game = db.query(models.Game).filter(models.Game.id == game_id).first()

    if not game:
        raise HTTPException(status_code=404, detail="Oyun bulunamadı.")

    if not game.turn_user_id:
        raise HTTPException(status_code=400, detail="Oyun henüz başlamadı ya da sırası atanmadı.")

    return {"turn_user_id": game.turn_user_id}



@router.post("/change_turn")
async def change_turn(payload: dict = Body(...), db: Session = Depends(get_db)):
    """
    turn_user_id bilgisini değiştirir (player1 <-> player2).
    """
    game_id = payload.get("game_id")
    if not game_id:
        raise HTTPException(status_code=400, detail="Eksik game_id gönderildi.")

    game = db.query(models.Game).filter(models.Game.id == game_id).first()

    if not game:
        raise HTTPException(status_code=404, detail="Oyun bulunamadı.")

    # Şu an kimdeyse, diğer oyuncuya geç
    if game.turn_user_id == game.player1_id:
        game.turn_user_id = game.player2_id
    else:
        game.turn_user_id = game.player1_id

    db.commit()
    db.refresh(game)

    return {"message": "Sıra değiştirildi.", "turn_user_id": game.turn_user_id}
