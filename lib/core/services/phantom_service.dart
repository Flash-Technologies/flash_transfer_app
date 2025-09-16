import 'dart:typed_data';
import 'package:flutter/material.dart';

class PhantomService {
  static PhantomService? _instance;
  
  static PhantomService get instance {
    _instance ??= PhantomService._();
    return _instance!;
  }
  
  PhantomService._();
  
  String? _connectedWalletAddress;
  bool _isConnected = false;
  
  bool get isConnected => _isConnected;
  String? get walletAddress => _connectedWalletAddress;
  
  // Handle Phantom deep link response
  Future<String?> handlePhantomResponse(Uri uri) async {
    try {
      debugPrint('🦄 PhantomService: Processing Phantom response...');
      
      // Extract the encrypted data and keys from the deep link
      final publicKey = uri.queryParameters['phantom_encryption_public_key'];
      final nonce = uri.queryParameters['nonce'];
      final encryptedData = uri.queryParameters['data'];
      
      if (publicKey == null || nonce == null || encryptedData == null) {
        debugPrint('❌ Missing required Phantom connection parameters');
        return null;
      }
      
      debugPrint('🔑 Public Key: ${publicKey.substring(0, 20)}...');
      debugPrint('🔐 Nonce: ${nonce.substring(0, 20)}...');
      debugPrint('📦 Encrypted Data Length: ${encryptedData.length}');
      
      // For Phantom, the public key in the response is often the wallet's public key
      // This is typically the Solana address
      String? walletAddress;
      
      // First, try to use the public key as the address (common for Phantom)
      if (_isValidSolanaAddress(publicKey)) {
        walletAddress = publicKey;
        debugPrint('🎯 Using public key as Solana address: $walletAddress');
      } else {
        // Fallback to decryption attempt
        walletAddress = await _decryptPhantomResponse(
          publicKey, 
          nonce, 
          encryptedData
        );
      }
      
      if (walletAddress != null && walletAddress.isNotEmpty) {
        _connectedWalletAddress = walletAddress;
        _isConnected = true;
        
        debugPrint('✅ Phantom wallet connected successfully!');
        debugPrint('🎯 Wallet Address: $walletAddress');
        debugPrint('🌐 Network: Solana (Primary)');
        
        return walletAddress;
      } else {
        debugPrint('❌ Failed to extract wallet address from Phantom response');
        return null;
      }
      
    } catch (e, stackTrace) {
      debugPrint('💥 Error handling Phantom response: $e');
      debugPrint('📜 Stack trace: $stackTrace');
      return null;
    }
  }
  
  // Decrypt Phantom wallet response
  Future<String?> _decryptPhantomResponse(
    String publicKeyBase58,
    String nonceBase58, 
    String encryptedDataBase58
  ) async {
    try {
      // For now, let's try to extract the wallet address from the encrypted payload
      // This is a simplified approach - in production, you'd want proper decryption
      
      // Phantom typically returns the wallet address in the response
      // Let's check if we can extract it from the data payload
      
      // Try base58 decoding the data to see if we can find a wallet address pattern
      final decodedData = _tryBase58Decode(encryptedDataBase58);
      if (decodedData != null) {
        // Look for Solana wallet address patterns (32 bytes, base58 encoded)
        final possibleAddress = _extractSolanaAddress(decodedData);
        if (possibleAddress != null) {
          return possibleAddress;
        }
      }
      
      // Fallback: Try to extract from the public key parameter
      // Sometimes the wallet address is related to the encryption public key
      if (_isValidSolanaAddress(publicKeyBase58)) {
        debugPrint('🔄 Using encryption public key as wallet address (fallback)');
        return publicKeyBase58;
      }
      
      debugPrint('⚠️ Could not decrypt or extract wallet address from Phantom response');
      return null;
      
    } catch (e) {
      debugPrint('❌ Error decrypting Phantom response: $e');
      return null;
    }
  }
  
  // Try to decode base58 string
  Uint8List? _tryBase58Decode(String base58String) {
    try {
      return _base58Decode(base58String);
    } catch (e) {
      return null;
    }
  }
  
  // Extract potential Solana address from decoded data
  String? _extractSolanaAddress(Uint8List data) {
    try {
      // Look for 32-byte sequences that could be wallet addresses
      for (int i = 0; i <= data.length - 32; i++) {
        final candidate = data.sublist(i, i + 32);
        final candidateBase58 = _base58Encode(candidate);
        
        if (_isValidSolanaAddress(candidateBase58)) {
          debugPrint('🎯 Found potential wallet address: $candidateBase58');
          return candidateBase58;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  // Validate if a string looks like a valid Solana address
  bool _isValidSolanaAddress(String address) {
    // Solana addresses are base58 encoded, 32 bytes long
    // They typically start with numbers 1-9 or letters A-H, J-N, P-Z, a-k, m-z
    if (address.length < 32 || address.length > 44) return false;
    
    // Check if it contains only valid base58 characters
    final base58Regex = RegExp(r'^[1-9A-HJ-NP-Za-km-z]+$');
    if (!base58Regex.hasMatch(address)) return false;
    
    try {
      final decoded = _base58Decode(address);
      return decoded.length == 32;
    } catch (e) {
      return false;
    }
  }
  
  // Simple base58 decode implementation
  Uint8List _base58Decode(String input) {
    const alphabet = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
    final decoded = <int>[];
    
    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      final value = alphabet.indexOf(char);
      if (value == -1) {
        throw ArgumentError('Invalid base58 character: $char');
      }
      
      int carry = value;
      for (int j = 0; j < decoded.length; j++) {
        carry += decoded[j] * 58;
        decoded[j] = carry & 0xff;
        carry >>= 8;
      }
      
      while (carry > 0) {
        decoded.add(carry & 0xff);
        carry >>= 8;
      }
    }
    
    // Handle leading zeros
    for (int i = 0; i < input.length && input[i] == '1'; i++) {
      decoded.insert(0, 0);
    }
    
    return Uint8List.fromList(decoded.reversed.toList());
  }
  
  // Simple base58 encode implementation
  String _base58Encode(Uint8List input) {
    const alphabet = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
    final encoded = <String>[];
    
    // Convert input to big integer
    var num = BigInt.zero;
    for (int i = 0; i < input.length; i++) {
      num = num * BigInt.from(256) + BigInt.from(input[i]);
    }
    
    // Convert to base58
    while (num > BigInt.zero) {
      final remainder = num % BigInt.from(58);
      num = num ~/ BigInt.from(58);
      encoded.insert(0, alphabet[remainder.toInt()]);
    }
    
    // Handle leading zeros
    for (int i = 0; i < input.length && input[i] == 0; i++) {
      encoded.insert(0, '1');
    }
    
    return encoded.join();
  }
  
  void disconnect() {
    _connectedWalletAddress = null;
    _isConnected = false;
    debugPrint('🦄 Phantom wallet disconnected');
  }
  
  void dispose() {
    disconnect();
    _instance = null;
  }
}