// File: /lib/presentation/common/icons/payment_icons.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flash_transfer_app/config/ui_constants.dart';

class PaymentIcons {
  // Cash Icon
  static Widget cashIcon({
    double size = 24,
    Color? color = AppColors.primaryBlue,
  }) {
    return CustomPaint(
      size: Size(size, size),
      painter: CashIconPainter(color: color!),
    );
  }

  // Phone Icon
  static Widget phoneIcon({
    double size = 24,
    Color? color = AppColors.primaryBlue,
  }) {
    return CustomPaint(
      size: Size(size, size),
      painter: PhoneIconPainter(color: color!),
    );
  }

  // Pay Icon
  static Widget payIcon({
    double size = 24,
    Color? color = AppColors.primaryBlue,
  }) {
    return CustomPaint(
      size: Size(size, size),
      painter: PayIconPainter(color: color!),
    );
  }

  // Bank Icon
  static Widget bankIcon({
    double size = 24,
    Color? color = AppColors.primaryBlue,
  }) {
    return CustomPaint(
      size: Size(size, size),
      painter: BankIconPainter(color: color!),
    );
  }

  // Wallet Icon
  static Widget walletIcon({
    double size = 24,
    Color? color = AppColors.primaryBlue,
  }) {
    return CustomPaint(
      size: Size(size, size),
      painter: WalletIconPainter(color: color!),
    );
  }

  // Credit Card Icon
  static Widget creditCardIcon({
    double size = 24,
    Color? color = AppColors.primaryBlue,
  }) {
    return CustomPaint(
      size: Size(size, size),
      painter: CreditCardIconPainter(color: color!),
    );
  }
}
class CashIconPainter extends CustomPainter {
  final Color color;

  CashIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // First path (dollar sign on top)
    Path path1 = Path();
    path1.moveTo(size.width * 0.6797, size.width * 0.0037);
    path1.cubicTo(
      size.width * 0.6331, size.width * 0.0143,
      size.width * 0.5945, size.width * 0.0356,
      size.width * 0.5606, size.width * 0.0717,
    );
    path1.cubicTo(
      size.width * 0.4600, size.width * 0.1785,
      size.width * 0.4859, size.width * 0.3557,
      size.width * 0.6129, size.width * 0.4283,
    );
    path1.cubicTo(
      size.width * 0.7223, size.width * 0.4910,
      size.width * 0.8602, size.width * 0.4527,
      size.width * 0.9227, size.width * 0.3422,
    );
    path1.cubicTo(
      size.width * 0.9418, size.width * 0.3082,
      size.width * 0.9512, size.width * 0.2715,
      size.width * 0.9512, size.width * 0.2299,
    );
    path1.cubicTo(
      size.width * 0.9512, size.width * 0.1998,
      size.width * 0.9479, size.width * 0.1781,
      size.width * 0.9398, size.width * 0.1539,
    );
    path1.cubicTo(
      size.width * 0.9148, size.width * 0.0807,
      size.width * 0.8560, size.width * 0.0262,
      size.width * 0.7799, size.width * 0.0055,
    );
    path1.cubicTo(
      size.width * 0.7576, size.width * -0.0004,
      size.width * 0.7031, size.width * -0.0015,
      size.width * 0.6797, size.width * 0.0037,
    );
    path1.close();
    
