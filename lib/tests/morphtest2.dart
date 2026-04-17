import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp2());
}

class MyApp2 extends StatelessWidget {
  const MyApp2({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const DemoPage(),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  int score = 0;

  void increment() {
    setState(() {
      score +=10;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Number Animation Demo')),
      floatingActionButton: FloatingActionButton(
        onPressed: increment,
        child: const Icon(Icons.add),
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('IntTween'),
                AnimatedScore(
                  value: score,
                  duration: const Duration(milliseconds: 400),
                ),
              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Slide'),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 1),
                        end: const Offset(0, 0),
                      ).animate(animation),
                      child: child,
                    );
                  },
                  child: Text(
                    '$score',
                    key: ValueKey(score),
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Scale'),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Text(
                    '$score',
                    key: ValueKey(score),
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedScore extends ImplicitlyAnimatedWidget {
  final int value;

  const AnimatedScore({
    super.key,
    required this.value,
    required super.duration,
  });

  @override
  _AnimatedScoreState createState() => _AnimatedScoreState();
}

class _AnimatedScoreState extends AnimatedWidgetBaseState<AnimatedScore> {
  IntTween? _intTween;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _intTween = visitor(
      _intTween,
      widget.value,
      (dynamic value) => IntTween(begin: value as int, end: widget.value),
    ) as IntTween?;
  }

  @override
  Widget build(BuildContext context) {
    final value = _intTween?.evaluate(animation) ?? widget.value;
    return Text(
      '$value',
      style: const TextStyle(fontSize: 40),
    );
  }
}
