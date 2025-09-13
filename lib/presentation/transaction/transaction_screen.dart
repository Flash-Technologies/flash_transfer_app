import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/services/translation_service.dart';
import '../../core/models/transaction_model.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/auth_provider.dart';
import 'widgets/transaction_card_widget.dart';
import 'widgets/transaction_filter_widget.dart';
import 'widgets/transaction_header_widget.dart' as header;

class TransactionScreen extends ConsumerStatefulWidget {
  const TransactionScreen({super.key});

  @override
  ConsumerState<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends ConsumerState<TransactionScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _contentAnimationController;
  late AnimationController _filterAnimationController;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _contentFadeAnimation;
  late Animation<double> _filterScaleAnimation;

  final ScrollController _scrollController = ScrollController();
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    
    // Load transactions after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Debug: Check if user is logged in before fetching transactions
      final authState = ref.read(authProvider);
      print('🔍 DEBUG: Transaction screen - User logged in: ${authState.user != null}');
      print('🔍 DEBUG: Transaction screen - User ID: ${authState.user?.id}');
      print('🔍 DEBUG: Transaction screen - Has token: ${authState.user?.token != null}');
      
      ref.read(transactionsProvider.notifier).fetchTransactions();
    });
  }

  void _initializeAnimations() {
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    _contentFadeAnimation = CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeInOut,
    );

    _filterScaleAnimation = CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.elasticOut,
    );

    // Start animations
    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _contentAnimationController.forward();
    });
  }

  void _filterTransactions(String filter) {
    _filterAnimationController.forward().then((_) {
      _filterAnimationController.reverse();
    });

    setState(() {
      _selectedFilter = filter;
    });

    // Haptic feedback
    HapticFeedback.selectionClick();
  }

  Future<void> _refreshTransactions() async {
    HapticFeedback.mediumImpact();
    await ref.read(transactionsProvider.notifier).fetchTransactions(refresh: true);
  }

  List<Transaction> _getFilteredTransactions(List<Transaction> transactions) {
    switch (_selectedFilter) {
      case 'sent':
        return transactions.where((t) => t.type.contains('TO')).toList();
      case 'received':
        return transactions.where((t) => t.destinationType == 'CRYPTO_WALLET').toList();
      case 'thisMonth':
        final now = DateTime.now();
        final thisMonth = DateTime(now.year, now.month);
        return transactions.where((t) => t.createdAt.isAfter(thisMonth)).toList();
      case 'lastMonth':
        final now = DateTime.now();
        final lastMonth = DateTime(now.year, now.month - 1);
        final thisMonth = DateTime(now.year, now.month);
        return transactions
            .where((t) => t.createdAt.isAfter(lastMonth) && t.createdAt.isBefore(thisMonth))
            .toList();
      default:
        return transactions;
    }
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _contentAnimationController.dispose();
    _filterAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final translationService = TranslationService.instance;

    return Scaffold(
      backgroundColor: const Color(0xFFEFF0F1),
      body: Column(
        children: [
          // Header
          SlideTransition(
            position: _headerSlideAnimation,
            child: header.TransactionHeaderWidget(
              title: translationService.translate('transaction.screen.title'),
              onBackPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // Content
          Expanded(
            child: FadeTransition(
              opacity: _contentFadeAnimation,
              child: Column(
                children: [
                  // Filter Section
                  ScaleTransition(
                    scale: _filterScaleAnimation,
                    child: TransactionFilterWidget(
                      selectedFilter: _selectedFilter,
                      onFilterChanged: _filterTransactions,
                    ).animate().slideX(
                      begin: -1,
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutBack,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Transactions List
                  Expanded(child: _buildTransactionsList()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    return Consumer(
      builder: (context, ref, child) {
        final transactionsState = ref.watch(transactionsProvider);
        
        if (transactionsState.isLoading && transactionsState.transactions.isEmpty) {
          return _buildLoadingState();
        }

        if (transactionsState.error != null && transactionsState.transactions.isEmpty) {
          return _buildErrorState(transactionsState.error!);
        }

        final filteredTransactions = _getFilteredTransactions(transactionsState.transactions);

        if (filteredTransactions.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: _refreshTransactions,
          color: const Color(0xFFFFC000),
          backgroundColor: Colors.white,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final transaction = filteredTransactions[index];
                    return TransactionCardWidget(
                          transaction: transaction,
                          onTap: () => _onTransactionTap(transaction),
                        )
                        .animate(delay: Duration(milliseconds: 100 * index))
                        .fadeIn(duration: const Duration(milliseconds: 400))
                        .slideY(begin: 1, curve: Curves.easeOutBack);
                  }, childCount: filteredTransactions.length),
                ),
              ),
              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        );
      }
    );
  }

  Widget _buildLoadingState() {
    return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC000)),
              ),
              const SizedBox(height: 16),
              Text(
                TranslationService.instance.translate(
                  'transaction.screen.loading',
                ),
                style: const TextStyle(color: Color(0xFF6E757D), fontSize: 14),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 300))
        .scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildErrorState(String error) {
    final isAuthError = error.contains('log in') || error.contains('Authentication') || error.contains('Access token');
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: isAuthError ? Colors.orange.shade50 : Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isAuthError ? Icons.login_rounded : Icons.error_outline_rounded,
                size: 60,
                color: isAuthError ? Colors.orange.shade400 : Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isAuthError ? 'Please Log In' : 'Failed to Load Transactions',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF181F30),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              isAuthError 
                ? 'You need to log in to view your transaction history.'
                : error,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6E757D),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (isAuthError) ...[
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop(); // Go back to previous screen
                },
                icon: const Icon(Icons.login, size: 16),
                label: const Text('Go to Login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC000),
                  foregroundColor: const Color(0xFF181F30),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref.read(transactionsProvider.notifier).fetchTransactions(refresh: true);
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC000),
                  foregroundColor: const Color(0xFF181F30),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final translationService = TranslationService.instance;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 60,
                color: Color(0xFF6E757D),
              ),
            ).animate().scale(
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
            ),

            const SizedBox(height: 24),

            Text(
                  translationService.translate('transaction.screen.emptyState'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF181F30),
                  ),
                  textAlign: TextAlign.center,
                )
                .animate(delay: const Duration(milliseconds: 200))
                .fadeIn(duration: const Duration(milliseconds: 400))
                .slideY(begin: 0.3),

            const SizedBox(height: 12),

            Text(
                  translationService.translate(
                    'transaction.screen.emptyDescription',
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6E757D),
                  ),
                  textAlign: TextAlign.center,
                )
                .animate(delay: const Duration(milliseconds: 400))
                .fadeIn(duration: const Duration(milliseconds: 400))
                .slideY(begin: 0.3),

            const SizedBox(height: 32),

            ElevatedButton(
                  onPressed: () {
                    // Navigate to send money
                    HapticFeedback.lightImpact();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC000),
                    foregroundColor: const Color(0xFF181F30),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Start Sending Money',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                )
                .animate(delay: const Duration(milliseconds: 600))
                .fadeIn(duration: const Duration(milliseconds: 400))
                .scale(begin: const Offset(0.8, 0.8), curve: Curves.elasticOut),
          ],
        ),
      ),
    );
  }

  void _onTransactionTap(Transaction transaction) {
    HapticFeedback.lightImpact();

    // Show transaction details modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildTransactionDetailsModal(transaction),
    );
  }

  Widget _buildTransactionDetailsModal(Transaction transaction) {
    final translationService = TranslationService.instance;

    return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Status indicator
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: transaction.statusColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        transaction.statusIcon,
                        color: transaction.statusColor,
                        size: 24,
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${transaction.amount.toStringAsFixed(2)} ${transaction.currency}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF181F30),
                            ),
                          ),
                          Text(
                            transaction.formattedType,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6E757D),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Close button
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey[100],
                      ),
                    ),
                  ],
                ),
              ),

              // Transaction details
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(
                        'Recipient',
                        _getWalletAddressFormatted(transaction),
                      ),
                      _buildDetailRow(
                        'Transaction Date',
                        _formatDate(transaction.createdAt),
                      ),
                      _buildDetailRow(
                        'Reference ID',
                        transaction.referenceId,
                      ),
                      _buildDetailRow(
                        'Tracking Number',
                        transaction.trackingNumber,
                      ),
                      _buildDetailRow(
                        'Transaction Fee',
                        '${transaction.fee.toStringAsFixed(2)} ${transaction.currency}',
                      ),
                      _buildDetailRow(
                        'Network',
                        transaction.blockchainNetwork ?? 'Unknown',
                      ),
                      _buildDetailRow(
                        'Status',
                        transaction.status.toUpperCase(),
                      ),
                      if (transaction.blockchainTxHash != null)
                        _buildDetailRow(
                          'Blockchain Hash',
                          _formatTxHash(transaction.blockchainTxHash!),
                        ),

                      const SizedBox(height: 32),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                // Download receipt
                                HapticFeedback.lightImpact();
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                translationService.translate(
                                  'transaction.actions.download',
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                // Repeat transaction
                                HapticFeedback.lightImpact();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFC000),
                                foregroundColor: const Color(0xFF181F30),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                translationService.translate(
                                  'transaction.actions.repeatTransaction',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
        .animate()
        .slideY(
          begin: 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        )
        .fadeIn(duration: const Duration(milliseconds: 200));
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6E757D)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF181F30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getWalletAddressFormatted(Transaction transaction) {
    if (transaction.destinationDetails != null) {
      final walletAddress = transaction.destinationDetails!['walletAddress'] as String?;
      if (walletAddress != null && walletAddress.isNotEmpty) {
        if (walletAddress.length > 16) {
          return '${walletAddress.substring(0, 8)}...${walletAddress.substring(walletAddress.length - 8)}';
        }
        return walletAddress;
      }
    }
    return 'Unknown';
  }

  String _formatTxHash(String txHash) {
    if (txHash.length > 16) {
      return '${txHash.substring(0, 8)}...${txHash.substring(txHash.length - 8)}';
    }
    return txHash;
  }

  String _formatDate(DateTime date) {
    // Format like: Sep 13, 2025, 04:35 PM
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    final month = months[date.month - 1];
    final day = date.day;
    final year = date.year;
    
    final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    
    return '$month $day, $year, ${hour.toString().padLeft(2, '0')}:$minute $ampm';
  }
}