    // Dollar sign details
    path1.moveTo(size.width * 0.7520, size.width * 0.0946);
    path1.lineTo(size.width * 0.7520, size.width * 0.1109);
    path1.lineTo(size.width * 0.7612, size.width * 0.1131);
    path1.cubicTo(
      size.width * 0.7660, size.width * 0.1145,
      size.width * 0.7766, size.width * 0.1186,
      size.width * 0.7844, size.width * 0.1225,
    );
    path1.lineTo(size.width * 0.7984, size.width * 0.1295);
    path1.lineTo(size.width * 0.7934, size.width * 0.1424);
    path1.cubicTo(
      size.width * 0.7908, size.width * 0.1494,
      size.width * 0.7869, size.width * 0.1602,
      size.width * 0.7848, size.width * 0.1660,
    );
    path1.cubicTo(
      size.width * 0.7824, size.width * 0.1719,
      size.width * 0.7805, size.width * 0.1771,
      size.width * 0.7801, size.width * 0.1775,
    );
    path1.cubicTo(
      size.width * 0.7797, size.width * 0.1779,
      size.width * 0.7723, size.width * 0.1750,
      size.width * 0.7635, size.width * 0.1709,
    );
    path1.cubicTo(
      size.width * 0.7516, size.width * 0.1652,
      size.width * 0.7445, size.width * 0.1633,
      size.width * 0.7348, size.width * 0.1627,
    );
    path1.cubicTo(
      size.width * 0.7178, size.width * 0.1617,
      size.width * 0.7121, size.width * 0.1645,
      size.width * 0.7113, size.width * 0.1742,
    );
    path1.cubicTo(
      size.width * 0.7105, size.width * 0.1826,
      size.width * 0.7148, size.width * 0.1873,
      size.width * 0.7283, size.width * 0.1936,
    );
    path1.cubicTo(
      size.width * 0.7639, size.width * 0.2096,
      size.width * 0.7715, size.width * 0.2143,
      size.width * 0.7814, size.width * 0.2248,
    );
    path1.cubicTo(
      size.width * 0.8037, size.width * 0.2471,
      size.width * 0.8084, size.width * 0.2793,
      size.width * 0.7934, size.width * 0.3072,
    );
    path1.cubicTo(
      size.width * 0.7871, size.width * 0.3192,
      size.width * 0.7725, size.width * 0.3322,
      size.width * 0.7598, size.width * 0.3381,
    );
    path1.lineTo(size.width * 0.7500, size.width * 0.3426);
    path1.lineTo(size.width * 0.7500, size.width * 0.3617);
    path1.lineTo(size.width * 0.7500, size.width * 0.3809);
    path1.lineTo(size.width * 0.7246, size.width * 0.3809);
    path1.lineTo(size.width * 0.6994, size.width * 0.3809);
    path1.lineTo(size.width * 0.6988, size.width * 0.3631);
    path1.lineTo(size.width * 0.6982, size.width * 0.3451);
    path1.lineTo(size.width * 0.6879, size.width * 0.3426);
    path1.cubicTo(
      size.width * 0.6764, size.width * 0.3395,
      size.width * 0.6587, size.width * 0.3317,
      size.width * 0.6518, size.width * 0.3260,
    );
    path1.lineTo(size.width * 0.6467, size.width * 0.3221);
    path1.lineTo(size.width * 0.6547, size.width * 0.2992);
    path1.cubicTo(
      size.width * 0.6592, size.width * 0.2867,
      size.width * 0.6635, size.width * 0.2756,
      size.width * 0.6643, size.width * 0.2746,
    );
    path1.cubicTo(
      size.width * 0.6650, size.width * 0.2737,
      size.width * 0.6684, size.width * 0.2748,
      size.width * 0.6718, size.width * 0.2773,
    );
    path1.cubicTo(
      size.width * 0.6884, size.width * 0.2893,
      size.width * 0.7148, size.width * 0.2967,
      size.width * 0.7283, size.width * 0.2930,
    );
    path1.cubicTo(
      size.width * 0.7424, size.width * 0.2893,
      size.width * 0.7484, size.width * 0.2754,
      size.width * 0.7404, size.width * 0.2654,
    );
    path1.cubicTo(
      size.width * 0.7365, size.width * 0.2606,
      size.width * 0.7359, size.width * 0.2602,
      size.width * 0.7029, size.width * 0.2444,
    );
    path1.cubicTo(
      size.width * 0.6795, size.width * 0.2330,
      size.width * 0.6654, size.width * 0.2211,
      size.width * 0.6580, size.width * 0.2057,
    );
    path1.cubicTo(
      size.width * 0.6514, size.width * 0.1926,
      size.width * 0.6514, size.width * 0.1674,
      size.width * 0.6578, size.width * 0.1535,
    );
    path1.cubicTo(
      size.width * 0.6646, size.width * 0.1383,
      size.width * 0.6742, size.width * 0.1281,
      size.width * 0.6885, size.width * 0.1209,
    );
    path1.lineTo(size.width * 0.7012, size.width * 0.1143);
    path1.lineTo(size.width * 0.7012, size.width * 0.0961);
    path1.lineTo(size.width * 0.7012, size.width * 0.0781);
    path1.lineTo(size.width * 0.7266, size.width * 0.0781);
    path1.lineTo(size.width * 0.7520, size.width * 0.0781);
    path1.lineTo(size.width * 0.7520, size.width * 0.0946);
    path1.close();

