// lib/sound_effect.dart
// =============================================
// Context-aware procedural score sound for "Pim Pam Pet"
// - Responds to score, rank change, subject, letter, etc.
// - Uses Gaussian (normal) pitch variation
// - Two high-frequency tones with dynamic shaping
// - Overlapping sounds allowed
// - Works on Android and Web

import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

// ====================== CONTEXT CLASS ======================
/// Pass whatever game state you want the sound to react to.
class SoundContext {
  final int score;                 // new total points
  final int rankChange;            // positions climbed (positive = up)
  final String? playerName;
  final String? subject;
  final String? letter;
  final int skipsBeforePoint;
  final DateTime? timeOfDay;
  final DateTime? date;

  const SoundContext({
    this.score = 0,
    this.rankChange = 0,
    this.playerName,
    this.subject,
    this.letter,
    this.skipsBeforePoint = 0,
    this.timeOfDay,
    this.date,
  });
}

// ====================== SOUND PROFILE ======================
/// Internal structure holding the final parameters for a tone.
class _SoundProfile {
  final double baseFreq;
  final double freqStdDev;         // standard deviation for normal random
  final double freqSweep;          // frequency increase per second
  final double fadeRate;
  final double harmonicBrightness; // 0..1, affects harmonic mix
  final double volume;

  const _SoundProfile({
    required this.baseFreq,
    required this.freqStdDev,
    required this.freqSweep,
    required this.fadeRate,
    required this.harmonicBrightness,
    required this.volume,
  });
}

// ====================== DEFAULT PARAMETERS ======================
// These are the base values; context will modify them.
const double _baseFreq1 = 520.0;
const double _baseFreq2 = 880.0;
const double _baseFade1 = 8.0;
const double _baseFade2 = 5.5;
const double _baseSweep1 = -0.8;    // slight downward sweep for first tone
const double _baseSweep2 = 1.2;     // slight upward sweep for second tone
const double _baseStdDev1 = 30.0;   // normal std dev in Hz
const double _baseStdDev2 = 15.0;
const double _endVolume1 = 0.09;     // 5% 
const double _endVolume2 = 0.03;     // 3%
const int _baseMinDelayMs = 150;

const Set<String> _hardLetters = {'X', 'Y', 'Z', 'Q', 'F', 'C', 'I', 'J', 'U', 'N'};
const Set<String> _hardSubjects = {'bloem', 'vis', 'schilder', 'beeldhouwer', 'schrijver', 'dichter', 'berg', 'bergketen', 'kanaal', 'rivier', 'muziekinstrument', 'stad', 'boom', 'vogel'};
AudioPlayer _firstAudioPlayer = AudioPlayer();
bool _isFirstPlayerAvailable = true;
AudioPlayer _secondAudioPlayer = AudioPlayer();
bool _isSecondPlayerAvailable = true;
bool _secondPlayerHasSound = false;

double _easeInOutQuad(double x) {
  return x < 0.5 ? 2 * x * x : 1 - math.pow(-2 * x + 2, 2) / 2;
}

Future<void> setupAudioPlayers() async {
  await _firstAudioPlayer.setAudioContext(
    AudioContext(
      android: AudioContextAndroid(
        contentType: AndroidContentType.sonification,
        usageType: AndroidUsageType.assistanceSonification,
        audioFocus: AndroidAudioFocus.none,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.ambient,
      ),
    ),
  );
  await _secondAudioPlayer.setAudioContext(
    AudioContext(
      android: AudioContextAndroid(
        contentType: AndroidContentType.sonification,
        usageType: AndroidUsageType.assistanceSonification,
        audioFocus: AndroidAudioFocus.none,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.ambient,
      ),
    ),
  );
}

// ====================== NORMAL RANDOM HELPER ======================
double _gaussianRandom({double mean = 0.0, double stdDev = 1.0}) {
  // Box-Muller transform using two uniform randoms
  final rng = math.Random();
  final u1 = rng.nextDouble();
  final u2 = rng.nextDouble();
  final z = math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2);
  return mean + stdDev * z;
}

