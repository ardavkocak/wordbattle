# backend/app/routers/game.py

from datetime import datetime
from app.word_utils import kelime_var_mi
from fastapi import APIRouter, Depends, HTTPException, Request, Query, Body
from sqlalchemy.orm import Session
from app import models, database
import json
from app.services.game_manager import game_manager
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from app.services.game_services import calculate_score, apply_mine_and_reward_effects, assign_mines_and_rewards


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

    # 🎯 Süre eşlemesi (saniye cinsinden)
    duration_map = {
        "2m": 120,
        "5m": 300,
        "12h": 43200,
        "24h": 86400
    }
    base_time = duration_map.get(duration)
    if not base_time:
        raise HTTPException(status_code=400, detail="Geçersiz süre değeri.")

    now = datetime.utcnow()

    # 1. Önce aynı sürede waiting oyun var mı kontrol et
    waiting_game = db.query(models.Game).filter(
        (models.Game.status == "waiting") &
        (models.Game.duration == duration) &
        (models.Game.player1_id != user_id)  # Kendisiyle eşleşmesin
    ).first()

    if waiting_game:
        # Eşleşme sağla
        waiting_game.player2_id = user_id
        waiting_game.status = "active"
        waiting_game.turn_user_id = waiting_game.player1_id
        waiting_game.player1_time_left = base_time
        waiting_game.player2_time_left = base_time
        waiting_game.last_move_time = now

        db.commit()
        db.refresh(waiting_game)

        # ⛏️ Mayın ve ödül dağılımı buraya eklendi
        assign_mines_and_rewards(db, waiting_game.id)

        print(f"✅ Eşleşme yapıldı! Oyun ID: {waiting_game.id}")
        return {
            "message": "Eşleşme bulundu! Oyun başladı.",
            "game_id": waiting_game.id,
            "player1_id": waiting_game.player1_id,
            "player2_id": waiting_game.player2_id
        }

    else:
        # Yeni waiting oyun oluştur
        new_game = models.Game(
            player1_id=user_id,
            player2_id=None,
            status="waiting",
            duration=duration,
            turn_user_id=user_id,
            player1_time_left=base_time,
            player2_time_left=base_time,
            last_move_time=now
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




# app/routers/game.py

@router.post("/make_move")
async def make_move(
    request: Request,
    game_id: int = Query(...),
    user_id: int = Query(...),
    db: Session = Depends(get_db)
):
    data = await request.json()
    board_state = data.get("board_state")
    placed_tiles = data.get("placed_tiles", [])

    if board_state is None:
        raise HTTPException(status_code=400, detail="Tahta bilgisi eksik.")

    game = db.query(models.Game).filter(models.Game.id == game_id).first()
    if not game:
        raise HTTPException(status_code=404, detail="Oyun bulunamadı.")

    # 🔍 Çarpanlar iptal edilmiş mi kontrol et
    ignore_multipliers = False
    for tile in placed_tiles:
        row, col = tile["row"], tile["col"]
        mine = db.query(models.GameMine).filter_by(game_id=game.id, row=row, col=col).first()
        if mine and mine.type == "cancel_multipliers":
            ignore_multipliers = True
            break

    # 🧮 Skoru hesapla
    base_score = calculate_score(board_state, placed_tiles, ignore_multipliers=ignore_multipliers)

    # 💣 Mayın ve 🎁 Ödül etkilerini uygula
    final_score, triggered_mines, triggered_rewards, _ = apply_mine_and_reward_effects(
        db=db,
        game=game,
        placed_tiles=placed_tiles,
        base_score=base_score
    )

    # 📝 Skoru oyuncuya yaz
    if game.turn_user_id == game.player1_id:
        game.player1_score += final_score
    else:
        game.player2_score += final_score

    # ♻️ Tahtayı ve sırayı güncelle
    game.board_state = json.dumps(board_state)
    game.turn_user_id = game.player2_id if game.turn_user_id == game.player1_id else game.player1_id

    db.commit()
    db.refresh(game)

    # 👤 Skorları kullanıcıya göre dön
    your_score = game.player1_score if user_id == game.player1_id else game.player2_score
    opponent_score = game.player2_score if user_id == game.player1_id else game.player1_score

    return {
        "message": "Hamle yapıldı.",
        "score": final_score,
        "your_score": your_score,
        "opponent_score": opponent_score,
        "turn_user_id": game.turn_user_id,
        "triggered_mines": triggered_mines,
        "triggered_rewards": triggered_rewards,
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
    game_id = payload.get("game_id")
    if not game_id:
        raise HTTPException(status_code=400, detail="Eksik game_id gönderildi.")

    game = db.query(models.Game).filter(models.Game.id == game_id).first()
    if not game:
        raise HTTPException(status_code=404, detail="Oyun bulunamadı.")

    now = datetime.utcnow()
    
    # Süre azalt
    if game.last_move_time:
        elapsed = (now - game.last_move_time).total_seconds()

        if game.turn_user_id == game.player1_id:
            game.player1_time_left -= elapsed
        elif game.turn_user_id == game.player2_id:
            game.player2_time_left -= elapsed

    # Sıra değiştir
    game.turn_user_id = (
        game.player2_id if game.turn_user_id == game.player1_id else game.player1_id
    )
    game.last_move_time = now
    db.commit()

    return {
        "message": "Sıra değiştirildi.",
        "turn_user_id": game.turn_user_id,
        "p1_time_left": game.player1_time_left,
        "p2_time_left": game.player2_time_left
    }



@router.get("/time-status")
def get_time_status(game_id: int, db: Session = Depends(get_db)):
    game = db.query(models.Game).filter(models.Game.id == game_id).first()
    if not game:
        raise HTTPException(status_code=404, detail="Oyun bulunamadı.")

    now = datetime.utcnow()
    p1_time = game.player1_time_left
    p2_time = game.player2_time_left

    if game.last_move_time:
        elapsed = (now - game.last_move_time).total_seconds()
        if game.turn_user_id == game.player1_id:
            p1_time -= elapsed
        elif game.turn_user_id == game.player2_id:
            p2_time -= elapsed

    return {
        "player1_time_left": max(p1_time, 0),
        "player2_time_left": max(p2_time, 0)
    }





@router.get("/details")
async def get_game_details(game_id: int, db: Session = Depends(get_db)):
    game = db.query(models.Game).filter(models.Game.id == game_id).first()
    if not game:
        raise HTTPException(status_code=404, detail="Oyun bulunamadı.")
    
    player1 = db.query(models.User).filter(models.User.id == game.player1_id).first()
    player2 = db.query(models.User).filter(models.User.id == game.player2_id).first()

    return {
        "player1_username": player1.username if player1 else None,
        "player2_username": player2.username if player2 else None,
        "player1_score": game.player1_score if hasattr(game, 'player1_score') else 0,
        "player2_score": game.player2_score if hasattr(game, 'player2_score') else 0,
        "turn_user_id": game.turn_user_id,
        "status": game.status,
        "winner_id": game.winner_id
    }



class WordCheckRequest(BaseModel):
    word: str




@router.post("/check-word")
async def check_word(payload: WordCheckRequest):
    word = payload.word.strip().lower()
    print(f"🧪 Kontrol ediliyor: '{word}'")

    if kelime_var_mi(word):
        print(f"✅ Geçerli kelime: {word}")
        return {"result": f"✅ Geçerli kelime: {word}"}
    else:
        print(f"❌ Geçersiz kelime: {word}")
        return {"result": f"❌ Geçersiz kelime: {word}"}
    
    
    
    
@router.get("/draw-letters")
def draw_letters(game_id: int, user_id: int, count: int = 7, db: Session = Depends(get_db)):
    pool = game_manager.get_pool(game_id)  # 🔄 Güncel kullanım

    drawn_letters = pool.draw_letters(count)

    game = db.query(models.Game).filter(models.Game.id == game_id).first()
    if not game:
        raise HTTPException(status_code=404, detail="Oyun bulunamadı.")

    if user_id == game.player1_id:
        game.player1_tiles = (game.player1_tiles or []) + drawn_letters
    elif user_id == game.player2_id:
        game.player2_tiles = (game.player2_tiles or []) + drawn_letters
    else:
        raise HTTPException(status_code=400, detail="Bu kullanıcı bu oyunun oyuncusu değil.")

    db.commit()
    print(f"🎯 draw_letters: {drawn_letters} | user_id: {user_id} | game_id: {game_id}")
    return {"drawn": drawn_letters, "remaining": pool.remaining_letters()}




@router.get("/remaining-letters")
def get_remaining_letters(game_id: int):
    pool = game_manager.get_pool(game_id)
    return {"remaining": pool.remaining_letters()}












@router.post("/pass")
async def player_pass(game_id: int, user_id: int, db: Session = Depends(get_db)):
    game = db.query(models.Game).filter(models.Game.id == game_id).first()
    if not game:
        raise HTTPException(status_code=404, detail="Oyun bulunamadı.")

    if game.status == "finished":
        raise HTTPException(status_code=400, detail="Oyun zaten bitmiş durumda.")

    # 🔁 Pas ve sıra işlemleri (sıra kontrolü kaldırıldı!)
    if user_id == game.player1_id:
        game.pass_count_player1 += 1
        game.turn_user_id = game.player2_id
        print("➡️ Sıra oyuncu 2'ye geçti")
    elif user_id == game.player2_id:
        game.pass_count_player2 += 1
        game.turn_user_id = game.player1_id
        print("➡️ Sıra oyuncu 1'e geçti")
    else:
        raise HTTPException(status_code=400, detail="Bu oyuncu bu oyunun oyuncusu değil.")

    # 🎯 2'şer pas sonrası oyun bitirme
    if game.pass_count_player1 >= 2 and game.pass_count_player2 >= 2:
        game.status = "finished"
        game.turn_user_id = None  # ❌ Oyun bitince sıra yok

        # 🏆 Kazananı belirle
        if game.player1_score > game.player2_score:
            game.winner_id = game.player1_id
        elif game.player2_score > game.player1_score:
            game.winner_id = game.player2_id
        else:
            game.winner_id = None  # Beraberlik

        print(f"🏁 Oyun sona erdi! Her iki oyuncu da 2 pas geçti. Oyun ID: {game_id}")

    db.commit()

    return {
        "message": "Pas kaydedildi.",
        "p1_pass": game.pass_count_player1,
        "p2_pass": game.pass_count_player2,
        "game_status": game.status,
        "turn_user_id": game.turn_user_id,
        "winner_id": game.winner_id
    }





@router.post("/resign")
async def player_resign(game_id: int, user_id: int, db: Session = Depends(get_db)):
    game = db.query(models.Game).filter(models.Game.id == game_id).first()
    if not game:
        raise HTTPException(status_code=404, detail="Oyun bulunamadı.")

    if game.status == "finished":
        return {"message": "Oyun zaten bitmiş durumda."}

    # Oyuncu kontrolü ve kazanan + çekilen ataması
    if user_id == game.player1_id:
        game.winner_id = game.player2_id
        game.resigned_user_id = game.player1_id  # 🆕 EKLENDİ
    elif user_id == game.player2_id:
        game.winner_id = game.player1_id
        game.resigned_user_id = game.player2_id  # 🆕 EKLENDİ
    else:
        raise HTTPException(status_code=400, detail="Bu oyuncu bu oyunun oyuncusu değil.")

    game.status = "finished"
    db.commit()

    print(f"🏳️ Oyuncu çekildi! User ID: {user_id}, Game ID: {game_id}")
    return {
        "message": "Oyuncu oyundan çekildi, oyun sona erdi.",
        "winner_id": game.winner_id,
        "resigned_user_id": game.resigned_user_id,  # 🆕 Opsiyonel olarak frontend'e de iletilebilir
        "game_status": game.status
    }






@router.get("/check-time-and-finish")
async def check_time_and_finish(game_id: int, db: Session = Depends(get_db)):
    game = db.query(models.Game).filter(models.Game.id == game_id).first()
    if not game:
        raise HTTPException(status_code=404, detail="Oyun bulunamadı.")

    now = datetime.utcnow()
    p1_time = game.player1_time_left
    p2_time = game.player2_time_left

    if game.last_move_time:
        elapsed = (now - game.last_move_time).total_seconds()
        if game.turn_user_id == game.player1_id:
            p1_time -= elapsed
        elif game.turn_user_id == game.player2_id:
            p2_time -= elapsed

    if p1_time <= 0 or p2_time <= 0:
        game.status = "finished"
        game.player1_time_left = max(p1_time, 0)
        game.player2_time_left = max(p2_time, 0)

        if p1_time <= 0:
            game.winner_id = game.player2_id
        else:
            game.winner_id = game.player1_id

        db.commit()
        return {
            "message": "Süre bitti. Oyun sona erdi.",
            "winner_id": game.winner_id,
            "p1_time_left": game.player1_time_left,
            "p2_time_left": game.player2_time_left
        }

    return {
        "message": "Henüz süresi biten oyuncu yok.",
        "p1_time_left": max(p1_time, 0),
        "p2_time_left": max(p2_time, 0)
    }







