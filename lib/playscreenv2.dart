import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pimpampet/pimpampetwidget.dart';
import 'package:pimpampet/randomise.dart';
import 'package:pimpampet/settings_provider.dart';
import 'package:provider/provider.dart';
import 'sound_effect3.dart';

class Playscreen2 extends StatefulWidget {
  const Playscreen2({super.key, required this.names});

  final List<String> names;

  @override
  State<Playscreen2> createState() => _PlayscreenState();
}

class Player {
  final String name;
  int score;
  double scale;
  double streakValue = 0;

  Player(this.name, this.score, {this.scale = 1});
}

class _PlayscreenState extends State<Playscreen2> {
  Timer? _scaleResetTimer;
  String subject = '';
  String randomLetter = '';
  List<Player> players = [];
  bool noArticle = false;
  int skipsInaRow = 0;
  DateTime? _lastPressedTime;
  final _cooldownDuration = Duration(milliseconds: 550);
  final List<String> _scoreGivenToThisRound = [];

  void _newRound() {
    if (_scoreGivenToThisRound.isEmpty) {
      skipsInaRow++;
    } else {
      // reset all the streak values to 0 for players that didn't get a point this round
      for (final player in players) {
        if (!_scoreGivenToThisRound.contains(player.name)) {
          player.streakValue = 0;
        }
      }
      skipsInaRow = 0;
      _scoreGivenToThisRound.clear();
    }

    final (letter, subjectValue, noOne) = randomise();
    setState(() {
      randomLetter = letter;
      subject = subjectValue;
      noArticle = noOne;
    });
  }

  @override
  void initState() {
    _newRound();
    players = List<Player>.generate(widget.names.length, (int index) => Player(widget.names[index], 0));
    setupAudioPlayers();
    super.initState();
  }

