// test/sound_lab_page.dart
import 'package:flutter/material.dart';
import 'package:pimpampet/sound_effect2.dart';
//import 'package:pim_pam_pet/sound_effect.dart'; // adjust import

class SoundLabPage extends StatefulWidget {
  const SoundLabPage({super.key});

  @override
  State<SoundLabPage> createState() => _SoundLabPageState();
}

class _SoundLabPageState extends State<SoundLabPage> {
  // Controllers for context values
  final _scoreController = TextEditingController(text: '0');
  final _rankChangeController = TextEditingController(text: '0');
  final _skipsController = TextEditingController(text: '0');
  final _playerNameController = TextEditingController();
  final _subjectController = TextEditingController();
  final _letterController = TextEditingController();

  DateTime _selectedDateTime = DateTime.now();

  Future<void> _pickDateTime() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );
      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  SoundContext _buildContext() {
    return SoundContext(
      score: int.tryParse(_scoreController.text) ?? 0,
      rankChange: int.tryParse(_rankChangeController.text) ?? 0,
      playerName: _playerNameController.text.isEmpty ? null : _playerNameController.text,
      subject: _subjectController.text.isEmpty ? null : _subjectController.text,
      letter: _letterController.text.isEmpty ? null : _letterController.text,
      skipsBeforePoint: int.tryParse(_skipsController.text) ?? 0,
      timeOfDay: _selectedDateTime,
      date: _selectedDateTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🔊 Sound Lab')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --- Controls ---
            TextField(
              controller: _scoreController,
              decoration: const InputDecoration(labelText: 'Score'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _rankChangeController,
              decoration: const InputDecoration(labelText: 'Rank change (positive = up)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _skipsController,
              decoration: const InputDecoration(labelText: 'Skips before point'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _playerNameController,
              decoration: const InputDecoration(labelText: 'Player name (optional)'),
            ),
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(labelText: 'Subject (e.g. "bloem")'),
            ),
            TextField(
              controller: _letterController,
              decoration: const InputDecoration(labelText: 'Letter (e.g. "X")'),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(
                'Date & Time: ${_selectedDateTime.toString().substring(0, 16)}',
              ),
              trailing: ElevatedButton(
                onPressed: _pickDateTime,
                child: const Text('Change'),
              ),
            ),
            const SizedBox(height: 32),
            // --- Play Buttons ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => playFirstTone(context: _buildContext()),
                  icon: const Icon(Icons.touch_app),
                  label: const Text('First Tone (Tap Down)'),
                ),
                ElevatedButton.icon(
                  onPressed: () => playSecondTone(context: _buildContext()),
                  icon: const Icon(Icons.touch_app_outlined),
                  label: const Text('Second Tone (Release)'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                await playFirstTone(context: _buildContext());
                // Simulate a quick tap
                await Future.delayed(const Duration(milliseconds: 100));
                await playSecondTone(context: _buildContext());
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Play Full "Dudu" (Both Tones)'),
            ),
            const SizedBox(height: 32),
            // --- Quick Presets ---
            const Divider(),
            const Text('Quick Presets', style: TextStyle(fontSize: 18)),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _scoreController.text = '0';
                    _rankChangeController.text = '0';
                    _skipsController.text = '0';
                    _playerNameController.clear();
                    _subjectController.clear();
                    _letterController.clear();
                    setState(() => _selectedDateTime = DateTime.now());
                  },
                  child: const Text('Neutral'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _scoreController.text = '10';
                    _rankChangeController.text = '3';
                    _skipsController.text = '5';
                    _subjectController.text = 'bloem';
                    _letterController.text = 'X';
                  },
                  child: const Text('High Score + Hard'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _scoreController.text = '1';
                    _rankChangeController.text = '0';
                    _skipsController.text = '12';
                    _playerNameController.text = 'Sophie';
                  },
                  child: const Text('First Point + Many Skips'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _selectedDateTime = DateTime(2025, 4, 1, 12, 0));
                  },
                  child: const Text('April Fools!'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}