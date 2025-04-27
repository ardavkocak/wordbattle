import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/new_game_screen.dart';
import 'screens/my_games_screen.dart';
import 'screens/finished_games_screen.dart';
import 'screens/game_screen.dart';

void main() {
  runApp(WordBattleApp());
}

class WordBattleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kelime Mayınları',
      theme: ThemeData(primarySwatch: Colors.indigo),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => HomeScreen(),
        '/new_game': (context) => NewGameScreen(),
        '/my_games': (context) => MyGamesScreen(),
        '/finished_games':
            (context) => FinishedGamesScreen(), // 🔥 doğru widget
        '/game': (context) => GameScreen(gameId: 0, userId: 0),
      },
    );
  }
}
