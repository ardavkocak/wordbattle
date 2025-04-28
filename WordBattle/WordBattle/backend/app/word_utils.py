# Kelime listesini yükleyen ve kontrol eden yardımcı fonksiyonlar

kelime_seti = set()

def kelime_listesini_yukle():
    global kelime_seti
    with open("app/wordlist/turkce_kelime_listesi.txt", "r", encoding="utf-8") as file:
        for line in file:
            kelime = line.strip().lower()
            kelime_seti.add(kelime)

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
