from typing import List, Optional
from app.letter_pool import LetterPool

def kalan_harf_puani(harfler: List[str]) -> int:
    """Bir oyuncunun elinde kalan harflerin toplam puanını hesaplar."""
    toplam = 0
    for harf in harfler:
        puan = LetterPool.get(harf.upper(), 0)
        toplam += puan
    return toplam

def oyun_sonu_hesapla(
    player1_puan: int,
    player2_puan: int,
    player1_tiles: List[str],
    player2_tiles: List[str],
    teslim_eden: Optional[str] = None,
    iki_pas: bool = False,
    zaman_asimi: Optional[str] = None,
    mayin_etkileri: Optional[dict] = None
) -> dict:
    """
    Oyun sonunda skoru hesapla:
    - Teslim olan kaybeder.
    - İki pas varsa doğrudan puan karşılaştırılır.
    - Normal bitişte kalan harflerin puanları hesaba katılır.
    """

    # Teslim olma durumu
    if teslim_eden == 'player1':
        return {"kazanan": "player2", "sebep": "Player1 teslim oldu"}
    if teslim_eden == 'player2':
        return {"kazanan": "player1", "sebep": "Player2 teslim oldu"}

    # Zaman aşımı durumu
    if zaman_asimi == 'player1':
        return {"kazanan": "player2", "sebep": "Player1 hamle süresini geçti"}
    if zaman_asimi == 'player2':
        return {"kazanan": "player1", "sebep": "Player2 hamle süresini geçti"}

    # İki pas geçildiyse puan karşılaştırması
    if iki_pas:
        if player1_puan > player2_puan:
            return {"kazanan": "player1", "sebep": "İki pas sonrası puanı yüksek"}
        elif player2_puan > player1_puan:
            return {"kazanan": "player2", "sebep": "İki pas sonrası puanı yüksek"}
        else:
            return {"kazanan": "berabere", "sebep": "İki pas sonrası puanlar eşit"}

    # Normal bitiş
    p1_kalan_puan = kalan_harf_puani(player1_tiles)
    p2_kalan_puan = kalan_harf_puani(player2_tiles)

    # Skor güncelleme
    p1_son_puan = player1_puan + p2_kalan_puan - p1_kalan_puan
    p2_son_puan = player2_puan + p1_kalan_puan - p2_kalan_puan

    # Mayın etkileri varsa uygula
    if mayin_etkileri:
        if 'player1' in mayin_etkileri:
            p1_son_puan += mayin_etkileri['player1']
        if 'player2' in mayin_etkileri:
            p2_son_puan += mayin_etkileri['player2']

    # Kazananı belirle
    if p1_son_puan > p2_son_puan:
        kazanan = "player1"
    elif p2_son_puan > p1_son_puan:
        kazanan = "player2"
    else:
        kazanan = "berabere"

    return {
        "player1_son_puan": p1_son_puan,
        "player2_son_puan": p2_son_puan,
        "kazanan": kazanan
    }
