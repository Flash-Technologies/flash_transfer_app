

import 'package:flutter/material.dart';
import 'package:flash_transfer_app/config/constants.dart';
import 'profile_menu_item.dart';

class ProfileMenuSection extends StatelessWidget {
  final String title;
  final List<ProfileMenuItemData> items;
  final int startDelay;

  const ProfileMenuSection({
    super.key,
    required this.title,
    required this.items,
    this.startDelay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 400),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(20 * (1 - value), 0),
              child: Opacity(
                opacity: value,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: 1.2,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return ProfileMenuItem(
            data: item,
            delay: startDelay + (index * 50),
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }
}
