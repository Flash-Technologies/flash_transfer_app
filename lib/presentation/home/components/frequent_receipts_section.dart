// lib/presentation/home/components/frequent_receipts_section.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flash_transfer_app/config/ui_constants.dart';
import '../../../providers/beneficiary_provider.dart';
import '../../../core/models/beneficiary.dart';
import '../../../providers/language_provider.dart';

class FrequentReceiptsSection extends ConsumerStatefulWidget {
  const FrequentReceiptsSection({Key? key}) : super(key: key);

  @override
  ConsumerState<FrequentReceiptsSection> createState() => _FrequentReceiptsSectionState();
}

class _FrequentReceiptsSectionState extends ConsumerState<FrequentReceiptsSection> {
  @override
  void initState() {
    super.initState();
    // Load beneficiaries when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(beneficiariesProvider.notifier).loadBeneficiaries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final beneficiariesState = ref.watch(beneficiariesProvider);
    final beneficiaries = beneficiariesState.beneficiaries;

    // Don't show widget if no beneficiaries
    if (beneficiaries.isEmpty && !beneficiariesState.isLoading) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 16),
        _buildReceiptsList(beneficiaries, beneficiariesState.isLoading),
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
            Consumer(
              builder: (context, ref, child) {
                final tr = ref.watch(translationHelperProvider);
                return Text(
                  tr('payment-method.contacts.frequentReceipts'),
                  style: AppTextStyles.heading3.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF181F30),
                  ),
                );
              },
            ),
          ],
        ),
        TextButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            // Navigate to all contacts
          },
          child: Consumer(
            builder: (context, ref, child) {
              final tr = ref.watch(translationHelperProvider);
              return Text(
                tr('payment-method.contacts.seeAll'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2475FF),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptsList(List<Beneficiary> beneficiaries, bool isLoading) {
    if (isLoading) {
      return SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: 6, // Show loading shimmer for 6 items
          itemBuilder: (context, index) => _buildLoadingItem(index),
        ),
      );
    }

    // Take only the first 6 beneficiaries for frequent receipts
    final frequentBeneficiaries = beneficiaries.take(6).toList();

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: frequentBeneficiaries.length,
        itemBuilder: (context, index) {
          final beneficiary = frequentBeneficiaries[index];
          return _buildReceiptItem(beneficiary, index);
        },
      ),
    );
  }

  Widget _buildReceiptItem(Beneficiary beneficiary, int index) {
    return Padding(
      padding: EdgeInsets.only(
        right: 16,
        left: index == 0 ? 0 : 0,
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          // Handle beneficiary selection
          ref.read(selectedBeneficiaryProvider.notifier).state = beneficiary;
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    _getAvatarColor(index).withValues(alpha: 0.2),
                    _getAvatarColor(index).withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: _getAvatarColor(index),
                  child: Text(
                    beneficiary.displayName.isNotEmpty
                        ? beneficiary.displayName.substring(0, 1).toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 60,
              child: Text(
                beneficiary.displayName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF181F30),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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

  Widget _buildLoadingItem(int index) {
    return Padding(
      padding: EdgeInsets.only(
        right: 16,
        left: index == 0 ? 0 : 0,
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 50,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    ).animate()
      .shimmer(
        delay: Duration(milliseconds: index * 100),
        duration: 1000.ms,
      );
  }

  Color _getAvatarColor(int index) {
    final colors = [
      const Color(0xFF2475FF),
      const Color(0xFF22C55E),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF9C27B0),
      const Color(0xFF607D8B),
      const Color(0xFF795548),
      const Color(0xFFFF5722),
    ];
    return colors[index % colors.length];
  }
}