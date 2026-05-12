# WordBattle

Türkçe kelime tabanlı, çok oyunculu, sıra tabanlı bir mobil kelime savaşı oyunu. **Flutter** ile yazılmış mobil istemci ve **FastAPI** tabanlı bir backend'den oluşur. Oyuncular zamanlı eşleşmelerde tahta üzerinde kelime oluşturur, puan toplar; tahtaya gizlenmiş **mayın** ve **ödüller** oyunun seyrini değiştirir.

## Özellikler

- **Online çok oyunculu**: kullanıcı kayıt/giriş (JWT), eşleşme bulma, sıra tabanlı oynanış
- **Türkçe kelime listesi** ile geçerlilik kontrolü
- **Süreli oyun modları**: 2 dakika, 5 dakika, 12 saat, 24 saat
- **Mayın & Ödül sistemi**: tahtada gizli kareler (puan bölme, puan transferi, bölge bloklama, harf dondurma, vb.)
- **Pas geçme / pes etme** mekanikleri
- Oyun durumu sunucu tarafında tutulur (tahta, eldeki harfler, puanlar, kalan süreler)

## Teknoloji Yığını

### Backend (`wordbattle/wordbattle/backend`)
- **FastAPI** – REST API
- **SQLAlchemy** + **Alembic** – ORM ve migration
- **pyodbc** – MSSQL bağlantısı
- **python-jose** + **passlib (bcrypt)** – JWT kimlik doğrulama ve parola hashleme

### Mobil (`wordbattle/wordbattle/mobile`)
- **Flutter** (Dart SDK ^3.7.2)
- **provider** – durum yönetimi
- **http** – API iletişimi
- **flutter_secure_storage** – token saklama

## Çalıştırma

### Backend

```bash
cd wordbattle/wordbattle/backend
pip install -r requirements.txt
alembic upgrade head           # migration'ları uygula
uvicorn app.main:app --reload
```

Veritabanı bağlantı dizesi `app/database.py` içinde, MSSQL için `pyodbc` üzerinden yapılandırılmıştır.

### Mobil

```bash
cd wordbattle/wordbattle/mobile
flutter pub get
flutter run
```

## Veri Modeli (özet)

- **User**: kullanıcı adı, e-posta, parola hash'i
- **Game**: iki oyuncu, kazanan, süre, tahta durumu, puanlar, sıradaki oyuncu, eldeki harfler, kalan süreler, pas sayıları
- **GameMine**: tahtaya gizlenmiş mayın hücreleri (tip: split_score, transfer_score, vb.)
- **GameReward**: toplanabilen ödüller (zone_block, letter_freeze, vb.)

## Proje Yapısı

```
wordbattle/
├── backend/
│   ├── app/
│   │   ├── main.py              # FastAPI uygulaması
│   │   ├── auth.py              # JWT kimlik doğrulama
│   │   ├── models.py            # SQLAlchemy modelleri
│   │   ├── schemas.py           # Pydantic şemaları
│   │   ├── database.py
│   │   ├── letter_pool.py       # Harf havuzu
│   │   ├── word_utils.py        # Kelime doğrulama
│   │   ├── routers/             # game.py, match.py
│   │   ├── services/            # game_manager, game_services
│   │   └── wordlist/turkce_kelime_listesi.txt
│   └── alembic/                 # DB migration'ları
└── mobile/                      # Flutter istemcisi
```
