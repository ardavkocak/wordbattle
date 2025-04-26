import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000'; // Android emülatör için

  // 🆕 Yeni Oyun Başlat (POST /game/create)
  static Future<Map<String, dynamic>?> startGame({
    required int userId,
    required String duration,
  }) async {
    final url = Uri.parse('$baseUrl/game/create?user_id=$userId');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"duration": duration}),
    );

    try {
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data; // {"message": "...", "game_id": ...}
      } else {
        // Başarısız da olsa backend'den gelen mesajı dön
        return data; // {"detail": "..."} gibi
      }
    } catch (e) {
      print('Cevap çözümlenemedi: $e');
      return {"detail": "Bilinmeyen bir hata oluştu."};
    }
  }
}
