import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'app.dart';

// Initialize GoogleSignIn at the app level
final GoogleSignIn googleSignIn = GoogleSignIn(
  // The client ID from the provided credentials
  clientId:
      '850808265877-916lji3l3vt73cc6r99d48hhtid53fb1.apps.googleusercontent.com',
  scopes: ['email', 'profile'],
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initApp();
  runApp(const FlashTransferApp());
}
