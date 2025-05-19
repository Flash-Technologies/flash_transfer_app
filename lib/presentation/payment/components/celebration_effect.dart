import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

class CelebrationEffect extends StatefulWidget {
  final bool play;

  const CelebrationEffect({Key? key, required this.play}) : super(key: key);

  @override
  State<CelebrationEffect> createState() => _CelebrationEffectState();
}

class _CelebrationEffectState extends State<CelebrationEffect> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    if (widget.play) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _confettiController.play();
      });
    }
  }

  @override
  void didUpdateWidget(CelebrationEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.play != oldWidget.play && widget.play) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConfettiWidget(
        confettiController: _confettiController,
        blastDirection: pi / 2, // straight up
        emissionFrequency: 0.05,
        numberOfParticles: 20,
        maxBlastForce: 20,
        minBlastForce: 10,
        gravity: 0.2,
        // Use professional colors for the confetti
        colors: const [
          Color(0xFF2475FF), // Blue
          Color(0xFFFFC000), // Gold
          Color(0xFFFFFFFF), // White
          Color(0xFF00C735), // Green
        ],
        createParticlePath: (size) {
          final path = Path();
          // Create a rounded rectangle shape for confetti (more professional than default shapes)
          path.addRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(0, 0, size.width, size.height),
              Radius.circular(size.width / 5),
            ),
          );
          return path;
        },
      ),
    );
  }
}
