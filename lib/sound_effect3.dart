// lib/sound_effect.dart
// =============================================
// Context-aware procedural score sound for "Pim Pam Pet"
// - Responds to score, rank change, subject, letter, etc.
// - Uses Gaussian (normal) pitch variation
// - Two high-frequency tones with dynamic shaping
// - Overlapping sounds allowed
// - Works on Android and Web

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

// ====================== CONTEXT CLASS ======================
/// Pass whatever game state you want the sound to react to.
class SoundContext {
  final String? playerName;
  final int score;                 // new total points
  final int rankChange;
  final double streakValue;
  final String? subject;
  final String? letter;
  final int skipsBeforePoint;
  final DateTime? time;

  const SoundContext({
    this.playerName,
    this.score = 0,
    this.rankChange = 0,
    this.streakValue = 0,
    this.subject,
    this.letter,
    this.skipsBeforePoint = 0,
    this.time,
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
const double _endVolume2 = 0.02;     // 2%
const int _minDelayBetweenTonesMs = 200;

const Set<String> _hardLetters = {'X', 'Y', 'Z', 'Q', 'F', 'C', 'I', 'J', 'U', 'N'};
const Set<String> _hardSubjects = {'bloem', 'vis', 'schilder', 'beeldhouwer', 'schrijver', 'dichter', 'berg', 'bergketen', 'kanaal', 'rivier', 'muziekinstrument', 'stad', 'boom', 'vogel'};
final SoLoud _soLoud = SoLoud.instance;

Future<void> setupAudioPlayers() async {
  await _soLoud.init();
}

void disposeAudioPlayers() {
  _soLoud.deinit();
}

double _easeInOutQuad(double x) {
  return x < 0.5 ? 2 * x * x : 1 - math.pow(-2 * x + 2, 2) / 2;
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
    // --- streakValue change influence ---
    //print('streakValue: ${ctx.streakValue}');
    double streakImpact = math.pow(math.min(ctx.streakValue -1, 7), 1.6).toDouble(); 
    fade += streakImpact * .1;
    sweep += (isFirstTone ? -0.4 : .5) * streakImpact;
    freq += math.min(streakImpact * 5, 50);

    // --- Rank change influence ---
    // Climbing feels more exciting → wider deviation, snappier fade, faster sweep
    double climb = math.pow(math.min(ctx.rankChange, 6), 1.2).toDouble(); 
    climb *= ctx.score == 1 ? 0 : ctx.score == 2 ? 0.6 : 1.0; // first and second points are less exciting
    fade += climb * .1;
    sweep += (isFirstTone ? -0.4 : .5) * climb;
    freq += climb * 5;

    // --- Skips influence: more relief/excitement when point is scored ---
    freq -= isFirstTone ? (ctx.skipsBeforePoint / 2).clamp(0, 40) : (ctx.skipsBeforePoint / 3).clamp(0, 40);
    stdDev += isFirstTone ? (ctx.skipsBeforePoint / 5).clamp(0, 20) : 0;
    fade -= (ctx.skipsBeforePoint / 6).clamp(0, 3); // more skips = smoother fade
    volume += (ctx.skipsBeforePoint / 50).clamp(0, .06); // more skips = louder to feel more rewarding
    sweep += (isFirstTone ? -0.2 : .3) * climb;

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
    sweep += (isFirstTone ? -0.4 : 0.5) * difficultyInfluence;
    volume += 0.03 * difficultyInfluence; // and a bit louder
    brightness -= 0.2 * difficultyInfluence;

    final now = ctx.time ?? DateTime.now();
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
        freq -= isFirstTone ? 0 : 10 * transitionValue;
        stdDev -= isFirstTone ? 0 : 6 * transitionValue;
        fade *= 0.9 + 0.1 * (1 - transitionValue);
        volume *= 0.9 + 0.1 * (1 - transitionValue);
      }
    } else {
      // Evening (transition between 18:00 and 19:00 and transition between 7:00 and 8:00) slightly softer / lower
      if (hour >= 18 && !(now.month == 12 && now.day == 31) || hour < 8) {
        final double transitionValue = hour == 18 ? _easeInOutQuad(now.minute / 60) : hour == 7 ? _easeInOutQuad(1 - now.minute / 60) : 1;
        freq -= isFirstTone ? 0 : 10 * transitionValue;
        stdDev -= isFirstTone ? 0 : 6 * transitionValue;
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
    freqStdDev: math.max(0, stdDev),
    freqSweep: sweep,
    fadeRate: fade,
    harmonicBrightness: brightness.clamp(0, 1), 
    volume: volume,
  );
}

// ====================== TONE GENERATION ======================
Uint8List _generateTone(_SoundProfile profile, bool isFirstTone) {
  const int sampleRate = 44100;
  final List<int> pcm = [];

  // Apply normal deviation
  final frequency = _gaussianRandom(mean: profile.baseFreq, stdDev: profile.freqStdDev);

  final double duration = -math.log(isFirstTone ? _endVolume1 : _endVolume2) / profile.fadeRate;
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

  final pcmBytes = Uint8List(pcm.length * 2);
  final bd = ByteData.view(pcmBytes.buffer);
  for (int i = 0; i < pcm.length; i++) {
    bd.setInt16(i * 2, pcm[i], Endian.little);
  }
  return pcmBytes;
}

// ====================== PLAYBACK ======================
DateTime? _firstToneStartTime;
Uint8List? _cachedSecondTone;

Future<void> _playTone(Uint8List pcmBytes, int sampleRate) async {
  if (pcmBytes.isEmpty) return;
  // Create a fresh buffer stream for this one-shot tone
  final AudioSource stream = SoLoud.instance.setBufferStream(
    bufferingType: BufferingType.released,   // frees memory immediately after playback
    sampleRate: sampleRate,
    channels: Channels.mono,
    format: BufferType.s16le,
    // maxBufferSizeBytes omitted → uses safe 100 MB default (perfect for short tones)
  );

  // Feed the entire PCM at once (instant for our short tones)
  SoLoud.instance.addAudioDataStream(stream, pcmBytes);

  // CRITICAL: tell SoLoud this is a complete one-shot sound
  SoLoud.instance.setDataIsEnded(stream);

  // Play it! (no loadMem, no WAV parsing → near-zero latency)
  SoLoud.instance.play(stream);

}

// ====================== PUBLIC API ======================
/// Call on tap down. Pass context for adaptive sound.
Future<void> playFirstTone({SoundContext? context}) async {
  final profile = _buildProfile(context, true);
  final pcmBytes = await Future(() => _generateTone(profile, true));

  _playTone(pcmBytes, 44100);

  _firstToneStartTime = DateTime.now();

  // Pre-generate second tone (raw PCM, super fast)
  Future(() {
    final secondProfile = _buildProfile(context, false);
    _cachedSecondTone = _generateTone(secondProfile, false);
  });
}

Future<void> playSecondTone({SoundContext? context}) async {
  Uint8List pcmBytes;

  if (_cachedSecondTone != null) {
    pcmBytes = _cachedSecondTone!;
  } else {
    final profile = _buildProfile(context, false);
    pcmBytes = await Future(() => _generateTone(profile, false));
  }

  if (_firstToneStartTime != null) {
    final elapsed = DateTime.now().difference(_firstToneStartTime!);
    final delayNeeded = _minDelayBetweenTonesMs - elapsed.inMilliseconds;
    if (delayNeeded > 0) {
      await Future.delayed(Duration(milliseconds: delayNeeded));
    }
  }

  _playTone(pcmBytes, 44100);
  _cachedSecondTone = null; // optional: clear after use
}