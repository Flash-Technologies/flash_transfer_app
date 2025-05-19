import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary colors
  static const primaryBlue = Color(0xFF2475FF);
  static const primaryYellow = Color(0xFFFFC000);

  // Background colors
  static const background = Color(0xFFEFF0F1);
  static const cardBackground = Colors.white;

  // Text colors
  static const textPrimary = Color(0xFF181F30);
  static const textSecondary = Color(0xFF6E757D);
  static const textDarkGrey = Color(0xFF273240);
  static const textGrey = Color(0xFF6A6A6A);

  // Status colors
  static const success = Color(0xFF00C735);
  static const error = Color(0xFFFF3E24);

  // Border colors
  static const border = Color(0xFFEBECED);
  static const greyBorder = Color(0xFFD3D8DD);

  // Other colors
  static const iconBackground = Color(0xFFF4F5F7);
}

class AppTextStyles {
  // Heading styles
  static TextStyle heading1 = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static TextStyle heading2 = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static TextStyle heading3 = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  // Body text styles
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  // Button text styles
  static TextStyle buttonLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle buttonMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Special styles
  static TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
}

class AppSpacing {
  // Padding
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;

  // Margins
  static const double marginXS = 4.0;
  static const double marginS = 8.0;
  static const double marginM = 16.0;
  static const double marginL = 24.0;
  static const double marginXL = 32.0;

  // Gaps
  static const double gapXS = 4.0;
  static const double gapS = 8.0;
  static const double gapM = 16.0;
  static const double gapL = 24.0;

  // Specific spacing
  static const double listItemSpacing = 12.0;
  static const double sectionSpacing = 20.0;
}

class AppRadius {
  static const double radiusXS = 4.0;
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusCircular = 100.0; // For circular elements

  // Specific radius values
  static const double buttonRadius = 12.0;
  static const double cardRadius = 16.0;
  static const double chipRadius = 20.0;
}

class AppAnimations {
  static const Duration quickAnimation = Duration(milliseconds: 150);
  static const Duration normalAnimation = Duration(milliseconds: 250);
  static const Duration slowAnimation = Duration(milliseconds: 350);

  static const Curve standardCurve = Curves.easeInOut;
  static const Curve emphasizedCurve = Curves.easeOutBack;
  static const Curve decelerateCurve = Curves.decelerate;

  // Staggered timing
  static Duration staggered(int index) => Duration(milliseconds: 50 * index);
}
