import random

class LetterPool:
    def __init__(self):
        self._pool = self._create_pool()

    def _create_pool(self):
        letters = []

        def add_letters(letter, count):
            for _ in range(count):
                letters.append(letter)

        add_letters('A', 12)
        add_letters('B', 2)
        add_letters('C', 2)
        add_letters('Ç', 2)
        add_letters('D', 3)
        add_letters('E', 8)
        add_letters('F', 2)
        add_letters('G', 3)
        add_letters('Ğ', 1)
        add_letters('H', 1)
        add_letters('I', 6)
        add_letters('İ', 4)
        add_letters('J', 1)
        add_letters('K', 7)
        add_letters('L', 5)
        add_letters('M', 4)
        add_letters('N', 7)
        add_letters('O', 3)
        add_letters('Ö', 1)
        add_letters('P', 2)
        add_letters('R', 6)
        add_letters('S', 5)
        add_letters('Ş', 2)
        add_letters('T', 5)
        add_letters('U', 3)
        add_letters('Ü', 2)
        add_letters('V', 2)
        add_letters('Y', 3)
        add_letters('Z', 2)

        return letters

    def draw_letters(self, count):
        """Havuzdan rastgele harfler çek ve havuzdan çıkar."""
        drawn = []
        for _ in range(count):
            if not self._pool:
                break
            index = random.randint(0, len(self._pool) - 1)
            drawn.append(self._pool.pop(index))
        return drawn

    def remaining_letters(self):
        """Kalan harf sayısını döner."""
        return len(self._pool)

    def get_pool(self):
        """Havuzdaki mevcut harfleri döner (liste)."""
        return list(self._pool)
