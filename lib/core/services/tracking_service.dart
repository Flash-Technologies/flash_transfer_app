import 'dart:async';
import '../api/api_client.dart';
import '../models/api_response.dart';
import '../models/transaction_model.dart';
import 'package:flutter/material.dart';

class TrackingService {
  final ApiClient _apiClient;
  final Map<String, StreamController<Transaction>> _watchStreams = {};

  TrackingService(this._apiClient);

  // Track a transfer by tracking number
  Future<ApiResponse<Map<String, dynamic>>> trackTransfer(
    String trackingNumber,
  ) async {
    try {
      print('🔍 Tracking API: Searching for transaction $trackingNumber');

      // Try to find the transaction in the user's transaction list
      final response = await _apiClient.get(
        '/api/transaction',
        queryParameters: {
          'page': 1,
          'limit': 100, // Search through recent transactions
          'sortBy': 'createdAt',
          'sortOrder': 'desc',
        },
      );

      print('📞 API Response Status: ${response.statusCode}');
      print('📦 API Response Data: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        Map<String, dynamic> responseData;
        
        if (response.data is Map<String, dynamic>) {
          responseData = response.data as Map<String, dynamic>;
          
          // Search through transactions to find matching tracking number
          if (responseData['success'] == true && responseData['data'] != null) {
            final transactions = responseData['data']['data'] as List?;
            
            if (transactions != null) {
              print('🔍 Searching through ${transactions.length} transactions for $trackingNumber');
              
              // Look for transaction with matching tracking number
              for (var transaction in transactions) {
                if (transaction is Map<String, dynamic>) {
                  final transactionTrackingNumber = transaction['trackingNumber']?.toString();
                  print('📋 Checking transaction: $transactionTrackingNumber vs $trackingNumber');
                  
                  if (transactionTrackingNumber == trackingNumber) {
                    print('🎉 Found matching transaction!');
                    // Found matching transaction
                    return ApiResponse<Map<String, dynamic>>(
                      success: true,
                      message: 'Transaction found successfully',
                      data: {
                        'transaction': transaction,
                        'statusDetails': {
                          'status': transaction['status'],
                          'statusMessage': transaction['statusMessage'] ?? 'Transaction in progress',
                          'estimatedCompletion': transaction['estimatedCompletion'],
                        }
                      },
                    );
                  }
                }
              }
              print('❌ No matching transaction found in ${transactions.length} transactions');
            }
          }
        }
        
        // If we reach here, transaction wasn't found
        throw Exception('Transaction not found in user transactions');
      } else {
        throw Exception('Failed to fetch transactions');
      }

    } catch (e) {
      print('❌ API Error: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Sorry, no transaction found for this tracking ID. Please check the tracking number and try again.',
      );
    }
  }

  // Get recent transactions for the user
  Future<List<Transaction>> getRecentTransactions({int limit = 10}) async {
    try {
      final response = await _apiClient.get(
        '/api/transactions/recent',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200 && response.data['success']) {
        final List<dynamic> transactionsData = response.data['data'];
        return transactionsData
            .map((json) => Transaction.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  // Search transactions by criteria
  Future<List<Transaction>> searchTransactions({
    String? senderName,
    String? receiverName,
    DateTimeRange? dateRange,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (senderName != null) queryParams['senderName'] = senderName;
      if (receiverName != null) queryParams['receiverName'] = receiverName;
      if (status != null) queryParams['status'] = status;

      if (dateRange != null) {
        queryParams['startDate'] = dateRange.start.toIso8601String();
        queryParams['endDate'] = dateRange.end.toIso8601String();
      }

      final response = await _apiClient.get(
        '/api/transactions/search',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success']) {
        final List<dynamic> transactionsData = response.data['data'];
        return transactionsData
            .map((json) => Transaction.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  // Get transaction statistics
  Future<Map<String, dynamic>> getTransactionStatistics() async {
    try {
      final response = await _apiClient.get('/api/transactions/statistics');

      if (response.statusCode == 200 && response.data['success']) {
        return response.data['data'] as Map<String, dynamic>;
      }

      return {};
    } catch (e) {
      return {};
    }
  }

  // Watch transaction updates in real-time
  Stream<Transaction> watchTransactionUpdates(String trackingNumber) {
    // Close existing stream if any
    _watchStreams[trackingNumber]?.close();

    final controller = StreamController<Transaction>.broadcast();
    _watchStreams[trackingNumber] = controller;

    // Start polling for updates
    _startPolling(trackingNumber, controller);

    return controller.stream;
  }

  // Start polling for transaction updates
  void _startPolling(
    String trackingNumber,
    StreamController<Transaction> controller,
  ) {
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        final response = await trackTransfer(trackingNumber);

        if (response.success && response.data != null) {
          final transactionData = TransactionData.fromJson(response.data!);
          controller.add(transactionData.transaction);

          // Stop polling if transaction is completed
          if (transactionData.transaction.status.toLowerCase() == 'completed' ||
              transactionData.transaction.status.toLowerCase() == 'failed' ||
              transactionData.transaction.status.toLowerCase() == 'cancelled') {
            timer.cancel();
            controller.close();
            _watchStreams.remove(trackingNumber);
          }
        } else {
          // Stop polling on error
          timer.cancel();
          controller.close();
          _watchStreams.remove(trackingNumber);
        }
      } catch (e) {
        // Continue polling on error, but limit retries
        if (timer.tick > 10) {
          // Stop after 5 minutes
          timer.cancel();
          controller.close();
          _watchStreams.remove(trackingNumber);
        }
      }
    });
  }

  // Get transaction timeline/events (status history)
  Future<List<StatusHistory>> getTransactionTimeline(
      String trackingNumber) async {
    try {
      final response = await _apiClient.get(
        '/api/transaction/$trackingNumber/timeline',
      );

      if (response.statusCode == 200 && response.data['success']) {
        final List<dynamic> eventsData = response.data['data'];
        return eventsData.map((json) => StatusHistory.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  // Report transaction issue
  Future<bool> reportTransactionIssue({
    required String trackingNumber,
    required String issueType,
    required String description,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/transaction/$trackingNumber/report-issue',
        data: {'issueType': issueType, 'description': description},
      );

      return response.statusCode == 200 && response.data['success'];
    } catch (e) {
      return false;
    }
  }

  // Cancel transaction
  Future<bool> cancelTransaction(String trackingNumber) async {
    try {
      final response = await _apiClient.post(
        '/api/transaction/$trackingNumber/cancel',
      );

      return response.statusCode == 200 && response.data['success'];
    } catch (e) {
      return false;
    }
  }

  // Get estimated delivery time
  Future<DateTime?> getEstimatedDelivery(String trackingNumber) async {
    try {
      final response = await _apiClient.get(
        '/api/transaction/$trackingNumber/estimate',
      );

      if (response.statusCode == 200 && response.data['success']) {
        final estimateStr = response.data['data']['estimatedDelivery'];
        return DateTime.parse(estimateStr);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Dispose all streams
  void dispose() {
    for (final controller in _watchStreams.values) {
      controller.close();
    }
    _watchStreams.clear();
  }
}
