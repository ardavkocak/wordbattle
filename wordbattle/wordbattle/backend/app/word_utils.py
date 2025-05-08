# Kelime listesini yükleyen ve kontrol eden yardımcı fonksiyonlar

import unicodedata


kelime_seti = set()


def normalize_word(w):
    return unicodedata.normalize("NFKD", w).encode("ASCII", "ignore").decode("utf-8").lower()



def kelime_listesini_yukle():
    global kelime_seti
    try:
        with open("app/wordlist/turkce_kelime_listesi.txt", "r", encoding="utf-8") as file:
            for line in file:
                kelime = line.strip().lower()
                kelime_seti.add(kelime)
        print(f"✅ {len(kelime_seti)} kelime yüklendi")
    except Exception as e:
        print(f"❌ Kelime listesi yüklenemedi: {e}")





def kelime_var_mi(kelime: str) -> bool:
    return kelime.lower() in kelime_seti


# KELIME KONTROLUNU YAPMAK ICIN KULLANILACAK KOD
# from app.utils.word_utils import kelime_var_mi

# @router.post("/check-word")
# def check_word(word: str):
#     if kelime_var_mi(word):
#         return {"result": "Geçerli kelime!"}
#     else:
#         return {"result": "Geçersiz kelime."}
