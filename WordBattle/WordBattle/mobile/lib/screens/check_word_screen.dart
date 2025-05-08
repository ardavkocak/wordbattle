import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class CheckWordScreen extends StatefulWidget {
  const CheckWordScreen({super.key});

  @override
  State<CheckWordScreen> createState() => _CheckWordScreenState();
}

class _CheckWordScreenState extends State<CheckWordScreen> {
  final wordController = TextEditingController();
  String resultMessage = '';

  void _checkWord() async {
    final word = wordController.text.trim();
    if (word.isEmpty) return;

    final result = await AuthService.checkWord(word);
    print("🔍 Flutter gelen yanıt: $result"); // 👈 EKLE BUNU
    setState(() {
      resultMessage = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelime Kontrol')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: wordController,
              decoration: const InputDecoration(labelText: 'Kelime Girin'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _checkWord,
              child: const Text('Kontrol Et'),
            ),
            const SizedBox(height: 20),
            Text(
              resultMessage,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
