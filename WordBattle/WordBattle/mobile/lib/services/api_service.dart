import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000'; // Chrome server için

  // 🆕 Yeni Oyun Başlat (POST /game/create)
  static Future<Map<String, dynamic>?> startGame({
    required int userId,
    required String duration,
  }) async {
    final url = Uri.parse('$baseUrl/game/create?user_id=$userId');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"duration": duration}),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return data; // {"message": "...", "game_id": ...}
      } else {
        return data; // {"detail": "..."}
      }
    } catch (e) {
      print('startGame hatası: $e');
      return {"detail": "Bilinmeyen bir hata oluştu."};
    }
  }

  static Future<Map<String, dynamic>?> makeMove({
    required int gameId,
    required int userId,
    required List<List<String?>> board,
    required List<Map<String, dynamic>> placedTiles,
  }) async {
    final url = Uri.parse(
      '$baseUrl/game/make_move?game_id=$gameId&user_id=$userId',
    );

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"board_state": board, "placed_tiles": placedTiles}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('makeMove başarısız: ${response.body}');
      }
    } catch (e) {
      print('makeMove hatası: $e');
    }
    return null;
  }

  // 🔥 Oyun Durumunu Kontrol Et (GET /game/status)
  static Future<String?> checkGameStatus({required int gameId}) async {
    final url = Uri.parse('$baseUrl/game/status?game_id=$gameId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["status"];
      }
    } catch (e) {
      print('Game status kontrol edilemedi: $e');
    }
    return null;
  }

  static Future<List<dynamic>?> fetchActiveGames(int userId) async {
    final url = Uri.parse('http://localhost:8000/game/active?user_id=$userId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("❌ Aktif oyunlar getirilemedi.");
      return null;
    }
  }

  // 🔥 Tahtayı Çek (GET /game/get_board)
  static Future<List<List<String>>?> fetchBoard(int gameId) async {
    final url = Uri.parse('$baseUrl/game/get_board?game_id=$gameId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['board'] != null) {
          List<List<String>> board = List<List<String>>.from(
            data['board'].map((row) => List<String>.from(row)),
          );
          return board;
        } else {
          return null; // henüz tahtası olmayan oyun
        }
      } else {
        print("fetchBoard sunucu hatası: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("fetchBoard çekilirken hata oluştu: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getRemainingLetters({
    required int gameId,
  }) async {
    final url = Uri.parse('$baseUrl/game/remaining-letters?game_id=$gameId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("getRemainingLetters hatası: $e");
    }
    return null;
  }

  // 🔥 Tahtayı Güncelle (POST /game/update_board)
  static Future<bool> updateBoard({
    required int gameId,
    required List<List<String>> board,
  }) async {
    final url = Uri.parse('$baseUrl/game/update_board');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"game_id": gameId, "board": board}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('updateBoard başarısız: ${response.body}');
        return false;
      }
    } catch (e) {
      print('updateBoard hatası: $e');
      return false;
    }
  }

  // 🆕 Oyuncu sırası kimde? (GET /game/turn)
  static Future<int?> fetchTurnUserId({required int gameId}) async {
    final url = Uri.parse('$baseUrl/game/turn?game_id=$gameId');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["turn_user_id"];
      } else {
        print('fetchTurnUserId sunucu hatası: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('fetchTurnUserId hatası: $e');
      return null;
    }
  }

  // 🆕 Sırayı değiştir (POST /game/change_turn)
  static Future<bool> changeTurn({required int gameId}) async {
    final url = Uri.parse('$baseUrl/game/change_turn');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"game_id": gameId}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('changeTurn başarısız: ${response.body}');
        return false;
      }
    } catch (e) {
      print('changeTurn hatası: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> fetchTimeStatus(int gameId) async {
    final url = Uri.parse('$baseUrl/game/time-status?game_id=$gameId');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("⛔ fetchTimeStatus hatası: ${response.body}");
      }
    } catch (e) {
      print("❌ fetchTimeStatus exception: $e");
    }
    return null;
  }

  static Future<Map<String, dynamic>?> drawLetters({
    required int gameId,
    required int userId, // 👈 EKLENDİ
    int count = 7,
  }) async {
    final url = Uri.parse(
      '$baseUrl/game/draw-letters?game_id=$gameId&user_id=$userId&count=$count',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('drawLetters başarısız: ${response.body}');
        return null;
      }
    } catch (e) {
      print('drawLetters hatası: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> fetchGameDetails(int gameId) async {
    final url = Uri.parse('$baseUrl/game/details?game_id=$gameId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('fetchGameDetails sunucu hatası: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('fetchGameDetails hatası: $e');
      return null;
    }
  }

  static Future<int?> fetchRemainingLetters({required int gameId}) async {
    final url = Uri.parse('$baseUrl/game/remaining-letters?game_id=$gameId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['remaining'];
      }
    } catch (e) {
      print('fetchRemainingLetters hatası: $e');
    }
    return null;
  }
}
