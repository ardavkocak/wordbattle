from app.letter_pool import LetterPool

class GameManager:
    def __init__(self):
        self._games = {}

    def get_pool(self, game_id: int):
        if game_id not in self._games:
            self._games[game_id] = LetterPool()
        return self._games[game_id]

game_manager = GameManager()
