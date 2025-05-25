
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/models/nft_model.dart';

class NFTGlowEffect extends StatelessWidget {
  final Widget child;
  final NFTRarity rarity;
  final double glowIntensity;

  const NFTGlowEffect({
    super.key,
    required this.child,
    required this.rarity,
    this.glowIntensity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    if (rarity == NFTRarity.common) {
      return child;
    }

    return Stack(
      children: [
        // Glow layers
        ..._buildGlowLayers(),
        // Main child
        child,
      ],
    );
  }

  List<Widget> _buildGlowLayers() {
    final colors = _getGlowColors();
    final layers = <Widget>[];

    for (int i = 0; i < colors.length; i++) {
      final blur = (i + 1) * 8.0;
      final spread = (i + 1) * 2.0;
      
      layers.add(
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colors[i].withOpacity(
                    _getOpacity() * glowIntensity * (1 - i * 0.2),
                  ),
                  blurRadius: blur,
                  spreadRadius: spread,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return layers;
  }

  List<Color> _getGlowColors() {
    switch (rarity) {
      case NFTRarity.common:
        return [];
      case NFTRarity.uncommon:
        return [Colors.green.shade400];
      case NFTRarity.rare:
        return [Colors.blue.shade400, Colors.blue.shade300];
      case NFTRarity.epic:
        return [
          Colors.purple.shade400,
          Colors.purple.shade300,
          Colors.pink.shade300,
        ];
      case NFTRarity.legendary:
        return [
          Colors.red.shade400,
          Colors.orange.shade400,
          Colors.yellow.shade400,
          Colors.green.shade400,
          Colors.blue.shade400,
        ];
    }
  }

  double _getOpacity() {
    switch (rarity) {
      case NFTRarity.common:
        return 0.0;
      case NFTRarity.uncommon:
        return 0.3;
      case NFTRarity.rare:
        return 0.4;
      case NFTRarity.epic:
        return 0.5;
      case NFTRarity.legendary:
        return 0.6;
    }
  }
}