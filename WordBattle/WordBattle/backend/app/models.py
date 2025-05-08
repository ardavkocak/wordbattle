from sqlalchemy import Column, Float, Integer, String, ForeignKey, DateTime, Text, Boolean
from sqlalchemy.orm import relationship
from datetime import datetime
from app.database import Base
from sqlalchemy import PickleType  # yukarıya ekle


class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, nullable=False)
    email = Column(String(100), unique=True, nullable=False)
    password = Column(String(100), nullable=False)
    hashed_password = Column(String(255), nullable=False)
    
    # İlişkiler
    games_as_player1 = relationship("Game", back_populates="player1", foreign_keys="Game.player1_id")
    games_as_player2 = relationship("Game", back_populates="player2", foreign_keys="Game.player2_id")
    games_won = relationship("Game", back_populates="winner", foreign_keys="Game.winner_id")


class Game(Base):
    __tablename__ = "games"

    id = Column(Integer, primary_key=True, index=True)
    player1_id = Column(Integer, ForeignKey("users.id"))
    player2_id = Column(Integer, ForeignKey("users.id"))
    winner_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    duration = Column(String(10), nullable=False)  # '2m', '5m', '12h', '24h'
    created_at = Column(DateTime, default=datetime.utcnow)
    status = Column(String(20), default="pending")
    board_state = Column(Text, nullable=True)  # 🔥 Burası yeni
    player1_score = Column(Integer, default=0)  # 🆕 EKLENDİ
    player2_score = Column(Integer, default=0)  # 🆕 EKLENDİ
    turn_user_id = Column(Integer, nullable=True)
    player1_tiles = Column(PickleType, default=[])
    player2_tiles = Column(PickleType, default=[])
    player1_time_left = Column(Float, default=300.0)  # saniye cinsinden
    player2_time_left = Column(Float, default=300.0)
    last_move_time = Column(DateTime, nullable=True)  # son hamle zamanı
    pass_count_player1 = Column(Integer, default=0)
    pass_count_player2 = Column(Integer, default=0)
    resigned_user_id = Column(Integer, nullable=True)
    
    
    
    # İlişkiler
    player1 = relationship("User", back_populates="games_as_player1", foreign_keys=[player1_id])
    player2 = relationship("User", back_populates="games_as_player2", foreign_keys=[player2_id])
    winner = relationship("User", back_populates="games_won", foreign_keys=[winner_id])




class GameMine(Base):
    __tablename__ = "game_mines"
    id = Column(Integer, primary_key=True, index=True)
    game_id = Column(Integer, ForeignKey("games.id"))
    row = Column(Integer)
    col = Column(Integer)
    type = Column(String)  # e.g., "split_score", "transfer_score", etc.

class GameReward(Base):
    __tablename__ = "game_rewards"
    id = Column(Integer, primary_key=True, index=True)
    game_id = Column(Integer, ForeignKey("games.id"))
    row = Column(Integer)
    col = Column(Integer)
    type = Column(String)  # e.g., "zone_block", "letter_freeze", etc.
    collected_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    used = Column(Boolean, default=False)
