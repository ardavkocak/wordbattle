import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:8000'; // Android emulator için
  // Eğer tarayıcıda çalıştırıyorsan:
  // static const String baseUrl = 'http://localhost:8000';

  static Future<String?> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "email": email,
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      return "Kayıt başarılı!";
    } else {
      return jsonDecode(response.body)["detail"];
    }
  }

  static Future<String?> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final token = json['access_token'];
      // TODO: Token'ı güvenli depola (flutter_secure_storage)
      return null; // Hata yok
    } else {
      return jsonDecode(response.body)["detail"];
    }
  }
}