    // Second path (middle part of the icon)
    Path path2 = Path();
    path2.moveTo(size.width * 0.3027, size.width * 0.5637);
    path2.cubicTo(
      size.width * 0.2770, size.width * 0.5693,
      size.width * 0.2447, size.width * 0.5885,
      size.width * 0.2254, size.width * 0.6100,
    );
    path2.cubicTo(
      size.width * 0.2137, size.width * 0.6228,
      size.width * 0.1975, size.width * 0.6477,
      size.width * 0.1887, size.width * 0.6660,
    );
    path2.lineTo(size.width * 0.1818, size.width * 0.6801);
    path2.lineTo(size.width * 0.1852, size.width * 0.6883);
    path2.cubicTo(
      size.width * 0.1869, size.width * 0.6926,
      size.width * 0.2061, size.width * 0.7410,
      size.width * 0.2277, size.width * 0.7959,
    );
    path2.lineTo(size.width * 0.2672, size.width * 0.8955);
    path2.lineTo(size.width * 0.4025, size.width * 0.8955);
    path2.lineTo(size.width * 0.5381, size.width * 0.8955);
    path2.lineTo(size.width * 0.5537, size.width * 0.8900);
    path2.cubicTo(
      size.width * 0.5717, size.width * 0.8836,
      size.width * 0.9518, size.width * 0.6674,
      size.width * 0.9623, size.width * 0.6576,
    );
    path2.cubicTo(
      size.width * 0.9707, size.width * 0.6498,
      size.width * 0.9746, size.width * 0.6410,
      size.width * 0.9746, size.width * 0.6299,
    );
    path2.cubicTo(
      size.width * 0.9746, size.width * 0.6188,
      size.width * 0.9701, size.width * 0.6086,
      size.width * 0.9627, size.width * 0.6033,
    );
    path2.cubicTo(
      size.width * 0.9596, size.width * 0.6012,
      size.width * 0.9485, size.width * 0.5971,
      size.width * 0.9389, size.width * 0.5943,
    );
    path2.cubicTo(
      size.width * 0.9221, size.width * 0.5902,
      size.width * 0.9146, size.width * 0.5895,
      size.width * 0.8926, size.width * 0.5895,
    );
    path2.cubicTo(
      size.width * 0.8574, size.width * 0.5895,
      size.width * 0.8404, size.width * 0.5939,
      size.width * 0.7930, size.width * 0.6156,
    );
    path2.cubicTo(
      size.width * 0.7730, size.width * 0.6248,
      size.width * 0.7270, size.width * 0.6457,
      size.width * 0.6904, size.width * 0.6621,
    );
    path2.cubicTo(
      size.width * 0.6539, size.width * 0.6787,
      size.width * 0.6215, size.width * 0.6938,
      size.width * 0.6186, size.width * 0.6959,
    );
    path2.cubicTo(
      size.width * 0.6154, size.width * 0.6981,
      size.width * 0.6076, size.width * 0.7014,
      size.width * 0.6012, size.width * 0.7033,
    );
    path2.cubicTo(
      size.width * 0.5908, size.width * 0.7066,
      size.width * 0.5826, size.width * 0.7070,
      size.width * 0.5271, size.width * 0.7070,
    );
    path2.cubicTo(
      size.width * 0.4594, size.width * 0.7070,
      size.width * 0.4578, size.width * 0.7068,
      size.width * 0.4494, size.width * 0.6961,
    );
    path2.cubicTo(
      size.width * 0.4467, size.width * 0.6926,
      size.width * 0.4453, size.width * 0.6881,
      size.width * 0.4453, size.width * 0.6824,
    );
    path2.cubicTo(
      size.width * 0.4453, size.width * 0.6754,
      size.width * 0.4465, size.width * 0.6725,
      size.width * 0.4520, size.width * 0.6664,
    );
    path2.lineTo(size.width * 0.4586, size.width * 0.6592);
    path2.lineTo(size.width * 0.5248, size.width * 0.6582);
    path2.cubicTo(
      size.width * 0.5844, size.width * 0.6572,
      size.width * 0.5914, size.width * 0.6568,
      size.width * 0.5961, size.width * 0.6537,
    );
    path2.cubicTo(
      size.width * 0.6035, size.width * 0.6486,
      size.width * 0.6080, size.width * 0.6377,
      size.width * 0.6090, size.width * 0.6225,
    );
    path2.cubicTo(
      size.width * 0.6100, size.width * 0.6066,
      size.width * 0.6063, size.width * 0.5951,
      size.width * 0.5975, size.width * 0.5867,
    );
    path2.lineTo(size.width * 0.5916, size.width * 0.5811);
    path2.lineTo(size.width * 0.5033, size.width * 0.5797);
    path2.cubicTo(
      size.width * 0.4160, size.width * 0.5783,
      size.width * 0.4148, size.width * 0.5783,
      size.width * 0.3984, size.width * 0.5732,
    );
    path2.cubicTo(
      size.width * 0.3613, size.width * 0.5621,
      size.width * 0.3533, size.width * 0.5605,
      size.width * 0.3342, size.width * 0.5607,
    );
    path2.cubicTo(
      size.width * 0.3238, size.width * 0.5609,
      size.width * 0.3098, size.width * 0.5621,
      size.width * 0.3027, size.width * 0.5637,
    );
    path2.close();

