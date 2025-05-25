import 'dart:async';
import '../api/api_client.dart';
import '../models/api_response.dart';
import '../models/transaction_model.dart';
import '../../providers/tracking_provider.dart';
import 'package:flutter/material.dart';

class TrackingService {
  final ApiClient _apiClient;
  final Map<String, StreamController<TransferDetails>> _watchStreams = {};

  TrackingService(this._apiClient);

  // Track a transfer by tracking number
  Future<ApiResponse<Map<String, dynamic>>> trackTransfer(
    String trackingNumber,
  ) async {
    try {
      final response = await _apiClient.get(
        '/api/transfers/track/$trackingNumber',
      );

      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Failed to track transfer: ${e.toString()}',
      );
    }
  }

  // Get recent transfers for the user
  Future<List<TransferDetails>> getRecentTransfers({int limit = 10}) async {
    try {
      final response = await _apiClient.get(
        '/api/transfers/recent',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200 && response.data['success']) {
        final List<dynamic> transfersData = response.data['data'];
        return transfersData
            .map((json) => TransferDetails.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  // Search transfers by criteria
  Future<List<TransferDetails>> searchTransfers({
    String? senderName,
    String? receiverName,
    DateTimeRange? dateRange,
    TransferStatus? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (senderName != null) queryParams['senderName'] = senderName;
      if (receiverName != null) queryParams['receiverName'] = receiverName;
      if (status != null) queryParams['status'] = status.name;

      if (dateRange != null) {
        queryParams['startDate'] = dateRange.start.toIso8601String();
        queryParams['endDate'] = dateRange.end.toIso8601String();
      }

      final response = await _apiClient.get(
        '/api/transfers/search',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success']) {
        final List<dynamic> transfersData = response.data['data'];
        return transfersData
            .map((json) => TransferDetails.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  // Get transfer statistics
  Future<Map<String, dynamic>> getTransferStatistics() async {
    try {
      final response = await _apiClient.get('/api/transfers/statistics');

      if (response.statusCode == 200 && response.data['success']) {
        return response.data['data'] as Map<String, dynamic>;
      }

      return {};
    } catch (e) {
      return {};
    }
  }

  // Watch transfer updates in real-time
  Stream<TransferDetails> watchTransferUpdates(String trackingNumber) {
    // Close existing stream if any
    _watchStreams[trackingNumber]?.close();

    final controller = StreamController<TransferDetails>.broadcast();
    _watchStreams[trackingNumber] = controller;

    // Start polling for updates
    _startPolling(trackingNumber, controller);

    return controller.stream;
  }

  // Start polling for transfer updates
  void _startPolling(
    String trackingNumber,
    StreamController<TransferDetails> controller,
  ) {
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        final response = await trackTransfer(trackingNumber);

        if (response.success && response.data != null) {
          final transferDetails = TransferDetails.fromJson(response.data!);
          controller.add(transferDetails);

          // Stop polling if transfer is completed
          if (!transferDetails.isActive) {
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

  // Ping service for connectivity check
  Future<void> ping() async {
    try {
      await _apiClient.get('/api/health/ping');
    } catch (e) {
      throw Exception('Service unavailable');
    }
  }

  // Get transfer timeline/events
  Future<List<TrackingEvent>> getTransferTimeline(String trackingNumber) async {
    try {
      final response = await _apiClient.get(
        '/api/transfers/$trackingNumber/timeline',
      );

      if (response.statusCode == 200 && response.data['success']) {
        final List<dynamic> eventsData = response.data['data'];
        return eventsData.map((json) => TrackingEvent.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  // Report transfer issue
  Future<bool> reportTransferIssue({
    required String trackingNumber,
    required String issueType,
    required String description,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/transfers/$trackingNumber/report-issue',
        data: {'issueType': issueType, 'description': description},
      );

      return response.statusCode == 200 && response.data['success'];
    } catch (e) {
      return false;
    }
  }

  // Cancel transfer
  Future<bool> cancelTransfer(String trackingNumber) async {
    try {
      final response = await _apiClient.post(
        '/api/transfers/$trackingNumber/cancel',
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
        '/api/transfers/$trackingNumber/estimate',
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
