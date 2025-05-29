// lib/presentation/home/components/frequent_receipts_section.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flash_transfer_app/config/ui_constants.dart';

class FrequentReceiptsSection extends StatelessWidget {
  const FrequentReceiptsSection({Key? key}) : super(key: key);

  // Sample data - replace with actual data from providers
  final List<Map<String, dynamic>> frequentReceipts = const [
    {'id': 1, 'name': 'Michael', 'image': 'assets/images/micheal.png', 'transfers': 12},
    {'id': 2, 'name': 'Billy', 'image': 'assets/images/Billy.png', 'transfers': 8},
    {'id': 3, 'name': 'Mark', 'image': 'assets/images/mark.png', 'transfers': 6},
    {'id': 4, 'name': 'James', 'image': 'assets/images/james.png', 'transfers': 5},
    {'id': 5, 'name': 'Alex', 'image': 'assets/images/alex.png', 'transfers': 4},
    {'id': 6, 'name': 'Sarah', 'image': 'assets/images/Billy.png', 'transfers': 3},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 16),
        _buildReceiptsList(),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF3E0), Color(0xFFFFECB3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.star_rounded,
                size: 20,
                color: Color(0xFFF57C00),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Frequent Receipts',
              style: AppTextStyles.heading3.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF181F30),
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            // Navigate to all contacts
          },
          child: Text(
            'See all',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2475FF),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptsList() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: frequentReceipts.length,
        itemBuilder: (context, index) {
          final receipt = frequentReceipts[index];
          return _buildReceiptItem(receipt, index);
        },
      ),
    );
  }

  Widget _buildReceiptItem(Map<String, dynamic> receipt, int index) {
    return Padding(
      padding: EdgeInsets.only(
        right: 16,
        left: index == 0 ? 0 : 0,
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          // Handle contact selection
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF2475FF).withOpacity(0.1),
                        const Color(0xFFFFC000).withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      backgroundImage: AssetImage(receipt['image']),
                      onBackgroundImageError: (_, __) {},
                      child: receipt['image'] == null
                          ? Text(
                              receipt['name'].substring(0, 1),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF181F30),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                // Transfer count badge
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2475FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      '${receipt['transfers']}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              receipt['name'],
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF181F30),
              ),
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(
        delay: Duration(milliseconds: 100 + (index * 50)),
        duration: 400.ms,
      )
      .slideX(
        begin: 0.2,
        end: 0,
        delay: Duration(milliseconds: 100 + (index * 50)),
        duration: 400.ms,
        curve: Curves.easeOutCubic,
      );
  }
}