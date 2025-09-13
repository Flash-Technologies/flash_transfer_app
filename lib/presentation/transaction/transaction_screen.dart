import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/services/translation_service.dart';
import '../../core/models/transaction_model.dart';
import '../../providers/transaction_provider.dart';
import 'widgets/transaction_card_widget.dart';
import 'widgets/transaction_filter_widget.dart';
import 'widgets/transaction_header_widget.dart' as header;
import 'individual_transaction_screen.dart';

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
    _setupScrollListener();
    
    // Load transactions after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionsProvider.notifier).fetchTransactions();
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final transactionsState = ref.read(transactionsProvider);
      
      // Load more when approaching the end, but only if we have transactions and there are more to load
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        if (!transactionsState.isLoading && transactionsState.hasMore && transactionsState.transactions.isNotEmpty) {
          ref.read(transactionsProvider.notifier).loadMoreTransactions();
        }
      }
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
      backgroundColor: Colors.white,
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
                  // Filter Section (no spacing above)
                  ScaleTransition(
                    scale: _filterScaleAnimation,
                    child: Container(
                      color: Colors.white,
                      child: TransactionFilterWidget(
                        selectedFilter: _selectedFilter,
                        onFilterChanged: _filterTransactions,
                      ).animate().slideX(
                        begin: -1,
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutBack,
                      ),
                    ),
                  ),

                  // Transactions List (starts immediately after filter)
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
          child: ListView.builder(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 80),
            itemCount: filteredTransactions.length + (transactionsState.isLoading && filteredTransactions.isNotEmpty ? 1 : 0),
            itemBuilder: (context, index) {
              // Show loading indicator at the end if loading more
              if (index == filteredTransactions.length) {
                return Container(
                  height: 60,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC000)),
                    strokeWidth: 2,
                  ),
                );
              }
              
              final transaction = filteredTransactions[index];
              
              // Don't animate if this is from pagination (index >= initial load count)
              // Assume first page has 10 items, don't animate items beyond that
              final isFromPagination = index >= 10;
              
              final widget = TransactionCardWidget(
                transaction: transaction,
                onTap: () => _onTransactionTap(transaction),
              );
              
              // Only animate initial load items, not paginated items
              if (isFromPagination) {
                return widget;
              }
              
              return widget
                  .animate(delay: Duration(milliseconds: 50 * (index % 10)))
                  .fadeIn(duration: const Duration(milliseconds: 300))
                  .slideY(begin: 0.5, curve: Curves.easeOutCubic);
            },
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

    // Navigate to individual transaction screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IndividualTransactionScreen(
          transactionId: transaction.id,
          transaction: transaction,
        ),
      ),
    );
  }
}