  @override
  void dispose() {
    disposeAudioPlayers();
    _scaleResetTimer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, value, child) => Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text('pim pam pet'),
          actions: <Widget>[
            PopupMenuButton<String>(
              onSelected: (value) {}, // you won't really use this anymore
              icon: Icon(Icons.settings),
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem<String>(
                    enabled: false, // prevents closing on tap
                    child: StatefulBuilder(
                      builder: (context, setState) {
                        return Text(
                          "instellingen:",
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                        );
                      },
                    ),
                  ),
                  PopupMenuItem<String>(
                    enabled: false, // prevents closing on tap
                    child: Consumer<SettingsProvider>(
                      builder: (context, settings, _) {
                        return CheckboxListTile(
                          title: Text(
                            "scores sorteren:",
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                          ),
                          value: settings.sortScores,
                          controlAffinity: ListTileControlAffinity.trailing,
                          onChanged: (bool? newValue) {
                            context.read<SettingsProvider>().setSettings(null, newValue);
                          },
                        );
                      },
                    ),
                  ),

                  PopupMenuItem<String>(
                    enabled: false,
                    child: Consumer<SettingsProvider>(
                      builder: (context, settings, _) {
                        return CheckboxListTile(
                          title: Text(
                            "geluid:",
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                          ),
                          value: settings.soundEnabled,
                          controlAffinity: ListTileControlAffinity.trailing,
                          onChanged: (bool? newValue) {
                            context.read<SettingsProvider>().setSettings(newValue, null);
                          },
                        );
                      },
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
        body: Column(
          mainAxisAlignment: .center,
          children: [
            pimpampetWidget(subject, randomLetter, noArticle, true, context),
            const SizedBox(height: 20),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const itemHeight = 70.0;

                  final children = <Widget>[];
                  for (int i = 0; i < players.length; i++) {
                    children.add(
                      AnimatedPositioned(
                        key: ValueKey(players[i].name),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                        top: i * itemHeight,
                          left: 0,
                          right: 0,
                        child: AnimatedScale(
                          scale: players[i].scale,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: _buildItem(players[i], value),
                        ),
                      ),
                    );
                  }
                  
                  children.sort((a, b) {
                    final aScale = (a as AnimatedPositioned).child is AnimatedScale
                        ? ((a.child as AnimatedScale).scale)
                        : 1;
                    final bScale = (b as AnimatedPositioned).child is AnimatedScale
                        ? ((b.child as AnimatedScale).scale)
                        : 1;
                    return aScale.compareTo(bScale);
                  });

                  return SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: 76),
                    child: SizedBox(
                      height: players.length * itemHeight,
                      child: Material(
                        child: Stack(
                          children: children,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _newRound,
          tooltip: 'nieuwe ronde',
          child: const Icon(Icons.refresh),
        ),
      )
    );
  }

  Widget _buildItem(Player player, SettingsProvider value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Align(
        alignment: .center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 550),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTapDown: (test) {
              // if (_lastPressedTime != null && DateTime.now().difference(_lastPressedTime!).inMilliseconds < _cooldownDuration.inMilliseconds) {
              //   print('Action on cooldown');
              //   return;
              // }

              late final int oldIndex;
              if (value.sortScores) {
                final oldOrder = {
                  for (int i = 0; i < players.length; i++) players[i].name: i,
                };
                oldIndex = oldOrder[player.name]!;
              }

              final newPlayerList = List<Player>.from(players);
              final playerIndex = newPlayerList.indexWhere((p) => p.name == player.name);
              newPlayerList[playerIndex] = Player(player.name, player.score + 1);
              //sort newPlayerList to calculate rank change
              newPlayerList.sort((a, b) => b.score.compareTo(a.score));

              //print("old index: $oldIndex, new index: ${newPlayerList.indexWhere((p) => p.name == player.name)}");
              //print(value.sortScores ? oldIndex - newPlayerList.indexWhere((p) => p.name == player.name) : 0);
              if (value.soundEnabled) {
                playFirstTone(context: SoundContext(
                  playerName: player.name,
                  score: player.score + 1, // sound will play as if it will get the point
                  rankChange: value.sortScores ? oldIndex - newPlayerList.indexWhere((p) => p.name == player.name) : 0,
                  streakValue: _scoreGivenToThisRound.contains(player.name) ? player.streakValue :  player.streakValue + 1,
                  subject: subject,
                  letter: randomLetter,
                  skipsBeforePoint: skipsInaRow,
                ));
              }
            },
            onTap: () {
              if (_lastPressedTime != null && DateTime.now().difference(_lastPressedTime!).inMilliseconds < _cooldownDuration.inMilliseconds) {
                return;
              }
              late final int oldIndex;
              _scaleResetTimer?.cancel();
              if (!value.sortScores) {
                setState(() {player.score++;});
              } else {
                final oldOrder = {
                  for (int i = 0; i < players.length; i++) players[i].name: i,
                };
                oldIndex = oldOrder[player.name]!;
            
                setState(() {
                  player.score++;
            
                  // 🔥 Sort list
                  players.sort((a, b) => b.score.compareTo(a.score));
            
                  for (int i = 0; i < players.length; i++) {
                    final p = players[i];
                    final int tempOldIndex = oldOrder[p.name]!;
                    p.scale = i < tempOldIndex ? 1.05 : (i > tempOldIndex ? 0.97 : 1);
                  }
                });
                _scaleResetTimer = Timer(const Duration(milliseconds: 300), () {
                  setState(() {
                    for (final p in players) {
                      p.scale = 1;
                    }
                  });
                });
              }

              _lastPressedTime = DateTime.now();
              if (!_scoreGivenToThisRound.contains(player.name)) {
                player.streakValue++;
                _scoreGivenToThisRound.add(player.name);
              }
          
              if (value.soundEnabled) {
                playSecondTone(context: SoundContext(
                  playerName: player.name,
                  score: player.score,
                  rankChange: value.sortScores ? oldIndex - players.indexOf(player) : 0,
                  streakValue: player.streakValue,
                  subject: subject,
                  letter: randomLetter,
                  skipsBeforePoint: skipsInaRow,
                ));
              }

              
              HapticFeedback.successNotification();
            },
            child: Container(
              height: 60, // IMPORTANT: fixed height
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      player.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 24),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Text(
                      player.score.toString(),
                      key: ValueKey(player.score), 
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 24),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}