// ====================== BUILD PROFILE FROM CONTEXT ======================
_SoundProfile _buildProfile(SoundContext? ctx, bool isFirstTone) {
  // Start with base values
  double freq = isFirstTone ? _baseFreq1 : _baseFreq2;
  double stdDev = isFirstTone ? _baseStdDev1 : _baseStdDev2;
  double sweep = isFirstTone ? _baseSweep1 : _baseSweep2;
  double fade = isFirstTone ? _baseFade1 : _baseFade2;
  double brightness = 0.5; // neutral
  double volume = .55;

  if (ctx != null) {
    // --- Score influence: higher score → higher pitch (max +60 Hz) ---
    freq += (ctx.score * 0.1).clamp(0.0, 60);

    // --- Rank change influence ---
    // Climbing feels more exciting → wider deviation, snappier fade, faster sweep
    double climb = math.pow(math.min(ctx.rankChange, 5), 2).toDouble();
    climb *= ctx.score == 1 ? 0 : ctx.score == 2 ? 0.6 : 1.0; // first and second points are less exciting
    fade += climb * .2;
    sweep += (isFirstTone ? -0.8 : 1.0) * climb * 0.5;
    // Also raise pitch slightly for big climbs
    freq += climb * 10;

    // --- Skips influence: more relief/excitement when point is scored ---
    freq -= isFirstTone ? (ctx.skipsBeforePoint / 2).clamp(0, 40) : (ctx.skipsBeforePoint / 3).clamp(0, 40);
    stdDev += isFirstTone ? (ctx.skipsBeforePoint / 5).clamp(0, 20) : 0;
    fade -= (ctx.skipsBeforePoint / 6).clamp(0, 3); // more skips = smoother fade
    volume += (ctx.skipsBeforePoint / 50).clamp(0, .07); // more skips = louder to feel more rewarding

    // --- hard Letter and hard Subject influence ---
    double difficultyInfluence = 0;
    if (ctx.letter != null && _hardLetters.contains(ctx.letter!.toUpperCase())) {
      difficultyInfluence = 1;
    }
    if (ctx.subject != null && ctx.subject!.toLowerCase().split(' ').any(_hardSubjects.contains)) {
      difficultyInfluence += 1;
    }
    fade += .5 * difficultyInfluence; // harder letters get a snappier sound
    stdDev -= isFirstTone ? 5 * difficultyInfluence : 0; // and less pitch variation on first tone 
    freq += (isFirstTone ? -0 : 15) * difficultyInfluence; // and slightly higher pitch
    //sweep += (isFirstTone ? -0.4 : 0.5) * difficultyInfluence;
    volume += 0.04 * difficultyInfluence; // and louder
    brightness -= 0.2 * difficultyInfluence;

    final now = ctx.timeOfDay ?? DateTime.now();
    final bool isAprilFirst = now.month == 4 && now.day == 1;
    
    // --- Player name consistency (same player always gets same offset) ---
    if (ctx.playerName != null && ctx.playerName!.isNotEmpty) {
      final int nameHash = ctx.playerName!.codeUnits.fold(0, (sum, c) => sum + c);
      freq += (nameHash % 21 - 10).toDouble(); // ±10 Hz
      brightness += isAprilFirst ? (nameHash % 7 - 3) / 60 : (nameHash % 7 - 3) / 100; // ±0.03 brightness (±0.05 on April 1st)
      //print('Name hash: $nameHash, freq offset: ${(nameHash % 21 - 10)}, brightness offset: ${((nameHash % 7 - 3) / 100)}');
    }

    // --- Time of day subtle variation ---
    final hour = now.hour;

    if (now.month == 1 && now.day == 1) {
      // late transition on new years day (transition between 00:00 and 1:00 and transition between 7:00 and 8:00) slightly softer / lower
      if (hour >= 18 || hour < 8) {
        final double transitionValue = hour == 18 ? _easeInOutQuad(now.minute / 60) : hour == 0 ? _easeInOutQuad(now.minute / 60) : hour == 7 ? _easeInOutQuad(1 - now.minute / 60) : 1;
        freq -= 10 * transitionValue;
        fade *= 0.9 + 0.1 * (1 - transitionValue);
        volume *= 0.9 + 0.1 * (1 - transitionValue);
      }
    } else {
      // Evening (transition between 18:00 and 19:00 and transition between 7:00 and 8:00) slightly softer / lower
      if (hour >= 18 && !(now.month == 12 && now.day == 31) || hour < 8) {
        final double transitionValue = hour == 18 ? _easeInOutQuad(now.minute / 60) : hour == 7 ? _easeInOutQuad(1 - now.minute / 60) : 1;
        freq -= isFirstTone ? 0 : 10 * transitionValue;
        fade *= 0.9 + 0.1 * (1 - transitionValue);
        volume *= 0.9 + 0.1 * (1 - transitionValue);
        //print(transitionValue);
      }
      if (isAprilFirst) { // April Fools' Day gets a random pitch shift and brightness
        stdDev += isFirstTone ? 10 : 2; // more pitch variation for fun
        brightness += (math.Random().nextDouble() -.5) * 0.4; // ±0.2 random brightness shift
      }
    }
  }

  return _SoundProfile(
    baseFreq: freq,
    freqStdDev: stdDev,
    freqSweep: sweep,
    fadeRate: fade,
    harmonicBrightness: brightness.clamp(0, 1), 
    volume: volume,
  );
}

