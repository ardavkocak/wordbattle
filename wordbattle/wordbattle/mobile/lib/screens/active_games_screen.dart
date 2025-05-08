// lib/screens/active_games_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../user_session.dart';
import 'game_screen.dart';

class ActiveGamesScreen extends StatefulWidget {
  const ActiveGamesScreen({super.key});

  @override
  State<ActiveGamesScreen> createState() => _ActiveGamesScreenState();
}

class _ActiveGamesScreenState extends State<ActiveGamesScreen> {
  List<dynamic> activeGames = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchActiveGames();
  }

  Future<void> fetchActiveGames() async {
    final int userId = UserSession.userId!;
    final result = await ApiService.fetchActiveGames(userId);

    if (result != null) {
      setState(() {
        activeGames = result;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aktif Oyunlar')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : activeGames.isEmpty
              ? const Center(child: Text('Aktif oyun bulunamadı.'))
              : ListView.builder(
                itemCount: activeGames.length,
                itemBuilder: (context, index) {
                  final game = activeGames[index];
                  return ListTile(
                    title: Text('Oyun ID: ${game['id']}'),
                    subtitle: Text('Süre: ${game['duration']}'),
                    trailing: const Icon(Icons.play_arrow),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => GameScreen(
                                gameId: game['id'],
                                userId: UserSession.userId!,
                              ),
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }
}
