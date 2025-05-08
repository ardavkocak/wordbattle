import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/new_game_screen.dart';
import 'screens/finished_games_screen.dart';
import 'screens/active_games_screen.dart'; // ✅ EKLENDİ
import 'screens/check_word_screen.dart';

void main() {
  runApp(const WordBattleApp());
}

class WordBattleApp extends StatelessWidget {
  const WordBattleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kelime Mayınları',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/new_game': (context) => const NewGameScreen(),
        '/finished_games': (context) => const FinishedGamesScreen(),
        '/my_games': (context) => const ActiveGamesScreen(), // ✅ EKLENDİ
        '/check_word': (context) => const CheckWordScreen(),
      },
    );
  }
}
