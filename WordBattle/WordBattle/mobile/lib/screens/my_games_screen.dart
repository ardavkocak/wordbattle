import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MyGamesScreen extends StatefulWidget {
  const MyGamesScreen({super.key});

  @override
  State<MyGamesScreen> createState() => _MyGamesScreenState();
}

class _MyGamesScreenState extends State<MyGamesScreen> {
  List<dynamic> activeGames = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchActiveGames();
  }

  Future<void> fetchActiveGames() async {
    final int userId =
        1; // 👈 Bunu login sonrası aldığın userId ile değiştirmen gerekiyor ileride
    final String url = 'http://localhost:8000/game/active?user_id=$userId';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          activeGames = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Aktif oyunlar getirilemedi.');
      }
    } catch (e) {
      print('Hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aktif Oyunlarım')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: activeGames.length,
                itemBuilder: (context, index) {
                  final game = activeGames[index];
                  return ListTile(
                    title: Text('Oyun ID: ${game['id']}'),
                    subtitle: Text('Süre: ${game['duration']} dakika'),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/finished_games',
          ); // ✅ Biten oyunlar sayfasına gider
        },
        child: const Icon(Icons.history),
        tooltip: 'Biten Oyunlarım',
      ),
    );
  }
}
