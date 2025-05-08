import 'package:flutter/material.dart';

class TopBar extends StatelessWidget {
  final String myUsername;
  final int myScore;
  final String opponentUsername;
  final int opponentScore;
  final int remainingLetters;
  final int myTimeLeft;
  final int opponentTimeLeft;

  const TopBar({
    super.key,
    required this.myUsername,
    required this.myScore,
    required this.opponentUsername,
    required this.opponentScore,
    required this.remainingLetters,
    required this.myTimeLeft,
    required this.opponentTimeLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      color: Colors.blue.shade100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Oyuncu bilgisi
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$myUsername (Siz)",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text("Skor: $myScore"),
              Text("Süre: $myTimeLeft sn"),
            ],
          ),

          // Ortada kalan harf sayısı
          Column(
            children: [
              const Text("🎯 Kalan Harfler"),
              Text("$remainingLetters"),
            ],
          ),

          // Rakip bilgisi
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                opponentUsername,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text("Skor: $opponentScore"),
              Text("Süre: $opponentTimeLeft sn"),
            ],
          ),
        ],
      ),
    );
  }
}
