import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../user_session.dart';
import 'game_screen.dart';

class NewGameScreen extends StatefulWidget {
  const NewGameScreen({super.key});

  @override
  State<NewGameScreen> createState() => _NewGameScreenState();
}

class _NewGameScreenState extends State<NewGameScreen> {
  String? selectedDuration;
  bool isSearching = false;
  Timer? _pollingTimer;
  Timer? _textAnimationTimer;
  String searchingText = "Rakip aranıyor";
  int dotCount = 0;
  int? createdGameId;

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

    final int userId = UserSession.userId!;

    setState(() {
      isSearching = true;
    });

    _startTextAnimation(); // Bekleme animasyonu başlatılıyor

    final result = await ApiService.startGame(
      userId: userId,
      duration: selectedDuration!,
    );

    if (result != null && result.containsKey('game_id')) {
      createdGameId = result["game_id"];
      _startPollingForMatch();
    } else {
      _showSnackbar('Eşleşme başlatılamadı.');
      setState(() {
        isSearching = false;
      });
      _textAnimationTimer?.cancel();
    }
  }

  void _startPollingForMatch() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (createdGameId == null) return;

      final gameStatus = await ApiService.checkGameStatus(
        gameId: createdGameId!,
      );
      if (gameStatus == "active") {
        timer.cancel();
        _textAnimationTimer?.cancel();
        _showSnackbar('🎉 Eşleşme bulundu! Oyun başlıyor.');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => GameScreen(
                  gameId: createdGameId!,
                  userId: UserSession.userId!, // doğru user id buradan
                ),
          ),
        );
      }
    });
  }

  void _startTextAnimation() {
    _textAnimationTimer = Timer.periodic(const Duration(milliseconds: 500), (
      timer,
    ) {
      setState(() {
        dotCount = (dotCount + 1) % 4;
        searchingText = "Rakip aranıyor" + "." * dotCount;
      });
    });
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _textAnimationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Oyun Başlat')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child:
            isSearching
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    Text(searchingText, style: const TextStyle(fontSize: 20)),
                  ],
                )
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Süre Seçin',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
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
