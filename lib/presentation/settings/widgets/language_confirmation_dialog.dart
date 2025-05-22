import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'dart:convert';
import '../../../core/models/language_model.dart';

class LanguageConfirmationDialog extends StatefulWidget {
  final LanguageModel language;

  const LanguageConfirmationDialog({
    super.key,
    required this.language,
  });

  @override
  State<LanguageConfirmationDialog> createState() => _LanguageConfirmationDialogState();
}

class _LanguageConfirmationDialogState extends State<LanguageConfirmationDialog>
    with TickerProviderStateMixin {
  late AnimationController _dialogController;
  late AnimationController _contentController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isConfirming = false;
  Map<String, String> _translations = {};

  @override
  void initState() {
    super.initState();
    _loadTranslations();
    
    _dialogController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _dialogController,
      curve: Curves.elasticOut,
    );

    _opacityAnimation = CurvedAnimation(
      parent: _dialogController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutBack,
    ));

    _dialogController.forward();
    _contentController.forward();
  }

  Future<void> _loadTranslations() async {
    final translations = await _loadTargetLanguageTranslations();
    setState(() {
      _translations = translations;
    });
  }

  @override
  void dispose() {
    _dialogController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    setState(() => _isConfirming = true);
    
    // Simulate confirmation delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _handleCancel() {
    _dialogController.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop(false);
      }
    });
  }

  Future<Map<String, String>> _loadTargetLanguageTranslations() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/locales/${widget.language.code}/language.json');
      final Map<String, dynamic> translations = json.decode(jsonString);
      return {
        'title': translations['confirmation']['title'] ?? 'Language Change Confirmation',
        'message': translations['confirmation']['message'] ?? 'Are you sure you want to change the language to ${widget.language.name}? We are happy to assist you with that.',
        'subtitle': translations['confirmation']['subtitle'] ?? 'This will update the entire app interface.',
        'yes': translations['confirmation']['buttons']['yes'] ?? 'Yes, Change Language',
        'no': translations['confirmation']['buttons']['no'] ?? 'Cancel',
      };
    } catch (e) {
      // Fallback to English
      return {
        'title': 'Language Change Confirmation',
        'message': 'Are you sure you want to change the language to ${widget.language.name}? We are happy to assist you with that.',
        'subtitle': 'This will update the entire app interface.',
        'yes': 'Yes, Change Language',
        'no': 'Cancel',
      };
    }
  }

  String _getYesButton() {
    return _translations['yes'] ?? 'Yes, Change Language';
  }

  String _getCancelButton() {
    return _translations['no'] ?? 'Cancel';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dialogController,
      builder: (context, child) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header with Lottie animation
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Lottie animation placeholder
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.language,
                                size: 40,
                                color: Theme.of(context).primaryColor,
                              ),
                            ).animate().scale(
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.elasticOut,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            Text(
                              _translations['title'] ?? 'Language Change Confirmation',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Language info
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                children: [
                                  // Flag placeholder
                                  Container(
                                    width: 32,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: Colors.grey[300],
                                      border: Border.all(color: Colors.grey[400]!),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.asset(
                                        widget.language.flagAsset,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(
                                            Icons.flag_outlined,
                                            size: 16,
                                            color: Colors.grey[600],
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(width: 12),
                                  
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.language.name,
                                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          widget.language.nativeName,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Confirmation message
                            Text(
                              _translations['message']?.replaceAll('{languageName}', widget.language.name) ??
                              'Are you sure you want to change the language to ${widget.language.name}? We are happy to assist you with that.',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            const SizedBox(height: 8),
                            
                            Text(
                              _translations['subtitle'] ?? 'This will update the entire app interface.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      
                      // Buttons
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: Column(
                          children: [
                            // Confirm button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isConfirming ? null : _handleConfirm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isConfirming
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        _translations['yes'] ?? 'Yes, Change Language',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Cancel button
                            SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: _isConfirming ? null : _handleCancel,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: Colors.grey[300]!),
                                  ),
                                ),
                                child: Text(
                                  _translations['no'] ?? 'Cancel',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}