import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../user_session.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login(BuildContext context) async {
    final String username = usernameController.text.trim();
    final String password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showSnackbar('Kullanıcı adı ve şifre boş olamaz.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('http://localhost:8000/login');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data["access_token"];
        final userId = data["user_id"]; // ✅ Buradan user_id alıyoruz

        UserSession.userId = userId; // ✅ UserSession'a kaydediyoruz

        print('✅ Giriş başarılı! Token: $token, User ID: $userId');

        Navigator.pushReplacementNamed(context, '/home');
      } else {
        final data = jsonDecode(response.body);
        final error = data["detail"] ?? "Giriş başarısız.";
        _showSnackbar(error);
      }
    } catch (e) {
      _showSnackbar('Sunucuya ulaşılamadı.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giriş Yap')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Kullanıcı Adı'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Şifre'),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: () => _login(context),
                  child: const Text('Giriş Yap'),
                ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              child: const Text('Hesabın yok mu? Kayıt ol'),
            ),
          ],
        ),
      ),
    );
  }
}
