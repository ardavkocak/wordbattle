import 'package:flutter/material.dart';

class BottomBar extends StatelessWidget {
  final List<String> letters;
  final Future<void> Function()? onConfirm;
  final int wordScore;

  const BottomBar({
    super.key,
    required this.letters,
    required this.onConfirm,
    required this.wordScore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.indigo.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        children: [
          // Harfler
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children:
                letters.map((letter) {
                  return Draggable<String>(
                    data: letter,
                    feedback: _buildTile(letter, isDragging: true),
                    childWhenDragging: _buildTile('', isDragging: false),
                    child: _buildTile(letter, isDragging: false),
                  );
                }).toList(),
          ),
          const SizedBox(height: 12),
          // Onay Butonu ve Skor
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed:
                    onConfirm != null
                        ? () async {
                          await onConfirm!();
                        }
                        : null,
                icon: const Icon(Icons.check),
                label: const Text('Onayla'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Text(
                "Puan: $wordScore",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTile(String letter, {required bool isDragging}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDragging ? Colors.orange.shade100 : Colors.orange.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        letter,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}
