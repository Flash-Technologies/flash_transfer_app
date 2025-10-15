import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../../config/router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/language_provider.dart';

class RegistrationSuccessScreen extends ConsumerWidget {
  final String email;

  const RegistrationSuccessScreen({Key? key, required this.email})
    : super(key: key);

  Future<void> _openGmail() async {
    try {
      // Try to open Gmail app first
      final Uri gmailUri = Uri.parse('googlegmail://');
      if (await canLaunchUrl(gmailUri)) {
        await launchUrl(gmailUri);
        return;
      }

      // Try alternative Gmail URIs if the first one fails
      final Uri altGmailUri = Uri.parse('gmail://');
      if (await canLaunchUrl(altGmailUri)) {
        await launchUrl(altGmailUri);
        return;
      }

      // If no Gmail app, try other mail apps
      final Uri mailToUri = Uri.parse('mailto:');
      if (await canLaunchUrl(mailToUri)) {
        await launchUrl(mailToUri);
        return;
      }

      // Fallback to web Gmail
      final Uri webGmailUri = Uri.parse('https://mail.google.com/');
      await launchUrl(webGmailUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error opening email app: $e');
      // Just copy to clipboard if there's an error
      await Clipboard.setData(ClipboardData(text: email));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationHelperProvider);
    return WillPopScope(
      // Prevent back navigation
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          // Prevent the back button
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const Spacer(flex: 1),

                // Success image
                Image.asset(
                  'assets/images/success.png',
                  height: 220,
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        height: 220,
                        width: 220,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          size: 100,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                ),

                const SizedBox(height: 32),

                // Success title
                Text(
                  tr('auth.success.title'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF181F30),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Success message
                Text(
                  tr('auth.success.verificationSent'),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6E757D),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Email display card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F9FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD0E1FF)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.email_outlined,
                        color: Color(0xFF2475FF),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          email,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2475FF),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Copy button
                      IconButton(
                        icon: const Icon(
                          Icons.copy_outlined,
                          color: Color(0xFF2475FF),
                          size: 20,
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: email));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(tr('auth.success.emailCopied')),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        tooltip: tr('auth.success.copyEmail'),
                        splashRadius: 24,
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 1),

                // Open Gmail button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _openGmail,
                    icon: const Icon(Icons.mail_outline, size: 24),
                    label: Text(
                      tr('auth.success.openGmail'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC000),
                      foregroundColor: const Color(0xFF181F30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Back to login button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () {
                      // Reset splash completed to ensure we go through splash when restarting the app
                      ref.read(splashCompletedProvider.notifier).state = false;
                      context.go('/');
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF2475FF)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      tr('auth.success.goToLogin'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2475FF),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
