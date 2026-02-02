import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

void main() {
  runApp(const DominoApp());
}

enum GameMode { teams, individual }

class DominoApp extends StatelessWidget {
  const DominoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Domino Scorekeeper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

/* ---------------- HOME SCREEN ---------------- */
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Domino Scorekeeper')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.sports_score),
              label: const Text('New Game'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GameSetupScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------- GAME SETUP ---------------- */
class GameSetupScreen extends StatefulWidget {
  const GameSetupScreen({super.key});

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  GameMode mode = GameMode.teams;
  int maxScore = 100;
  int individualPlayersCount = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game Setup')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Game Mode', style: TextStyle(fontSize: 18)),
            RadioListTile<GameMode>(
              title: const Text('Teams (US vs THEM)'),
              value: GameMode.teams,
              groupValue: mode,
              onChanged: (value) => setState(() => mode = value!),
            ),
            RadioListTile<GameMode>(
              title: const Text('Individual Players'),
              value: GameMode.individual,
              groupValue: mode,
              onChanged: (value) => setState(() => mode = value!),
            ),
            if (mode == GameMode.individual) ...[
              const SizedBox(height: 10),
              const Text('Number of Players', style: TextStyle(fontSize: 18)),
              DropdownButton<int>(
                value: individualPlayersCount,
                items: [2, 3, 4].map((e) {
                  return DropdownMenuItem(value: e, child: Text('$e'));
                }).toList(),
                onChanged: (value) =>
                    setState(() => individualPlayersCount = value!),
              ),
            ],
            const SizedBox(height: 20),
            const Text('Max Score', style: TextStyle(fontSize: 18)),
            RadioListTile<int>(
              title: const Text('100 Points'),
              value: 100,
              groupValue: maxScore,
              onChanged: (value) => setState(() => maxScore = value!),
            ),
            RadioListTile<int>(
              title: const Text('200 Points'),
              value: 200,
              groupValue: maxScore,
              onChanged: (value) => setState(() => maxScore = value!),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('Start Game'),
              onPressed: () {
                if (mode == GameMode.teams) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ScoreScreen(
                        maxScore: maxScore,
                        isTeamsMode: true,
                        playersCount: 2,
                        playerNames: const ['US', 'THEM'],
                      ),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ScoreScreen(
                        maxScore: maxScore,
                        isTeamsMode: false,
                        playersCount: individualPlayersCount,
                        playerNames: List.generate(
                          individualPlayersCount,
                              (index) => 'Player ${index + 1}',
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------- SCORE SCREEN (TEAMS & INDIVIDUAL) ---------------- */
class ScoreScreen extends StatefulWidget {
  final int maxScore;
  final bool isTeamsMode;
  final int playersCount;
  final List<String> playerNames;

  const ScoreScreen({
    super.key,
    required this.maxScore,
    required this.isTeamsMode,
    required this.playersCount,
    required this.playerNames,
  });

  @override
  State<ScoreScreen> createState() => _ScoreScreenState();
}

class _ScoreScreenState extends State<ScoreScreen> {
  late List<int> totals;
  late List<TextEditingController> controllers;
  final List<List<int>> roundHistory = [];
  late List<Color> playerColors;

  @override
  void initState() {
    super.initState();
    totals = List.filled(widget.playersCount, 0);
    controllers = List.generate(widget.playersCount, (_) => TextEditingController());

    final List<Color> defaultColors = [
      Colors.green.shade300,
      Colors.red.shade300,
      Colors.blue.shade300,
      Colors.orange.shade300,
      Colors.purple.shade300,
      Colors.teal.shade300,
    ];
    playerColors = List.generate(
      widget.playersCount,
          (i) => defaultColors[i % defaultColors.length],
    );
  }

  @override
  void dispose() {
    for (final c in controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void addRound() {
    final roundPoints = controllers.map((c) {
      final v = int.tryParse(c.text) ?? 0;
      c.clear();
      return v;
    }).toList();

    if (roundPoints.every((p) => p == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least one non-zero score.')),
      );
      return;
    }

    // Determine winner (ONLY ONE winner allowed)
        final maxPoint = roundPoints.reduce(max);

    // Find all players/teams that share the max
        final winnerIndexes = <int>[];
        for (var i = 0; i < roundPoints.length; i++) {
          if (roundPoints[i] == maxPoint && maxPoint > 0) {
            winnerIndexes.add(i);
          }
        }

    // If tie, block the round and ask user to fix it
        if (winnerIndexes.length != 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Empate: solo puede haber un ganador. Ajusta los puntos.'),
            ),
          );
          return;
        }

    // Only the single winner gets points; others get 0
        final adjustedRound = List<int>.filled(roundPoints.length, 0);
        adjustedRound[winnerIndexes.first] = maxPoint;

    setState(() {
      roundHistory.add(adjustedRound);
      for (int i = 0; i < totals.length; i++) {
        totals[i] += adjustedRound[i];
      }
    });

    checkGameOver();
  }

  void undoLastRound() {
    if (roundHistory.isEmpty) return;
    final last = roundHistory.removeLast();
    setState(() {
      for (int i = 0; i < totals.length; i++) {
        totals[i] -= last[i];
      }
    });
  }

  void checkGameOver() {
    final winners = <int>[];
    for (int i = 0; i < totals.length; i++) {
      if (totals[i] >= widget.maxScore) winners.add(i);
    }

    if (winners.isNotEmpty) {
      final winnerNames = winners.map((i) => widget.playerNames[i]).join(', ');
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("Game Complete"),
          content: Text("🎉 $winnerNames WINS! Congratulations!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Review"),
            ),
            TextButton(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text("Home"),
            ),
          ],
        ),
      );
    }
  }

  Color getRoundCellColor(int playerIndex, List<int> round) {
    if (round.isEmpty) {
      return playerColors[playerIndex].withOpacity(0.4);
    }
    final maxPoints = round.reduce(max);
    final isWinner = maxPoints > 0 && round[playerIndex] == maxPoints;
    return playerColors[playerIndex].withOpacity(isWinner ? 0.9 : 0.4);
  }

  @override
  Widget build(BuildContext context) {
    final titleText =
    widget.isTeamsMode ? 'Teams Scoreboard' : 'Individual Scoreboard';

    return Scaffold(
      appBar: AppBar(title: Text(titleText)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: List.generate(widget.playersCount, (index) {
                final label = widget.isTeamsMode
                    ? 'Team ${widget.playerNames[index]}'
                    : widget.playerNames[index];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: TextField(
                      controller: controllers[index],
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        labelText: label,
                        border: const OutlineInputBorder(),
                        contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton(
                  onPressed: addRound,
                  child: const Text('Add Round'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: undoLastRound,
                  child: const Text('Undo'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Round History', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: MediaQuery.of(context).size.width,
                    ),
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        child: Table(
                          border: TableBorder.all(),
                          defaultColumnWidth: const FixedColumnWidth(100),
                          children: [
                            TableRow(
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withOpacity(0.4),
                              ),
                              children: [
                                const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text(
                                    'ROUND',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                ...widget.playerNames.map(
                                      (p) => Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      p,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            ...List.generate(roundHistory.length, (i) {
                              final round = roundHistory[i];
                              return TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text('Round ${i + 1}',
                                        textAlign: TextAlign.center),
                                  ),
                                  ...List.generate(widget.playersCount, (j) {
                                    return Container(
                                      color: getRoundCellColor(j, round),
                                      padding: const EdgeInsets.all(8),
                                      child: Text(
                                        '${round[j]}',
                                        textAlign: TextAlign.center,
                                      ),
                                    );
                                  }),
                                ],
                              );
                            }),
                            TableRow(
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withOpacity(0.5),
                              ),
                              children: [
                                const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text(
                                    'Total',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                ...List.generate(widget.playersCount, (j) {
                                  return Container(
                                    color: playerColors[j].withOpacity(0.6),
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      '${totals[j]}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(widget.playersCount, (i) {
                return Chip(
                  label: Text(
                    '${widget.playerNames[i]}: ${totals[i]}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: playerColors[i].withOpacity(0.25),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}