import 'package:flutter/material.dart';

void main() => runApp(const MyApp2());

class MyApp2 extends StatelessWidget {
  const MyApp2({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Score Morph Test',
      theme: ThemeData.dark(useMaterial3: true),
      home: const MorphTestScreen(),
    );
  }
}

class MorphTestScreen extends StatefulWidget {
  const MorphTestScreen({super.key});

  @override
  State<MorphTestScreen> createState() => _MorphTestScreenState();
}

class _MorphTestScreenState extends State<MorphTestScreen> {
  int _score = 1234;

  void _changeScore(int delta) {
    setState(() => _score += delta);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Score Morphing Test')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Shared score controls
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Current Score', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text('$_score', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(onPressed: () => _changeScore(1), child: const Text('+1')),
                        ElevatedButton(onPressed: () => _changeScore(10), child: const Text('+10')),
                        ElevatedButton(onPressed: () => _changeScore(100), child: const Text('+100')),
                        ElevatedButton(onPressed: () => _changeScore(-50), child: const Text('-50')),
                        ElevatedButton(onPressed: () => _changeScore(1234), child: const Text('→ 1234')),
                        ElevatedButton(
                          onPressed: () => _changeScore((DateTime.now().millisecondsSinceEpoch % 10000) - _score),
                          child: const Text('Random'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Method 1: Static (baseline)
            _buildMethodCard('1. Static Text (no animation)', StaticScore(score: _score)),

            // Method 2: AnimatedSwitcher - Slide (great morph feel)
            _buildMethodCard('2. AnimatedSwitcher + SlideTransition', AnimatedSwitcherScore(score: _score, transition: 'slide')),

            // Method 3: AnimatedSwitcher - Scale
            _buildMethodCard('3. AnimatedSwitcher + ScaleTransition', AnimatedSwitcherScore(score: _score, transition: 'scale')),

            // Method 4: Smooth Counting Morph (best pure-Flutter "morph")
            _buildMethodCard('4. Smooth Count Morph (digits interpolate)', CountingScore(score: _score)),

            // Method 5: AnimatedSwitcher + Rotate (fun extra)
            _buildMethodCard('5. AnimatedSwitcher + Rotation', AnimatedSwitcherScore(score: _score, transition: 'rotate')),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodCard(String title, Widget display) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Center(child: display),
          ],
        ),
      ),
    );
  }
}

// ==================== IMPLEMENTATIONS ====================

// Method 1: Plain Text
class StaticScore extends StatelessWidget {
  final int score;
  const StaticScore({super.key, required this.score});
  @override
  Widget build(BuildContext context) => Text('$score', style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold));
}

// Method 2-3-5: AnimatedSwitcher with different transitions
class AnimatedSwitcherScore extends StatelessWidget {
  final int score;
  final String transition;
  const AnimatedSwitcherScore({super.key, required this.score, required this.transition});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) {
        switch (transition) {
          case 'slide':
            return SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero).animate(animation),
              child: child,
            );
          case 'scale':
            return ScaleTransition(scale: animation, child: child);
          case 'rotate':
            return RotationTransition(turns: animation, child: child);
          default:
            return child;
        }
      },
      child: Text(
        '$score',
        key: ValueKey(score), // Critical: forces rebuild on value change
        style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// Method 4: True smooth counting morph (digits "morph" via interpolation)
class CountingScore extends StatefulWidget {
  final int score;
  const CountingScore({super.key, required this.score});

  @override
  State<CountingScore> createState() => _CountingScoreState();
}

class _CountingScoreState extends State<CountingScore> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _displayedValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _displayedValue = widget.score.toDouble();
  }

  @override
  void didUpdateWidget(CountingScore oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _controller.reset();
      final tween = Tween<double>(begin: _displayedValue, end: widget.score.toDouble());
      _animation = tween.animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller.forward();
      _animation.addListener(() => setState(() => _displayedValue = _animation.value));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int display = _displayedValue.round();
    return Text('$display', style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold));
  }
}