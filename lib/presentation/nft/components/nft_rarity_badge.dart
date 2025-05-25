
import 'package:flutter/material.dart';
import '../../../core/models/nft_model.dart';

class NFTRarityBadge extends StatelessWidget {
  final NFTRarity rarity;
  final double size;

  const NFTRarityBadge({
    super.key,
    required this.rarity,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size * 0.67,
        vertical: size * 0.33,
      ),
      decoration: BoxDecoration(
        gradient: _getRarityGradient(),
        borderRadius: BorderRadius.circular(size * 0.67),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _getRarityColor().withOpacity(0.3),
            blurRadius: size * 0.5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        _getRarityName(),
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.83,
          fontWeight: FontWeight.w700,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  Color _getRarityColor() {
    switch (rarity) {
      case NFTRarity.common:
        return Colors.grey.shade500;
      case NFTRarity.uncommon:
        return Colors.green.shade500;
      case NFTRarity.rare:
        return Colors.blue.shade500;
      case NFTRarity.epic:
        return Colors.purple.shade500;
      case NFTRarity.legendary:
        return Colors.amber.shade500;
    }
  }

  LinearGradient _getRarityGradient() {
    switch (rarity) {
      case NFTRarity.common:
        return LinearGradient(
          colors: [Colors.grey.shade400, Colors.grey.shade600],
        );
      case NFTRarity.uncommon:
        return LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
        );
      case NFTRarity.rare:
        return LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
        );
      case NFTRarity.epic:
        return LinearGradient(
          colors: [Colors.purple.shade400, Colors.purple.shade600],
        );
      case NFTRarity.legendary:
        return const LinearGradient(
          colors: [
            Colors.red,
            Colors.orange,
            Colors.yellow,
            Colors.green,
            Colors.blue,
            Colors.purple,
          ],
        );
    }
  }

  String _getRarityName() {
    switch (rarity) {
      case NFTRarity.common:
        return 'COMMON';
      case NFTRarity.uncommon:
        return 'UNCOMMON';
      case NFTRarity.rare:
        return 'RARE';
      case NFTRarity.epic:
        return 'EPIC';
      case NFTRarity.legendary:
        return 'LEGENDARY';
    }
  }
}

