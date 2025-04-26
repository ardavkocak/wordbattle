# app/schemas.py
from pydantic import BaseModel, EmailStr

class UserCreate(BaseModel):
    username: str
    email: EmailStr
    password: str

class UserOut(BaseModel):
    id: int
    username: str
    email: EmailStr

    model_config = {
        "from_attributes": True
    }

class UserLogin(BaseModel):
    username: str
    password: str
    
    

class GameCreate(BaseModel):
    player1_id: int
    player2_id: int
    duration: str

class GameOut(BaseModel):
    id: int
    player1_id: int
    player2_id: int
    winner_id: int | None
    duration: str
    created_at: datetime
    status: str

    model_config = {
        "from_attributes": True
    }