// ====================== TONE GENERATION ======================
Uint8List _generateTone(_SoundProfile profile, bool isFirstTone) {
  const int sampleRate = 44100;
  const int channels = 1;
  const int bitsPerSample = 16;
  final List<int> pcm = [];

  // Apply normal deviation
  final frequency = _gaussianRandom(mean: profile.baseFreq, stdDev: profile.freqStdDev);

  final double duration = -math.log(isFirstTone ? _endVolume1 : _endVolume2) / profile.fadeRate;
  print('duration: $duration seconds, is first tone: $isFirstTone');
  final int samples = (duration * sampleRate).round();

  // Harmonic mix based on brightness
  // Brightness 0 → only fundamental (dull)
  // Brightness 1 → full harmonic series (bright)
  double harmonicTone(double f, double t) {
    final w = 2 * math.pi * f * t;
    final fund = math.sin(w);
    final h3 = math.sin(3 * w);
    final h5 = math.sin(5 * w);
    final h7 = math.sin(7 * w);
    final h9 = math.sin(9 * w);

    // Even harmonics added when brightness > 0.5
    final h2 = profile.harmonicBrightness > 0.5
        ? math.sin(2 * w)
        : 0.0;
    final h4 = profile.harmonicBrightness > 0.5
        ? math.sin(4 * w)
        : 0.0;

    // Mix coefficients (normalised)
    const a1 = 0.70;
    final a3 = 0.20 * (0.7 + 0.6 * profile.harmonicBrightness);
    final a5 = 0.10 * (0.5 + 1.0 * profile.harmonicBrightness);
    final a7 = 0.04;
    final a9 = 0.01;

    final a2 = profile.harmonicBrightness > 0.5
        ? (profile.harmonicBrightness - 0.5) * 2
        : 0.0;
    final a4 = profile.harmonicBrightness > 0.5
        ? (profile.harmonicBrightness - 0.5) * 1.5
        : 0.0;

    final sum = a1 + a3 + a5 + a7 + a9 + a2 + a4;
    return (a1*fund + a3*h3 + a5*h5 + a7*h7 + a9*h9 + a2*h2 + a4*h4) / sum;
  }

  double envelopeFor(double t) {
    // Attack (quick)
    final attack = (t / 0.003).clamp(0.0, 1.0);
    // Decay
    final decay = math.exp(-profile.fadeRate * t);
    // Gentle release to avoid click at end
    final release = t > duration - 0.02
        ? 1.0 - ((t - (duration - 0.02)) / 0.02).clamp(0.0, 1.0)
        : 1.0;
    return attack * decay * release;
  }

  for (int i = 0; i < samples; i++) {
    final double t = i / sampleRate;
    // Frequency sweep
    final double sweep = profile.freqSweep * t;
    final double f = frequency + sweep;
    final double envelope = envelopeFor(t);
    final double sampleValue = harmonicTone(f, t) * envelope;
    // Slightly lower volume to avoid harshness
    final int intSample = (sampleValue * 32767 * profile.volume).round().clamp(-32768, 32767);
    pcm.add(intSample);
  }

  return _createWav(pcm, sampleRate, channels, bitsPerSample);
}

