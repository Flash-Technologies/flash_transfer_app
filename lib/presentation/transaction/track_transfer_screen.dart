// File: lib/presentation/settings/contact_us_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import '../../providers/contact_provider.dart';

class ContactUsScreen extends ConsumerStatefulWidget {
  const ContactUsScreen({super.key});

  @override
  ConsumerState<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends ConsumerState<ContactUsScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _heroAnimationController;
  late AnimationController _contentAnimationController;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _heroFloatAnimation;
  late Animation<double> _contentFadeAnimation;

  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  final FocusNode _subjectFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _messageFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _heroAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutBack,
    ));

    _heroFloatAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _heroAnimationController,
      curve: Curves.easeInOut,
    ));

    _contentFadeAnimation = CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeInOut,
    );
  }

  void _startAnimations() {
    _headerAnimationController.forward();
    _heroAnimationController.repeat(reverse: true);
    
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _contentAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _heroAnimationController.dispose();
    _contentAnimationController.dispose();
    _subjectController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    _subjectFocus.dispose();
    _emailFocus.dispose();
    _messageFocus.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    HapticFeedback.lightImpact();
    
    // Show loading state
    ref.read(contactProvider.notifier).setLoading(true);
    
    try {
      final success = await ref.read(contactProvider.notifier).submitContact(
        subject: _subjectController.text.trim(),
        email: _emailController.text.trim(),
        message: _messageController.text.trim(),
      );

      if (success && mounted) {
        HapticFeedback.mediumImpact();
        
        // Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Message sent successfully! We\'ll get back to you soon.'),
                ),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );

        // Clear form
        _subjectController.clear();
        _emailController.clear();
        _messageController.clear();
        
        // Navigate back after delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Failed to send message. Please try again.')),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  String? _validateEmail(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value!)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validateSubject(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Subject is required';
    }
    if (value!.length < 3) {
      return 'Subject must be at least 3 characters';
    }
    return null;
  }

  String? _validateMessage(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Message is required';
    }
    if (value!.length < 10) {
      return 'Message must be at least 10 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final contactState = ref.watch(contactProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFEFF0F1),
      body: Column(
        children: [
          // Header
          SlideTransition(
            position: _headerSlideAnimation,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 56, 16, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_back_ios,
                            size: 20,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Back',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(
                    delay: const Duration(milliseconds: 400),
                    duration: const Duration(milliseconds: 400),
                  ),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: FadeTransition(
              opacity: _contentFadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Hero Image
                      AnimatedBuilder(
                        animation: _heroFloatAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _heroFloatAnimation.value),
                            child: Container(
                              width: 282,
                              height: 250,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: [
                                    theme.primaryColor.withOpacity(0.1),
                                    Colors.blue.withOpacity(0.05),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.support_agent_rounded,
                                  size: 120,
                                  color: theme.primaryColor.withOpacity(0.6),
                                ),
                              ),
                            ).animate().scale(
                              delay: const Duration(milliseconds: 600),
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.elasticOut,
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 32),

                      // Title and Description
                      Column(
                        children: [
                          Text(
                            'How can we help you?',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF181F30),
                            ),
                          ).animate().fadeIn(
                            delay: const Duration(milliseconds: 700),
                            duration: const Duration(milliseconds: 600),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          Text(
                            'It looks like you have problems with our system. We are here to help you, so, please get in touch with us.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF6E757D),
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                          ).animate().fadeIn(
                            delay: const Duration(milliseconds: 800),
                            duration: const Duration(milliseconds: 600),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Form Fields
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Subject Field
                            _buildFormField(
                              label: 'Subject',
                              controller: _subjectController,
                              focusNode: _subjectFocus,
                              validator: _validateSubject,
                              hintText: 'Enter your subject',
                              animationDelay: 900,
                              onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                            ),

                            const SizedBox(height: 20),

                            // Email Field
                            _buildFormField(
                              label: 'Email',
                              controller: _emailController,
                              focusNode: _emailFocus,
                              validator: _validateEmail,
                              hintText: 'Enter your email',
                              keyboardType: TextInputType.emailAddress,
                              animationDelay: 1000,
                              onFieldSubmitted: (_) => _messageFocus.requestFocus(),
                            ),

                            const SizedBox(height: 20),

                            // Message Field
                            _buildFormField(
                              label: 'Message',
                              controller: _messageController,
                              focusNode: _messageFocus,
                              validator: _validateMessage,
                              hintText: 'Type your message...',
                              maxLines: 5,
                              animationDelay: 1100,
                              onFieldSubmitted: (_) => _submitForm(),
                            ),

                            const SizedBox(height: 32),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: contactState.isLoading ? null : _submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFC000),
                                  foregroundColor: const Color(0xFF181F30),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                  disabledBackgroundColor: Colors.grey.shade300,
                                ),
                                child: contactState.isLoading
                                    ? SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            const Color(0xFF181F30),
                                          ),
                                        ),
                                      )
                                    : Text(
                                        'Continue',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ).animate().slideY(
                              begin: 1,
                              delay: const Duration(milliseconds: 1200),
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOutBack,
                            ),
                          ],
                        ),
                      ).animate().scale(
                        delay: const Duration(milliseconds: 500),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutBack,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String? Function(String?) validator,
    required String hintText,
    required int animationDelay,
    TextInputType? keyboardType,
    int maxLines = 1,
    void Function(String)? onFieldSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF181F30),
          ),
        ),
        const SizedBox(height: 8),
        Focus(
          onFocusChange: (hasFocus) {
            if (hasFocus) {
              HapticFeedback.selectionClick();
            }
          },
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            validator: validator,
            keyboardType: keyboardType,
            maxLines: maxLines,
            onFieldSubmitted: onFieldSubmitted,
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF181F30),
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: const Color(0xFF6E757D),
                fontSize: 14,
              ),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFFEBECED)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFFEBECED)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFFFFC000), width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red.shade400, width: 2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red.shade400, width: 2),
              ),
              contentPadding: const EdgeInsets.all(16),
              errorStyle: TextStyle(
                fontSize: 12,
                color: Colors.red.shade600,
              ),
            ),
          ),
        ),
      ],
    ).animate().slideX(
      begin: -1,
      delay: Duration(milliseconds: animationDelay),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
    );
  }
}
