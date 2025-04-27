import 'package:flutter/material.dart';

class TopBar extends StatelessWidget {
  final String myUsername;
  final int myScore;
  final String opponentUsername;
  final int opponentScore;
  final int remainingLetters;

  const TopBar({
    super.key,
    required this.myUsername,
    required this.myScore,
    required this.opponentUsername,
    required this.opponentScore,
    required this.remainingLetters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      color: Colors.indigo.shade700,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sol: Kullanıcı adı ve skor
          Column(
            children: [
              Text(
                myUsername,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                myScore.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),

          // Orta: Kalan harf sayısı
          Column(
            children: [
              const Text(
                'Kalan Harf',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                remainingLetters.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),

          // Sağ: Rakip adı ve skor
          Column(
            children: [
              Text(
                opponentUsername,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                opponentScore.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
