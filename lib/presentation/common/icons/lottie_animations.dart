import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieAnimations {
  // Cash animation
  static Widget cashAnimation({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    bool repeat = true,
    bool animate = true,
  }) {
    return Lottie.asset(
      'assets/LottieFiles/cashPayment.json',
      width: width,
      height: height,
      fit: fit,
      repeat: repeat,
      animate: animate,
    );
  }

  // Wallet animation
  static Widget walletAnimation({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    bool repeat = true,
    bool animate = true,
  }) {
    return Lottie.asset(
      'assets/LottieFiles/cryptoWallet.json',
      width: width,
      height: height,
      fit: fit,
      repeat: repeat,
      animate: animate,
    );
  }

  // Credit Card animation
  static Widget creditCardAnimation({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    bool repeat = true,
    bool animate = true,
  }) {
    return Lottie.asset(
      'assets/LottieFiles/creditCard.json',
      width: width,
      height: height,
      fit: fit,
      repeat: repeat,
      animate: animate,
    );
  }

  // Bank animation
  static Widget bankAnimation({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    bool repeat = true,
    bool animate = true,
  }) {
    return Lottie.asset(
      'assets/LottieFiles/bankTransfer.json',
      width: width,
      height: height,
      fit: fit,
      repeat: repeat,
      animate: animate,
    );
  }

  // Mobile/Phone animation
  static Widget phoneAnimation({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    bool repeat = true,
    bool animate = true,
  }) {
    return Lottie.asset(
      'assets/LottieFiles/mobileMoney.json',
      width: width,
      height: height,
      fit: fit,
      repeat: repeat,
      animate: animate,
    );
  }
}
