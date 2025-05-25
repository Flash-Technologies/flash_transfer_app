import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import '../../../providers/contact_provider.dart';
import '../../common/enhanced_text_field.dart';
import '../../common/animated_button.dart';
import '../../common/error_boundary_widget.dart';
import '../../common/accessibility_widget.dart';
import 'dart:async';

class ContactFormWidget extends ConsumerStatefulWidget {
  final VoidCallback? onSuccess;
  final VoidCallback? onCancel;
  final String? initialSubject;
  final String? initialEmail;
  final String? initialMessage;
  final bool showCancelButton;
  final bool isCompact;
  final EdgeInsets? padding;
  final ContactFormType formType;

  const ContactFormWidget({
    super.key,
    this.onSuccess,
    this.onCancel,
    this.initialSubject,
    this.initialEmail,
    this.initialMessage,
    this.showCancelButton = true,
    this.isCompact = false,
    this.padding,
    this.formType = ContactFormType.general,
  });

  @override
  ConsumerState<ContactFormWidget> createState() => _ContactFormWidgetState();
}

class _ContactFormWidgetState extends ConsumerState<ContactFormWidget>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  
  // Animation Controllers
  late AnimationController _formAnimationController;
  late AnimationController _submitAnimationController;
  late AnimationController _errorAnimationController;
  
  // Animations
  late Animation<double> _formFadeAnimation;
  late Animation<double> _submitScaleAnimation;
  late Animation<Offset> _errorShakeAnimation;

  // Form Controllers
  final _subjectController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  // Focus Nodes
  final _subjectFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _messageFocus = FocusNode();

  // State Variables
  bool _hasInteracted = false;
  bool _isFormValid = false;
  int _characterCount = 0;
  String? _lastValidationError;

  // Debounce timer for validation
  Timer? _debounceTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _populateInitialData();
    _setupValidationListeners();
    _startAnimations();
  }

  void _initializeAnimations() {
    _formAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _submitAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _errorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _formFadeAnimation = CurvedAnimation(
      parent: _formAnimationController,
      curve: Curves.easeInOut,
    );

    _submitScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _submitAnimationController,
      curve: Curves.easeInOut,
    ));

    _errorShakeAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.1, 0),
    ).animate(CurvedAnimation(
      parent: _errorAnimationController,
      curve: Curves.elasticInOut,
    ));
  }

  void _populateInitialData() {
    _subjectController.text = widget.initialSubject ?? _getDefaultSubject();
    _emailController.text = widget.initialEmail ?? '';
    _messageController.text = widget.initialMessage ?? '';
    _characterCount = _messageController.text.length;
  }

  String _getDefaultSubject() {
    switch (widget.formType) {
      case ContactFormType.support:
        return 'Support Request';
      case ContactFormType.feedback:
        return 'App Feedback';
      case ContactFormType.bug:
        return 'Bug Report';
      case ContactFormType.feature:
        return 'Feature Request';
      default:
        return '';
    }
  }

  void _setupValidationListeners() {
    final controllers = [_subjectController, _emailController, _messageController];
    
    for (final controller in controllers) {
      controller.addListener(_onFormChanged);
    }

    _messageController.addListener(() {
      setState(() {
        _characterCount = _messageController.text.length;
      });
    });
  }

  void _onFormChanged() {
    if (!_hasInteracted) {
      setState(() {
        _hasInteracted = true;
      });
    }

    // Debounce validation
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _validateForm(silent: true);
    });
  }

  void _startAnimations() {
    _formAnimationController.forward();
  }

  @override
  void dispose() {
    _formAnimationController.dispose();
    _submitAnimationController.dispose();
    _errorAnimationController.dispose();
    
    _subjectController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    
    _subjectFocus.dispose();
    _emailFocus.dispose();
    _messageFocus.dispose();
    
    _debounceTimer?.cancel();
    
    super.dispose();
  }

  bool _validateForm({bool silent = false}) {
    if (!_formKey.currentState!.validate()) {
      if (!silent) {
        _triggerErrorAnimation();
        HapticFeedback.heavyImpact();
      }
      setState(() {
        _isFormValid = false;
      });
      return false;
    }

    setState(() {
      _isFormValid = true;
    });
    return true;
  }

  void _triggerErrorAnimation() {
    _errorAnimationController.reset();
    _errorAnimationController.forward().then((_) {
      _errorAnimationController.reverse();
    });
  }

  Future<void> _submitForm() async {
    if (!_validateForm()) return;

    HapticFeedback.lightImpact();
    
    // Trigger submit animation
    _submitAnimationController.forward();

    try {
      final success = await ref.read(contactProvider.notifier).submitContact(
        subject: _subjectController.text.trim(),
        email: _emailController.text.trim(),
        message: _messageController.text.trim(),
      );

      _submitAnimationController.reverse();

      if (success && mounted) {
        HapticFeedback.mediumImpact();
        
        // Show success state
        _showSuccessState();
        
        // Call success callback
        widget.onSuccess?.call();
        
        // Clear form after delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _clearForm();
          }
        });
      }
    } catch (e) {
      _submitAnimationController.reverse();
      _triggerErrorAnimation();
      
      if (mounted) {
        HapticFeedback.heavyImpact();
        _showErrorState(e.toString());
      }
    }
  }

  void _showSuccessState() {
    setState(() {
      _lastValidationError = null;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Message sent successfully! We\'ll get back to you soon.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showErrorState(String error) {
    setState(() {
      _lastValidationError = error;
    });
  }

  void _clearForm() {
    _subjectController.clear();
    _emailController.clear();
    _messageController.clear();
    
    setState(() {
      _hasInteracted = false;
      _isFormValid = false;
      _characterCount = 0;
      _lastValidationError = null;
    });
  }

  String? _validateSubject(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Subject is required';
    }
    if (value!.length < 3) {
      return 'Subject must be at least 3 characters';
    }
    if (value.length > 100) {
      return 'Subject must be less than 100 characters';
    }
    return null;
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

  String? _validateMessage(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Message is required';
    }
    if (value!.length < 10) {
      return 'Message must be at least 10 characters';
    }
    if (value.length > 1000) {
      return 'Message must be less than 1000 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final contactState = ref.watch(contactProvider);
    final theme = Theme.of(context);

    return ErrorBoundaryWidget(
      child: AccessibilityWidget(
        label: 'Contact Form',
        hint: 'Fill out the form to contact support',
        child: FadeTransition(
          opacity: _formFadeAnimation,
          child: SlideTransition(
            position: _errorShakeAnimation,
            child: Container(
              padding: widget.padding ?? EdgeInsets.all(widget.isCompact ? 16 : 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(widget.isCompact ? 12 : 16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: widget.isCompact ? 5 : 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Form Header (if not compact)
                    if (!widget.isCompact) ...[
                      Row(
                        children: [
                          Icon(
                            _getFormIcon(),
                            color: theme.primaryColor,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _getFormTitle(),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF181F30),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getFormDescription(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF6E757D),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Form Fields
                    EnhancedTextField(
                      label: 'Subject',
                      controller: _subjectController,
                      focusNode: _subjectFocus,
                      hintText: 'Enter subject',
                      maxLength: 100,
                      showCharacterCount: true,
                      onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                      animationDelay: 100,
                      suffixIcon: _hasInteracted && _subjectController.text.isNotEmpty
                          ? Icon(
                              _validateSubject(_subjectController.text) == null
                                  ? Icons.check_circle
                                  : Icons.error,
                              color: _validateSubject(_subjectController.text) == null
                                  ? Colors.green
                                  : Colors.red,
                              size: 20,
                            )
                          : null,
                    ),

                    SizedBox(height: widget.isCompact ? 16 : 20),

                    EnhancedTextField(
                      label: 'Email Address',
                      controller: _emailController,
                      focusNode: _emailFocus,
                      hintText: 'Enter your email',
                      keyboardType: TextInputType.emailAddress,
                      onFieldSubmitted: (_) => _messageFocus.requestFocus(),
                      animationDelay: 200,
                      suffixIcon: _hasInteracted && _emailController.text.isNotEmpty
                          ? Icon(
                              _validateEmail(_emailController.text) == null
                                  ? Icons.check_circle
                                  : Icons.error,
                              color: _validateEmail(_emailController.text) == null
                                  ? Colors.green
                                  : Colors.red,
                              size: 20,
                            )
                          : null,
                    ),

                    SizedBox(height: widget.isCompact ? 16 : 20),

                    EnhancedTextField(
                      label: 'Message',
                      controller: _messageController,
                      focusNode: _messageFocus,
                      hintText: 'Type your message...',
                      maxLines: widget.isCompact ? 3 : 5,
                      maxLength: 1000,
                      showCharacterCount: true,
                      onFieldSubmitted: (_) => _submitForm(),
                      animationDelay: 300,
                    ),

                    // Character counter with color coding
                    if (!widget.isCompact) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '$_characterCount/1000',
                            style: TextStyle(
                              fontSize: 12,
                              color: _characterCount > 900
                                  ? Colors.red
                                  : _characterCount > 800
                                      ? Colors.orange
                                      : Colors.grey[600],
                              fontWeight: _characterCount > 900 ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Error Message
                    if (_lastValidationError != null) ...[
                      SizedBox(height: widget.isCompact ? 12 : 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error, color: Colors.red.shade600, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _lastValidationError!,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn().shake(),
                    ],

                    SizedBox(height: widget.isCompact ? 20 : 32),

                    // Action Buttons
                    Row(
                      children: [
                        if (widget.showCancelButton) ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: contactState.isLoading ? null : widget.onCancel,
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  vertical: widget.isCompact ? 12 : 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: widget.isCompact ? 14 : 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF6E757D),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: widget.isCompact ? 12 : 16),
                        ],
                        Expanded(
                          flex: widget.showCancelButton ? 1 : 1,
                          child: ScaleTransition(
                            scale: _submitScaleAnimation,
                            child: AnimatedButton(
                              onPressed: contactState.isLoading || !_isFormValid ? null : _submitForm,
                              isLoading: contactState.isLoading,
                              backgroundColor: const Color(0xFFFFC000),
                              foregroundColor: const Color(0xFF181F30),
                              height: widget.isCompact ? 44 : 56,
                              borderRadius: 12,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (!contactState.isLoading) ...[
                                    Icon(Icons.send, size: widget.isCompact ? 16 : 20),
                                    SizedBox(width: widget.isCompact ? 6 : 8),
                                  ],
                                  Text(
                                    contactState.isLoading ? 'Sending...' : 'Send Message',
                                    style: TextStyle(
                                      fontSize: widget.isCompact ? 14 : 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Form Validation Status
                    if (_hasInteracted && !widget.isCompact) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _isFormValid 
                              ? Colors.green.shade50 
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isFormValid 
                                ? Colors.green.shade200 
                                : Colors.orange.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isFormValid ? Icons.check_circle : Icons.info,
                              color: _isFormValid 
                                  ? Colors.green.shade600 
                                  : Colors.orange.shade600,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _isFormValid 
                                    ? 'Form is ready to submit'
                                    : 'Please complete all required fields',
                                style: TextStyle(
                                  color: _isFormValid 
                                      ? Colors.green.shade700 
                                      : Colors.orange.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: const Duration(milliseconds: 500)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getFormIcon() {
    switch (widget.formType) {
      case ContactFormType.support:
        return Icons.support_agent;
      case ContactFormType.feedback:
        return Icons.feedback;
      case ContactFormType.bug:
        return Icons.bug_report;
      case ContactFormType.feature:
        return Icons.lightbulb;
      default:
        return Icons.contact_support;
    }
  }

  String _getFormTitle() {
    switch (widget.formType) {
      case ContactFormType.support:
        return 'Need Support?';
      case ContactFormType.feedback:
        return 'Share Feedback';
      case ContactFormType.bug:
        return 'Report a Bug';
      case ContactFormType.feature:
        return 'Request Feature';
      default:
        return 'Contact Us';
    }
  }

  String _getFormDescription() {
    switch (widget.formType) {
      case ContactFormType.support:
        return 'Having trouble? Our support team is here to help you resolve any issues.';
      case ContactFormType.feedback:
        return 'We value your feedback! Let us know how we can improve your experience.';
      case ContactFormType.bug:
        return 'Found a bug? Help us improve by reporting the issue with details.';
      case ContactFormType.feature:
        return 'Have an idea for a new feature? We\'d love to hear your suggestions!';
      default:
        return 'Get in touch with us. We\'re here to help!';
    }
  }
}

enum ContactFormType {
  general,
  support,
  feedback,
  bug,
  feature,
}
