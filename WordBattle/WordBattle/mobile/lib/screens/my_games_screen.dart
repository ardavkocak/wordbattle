import 'package:flutter/material.dart';

class MyGamesScreen extends StatelessWidget {
  const MyGamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Oyunlarım')),
      body: const Center(
        child: Text('Buraya geçmiş ve aktif oyunlar listesi gelecek.'),
      ),
    );
  }
}
