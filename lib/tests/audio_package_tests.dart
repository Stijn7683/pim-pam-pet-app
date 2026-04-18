import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const AudioTestApp());
}

class AudioTestApp extends StatelessWidget {
  const AudioTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: AudioTestPage(),
    );
  }
}

class AudioTestPage extends StatefulWidget {
  const AudioTestPage({super.key});

  @override
  State<AudioTestPage> createState() => _AudioTestPageState();
}

class _AudioTestPageState extends State<AudioTestPage> {
  // Audioplayers
  final AudioPlayer _audioPlayer = AudioPlayer();

  // SoLoud
  final SoLoud _soLoud = SoLoud.instance;
  AudioSource? _soLoudSource;

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    await _setupAudioPlayer();
    await _initSoLoud();
  }

  Future<void> _setupAudioPlayer() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.stop);
    await _audioPlayer.setPlayerMode(PlayerMode.lowLatency);
  }

  Future<void> _initSoLoud() async {
    await _soLoud.init();
    _soLoudSource = await _soLoud.loadAsset('assets/testsound.wav');
  }

  Future<void> _playAudioplayers() async {
    await _audioPlayer.play(AssetSource('testsound.wav'));
  }

  Future<void> _playSoLoud() async {
    if (_soLoudSource != null) {
      _soLoud.play(_soLoudSource!);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _soLoud.deinit();
    super.dispose();
  }

  Widget _buildButton(String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton(
        onPressed: onTap,
        child: Text(title),
      ),
    );
  }

  void _spam(Function fn) {
    for (int i = 0; i < 5; i++) {
      fn();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audio Package Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Tap buttons to test audio packages'),
            const SizedBox(height: 20),

            _buildButton('Play with audioplayers', _playAudioplayers),
            _buildButton('Play with flutter_soloud', _playSoLoud),

            const SizedBox(height: 40),
            const Text('Spam test (tap fast!)'),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => _spam(_playAudioplayers),
                  child: const Text('Spam audioplayers'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _spam(_playSoLoud),
                  child: const Text('Spam SoLoud'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
