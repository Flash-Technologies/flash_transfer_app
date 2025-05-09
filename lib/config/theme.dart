import 'package:flutter/material.dart';

final appTheme = ThemeData(
  primaryColor: const Color(0xFFFFC000),
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFFFFC000),
    primary: const Color(0xFFFFC000),
    secondary: const Color(0xFF2475FF),
    onPrimary: const Color(0xFF181F30),
    onSecondary: Colors.white,
    surface: Colors.white,
    background: const Color(0xFFEFF0F1),
  ),
  scaffoldBackgroundColor: Colors.white,
  fontFamily: 'Inter',
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: Color(0xFF181F30),
    ),
    titleLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Color(0xFF181F30),
    ),
    titleMedium: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Color(0xFF181F30),
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      color: Color(0xFF181F30),
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      color: Color(0xFF6E757D),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: false,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(
        color: Color(0xFFEBECED),
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(
        color: Color(0xFFEBECED),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(
        color: Color(0xFF2475FF),
      ),
    ),
    contentPadding: const EdgeInsets.all(16),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFFFC000),
      foregroundColor: const Color(0xFF181F30),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    ),
  ),
);