// ====================== WAV CREATION ======================
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

  _writeString(buffer, 0, 'RIFF');
  buffer.setUint32(4, riffSize, Endian.little);
  _writeString(buffer, 8, 'WAVE');

  _writeString(buffer, 12, 'fmt ');
  buffer.setUint32(16, 16, Endian.little);
  buffer.setUint16(20, 1, Endian.little);
  buffer.setUint16(22, numChannels, Endian.little);
  buffer.setUint32(24, sampleRate, Endian.little);
  buffer.setUint32(28, byteRate, Endian.little);
  buffer.setUint16(32, blockAlign, Endian.little);
  buffer.setUint16(34, bitsPerSample, Endian.little);

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

// ====================== PLAYBACK ======================
DateTime? _firstToneStartTime;
int _currentMinDelayMs = _baseMinDelayMs;

AudioPlayer createNewAudioPlayer() {
  final player = AudioPlayer();
  player.setAudioContext(
    AudioContext(
      android: AudioContextAndroid(
        contentType: AndroidContentType.sonification,
        usageType: AndroidUsageType.assistanceSonification,
        audioFocus: AndroidAudioFocus.none,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.ambient,
      ),
    ),
  );
  return player;
}

Future<void> _playTone(Uint8List? wavBytes, bool isFirstTone) async {
  final AudioPlayer player;
  bool isNewPlayer = false;
  if (isFirstTone) {
    if (_isFirstPlayerAvailable) {
      player = _firstAudioPlayer;
      _isFirstPlayerAvailable = false;
    } else {
      player = createNewAudioPlayer();
      isNewPlayer = true;
    }
  } else {
    if (_isSecondPlayerAvailable) {
      player = _secondAudioPlayer;
      _isSecondPlayerAvailable = false;
    } else {
      player = createNewAudioPlayer();
      isNewPlayer = true;
    }
  }
  // print(_isFirstPlayerAvailable);
  // print(_isSecondPlayerAvailable);

  if (wavBytes != null) {
    await player.setSource(BytesSource(wavBytes));
  }
  // await Future.delayed(const Duration(milliseconds: 8));
  await player.resume();
  //player.play(BytesSource(wavBytes));
  
      // ✅ 1. Normal completion
    player.onPlayerComplete.first.then((_) {
      if (isFirstTone) {
        _isFirstPlayerAvailable = true;
      } else {
        _isSecondPlayerAvailable = true;
      }
      //print('done');
      if (isNewPlayer) {
        player.dispose();
      }
    }).catchError((_) {
      // ✅ 2. Error during playback
      if (isFirstTone) {
        _isFirstPlayerAvailable = true;
      } else {
        _isSecondPlayerAvailable = true;
      }
      print('error');
      if (isNewPlayer) {
        player.dispose();
      }
    });
}

// ====================== PUBLIC API ======================
/// Call on tap down. Pass context for adaptive sound.
Future<void> playFirstTone({SoundContext? context}) async {
  final profile = _buildProfile(context, true);

  // Calculate dynamic min delay based on rank change
  //final climb = context?.rankChange ?? 0;
  _currentMinDelayMs = _baseMinDelayMs; //- (climb * 8).clamp(0, 40).toInt();

  final wavBytes = await Future(() => _generateTone(profile, true));
  _firstToneStartTime = DateTime.now();
  _playTone(wavBytes, true);
  if (_isSecondPlayerAvailable) {
    // Pre-generate second tone for faster response on tap up
    final secondProfile = _buildProfile(context, false);
    Future(() {
      final secondWavBytes = _generateTone(secondProfile, false);
      _secondPlayerHasSound = true;
      _secondAudioPlayer.setSource(BytesSource(secondWavBytes));
    });
  }
}

/// Call on tap up (release).
Future<void> playSecondTone({SoundContext? context}) async {
  late final Uint8List wavBytes;
  if (!_secondPlayerHasSound) {
    final profile = _buildProfile(context, false);
    wavBytes = await Future(() => _generateTone(profile, false));
  }

  if (_firstToneStartTime != null) {
    final elapsed = DateTime.now().difference(_firstToneStartTime!);
    final delayNeeded = _currentMinDelayMs - elapsed.inMilliseconds;
    if (delayNeeded > 0) {
      await Future.delayed(Duration(milliseconds: delayNeeded));
    }
  }
  if (_secondPlayerHasSound) {
    _playTone(null, false);
    _secondPlayerHasSound = false;
    return;
  }
  _playTone(wavBytes, false);
}