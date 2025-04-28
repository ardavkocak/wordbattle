import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/top_bar.dart';
import '../widgets/bottom_bar.dart';
import '../utilize/letter_pool.dart';
import '../utilize/letter_points.dart';
import '../services/api_service.dart';

class GameScreen extends StatefulWidget {
  final int gameId;
  final int userId;

  const GameScreen({super.key, required this.gameId, required this.userId});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final List<String> myLetters = LetterPool.drawLetters(7);
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
    _fetchBoardAndTurn();
    _fetchGameDetails(); // 🔥 isim ve skorları çek
    _startPollingForBoard();
  }

  @override
  void dispose() {
    _boardPollingTimer?.cancel();
    super.dispose();
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

  Future<void> _fetchGameDetails() async {
    final details = await ApiService.fetchGameDetails(widget.gameId);

    if (details != null) {
      setState(() {
        int userId = widget.userId; // giriş yapan kullanıcının ID'si

        if (userId == details['player1_id']) {
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

  void _startPollingForBoard() {
    _boardPollingTimer = Timer.periodic(const Duration(seconds: 2), (
      timer,
    ) async {
      try {
        final fetchedTurn = await ApiService.fetchTurnUserId(
          gameId: widget.gameId,
        );

        if (fetchedTurn != null) {
          bool newIsMyTurn = (fetchedTurn == widget.userId);

          // Eğer sırada değişiklik olduysa mutlaka board'u güncelle
          if (newIsMyTurn != isMyTurn) {
            isMyTurn = newIsMyTurn;

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
          } else {
            // Eğer sıra bizde değilse ve değişiklik yoksa yine de server board'u çekelim
            if (!isMyTurn) {
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
            // Eğer sıra bizdeyse (ve değişiklik yoksa) server'dan board çekmiyoruz ❗
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
                    remainingLetters: LetterPool.remainingLetters,
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
                              int score = calculateWordScore();
                              print('✅ Bu kelimenin puanı: $score');

                              bool success = await ApiService.updateBoard(
                                gameId: widget.gameId,
                                board:
                                    board
                                        .map(
                                          (row) =>
                                              row.map((e) => e ?? "").toList(),
                                        )
                                        .toList(),
                              );

                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Tahta başarıyla güncellendi!',
                                    ),
                                  ),
                                );

                                bool turnChanged = await ApiService.changeTurn(
                                  gameId: widget.gameId,
                                );

                                if (turnChanged) {
                                  print('✅ Sıra başarıyla değiştirildi.');
                                } else {
                                  print('❌ Sıra değiştirilemedi.');
                                }

                                // 🔥 BURASI: Eksik harfleri tamamlama
                                setState(() {
                                  int eksikHarfSayisi = 7 - myLetters.length;
                                  if (eksikHarfSayisi > 0) {
                                    myLetters.addAll(
                                      LetterPool.drawLetters(eksikHarfSayisi),
                                    );
                                  }
                                });

                                await _fetchBoardAndTurn();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      '❌ Tahta güncellenirken hata oluştu',
                                    ),
                                  ),
                                );
                              }
                            }
                            : null,

                    wordScore: calculateWordScore(),
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
}
