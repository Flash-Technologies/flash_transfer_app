import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/transaction_provider.dart';
import '../../../core/models/transaction_model.dart';
import '../../transaction/individual_transaction_screen.dart';
import '../../transaction/transaction_screen.dart';

class RecentTransactionsWidget extends ConsumerStatefulWidget {
  const RecentTransactionsWidget({Key? key}) : super(key: key);

  @override
  ConsumerState<RecentTransactionsWidget> createState() => _RecentTransactionsWidgetState();
}

class _RecentTransactionsWidgetState extends ConsumerState<RecentTransactionsWidget> {
  @override
  void initState() {
    super.initState();
    // Load transactions when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionsProvider.notifier).fetchTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactionsState = ref.watch(transactionsProvider);
    
    // Get latest 4 transactions
    final recentTransactions = transactionsState.transactions.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    size: 20,
                    color: Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Recent transactions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF273240),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TransactionScreen(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF2475FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              child: Row(
                children: const [
                  Text(
                    'See all',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ],
              ),
            ).animate().scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1, 1),
                  duration: 300.ms,
                ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Show loading state if no transactions yet
        if (transactionsState.isLoading && recentTransactions.isEmpty)
          _buildLoadingState(),
        
        // Show recent transactions
        if (recentTransactions.isNotEmpty)
          ...recentTransactions.asMap().entries.map((entry) {
            final index = entry.key;
            final transaction = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildTransactionItem(transaction, index)
                  .animate()
                  .fadeIn(
                      duration: 400.ms,
                      delay: Duration(milliseconds: index * 100))
                  .slideX(begin: -0.1, end: 0),
            );
          }),
        
        // Show empty state if no transactions
        if (!transactionsState.isLoading && recentTransactions.isEmpty)
          _buildEmptyState(),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: List.generate(4, (index) => 
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    height: 20,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 16,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No recent transactions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your transactions will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction, int index) {
    final isSend = transaction.type.toLowerCase().contains('to');
    final recipientName = _getRecipientName(transaction);
    final amount = '${transaction.amount.toStringAsFixed(2)} ${transaction.currency}';
    final date = _formatDate(transaction.createdAt);
    
    return GestureDetector(
      onTap: () {
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
      },
      child: _buildTransactionContainer(recipientName, date, isSend, amount),
    );
  }

  String _getRecipientName(Transaction transaction) {
    print('🔍 Getting recipient name for transaction: ${transaction.id}');
    print('📄 Destination details: ${transaction.destinationDetails}');
    
    // Try to get recipient name from destination details
    if (transaction.destinationDetails != null) {
      final destinationDetails = transaction.destinationDetails!;
      
      // Check for customer info first (for fiat transfers)
      if (destinationDetails['customerInfo'] != null) {
        final customerInfo = destinationDetails['customerInfo'] as Map<String, dynamic>;
        final firstName = customerInfo['firstName'] as String?;
        final lastName = customerInfo['lastName'] as String?;
        
        if (firstName != null && lastName != null) {
          final fullName = '$firstName $lastName'.trim();
          print('✅ Found recipient name: $fullName');
          return fullName;
        } else if (firstName != null) {
          print('✅ Found recipient first name: $firstName');
          return firstName;
        } else if (lastName != null) {
          print('✅ Found recipient last name: $lastName');
          return lastName;
        }
        
        // Fallback to email if no name available
        final email = customerInfo['email'] as String?;
        if (email != null && email.isNotEmpty) {
          // Get email prefix before @
          final atIndex = email.indexOf('@');
          if (atIndex > 0) {
            return email.substring(0, atIndex);
          }
          return email;
        }
      }
      
      // Check for wallet address (for crypto transfers)
      final walletAddress = destinationDetails['walletAddress'] as String?;
      if (walletAddress != null && walletAddress.isNotEmpty) {
        // Format wallet address as name-like display
        if (walletAddress.length > 8) {
          return '${walletAddress.substring(0, 6)}...${walletAddress.substring(walletAddress.length - 4)}';
        }
        return walletAddress;
      }
      
      // Check for any other identifying information
      final recipientName = destinationDetails['recipientName'] as String?;
      if (recipientName != null && recipientName.isNotEmpty) {
        return recipientName;
      }
    }
    
    // Final fallback
    return 'Unknown Recipient';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day} ${months[date.month - 1]}, ${date.year}';
    }
  }

  Widget _buildTransactionContainer(
    String name,
    String date,
    bool isSend,
    String amount,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Hero(
                tag: 'avatar-$name',
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: CircleAvatar(
                      backgroundColor: const Color(0xFF4CAF50),
                      radius: 24,
                      child: Text(
                        name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF181F30),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6E757D),
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isSend
                      ? const Color(0xFFFFEBEE)
                      : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSend
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 14,
                      color: isSend
                          ? const Color(0xFFFF3E24)
                          : const Color(0xFF00C735),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isSend ? 'Send' : 'Receive',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSend
                            ? const Color(0xFFFF3E24)
                            : const Color(0xFF00C735),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF181F30),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
