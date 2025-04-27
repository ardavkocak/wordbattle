import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FinishedGamesScreen extends StatefulWidget {
  const FinishedGamesScreen({super.key});

  @override
  State<FinishedGamesScreen> createState() => _FinishedGamesScreenState();
}

class _FinishedGamesScreenState extends State<FinishedGamesScreen> {
  List<dynamic> finishedGames = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFinishedGames();
  }

  Future<void> fetchFinishedGames() async {
    final int userId = 1;
    final String url = 'http://localhost:8000/game/finished?user_id=$userId';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          finishedGames = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Biten oyunlar getirilemedi.');
      }
    } catch (e) {
      print('Hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Biten Oyunlarım')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: finishedGames.length,
                itemBuilder: (context, index) {
                  final game = finishedGames[index];
                  return ListTile(
                    title: Text('Oyun ID: ${game['id']}'),
                    subtitle: Text('Süre: ${game['duration']} dakika'),
                  );
                },
              ),
    );
  }
}
