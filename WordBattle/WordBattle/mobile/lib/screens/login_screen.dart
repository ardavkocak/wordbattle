import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void _login(BuildContext context) {
    // Burada backend'e http isteği gönderilecek
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Giriş Yap')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: usernameController, decoration: InputDecoration(labelText: 'Kullanıcı Adı')),
            TextField(controller: passwordController, obscureText: true, decoration: InputDecoration(labelText: 'Şifre')),
            SizedBox(height: 20),
            ElevatedButton(onPressed: () => _login(context), child: Text('Giriş Yap')),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              child: Text('Hesabın yok mu? Kayıt ol'),
            )
          ],
        ),
      ),
    );
  }
}
