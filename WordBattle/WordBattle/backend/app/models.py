from sqlalchemy import Column, Integer, String, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from datetime import datetime
from app.database import Base

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

    # İlişkiler
    player1 = relationship("User", back_populates="games_as_player1", foreign_keys=[player1_id])
    player2 = relationship("User", back_populates="games_as_player2", foreign_keys=[player2_id])
    winner = relationship("User", back_populates="games_won", foreign_keys=[winner_id])
