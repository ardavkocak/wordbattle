import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String? error;

  void _register() async {
    final message = await AuthService.register(
      username: usernameController.text,
      email: emailController.text,
      password: passwordController.text,
    );

    if (message == "Kayıt başarılı!") {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      setState(() => error = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kayıt Ol')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: usernameController, decoration: InputDecoration(labelText: 'Kullanıcı Adı')),
            TextField(controller: emailController, decoration: InputDecoration(labelText: 'E-posta')),
            TextField(controller: passwordController, obscureText: true, decoration: InputDecoration(labelText: 'Şifre')),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _register, child: Text('Kayıt Ol')),
            if (error != null) Text(error!, style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
