import 'package:flutter/material.dart';
import '../services/api_service.dart'; // ApiService dosyasını import etmeyi unutma!

class NewGameScreen extends StatefulWidget {
  const NewGameScreen({super.key});

  @override
  State<NewGameScreen> createState() => _NewGameScreenState();
}

class _NewGameScreenState extends State<NewGameScreen> {
  String? selectedDuration;

  final Map<String, String> durations = {
    '2 Dakika': '2m',
    '5 Dakika': '5m',
    '12 Saat': '12h',
    '24 Saat': '24h',
  };

  Future<void> _startMatchmaking() async {
    if (selectedDuration == null) {
      _showSnackbar('Lütfen bir süre seçin.');
      return;
    }

    const int userId = 1; // Şu an test için sabit kullanıcı ID'si

    final result = await ApiService.startGame(
      userId: userId,
      duration: selectedDuration!,
    );

    if (result != null) {
      if (result.containsKey('message')) {
        _showSnackbar('Oyun oluşturuldu! Oyun ID: ${result["game_id"]}');
        Navigator.pop(context); // İstersen home'a geri dönebilirsin
      } else if (result.containsKey('detail')) {
        _showSnackbar('Hata: ${result["detail"]}');
      }
    } else {
      _showSnackbar('Sunucuya bağlanılamadı.');
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
      appBar: AppBar(title: const Text('Yeni Oyun Başlat')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Süre Seçin',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Süre Seçimi
            ...durations.entries.map(
              (entry) => RadioListTile<String>(
                title: Text(entry.key),
                value: entry.value,
                groupValue: selectedDuration,
                onChanged: (value) {
                  setState(() {
                    selectedDuration = value;
                  });
                },
              ),
            ),

            const Spacer(),

            ElevatedButton(
              onPressed: _startMatchmaking,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('Eşleşmeyi Başlat'),
            ),
          ],
        ),
      ),
    );
  }
}
