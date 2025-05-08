import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/top_bar.dart';
import '../widgets/bottom_bar.dart';
import '../utilize/letter_points.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GameScreen extends StatefulWidget {
  final int gameId;
  final int userId;

  const GameScreen({super.key, required this.gameId, required this.userId});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  List<Map<String, dynamic>> moveHistory = []; // 👈 {row, col, letter}

  int player1TimeLeft = 0;
  int player2TimeLeft = 0;
  int? player1Id;
  int? player2Id;
  Timer? _timePollingTimer;
  int remainingLetters = 0;

  Timer? _checkTimer;

  List<String> myLetters = [];

  List<List<String?>> board = List.generate(
    15,
    (_) => List.generate(15, (_) => null),
  );

  bool isMyTurn = false;
  bool isLoading = true;
  Timer? _boardPollingTimer;

  String myUsername = "";
  String opponentUsername = "";
  int myScore = 0;
  int opponentScore = 0;

  @override
  void initState() {
    super.initState();
    startTimeChecker();
    _fetchInitialLetters();
    _fetchBoardAndTurn();
    _fetchGameDetails();
    _startPollingForBoard();
    _fetchRemainingLetters();
    _startPollingForTime();
  }

  @override
  void dispose() {
    _boardPollingTimer?.cancel();
    _timePollingTimer?.cancel(); // 👈 bu satırı ekle
    _checkTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchRemainingLetters() async {
    final result = await ApiService.getRemainingLetters(gameId: widget.gameId);
    if (result != null && result["remaining"] != null) {
      setState(() {
        remainingLetters = result["remaining"];
      });
    }
  }

  String _extractWordFromBoard(int row, int col) {
    String word = "";

    // Soldan itibaren kelime başlangıcını bul
    int startCol = col;
    while (startCol > 0 && board[row][startCol - 1] != null) {
      startCol--;
    }

    // Sağdan itibaren kelimeyi tamamla
    for (int c = startCol; c < 15 && board[row][c] != null; c++) {
      word += board[row][c]!;
    }

    return word;
  }

  Future<void> _fetchBoardAndTurn() async {
    final fetchedBoard = await ApiService.fetchBoard(widget.gameId);
    final fetchedTurn = await ApiService.fetchTurnUserId(gameId: widget.gameId);

    if (fetchedBoard != null) {
      setState(() {
        board =
            fetchedBoard
                .map((row) => row.map((e) => e.isEmpty ? null : e).toList())
                .toList();
      });
    }

    if (fetchedTurn != null) {
      setState(() {
        isMyTurn = (fetchedTurn == widget.userId);
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _fetchInitialLetters() async {
    print("🚀 _fetchInitialLetters() fonksiyonu çalıştı!");
    final result = await ApiService.drawLetters(
      gameId: widget.gameId,
      userId: widget.userId,
      count: 7,
    );

    print("🛰️ API'den gelen harfler: $result"); // ⬅️ BURAYI EKLE

    if (result != null && result["drawn"] != null) {
      setState(() {
        myLetters = List<String>.from(result["drawn"]);
        print("🎯 myLetters güncellendi: $myLetters"); // ⬅️ BURAYI EKLE
      });
    }
  }

  Future<void> _fetchGameDetails() async {
    final details = await ApiService.fetchGameDetails(widget.gameId);

    if (details != null) {
      // Oyun bittiyse ve ekrandayız, otomatik olarak çık
      if (details['status'] == 'finished') {
        int winnerId = details['winner_id'];
        String message =
            (winnerId == widget.userId)
                ? "🎉 Rakibin çekildi veya süre bitti, oyunu kazandın!"
                : "😢 Oyun sona erdi. Rakibin kazandı.";

        if (mounted) {
          showDialog(
            context: context,
            builder:
                (ctx) => AlertDialog(
                  title: Text("Oyun Bitti"),
                  content: Text(message),
                  actions: [
                    TextButton(
                      child: Text("Tamam"),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(ctx).pop(); // ekrandan çık
                      },
                    ),
                  ],
                ),
          );
        }

        return;
      }

      setState(() {
        player1Id = details['player1_id'];
        player2Id = details['player2_id'];

        if (widget.userId == player1Id) {
          myUsername = details['player1_username'] ?? "Bilinmeyen";
          opponentUsername = details['player2_username'] ?? "Bilinmeyen";
          myScore = details['player1_score'] ?? 0;
          opponentScore = details['player2_score'] ?? 0;
        } else {
          myUsername = details['player2_username'] ?? "Bilinmeyen";
          opponentUsername = details['player1_username'] ?? "Bilinmeyen";
          myScore = details['player2_score'] ?? 0;
          opponentScore = details['player1_score'] ?? 0;
        }
      });
    }
  }

  void _startPollingForTime() {
    _timePollingTimer = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) async {
      final timeData = await ApiService.fetchTimeStatus(widget.gameId);
      if (timeData != null) {
        setState(() {
          player1TimeLeft = timeData["player1_time_left"].round();
          player2TimeLeft = timeData["player2_time_left"].round();
        });
      }
    });
  }

  void _startPollingForBoard() {
    _boardPollingTimer = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) async {
      try {
        // 1. Oyunun detaylarını al (sıra, durum, vs.)
        final details = await ApiService.fetchGameDetails(widget.gameId);

        if (details != null) {
          // 1.5 🔥 Skorları güncelle
          setState(() {
            myScore =
                (widget.userId == details["player1_id"])
                    ? details["player1_score"]
                    : details["player2_score"];
            opponentScore =
                (widget.userId == details["player1_id"])
                    ? details["player2_score"]
                    : details["player1_score"];
          });

          // 2. Oyun bitmiş mi kontrol et
          if (details["status"] == "finished") {
            int winnerId = details["winner_id"];
            String resultMessage =
                winnerId == widget.userId
                    ? "🎉 Tebrikler, oyunu kazandınız!"
                    : "😢 Üzgünüz, rakibiniz oyunu kazandı.";

            showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: const Text("Oyun Bitti"),
                    content: Text(resultMessage),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // dialog kapat
                          Navigator.of(context).pop(); // ekrandan çık
                        },
                        child: const Text("Tamam"),
                      ),
                    ],
                  ),
            );

            timer.cancel(); // polling'i durdur
            return;
          }

          // 3. Sıra kontrolü
          final fetchedTurn = details["turn_user_id"];
          if (fetchedTurn != null) {
            bool newIsMyTurn = (fetchedTurn == widget.userId);

            if (newIsMyTurn != isMyTurn) {
              print("🎯 Sıra değişti!");
              final fetchedBoard = await ApiService.fetchBoard(widget.gameId);
              if (fetchedBoard != null) {
                setState(() {
                  board =
                      fetchedBoard
                          .map(
                            (row) =>
                                row.map((e) => e.isEmpty ? null : e).toList(),
                          )
                          .toList();
                  isMyTurn = newIsMyTurn;
                });
              }
            } else if (!isMyTurn) {
              final fetchedBoard = await ApiService.fetchBoard(widget.gameId);
              if (fetchedBoard != null) {
                setState(() {
                  board =
                      fetchedBoard
                          .map(
                            (row) =>
                                row.map((e) => e.isEmpty ? null : e).toList(),
                          )
                          .toList();
                });
              }
            }
          }
        }
      } catch (e) {
        print('Polling sırasında hata oluştu: $e');
      }
    });
  }

  static final Map<String, List<List<int>>> specialTiles = {
    "H2": [
      [0, 3],
      [0, 11],
      [2, 6],
      [2, 8],
      [3, 0],
      [3, 7],
      [3, 14],
      [6, 2],
      [6, 6],
      [6, 8],
      [6, 12],
      [7, 3],
      [7, 11],
      [8, 2],
      [8, 6],
      [8, 8],
      [8, 12],
      [11, 0],
      [11, 7],
      [11, 14],
      [12, 6],
      [12, 8],
      [14, 3],
      [14, 11],
    ],
    "H3": [
      [1, 5],
      [1, 9],
      [5, 1],
      [5, 5],
      [5, 9],
      [5, 13],
      [9, 1],
      [9, 5],
      [9, 9],
      [9, 13],
      [13, 5],
      [13, 9],
    ],
    "K2": [
      [1, 1],
      [2, 2],
      [3, 3],
      [4, 4],
      [10, 10],
      [11, 11],
      [12, 12],
      [13, 13],
      [1, 13],
      [2, 12],
      [3, 11],
      [4, 10],
      [10, 4],
      [11, 3],
      [12, 2],
      [13, 1],
    ],
    "K3": [
      [0, 0],
      [0, 7],
      [0, 14],
      [7, 0],
      [7, 14],
      [14, 0],
      [14, 7],
      [14, 14],
    ],
    "STAR": [
      [7, 7],
    ],
  };

  @override
  Widget build(BuildContext context) {
    print("🧪 GameScreen başlatıldı!");

    return Scaffold(
      appBar: AppBar(title: Text('Oyun ID: ${widget.gameId}')),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  TopBar(
                    myUsername: myUsername,
                    myScore: myScore,
                    opponentUsername: opponentUsername,
                    opponentScore: opponentScore,
                    remainingLetters: remainingLetters,
                    myTimeLeft:
                        widget.userId == player1Id
                            ? player1TimeLeft
                            : player2TimeLeft,
                    opponentTimeLeft:
                        widget.userId == player1Id
                            ? player2TimeLeft
                            : player1TimeLeft,
                  ),

                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      isMyTurn ? "🎯 Sıra sizde!" : "⏳ Rakip oynuyor...",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GridView.builder(
                        itemCount: 15 * 15,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 15,
                            ),
                        itemBuilder: (context, index) {
                          int row = index ~/ 15;
                          int col = index % 15;

                          return DragTarget<String>(
                            onAccept: (receivedLetter) {
                              if (!isMyTurn) return;
                              setState(() {
                                if (board[row][col] == null) {
                                  board[row][col] = receivedLetter;
                                  myLetters.remove(receivedLetter);

                                  moveHistory.add({
                                    "row": row,
                                    "col": col,
                                    "letter": receivedLetter,
                                  });
                                }
                              });
                            },
                            builder: (context, candidateData, rejectedData) {
                              final currentLetter = board[row][col];
                              final currentCellType = _getCellType(row, col);

                              Color color;
                              String text;

                              if (currentLetter != null) {
                                color = Colors.white;
                                text = currentLetter;
                              } else if (currentCellType == "H2") {
                                color = Colors.blue.shade300;
                                text = "H²";
                              } else if (currentCellType == "H3") {
                                color = Colors.pink.shade300;
                                text = "H³";
                              } else if (currentCellType == "K2") {
                                color = Colors.green.shade200;
                                text = "K²";
                              } else if (currentCellType == "K3") {
                                color = Colors.brown.shade300;
                                text = "K³";
                              } else if (currentCellType == "STAR") {
                                color = Colors.yellow.shade400;
                                text = "★";
                              } else {
                                color = Colors.grey.shade300;
                                text = "";
                              }

                              return Container(
                                margin: const EdgeInsets.all(1),
                                decoration: BoxDecoration(
                                  color: color,
                                  border: Border.all(color: Colors.black26),
                                ),
                                child: Center(
                                  child: Text(
                                    text,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  BottomBar(
                    letters: myLetters,
                    onConfirm:
                        isMyTurn
                            ? () async {
                              final lastMove =
                                  moveHistory.isNotEmpty
                                      ? moveHistory.last
                                      : null;
                              if (lastMove == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Hamle yapılmadan onaylanamaz.",
                                    ),
                                  ),
                                );
                                return;
                              }

                              int row = lastMove["row"];
                              int col = lastMove["col"];
                              String formedWord = _extractWordFromBoard(
                                row,
                                col,
                              );
                              print("🧪 Kontrol edilen kelime: '$formedWord'");

                              String result = await AuthService.checkWord(
                                formedWord,
                              );
                              print("🧠 Backend kelime sonucu: $result");

                              if (result.contains("Geçersiz")) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "❌ Geçersiz kelime: $formedWord",
                                    ),
                                  ),
                                );
                                return;
                              }

                              setState(() {
                                for (var move in moveHistory) {
                                  int r = move["row"];
                                  int c = move["col"];
                                  print(
                                    "🟩 Harf onaylandı: ${move["letter"]} @ [$r, $c]",
                                  );
                                }
                              });

                              final response = await ApiService.makeMove(
                                gameId: widget.gameId,
                                userId: widget.userId,
                                board:
                                    board
                                        .map(
                                          (row) =>
                                              row.map((e) => e ?? "").toList(),
                                        )
                                        .toList(),
                                placedTiles: moveHistory,
                              );

                              if (response != null) {
                                setState(() {
                                  myScore = response["your_score"];
                                  opponentScore = response["opponent_score"];
                                });

                                final mines = List<String>.from(
                                  response["triggered_mines"] ?? [],
                                );
                                final rewards = List<String>.from(
                                  response["triggered_rewards"] ?? [],
                                );
                                final score = response["score"] ?? 0;

                                if (mines.isNotEmpty || rewards.isNotEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "⛏️ Mayınlar: ${mines.join(', ')} | 🎁 Ödüller: ${rewards.join(', ')}\nSkor: $score",
                                      ),
                                    ),
                                  );
                                }

                                if (mines.contains("reset_letters")) {
                                  setState(() {
                                    myLetters.clear();
                                  });
                                  final drawResult =
                                      await ApiService.drawLetters(
                                        gameId: widget.gameId,
                                        userId: widget.userId,
                                        count: 7,
                                      );
                                  if (drawResult != null &&
                                      drawResult["drawn"] != null) {
                                    setState(() {
                                      myLetters = List<String>.from(
                                        drawResult["drawn"],
                                      );
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "🌀 Harfler sıfırlandı ve yeni harfler çekildi!",
                                        ),
                                      ),
                                    );
                                  }
                                } else {
                                  int eksikHarfSayisi = 7 - myLetters.length;
                                  if (eksikHarfSayisi > 0) {
                                    final drawResult =
                                        await ApiService.drawLetters(
                                          gameId: widget.gameId,
                                          userId: widget.userId,
                                          count: eksikHarfSayisi,
                                        );
                                    if (drawResult != null &&
                                        drawResult["drawn"] != null) {
                                      setState(() {
                                        myLetters.addAll(
                                          List<String>.from(
                                            drawResult["drawn"],
                                          ),
                                        );
                                      });
                                    }
                                  }
                                }

                                for (var mine
                                    in response["triggered_mines"] ?? []) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "💣 Mayın tetiklendi: $mine",
                                      ),
                                    ),
                                  );
                                }

                                for (var reward
                                    in response["triggered_rewards"] ?? []) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "🎁 Ödül kazanıldı: $reward",
                                      ),
                                    ),
                                  );
                                }

                                await _fetchBoardAndTurn();
                                await _fetchGameDetails();
                                await _fetchRemainingLetters();
                                moveHistory.clear();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Hamle gönderilemedi."),
                                  ),
                                );
                              }
                            }
                            : null,

                    onUndo: () {
                      setState(() {
                        if (moveHistory.isNotEmpty) {
                          final lastMove = moveHistory.removeLast();
                          int row = lastMove["row"];
                          int col = lastMove["col"];
                          String letter = lastMove["letter"];

                          board[row][col] = null;
                          myLetters.add(letter);
                        }
                      });
                    },

                    onPass: _handlePass,
                    onResign: _handleResign,
                  ),
                ],
              ),
    );
  }

  String? _getCellType(int row, int col) {
    for (var entry in specialTiles.entries) {
      if (entry.value.any((pos) => pos[0] == row && pos[1] == col)) {
        return entry.key;
      }
    }
    return null;
  }

  int calculateWordScore() {
    int score = 0;
    int wordMultiplier = 1;

    for (int row = 0; row < 15; row++) {
      for (int col = 0; col < 15; col++) {
        final letter = board[row][col];
        if (letter != null) {
          int letterScore = LetterPoints.points[letter.toUpperCase()] ?? 0;

          String? cellType = _getCellType(row, col);
          if (cellType == "H2") {
            letterScore *= 2;
          } else if (cellType == "H3") {
            letterScore *= 3;
          } else if (cellType == "K2") {
            wordMultiplier *= 2;
          } else if (cellType == "K3") {
            wordMultiplier *= 3;
          }

          score += letterScore;
        }
      }
    }

    return score * wordMultiplier;
  }

  void _handlePass() async {
    final response = await http.post(
      Uri.parse(
        'http://localhost:8000/game/pass?game_id=${widget.gameId}&user_id=${widget.userId}',
      ),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("🙋 Pas geçildi: $data");

      if (data["game_status"] == "finished") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🏁 Oyun sona erdi. Her iki oyuncu da 2 pas geçti."),
          ),
        );
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        await _fetchGameDetails(); // turn_user_id değiştiği için güncelle
        await _fetchBoardAndTurn();
        await _fetchRemainingLetters();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Pas geçerken hata oluştu.")),
      );
    }
  }

  void _handleResign() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Çekil"),
            content: const Text("Oyundan çekilmek istediğine emin misin?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("İptal"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Evet"),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    final response = await http.post(
      Uri.parse(
        'http://localhost:8000/game/resign?game_id=${widget.gameId}&user_id=${widget.userId}',
      ),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("🏳️ Oyundan çekildi: $data");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Oyundan çekildiniz. Oyun sona erdi.")),
      );
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Çekilme işlemi başarısız.")),
      );
    }
  }

  void startTimeChecker() {
    _checkTimer = Timer.periodic(Duration(seconds: 1), (_) {
      checkAndFinishIfTimeout();
    });
  }

  Future<void> checkAndFinishIfTimeout() async {
    final url = Uri.parse(
      'http://localhost:8000/game/check-time-and-finish?game_id=${widget.gameId}',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["message"] == "Süre bitti. Oyun sona erdi.") {
        int winnerId = data["winner_id"];
        String resultMessage =
            winnerId == widget.userId
                ? "⏳ Rakibin süresi bitti! Oyunu kazandın! 🎉"
                : "😢 Süren dolduğu için oyunu kaybettin.";

        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text("Oyun Bitti"),
                content: Text(resultMessage),
                actions: [
                  TextButton(
                    child: Text("Tamam"),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop(); // Oyundan çık
                    },
                  ),
                ],
              ),
        );

        _checkTimer?.cancel();
      }
    }
  }
}
