import 'package:flutter/material.dart';
import 'ui_constants.dart';
import 'theme.dart';

// App sizes for spacing and padding
class AppSizes {
  // Padding
  static const double paddingXSmall = 4;
  static const double paddingSmall = 8;
  static const double paddingMedium = 16;
  static const double paddingLarge = 24;
  static const double paddingXLarge = 32;

  // Spacing
  static const double spacingXSmall = 4;
  static const double spacingSmall = 8;
  static const double spacingMedium = 16;
  static const double spacingLarge = 24;
  static const double spacingXLarge = 32;

  // Border radius
  static const double borderRadiusSmall = 8;
  static const double borderRadiusMedium = 12;
  static const double borderRadiusLarge = 16;
  static const double borderRadiusXLarge = 24;

  // Icon sizes
  static const double iconSmall = 16;
  static const double iconMedium = 24;
  static const double iconLarge = 32;

  // Button heights
  static const double buttonHeight = 56;
  static const double buttonSmallHeight = 40;
}

// App colors redirects for backward compatibility
class AppColors {
  // Primary colors
  static const Color primary = Color(0xFFFFC000); // AppTheme.primaryColor
  static const Color secondary = Color(0xFF2475FF); // AppTheme.secondaryColor
  static const Color accent = Color(0xFFFFC000); // AppTheme.accentColor

  // Status colors
  static const Color success = Color(0xFF00C735); // AppTheme.successColor
  static const Color error = Color(0xFFFF3E24); // AppTheme.errorColor

  // Text colors
  static const Color textPrimary = Color(0xFF181F30);
  static const Color textSecondary = Color(0xFF6E757D);
}
