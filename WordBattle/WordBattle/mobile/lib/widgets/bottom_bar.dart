import 'package:flutter/material.dart';

class BottomBar extends StatelessWidget {
  final List<String> letters;
  final Future<void> Function()? onConfirm;
  final int? wordScore; // opsiyonel hale getir
  final VoidCallback? onUndo; // 👈 Geri al fonksiyonu
  final VoidCallback? onPass;
  final VoidCallback? onResign;

  const BottomBar({
    super.key,
    required this.letters,
    required this.onConfirm,
    this.wordScore, // artık gerekli değil
    required this.onUndo, // 👈 Yeni parametre eklendi
    this.onPass, // ✅ yeni
    this.onResign, // ✅ yeni
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.indigo.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        children: [
          // 🔠 Harf kutuları
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children:
                letters.map((letter) {
                  print("🧩 Drag harfi: $letter"); // DEBUG
                  return Draggable<String>(
                    data: letter,
                    feedback: _buildTile(letter, isDragging: true),
                    childWhenDragging: _buildTile('', isDragging: false),
                    child: _buildTile(letter, isDragging: false),
                  );
                }).toList(),
          ),
          const SizedBox(height: 12),

          // ✅ Butonlar ve skor
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Onayla butonu
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
              const SizedBox(width: 16),

              // Geri Al butonu
              ElevatedButton.icon(
                onPressed: onUndo,
                icon: const Icon(Icons.undo),
                label: const Text("Geri Al"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // ✅ Pas Geç
              ElevatedButton.icon(
                onPressed: onPass,
                icon: const Icon(Icons.pan_tool),
                label: const Text("Pas"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              Text("Skor: ${wordScore ?? 0}"), // null gelirse 0 göster
              // ✅ Çekil
              ElevatedButton.icon(
                onPressed: onResign,
                icon: const Icon(Icons.flag),
                label: const Text("Çekil"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
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
