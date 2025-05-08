# app/services/game_service.py
from app import models , database
import random

def calculate_score(board, placed_tiles, ignore_multipliers=False):
    special_tiles = {
        (0, 3): "H2", (0, 11): "H2", (2, 6): "H2", (2, 8): "H2", (3, 0): "H2",
        (3, 7): "H2", (3, 14): "H2", (6, 2): "H2", (6, 6): "H2", (6, 8): "H2",
        (6, 12): "H2", (7, 3): "H2", (7, 11): "H2", (8, 2): "H2", (8, 6): "H2",
        (8, 8): "H2", (8, 12): "H2", (11, 0): "H2", (11, 7): "H2", (11, 14): "H2",
        (12, 6): "H2", (12, 8): "H2", (14, 3): "H2", (14, 11): "H2",
        (1, 5): "H3", (1, 9): "H3", (5, 1): "H3", (5, 5): "H3", (5, 9): "H3", (5, 13): "H3",
        (9, 1): "H3", (9, 5): "H3", (9, 9): "H3", (9, 13): "H3", (13, 5): "H3", (13, 9): "H3",
        (1, 1): "K2", (2, 2): "K2", (3, 3): "K2", (4, 4): "K2", (10, 10): "K2",
        (11, 11): "K2", (12, 12): "K2", (13, 13): "K2", (1, 13): "K2", (2, 12): "K2",
        (3, 11): "K2", (4, 10): "K2", (10, 4): "K2", (11, 3): "K2", (12, 2): "K2", (13, 1): "K2",
        (0, 0): "K3", (0, 7): "K3", (0, 14): "K3", (7, 0): "K3", (7, 14): "K3",
        (14, 0): "K3", (14, 7): "K3", (14, 14): "K3"
    }

    letter_points = {
        'A': 1, 'B': 3, 'C': 4, 'Ç': 4, 'D': 3, 'E': 1, 'F': 7, 'G': 5, 'Ğ': 8,
        'H': 5, 'I': 2, 'İ': 1, 'J': 10, 'K': 1, 'L': 1, 'M': 2, 'N': 1, 'O': 2,
        'Ö': 7, 'P': 5, 'R': 1, 'S': 2, 'Ş': 4, 'T': 1, 'U': 2, 'Ü': 3, 'V': 7,
        'Y': 3, 'Z': 4
    }

    total_score = 0
    word_multiplier = 1

    for tile in placed_tiles:
        row, col = tile['row'], tile['col']
        letter = tile['letter'].upper()
        score = letter_points.get(letter, 0)

        if not ignore_multipliers:
            cell_type = special_tiles.get((row, col))
            if cell_type == "H2":
                score *= 2
            elif cell_type == "H3":
                score *= 3
            elif cell_type == "K2":
                word_multiplier *= 2
            elif cell_type == "K3":
                word_multiplier *= 3

        total_score += score

    return total_score * word_multiplier


def assign_mines_and_rewards(db, game_id: int):
    def get_random_coords(existing):
        while True:
            r, c = random.randint(0, 14), random.randint(0, 14)
            if (r, c) not in existing:
                existing.add((r, c))
                return r, c

    existing = set()
    
    print(f"🎯 Oyun {game_id} için mayın ve ödül yerleştiriliyor...")

    # Mine assignments
    mine_types = [
        ("split_score", 5),
        ("transfer_score", 4),
        ("reset_letters", 3),
        ("cancel_multipliers", 2),
        ("cancel_word", 2),
    ]
    for mtype, count in mine_types:
        for _ in range(count):
            r, c = get_random_coords(existing)
            print(f"💣 Mayın yerleştirildi: {mtype} → ({r}, {c})")
            db.add(models.GameMine(game_id=game_id, row=r, col=c, type=mtype))

    # Reward assignments
    reward_types = [
        ("zone_block", 2),
        ("letter_freeze", 3),
        ("extra_move", 2),
    ]
    for rtype, count in reward_types:
        for _ in range(count):
            r, c = get_random_coords(existing)
            print(f"🎁 Ödül yerleştirildi: {rtype} → ({r}, {c})")
            db.add(models.GameReward(game_id=game_id, row=r, col=c, type=rtype))

    db.commit()


def apply_mine_and_reward_effects(db, game, placed_tiles, base_score):
    triggered_mines = []
    triggered_rewards = []
    ignore_multipliers = False

    for tile in placed_tiles:
        row, col = tile["row"], tile["col"]

        # Mayın kontrolü
        mine = db.query(models.GameMine).filter_by(game_id=game.id, row=row, col=col).first()
        if mine:
            print(f"💥 ({row}, {col}) konumunda {mine.type} mayını tetiklendi!")
            triggered_mines.append(mine.type)

            if mine.type == "split_score":
                base_score = int(base_score * 0.3)
                print(f"🔻 Skor %30'a düşürüldü: {base_score}")

            elif mine.type == "transfer_score":
                if game.turn_user_id == game.player1_id:
                    game.player2_score += base_score
                    print(f"➡️ Puan rakibe aktarıldı: +{base_score} (Player2)")
                else:
                    game.player1_score += base_score
                    print(f"➡️ Puan rakibe aktarıldı: +{base_score} (Player1)")
                base_score = 0

            elif mine.type == "reset_letters":
                print("🌀 Harfler sıfırlanacak (frontend'de tetiklenecek)")

            elif mine.type == "cancel_multipliers":
                ignore_multipliers = True
                print("❌ Kat sayılar iptal (puan düz verilecek)")

            elif mine.type == "cancel_word":
                print("❌ Kelime tamamen iptal edildi, skor 0")
                base_score = 0

        # Ödül kontrolü
        reward = db.query(models.GameReward).filter_by(game_id=game.id, row=row, col=col).first()
        if reward and reward.collected_by is None:
            reward.collected_by = game.turn_user_id
            triggered_rewards.append(reward.type)
            print(f"🎁 ({row}, {col}) konumundaki ödül toplandı: {reward.type}")

    db.commit()
    return base_score, triggered_mines, triggered_rewards, ignore_multipliers
