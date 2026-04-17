// lib/main.dart
// =============================================
// Simple Flutter demo: Procedural "dudu" score sound effect
// - Generated entirely in code (no audio files)
// - Two high-frequency tones played quickly one after the other
// - Slight random variation in pitch every time → never sounds exactly the same
// - Overlapping sounds allowed (click rapidly → multiple "dudu" play at once)
// - Works on Android and Web
// - Haptic feedback included

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';   // for HapticFeedback

void main() {
  runApp(const MyApp3());
}

class MyApp3 extends StatelessWidget {
  const MyApp3({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Score Sound Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // ====================== SOUND PARAMETERS (tweak here!) ======================
  final double fadeRate1 = 8;           // fade strength for each note
  final double fadeRate2 = 5;          // higher value = faster fade-out (more snappy)
  final int minmalDelay = 120; //miliseconds
  final double endVolume = 0.05; // 5% sound volume

  final double frequencyIncrease1 = -1;
  final double frequencyIncrease2 = 1;

  // Frequency ranges (high-pitched "coin/score" feel)
  final double avarageFreq1 = 510;
  final double deviationFreq1 = 200;
  final double avarageFreq2 = 869;
  final double deviationFreq2 = 3;
  // ===========================================================================

  DateTime? _firstToneStartTime;  // Track when first tone started

  // Generate the first tone (plays on touch)
  Uint8List _generateTone(double frequency, double frequencyIncrease, double fadeRate) {
    const int sampleRate = 44100;
    const int channels = 1;
    const int bitsPerSample = 16;
    final List<int> pcm = [];

    final double duration = -math.log(endVolume)/fadeRate;

    final int samples = (duration * sampleRate).round();

    double harmonicTone(double f, double t) {
      return (0.74 * math.sin(2 * math.pi * f * t) +
          0.21 * math.sin(2 * math.pi * 3 * f * t) +
          0.11 * math.sin(2 * math.pi * 5 * f * t) +
          0.04 * math.sin(2 * math.pi * 7 * f * t) +
          0.01 * math.sin(2 * math.pi * 9 * f * t)) /
          (.74 + .21 + .11 + .04 + .01);
    }

    double envelopeFor(double t) {
      final attack = (t / 0.004).clamp(0.0, 1.0);
      final decay = math.exp(-fadeRate * t);
      return attack * decay;
    }

    for (int i = 0; i < samples; i++) {
      final double t = i / sampleRate;
      final double sweep = frequencyIncrease * t;
      final double f = frequency + sweep;
      final double envelope = envelopeFor(t);
      final double sampleValue = harmonicTone(f, t) * envelope;
      final int intSample = (sampleValue * 32767 * 0.6).round().clamp(-32768, 32767);
      pcm.add(intSample);
    }
    
    return _createWav(pcm, sampleRate, channels, bitsPerSample);
  }

  // Creates a valid 16-bit PCM WAV file from raw samples
  Uint8List _createWav(
    List<int> pcmData,
    int sampleRate,
    int numChannels,
    int bitsPerSample,
  ) {
    final int byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    final int blockAlign = numChannels * bitsPerSample ~/ 8;
    final int dataSize = pcmData.length * (bitsPerSample ~/ 8);
    final int riffSize = 36 + dataSize;

    final buffer = ByteData(44 + dataSize);

    // RIFF header
    _writeString(buffer, 0, 'RIFF');
    buffer.setUint32(4, riffSize, Endian.little);
    _writeString(buffer, 8, 'WAVE');

    // fmt sub-chunk
    _writeString(buffer, 12, 'fmt ');
    buffer.setUint32(16, 16, Endian.little);
    buffer.setUint16(20, 1, Endian.little);
    buffer.setUint16(22, numChannels, Endian.little);
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, byteRate, Endian.little);
    buffer.setUint16(32, blockAlign, Endian.little);
    buffer.setUint16(34, bitsPerSample, Endian.little);

    // data sub-chunk
    _writeString(buffer, 36, 'data');
    buffer.setUint32(40, dataSize, Endian.little);

    int offset = 44;
    for (final sample in pcmData) {
      buffer.setInt16(offset, sample, Endian.little);
      offset += 2;
    }

    return buffer.buffer.asUint8List();
  }

  void _writeString(ByteData buffer, int offset, String value) {
    for (int i = 0; i < value.length; i++) {
      buffer.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  Future<void> _playTone(Uint8List wavBytes) async {
    final player = AudioPlayer();

    try {
      await player.play(BytesSource(wavBytes));

      player.onPlayerComplete.first.then((_) {
        player.dispose();
      }).catchError((_) {
        player.dispose();
      });
    } catch (e) {
      debugPrint('Error playing tone: $e');
      player.dispose();
    }
  }

  // Play the first tone on touch
  Future<void> _playFirstTone() async {
    _firstToneStartTime = DateTime.now();

    final wavBytes = await Future(() => _generateTone(
      avarageFreq1 + (math.Random().nextDouble() - 0.5)*2 * deviationFreq1,
      frequencyIncrease1,
      fadeRate1,
    ));

    _playTone(wavBytes);
  }

  // Play the second tone on press/release
  Future<void> _playSecondTone() async {
    final wavBytes = await Future(() => _generateTone(
      avarageFreq2 + (math.Random().nextDouble() - 0.5) * deviationFreq2 *2,
      frequencyIncrease2,
      fadeRate2,
    ));

    if (_firstToneStartTime != null) {
      final elapsed = DateTime.now().difference(_firstToneStartTime!);
      if (elapsed.inMilliseconds < minmalDelay) {
        await Future.delayed(Duration(milliseconds: minmalDelay - elapsed.inMilliseconds));
      }
    }

    _playTone(wavBytes);

    HapticFeedback.successNotification();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Score Sound Demo'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.indigo],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sports_score, size: 120, color: Colors.white),
              const SizedBox(height: 40),
              const Text(
                'Click to score!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Procedural "dudu" sound\ngenerated live in Dart',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
              const SizedBox(height: 60),
              GestureDetector(
                onTapDown: (_) => _playFirstTone(),
                onTapUp: (_) => _playSecondTone(),
                onTapCancel: () async {

                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.play_arrow, size: 36, color: Colors.black),
                      SizedBox(width: 12),
                      Text('SCORE!',
                          style: TextStyle(fontSize: 28, color: Colors.black, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Touch the button for first sound\n'
                'Release on button for second sound\n'
                'Slide away and release to cancel second sound',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.white54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}