import 'package:flutter/material.dart';

void main() => runApp(const MyApp2());

class MyApp2 extends StatefulWidget {
  const MyApp2({super.key});

  @override
  State<MyApp2> createState() => _MorphingScoreDemoState();
}

class _MorphingScoreDemoState extends State<MyApp2> {
  int _score = 0;

  void _incrementScore() {
    setState(() {
      _score++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Number Morphing Demo')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildMethodCard(
              '1. Scale + Fade (quick pulse)',
              _ScaleFadeNumber(score: _score),
            ),
            _buildMethodCard(
              '2. 3D Rotation (flip effect)',
              _FlipNumber(score: _score),
            ),
            _buildMethodCard(
              '3. Interpolated Float (smooth morph)',
              _InterpolatedNumber(score: _score),
            ),
            _buildMethodCard(
              '4. Digit‑by‑Digit Rolling (slot machine)',
              _RollingDigitsNumber(score: _score),
            ),
            _buildMethodCard(
              '5. AnimatedSwitcher + Rotation',
              _RotatingNumber(score: _score),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _incrementScore,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildMethodCard(String title, Widget numberWidget) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(height: 100, child: Center(child: numberWidget)),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// Method 1: Scale + Fade transition using AnimatedSwitcher
// ------------------------------------------------------------
class _ScaleFadeNumber extends StatelessWidget {
  final int score;
  const _ScaleFadeNumber({required this.score});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) {
        final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.5, end: 1.0).animate(curve),
          child: FadeTransition(opacity: curve, child: child),
        );
      },
      child: Text(
        '$score',
        key: ValueKey(score),
        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ------------------------------------------------------------
// Method 2: 3D Flip (rotation around X axis)
// ------------------------------------------------------------
class _FlipNumber extends StatelessWidget {
  final int score;
  const _FlipNumber({required this.score});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) {
        final rotateAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        );
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // small perspective
            ..rotateX(rotateAnim.value * 3.14159),
          child: child,
        );
      },
      child: Text(
        '$score',
        key: ValueKey(score),
        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ------------------------------------------------------------
// Method 3: Interpolated floating number (morphs through decimals) - FIXED
// ------------------------------------------------------------
class _InterpolatedNumber extends StatefulWidget {
  final int score;
  const _InterpolatedNumber({required this.score});

  @override
  State<_InterpolatedNumber> createState() => _InterpolatedNumberState();
}

class _InterpolatedNumberState extends State<_InterpolatedNumber>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late double _displayValue;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _displayValue = widget.score.toDouble();
    
    _controller.addListener(() {
      setState(() {
        _displayValue = _animation.value;
      });
    });
  }

  @override
  void didUpdateWidget(covariant _InterpolatedNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _displayValue = oldWidget.score.toDouble();
      
      // Stop any ongoing animation
      _controller.stop();
      
      // Create new tween and animate
      _animation = Tween<double>(
        begin: oldWidget.score.toDouble(),
        end: widget.score.toDouble(),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      
      // Reset and start animation
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show integer when animation completes, otherwise show with 1 decimal
    String text = _displayValue.toStringAsFixed(
      _displayValue == widget.score ? 0 : 1
    );
    return Text(
      text,
      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
    );
  }
}

// ------------------------------------------------------------
// Method 4: Digit-by-digit rolling (like a slot machine)
// ------------------------------------------------------------
class _RollingDigitsNumber extends StatelessWidget {
  final int score;
  const _RollingDigitsNumber({required this.score});

  @override
  Widget build(BuildContext context) {
    String oldStr = (score - 1).toString();
    String newStr = score.toString();
    // Pad with leading zeros for same length
    int maxLen = oldStr.length > newStr.length ? oldStr.length : newStr.length;
    oldStr = oldStr.padLeft(maxLen, '0');
    newStr = newStr.padLeft(maxLen, '0');

    List<Widget> digits = [];
    for (int i = 0; i < maxLen; i++) {
      String oldDigit = oldStr[i];
      String newDigit = newStr[i];
      if (oldDigit == newDigit) {
        digits.add(Text(newDigit, style: const TextStyle(fontSize: 48)));
      } else {
        digits.add(_RollingDigit(oldDigit: oldDigit, newDigit: newDigit));
      }
      // Add a small gap between digits
      if (i != maxLen - 1) digits.add(const SizedBox(width: 4));
    }
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: digits);
  }
}

class _RollingDigit extends StatefulWidget {
  final String oldDigit;
  final String newDigit;
  const _RollingDigit({required this.oldDigit, required this.newDigit});

  @override
  State<_RollingDigit> createState() => _RollingDigitState();
}

class _RollingDigitState extends State<_RollingDigit> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _animation = Tween<double>(begin: -0.3, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value * 50),
          child: Opacity(
            opacity: 1.0 - _animation.value.abs() * 1.5,
            child: child,
          ),
        );
      },
      child: Text(widget.newDigit, style: const TextStyle(fontSize: 48)),
    );
  }
}

// ------------------------------------------------------------
// Method 5: Simple rotation + fade (another AnimatedSwitcher variant)
// ------------------------------------------------------------
class _RotatingNumber extends StatelessWidget {
  final int score;
  const _RotatingNumber({required this.score});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) {
        return RotationTransition(
          turns: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          ),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: Text(
        '$score',
        key: ValueKey(score),
        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
      ),
    );
  }
}