    // Third path (bottom part of the icon)
    Path path3 = Path();
    path3.moveTo(size.width * 0.0723, size.width * 0.6797);
    path3.cubicTo(
      size.width * 0.0471, size.width * 0.6935,
      size.width * 0.0262, size.width * 0.7061,
      size.width * 0.0258, size.width * 0.7074,
    );
    path3.cubicTo(
      size.width * 0.0252, size.width * 0.7109,
      size.width * 0.1398, size.width * 0.9986,
      size.width * 0.1420, size.width * 0.9994,
    );
    path3.cubicTo(
      size.width * 0.1457, size.width * 1.0008,
      size.width * 0.2352, size.width * 0.9502,
      size.width * 0.2350, size.width * 0.9471,
    );
    path3.cubicTo(
      size.width * 0.2343, size.width * 0.9432,
      size.width * 0.1211, size.width * 0.6574,
      size.width * 0.1195, size.width * 0.6559,
    );
    path3.cubicTo(
      size.width * 0.1187, size.width * 0.6551,
      size.width * 0.0975, size.width * 0.6658,
      size.width * 0.0723, size.width * 0.6797,
    );
    path3.close();

    // Draw all paths 
    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
    canvas.drawPath(path3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PhoneIconPainter extends CustomPainter {
  final Color color;

  PhoneIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    Path path = Path();
    // Phone icon path data
    path.moveTo(size.width * 0.1208, size.width * 0.0031);
    path.cubicTo(
      size.width * 0.1150, size.width * 0.0047,
      size.width * 0.1035, size.width * 0.0092,
      size.width * 0.0955, size.width * 0.0131,
    );
    path.cubicTo(
      size.width * 0.0751, size.width * 0.0229,
      size.width * 0.0506, size.width * 0.0476,
      size.width * 0.0404, size.width * 0.0683,
    );
    // Add more points to complete the phone shape
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PayIconPainter extends CustomPainter {
  final Color color;

  PayIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    Path path = Path();
    // Pay icon path data
    path.moveTo(size.width * 0.7498, size.width * 0.0);
    path.lineTo(size.width * 0.7378, size.width * 0.0173);
    path.lineTo(size.width * 0.5499, size.width * 0.2931);
    path.lineTo(size.width * 0.3868, size.width * 0.3418);
    path.cubicTo(
      size.width * 0.3654, size.width * 0.3484,
      size.width * 0.3471, size.width * 0.3627,
      size.width * 0.3349, size.width * 0.3818,
    );
    // Add more points to complete the pay icon shape
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BankIconPainter extends CustomPainter {
  final Color color;

  BankIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    Path path = Path();
    // Bank icon path data
    path.moveTo(size.width * 0.4824, size.width * 0.0027);
    path.cubicTo(
      size.width * 0.4548, size.width * 0.0135,
      size.width * 0.0211, size.width * 0.2103,
      size.width * 0.0156, size.width * 0.2148,
    );
    path.cubicTo(
      size.width * 0.0119, size.width * 0.2176,
      size.width * 0.0068, size.width * 0.2238,
      size.width * 0.0043, size.width * 0.2287,
    );
    // Add more points to complete the bank icon shape
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WalletIconPainter extends CustomPainter {
  final Color color;

  WalletIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    Path path = Path();
    // Wallet icon path data
    path.moveTo(size.width * 0.3477, size.width * 0.0332);
    path.cubicTo(
      size.width * 0.2760, size.width * 0.0402,
      size.width * 0.2135, size.width * 0.0693,
      size.width * 0.1918, size.width * 0.1582,
    );
    path.cubicTo(
      size.width * 0.1781, size.width * 0.2013,
      size.width * 0.1801, size.width * 0.2504,
      size.width * 0.1971, size.width * 0.2881,
    );
    // Add more points to complete the wallet icon shape
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CreditCardIconPainter extends CustomPainter {
  final Color color;

  CreditCardIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    Path path = Path();
    // Credit card icon path data
    path.moveTo(size.width * 0.5938, size.width * 0.0051);
    path.cubicTo(
      size.width * 0.5417, size.width * 0.0094,
      size.width * 0.4774, size.width * 0.0321,
      size.width * 0.4224, size.width * 0.0599,
    );
    path.cubicTo(
      size.width * 0.3385, size.width * 0.1042,
      size.width * 0.2854, size.width * 0.1760,
      size.width * 0.2552, size.width * 0.2734,
    );
    // Add more points to complete the credit card icon shape
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}