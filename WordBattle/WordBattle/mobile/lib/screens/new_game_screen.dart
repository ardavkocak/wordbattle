import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // JSON encode/decode işlemleri için

class NewGameScreen extends StatefulWidget {
  const NewGameScreen({super.key});

  @override
  State<NewGameScreen> createState() => _NewGameScreenState();
}

class _NewGameScreenState extends State<NewGameScreen> {
  String? selectedDuration; // Kullanıcının seçtiği süre

  final Map<String, String> durations = {
    '2 Dakika': '2m',
    '5 Dakika': '5m',
    '12 Saat': '12h',
    '24 Saat': '24h',
  };

  Future<void> _startMatchmaking() async {
    if (selectedDuration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir süre seçin')),
      );
      return;
    }

    try {
      // Backend API adresi (kendi IP adresine göre değiştirmen gerekebilir)
      const String apiUrl = 'http://10.0.2.2:8000/game/create'; 
      // Not: Eğer Android emülatörde çalışıyorsan IP '10.0.2.2' olacak
      // Gerçek telefonda test yapıyorsan, backend bilgisayarının yerel IP'sini yaz (örnek: 192.168.1.5 gibi)

      int userId = 1; // Şu anda örnek user id (ileride login olunca gerçek kullanıcıdan alınacak)

      // API'ye POST isteği gönderiyoruz
      final response = await http.post(
        Uri.parse('$apiUrl?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "duration": selectedDuration,
        }),
      );

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Oyun oluşturuldu! Oyun ID: ${responseData["game_id"]}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Oyun oluşturulamadı: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata oluştu: $e')),
      );
    }
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
            ...durations.keys.map((label) => RadioListTile<String>(
                  title: Text(label),
                  value: durations[label]!,
                  groupValue: selectedDuration,
                  onChanged: (value) {
                    setState(() {
                      selectedDuration = value;
                    });
                  },
                )),

            const Spacer(),

            ElevatedButton(
              onPressed: _startMatchmaking,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.indigo,
              ),
              child: const Text(
                'Eşleşmeyi Başlat',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
