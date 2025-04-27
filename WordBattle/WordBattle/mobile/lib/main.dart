import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/new_game_screen.dart';
import 'screens/my_games_screen.dart';

void main() {
  runApp(WordBattleApp());
}

class WordBattleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kelime Mayınları',
      theme: ThemeData(primarySwatch: Colors.indigo),
      initialRoute: '/login', // ilk ekran
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => HomeScreen(),
        '/new_game': (context) => NewGameScreen(), // ileri adımda
        '/my_games': (context) => MyGamesScreen(), // ileri adımda
      },
    );
  }
}
