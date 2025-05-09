import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  final String email;

  const VerificationScreen({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    4,
    (_) => FocusNode(),
  );
  
  int _timerSeconds = 120;
  Timer? _timer;
  bool _isResending = false;
  
  @override
  void initState() {
    super.initState();
    _startTimer();
    
    for (var i = 0; i < _controllers.length; i++) {
      _focusNodes[i].addListener(() {
        if (_focusNodes[i].hasFocus && _controllers[i].text.isNotEmpty) {
          _controllers[i].selection = TextSelection.fromPosition(
            TextPosition(offset: _controllers[i].text.length),
          );
        }
      });
    }
  }
  
  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }
  
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timerSeconds > 0) {
          _timerSeconds--;
        } else {
          timer.cancel();
        }
      });
    });
  }
  
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  Future<void> _resendCode() async {
    if (_timerSeconds > 0 || _isResending) return;
    
    setState(() {
      _isResending = true;
    });
    
    final success = await ref.read(authProvider.notifier).resendVerification(widget.email);
    
    if (mounted) {
      setState(() {
        _isResending = false;
        if (success) {
          _timerSeconds = 120;
          _startTimer();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Verification code has been resent')),
          );
        } else {
          final errorMessage = ref.read(authProvider).message ?? 'Failed to resend code';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      });
    }
  }
  
  void _verifyCode() {
    final code = _controllers.map((c) => c.text).join();
    
    if (code.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter complete verification code')),
      );
      return;
    }
    
    // This is just a demo verification since the actual verification 
    // happens via email link click in this app
    // In a real app, you would call an API to verify the code
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verification Success'),
        content: const Text('Your account has been verified successfully.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/success');
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify your code'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/sign-up'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  text: 'Check your email inbox, we have sent you the code at ',
                  style: const TextStyle(color: Colors.black),
                  children: [
                    TextSpan(
                      text: widget.email,
                      style: TextStyle(color: Theme.of(context).primaryColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _controllers.length,
                  (index) => Container(
                    width: 60,
                    height: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      decoration: InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: _controllers[index].text.isNotEmpty
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: _controllers[index].text.isNotEmpty
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                      style: Theme.of(context).textTheme.titleLarge,
                      onChanged: (value) {
                        if (value.isNotEmpty && index < _controllers.length - 1) {
                          _focusNodes[index + 1].requestFocus();
                        }
                      },
                      onEditingComplete: () {
                        if (index < _controllers.length - 1) {
                          _focusNodes[index + 1].requestFocus();
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _timerSeconds > 0 || _isResending ? null : _resendCode,
                    child: Text(
                      'Didn\'t get the code? Resend',
                      style: TextStyle(
                        color: _timerSeconds > 0 || _isResending
                            ? Colors.grey
                            : Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  Text(_formatTime(_timerSeconds)),
                ],
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _verifyCode,
                  child: const Text('Verify and Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}