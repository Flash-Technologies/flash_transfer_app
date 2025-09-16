import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flash_transfer_app/core/services/reown_service.dart';
import 'package:flash_transfer_app/providers/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReownWalletAuthButton extends ConsumerStatefulWidget {
  final Function()? onWalletLogin;
  final bool isSignUp;
  final double? width;
  
  const ReownWalletAuthButton({
    Key? key,
    this.onWalletLogin,
    this.isSignUp = false,
    this.width,
  }) : super(key: key);

  @override
  ConsumerState<ReownWalletAuthButton> createState() => _ReownWalletAuthButtonState();
}

class _ReownWalletAuthButtonState extends ConsumerState<ReownWalletAuthButton> {
  bool _isConnecting = false;
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    // Set as initialized immediately if already initialized
    if (ReownService.instance.isInitialized) {
      _isInitialized = true;
    } else {
      // Start background initialization but allow button to be enabled
      _initializeReown();
    }
  }
  
  Future<void> _initializeReown() async {
    // Allow button to be clicked immediately, initialization will happen on demand
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
    
    try {
      if (!ReownService.instance.isInitialized) {
        await ReownService.instance.initialize(context);
      }
    } catch (e) {
      debugPrint('Error initializing Reown for auth: $e');
      // Button remains functional, initialization will retry on wallet click
    }
  }
  
  Future<void> _handleReownWalletLogin() async {
    if (widget.onWalletLogin != null) {
      widget.onWalletLogin!();
      return;
    }
    
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    setState(() {
      _isConnecting = true;
    });
    
    try {
      // Initialize Reown if not already done
      if (!ReownService.instance.isInitialized) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Initializing wallet connection...')),
        );
        await ReownService.instance.initialize(context);
      }
      
      // Connect wallet and get address
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Opening wallet selection...')),
      );
      
      final walletAddress = await ReownService.instance.connectForAuth();
      
      if (walletAddress == null || walletAddress.isEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Wallet connection cancelled or failed'),
            backgroundColor: Colors.orange,
          ),
        );
        // Reset loading state immediately when cancelled
        if (mounted) {
          setState(() {
            _isConnecting = false;
          });
        }
        return;
      }
      
      // Show connected address
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Connected: ${walletAddress.substring(0, 6)}...${walletAddress.substring(walletAddress.length - 4)}'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Get user country
      String countryName = 'Unknown';
      try {
        final response = await http.get(Uri.parse('https://ipapi.co/json/'));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          countryName = data['country_name'] ?? 'Unknown';
          debugPrint('Detected country: $countryName');
        }
      } catch (e) {
        debugPrint('Failed to fetch user country: $e');
      }
      
      // Show authenticating message
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(widget.isSignUp ? 'Creating account...' : 'Signing in...'),
        ),
      );
      
      // Authenticate with backend
      final success = await ref
          .read(authProvider.notifier)
          .loginWithWalletAddress(walletAddress, countryName);
      
      if (success) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(widget.isSignUp ? 'Account created successfully!' : 'Login successful!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to home
        await Future.delayed(const Duration(milliseconds: 500));
        if (!context.mounted) return;
        context.go('/home');
      } else {
        final errorMessage = ref.read(authProvider).message ?? 
            (widget.isSignUp ? 'Failed to create account' : 'Login failed');
        
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
        
        // Optionally disconnect wallet on auth failure
        await ReownService.instance.disconnect();
      }
    } catch (e) {
      debugPrint('Reown wallet auth error: $e');
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Wallet authentication error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width ?? 160,
      child: ElevatedButton(
        onPressed: (_isConnecting || !_isInitialized) ? null : _handleReownWalletLogin,
        style: ElevatedButton.styleFrom(
          foregroundColor: const Color(0xFF6E757D),
          backgroundColor: const Color(0xFFF4F5F7),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isConnecting)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(0xFF6E757D),
                  ),
                ),
              )
            else if (ReownService.instance.isConnected)
              const Icon(
                Icons.check_circle,
                size: 24,
                color: Colors.green,
              )
            else
              Image.asset(
                'assets/images/wallet.png',
                width: 24,
                height: 24,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.account_balance_wallet,
                  size: 24,
                  color: Colors.black,
                ),
              ),
            const SizedBox(width: 8.0),
            Text(
              _isConnecting 
                  ? 'Connecting...' 
                  : ReownService.instance.isConnected
                      ? 'Connected'
                      : 'Wallet',
              style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}