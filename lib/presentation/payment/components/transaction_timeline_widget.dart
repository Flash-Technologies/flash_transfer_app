import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flash_transfer_app/config/ui_constants.dart';
import 'package:flash_transfer_app/providers/language_provider.dart';
import 'package:intl/intl.dart';

class TransactionTimelineWidget extends ConsumerStatefulWidget {
  final List<dynamic>? enhancedTimeline;
  final Map<String, dynamic>? statusDetails;
  
  const TransactionTimelineWidget({
    Key? key,
    this.enhancedTimeline,
    this.statusDetails,
  }) : super(key: key);

  @override
  ConsumerState<TransactionTimelineWidget> createState() => _TransactionTimelineWidgetState();
}

class _TransactionTimelineWidgetState extends ConsumerState<TransactionTimelineWidget> {
  bool _isExpanded = false;
  
  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationHelperProvider);
    final timeline = widget.enhancedTimeline ?? [];
    if (timeline.isEmpty && widget.statusDetails == null) {
      return SizedBox.shrink();
    }
    
    // Filter timeline items for user visibility
    final visibleItems = timeline.where((item) => 
      item['userVisible'] == true || item['importance'] == 'CRITICAL'
    ).toList();
    
    if (visibleItems.isEmpty && widget.statusDetails == null) {
      return SizedBox.shrink();
    }
    
    // Show max 3 items initially, rest behind "View More"
    final displayItems = _isExpanded ? visibleItems : visibleItems.take(3).toList();
    final hasMore = visibleItems.length > 3;
    
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.marginL),
      padding: EdgeInsets.all(AppSpacing.paddingL),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.radiusL),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tr('transaction.timeline.title'),
                  style: AppTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (widget.statusDetails?['lastChecked'] != null)
                Flexible(
                  child: Text(
                    '${tr('transaction.timeline.updated')}: ${_formatLastChecked(widget.statusDetails!['lastChecked'], tr)}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
            ],
          ),
          
          SizedBox(height: AppSpacing.marginL),
          
          // Timeline items
          ...displayItems.map((item) => _buildTimelineItem(item)),
          
          // View More button
          if (hasMore) ...[
            SizedBox(height: AppSpacing.marginM),
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isExpanded ? tr('transaction.timeline.viewLess') : tr('transaction.timeline.viewMore'),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.primaryBlue,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
          
          // Additional status info if monitoring
          if (widget.statusDetails?['monitoredByCentralizedSystem'] == true) ...[
            SizedBox(height: AppSpacing.marginL),
            Container(
              padding: EdgeInsets.all(AppSpacing.paddingM),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(AppRadius.radiusM),
                border: Border.all(
                  color: AppColors.primaryBlue.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.visibility,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                  SizedBox(width: AppSpacing.marginS),
                  Expanded(
                    child: Text(
                      tr('transaction.timeline.monitoringMessage'),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildTimelineItem(Map<String, dynamic> item) {
    final tr = ref.watch(translationHelperProvider);
    final icon = _getIconForEvent(item);
    final color = _getColorForEvent(item);
    final isLastItem = widget.enhancedTimeline?.last == item;
    
    return Container(
      margin: EdgeInsets.only(bottom: isLastItem ? 0 : AppSpacing.marginM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and line
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    item['icon'] ?? icon,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              if (!isLastItem)
                Container(
                  width: 2,
                  height: 40,
                  color: AppColors.border,
                ),
            ],
          ),
          
          SizedBox(width: AppSpacing.marginM),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item['title'] ?? _getTranslatedEventType(item['eventType'], tr) ?? tr('transaction.timeline.event'),
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                    if (item['relativeTime'] != null)
                      Text(
                        item['relativeTime'],
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
                
                SizedBox(height: 4),
                
                Text(
                  item['description'] ?? '',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: _isExpanded ? null : 2,
                  overflow: _isExpanded ? null : TextOverflow.ellipsis,
                ),
                
                // Additional details for critical items
                if (item['importance'] == 'CRITICAL' && item['details'] != null) ...[
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(AppSpacing.paddingS),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(AppRadius.radiusS),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item['details']['errorMessage'] != null)
                          Text(
                            '${tr('transaction.timeline.error')}: ${item['details']['errorMessage']}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.error,
                              fontSize: 11,
                            ),
                          ),
                        if (item['details']['amount'] != null)
                          Text(
                            '${tr('transaction.timeline.amount')}: ${item['details']['amount']}',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _getIconForEvent(Map<String, dynamic> item) {
    switch (item['eventType']) {
      case 'TRANSACTION_CREATED':
        return '🎯';
      case 'TRANSACTION_PROCESSING':
        return '⚙️';
      case 'TRANSACTION_SUCCESS':
        return '✅';
      case 'TRANSACTION_FAILURE':
        return '❌';
      case 'SYSTEM_EVENT':
        return '📋';
      case 'PAYMENT_CONFIRMED':
        return '💰';
      case 'MONITORING':
        return '👀';
      default:
        return '📌';
    }
  }
  
  Color _getColorForEvent(Map<String, dynamic> item) {
    switch (item['category'] ?? item['eventType']) {
      case 'SUCCESS':
        return AppColors.success;
      case 'ERROR':
      case 'TRANSACTION_FAILURE':
        return AppColors.error;
      case 'WARNING':
        return AppColors.primaryYellow;
      case 'SYSTEM':
        return AppColors.textSecondary;
      default:
        return AppColors.primaryBlue;
    }
  }
  
  String _getTranslatedEventType(String? eventType, Function tr) {
    switch (eventType) {
      case 'TRANSACTION_CREATED':
        return tr('transaction.timeline.transactionCreated');
      case 'TRANSACTION_PROCESSING':
        return tr('transaction.timeline.transactionProcessing');
      case 'TRANSACTION_SUCCESS':
        return tr('transaction.timeline.transactionSuccess');
      case 'TRANSACTION_FAILURE':
        return tr('transaction.timeline.transactionFailure');
      case 'SYSTEM_EVENT':
        return tr('transaction.timeline.systemEvent');
      case 'PAYMENT_CONFIRMED':
        return tr('transaction.timeline.paymentConfirmed');
      case 'MONITORING':
        return tr('transaction.timeline.monitoring');
      default:
        return tr('transaction.timeline.event');
    }
  }

  String _formatLastChecked(String timestamp, Function tr) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inSeconds < 60) {
        return tr('transaction.timeline.timeFormat.secondsAgo', {'seconds': difference.inSeconds});
      } else if (difference.inMinutes < 60) {
        return tr('transaction.timeline.timeFormat.minutesAgo', {'minutes': difference.inMinutes});
      } else if (difference.inHours < 24) {
        return tr('transaction.timeline.timeFormat.hoursAgo', {'hours': difference.inHours});
      } else {
        return DateFormat('MMM dd, HH:mm').format(date);
      }
    } catch (e) {
      return timestamp;
    }
  }
}