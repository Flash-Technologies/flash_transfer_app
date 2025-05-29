import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RecentTransactionsWidget extends StatelessWidget {
  const RecentTransactionsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dummyTransactions = [
      {
        'name': 'Jane Cooper',
        'date': '24 May, 2024',
        'action': 'Send',
        'amount': '\$396.84',
        'avatar': 'assets/image/users/homeUser4.png',
      },
      {
        'name': 'Marvin McKinney',
        'date': '24 May, 2024',
        'action': 'Receive',
        'amount': '\$396.84',
        'avatar': 'assets/image/users/homeUser1.png',
      },
      {
        'name': 'Esther Howard',
        'date': '24 May, 2024',
        'action': 'Receive',
        'amount': '\$396.84',
        'avatar': 'assets/image/users/homeUser2.png',
      },
      {
        'name': 'Ralph Edwards',
        'date': '24 May, 2024',
        'action': 'Send',
        'amount': '\$396.84',
        'avatar': 'assets/image/users/homeUser3.png',
      },
    ];

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
                context.push('/transaction');
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
        ...dummyTransactions.asMap().entries.map((entry) {
          final index = entry.key;
          final transaction = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildTransactionItem(
              transaction['name']!,
              transaction['date']!,
              transaction['action']!,
              transaction['amount']!,
              transaction['action'] == 'Send',
              transaction['avatar']!,
            )
                .animate()
                .fadeIn(
                    duration: 400.ms,
                    delay: Duration(milliseconds: index * 100))
                .slideX(begin: -0.1, end: 0),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTransactionItem(
    String name,
    String date,
    String action,
    String amount,
    bool isSend,
    String avatarPath,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      avatarPath,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, _) => CircleAvatar(
                        backgroundColor: Colors.grey.shade200,
                        radius: 24,
                        child: Text(
                          name.substring(0, 1),
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
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
                      action,
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
