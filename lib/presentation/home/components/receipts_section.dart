import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flash_transfer_app/config/ui_constants.dart';
import '../../../providers/beneficiary_provider.dart';
import '../../../core/models/beneficiary.dart';

class ReceiptsSection extends ConsumerStatefulWidget {
  const ReceiptsSection({Key? key}) : super(key: key);

  @override
  ConsumerState<ReceiptsSection> createState() => _ReceiptsSectionState();
}

class _ReceiptsSectionState extends ConsumerState<ReceiptsSection> {
  final TextEditingController searchController = TextEditingController();
  final Set<int> invitedUsers = {};
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Load beneficiaries when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(beneficiariesProvider.notifier).loadBeneficiaries();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final beneficiariesState = ref.watch(beneficiariesProvider);
    final beneficiaries = beneficiariesState.beneficiaries;

    // Don't show widget if no beneficiaries
    if (beneficiaries.isEmpty && !beneficiariesState.isLoading) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingL),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFrequentReceipts(beneficiaries, beneficiariesState.isLoading),
          SizedBox(height: AppSpacing.marginL),
          _buildRecentReceipts(beneficiaries, beneficiariesState.isLoading),
          SizedBox(height: AppSpacing.marginL),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildFrequentReceipts(List<Beneficiary> beneficiaries, bool isLoading) {
    if (isLoading) {
      return _buildFrequentReceiptsLoading();
    }

    // Take only the first 6 beneficiaries for frequent receipts
    final frequentBeneficiaries = beneficiaries.take(6).toList();

    if (frequentBeneficiaries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.paddingS),
          child: Text(
            'Frequent Receipts',
            style: AppTextStyles.heading3,
          ),
        ),
        SizedBox(height: AppSpacing.marginM),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.paddingS),
            itemCount: frequentBeneficiaries.length,
            itemBuilder: (context, index) {
              final beneficiary = frequentBeneficiaries[index];
              return Padding(
                padding: EdgeInsets.only(right: AppSpacing.paddingM),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () {
                        ref.read(selectedBeneficiaryProvider.notifier).state = beneficiary;
                      },
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: _getAvatarColor(index),
                        child: Text(
                          beneficiary.displayName.isNotEmpty
                              ? beneficiary.displayName.substring(0, 1).toUpperCase()
                              : '?',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.marginXS),
                    SizedBox(
                      width: 60,
                      child: Text(
                        beneficiary.displayName,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ).animate()
                .fadeIn(
                  delay: AppAnimations.staggered(index),
                  duration: AppAnimations.normalAnimation,
                )
                .slideX(
                  begin: 0.2,
                  end: 0,
                  delay: AppAnimations.staggered(index),
                  duration: AppAnimations.normalAnimation,
                  curve: AppAnimations.standardCurve,
                );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFrequentReceiptsLoading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.paddingS),
          child: Text(
            'Frequent Receipts',
            style: AppTextStyles.heading3,
          ),
        ),
        SizedBox(height: AppSpacing.marginM),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.paddingS),
            itemCount: 6,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(right: AppSpacing.paddingM),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[300],
                      ),
                    ),
                    SizedBox(height: AppSpacing.marginXS),
                    Container(
                      width: 40,
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
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentReceipts(List<Beneficiary> beneficiaries, bool isLoading) {
    if (isLoading) {
      return _buildRecentReceiptsLoading();
    }

    // Filter beneficiaries based on search query
    List<Beneficiary> filteredBeneficiaries = beneficiaries;
    
    if (searchQuery.isNotEmpty) {
      filteredBeneficiaries = beneficiaries
          .where((beneficiary) => beneficiary.displayName
              .toLowerCase()
              .contains(searchQuery.toLowerCase()) ||
              beneficiary.country.toLowerCase().contains(searchQuery.toLowerCase()) ||
              beneficiary.email.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }

    // Only hide if no beneficiaries at all (not due to search filtering)
    if (beneficiaries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.paddingS),
          child: Text(
            'Recent Receipts',
            style: AppTextStyles.heading3,
          ),
        ),
        SizedBox(height: AppSpacing.marginL),
        
        // Search bar
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.paddingS),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.paddingM,
              vertical: AppSpacing.paddingS,
            ),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppRadius.buttonRadius),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  size: 24,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: AppSpacing.marginS),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) => setState(() => searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search beneficiaries',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        SizedBox(height: AppSpacing.marginM),
        
        // Recent receipts list - show all beneficiaries from API response
        if (filteredBeneficiaries.isNotEmpty)
          ...filteredBeneficiaries.asMap().entries.map((entry) {
            final index = entry.key;
            final beneficiary = entry.value;
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.paddingS,
                vertical: AppSpacing.paddingXS,
              ),
              child: _buildReceiptItem(beneficiary, index),
            );
          })
        else if (searchQuery.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.paddingS),
            child: Container(
              padding: EdgeInsets.all(AppSpacing.paddingL),
              child: Center(
                child: Text(
                  'No beneficiaries found matching "$searchQuery"',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          )
        else
          // Show message when no beneficiaries but search is empty
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.paddingS),
            child: Container(
              padding: EdgeInsets.all(AppSpacing.paddingL),
              child: Center(
                child: Text(
                  'No beneficiaries found. Add some recipients to see them here.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRecentReceiptsLoading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.paddingS),
          child: Text(
            'Recent Receipts',
            style: AppTextStyles.heading3,
          ),
        ),
        SizedBox(height: AppSpacing.marginL),
        
        // Search bar (always show)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.paddingS),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(AppRadius.buttonRadius),
            ),
          ),
        ).animate().shimmer(duration: 1000.ms),
        
        SizedBox(height: AppSpacing.marginM),
        
        // Loading items
        ...List.generate(3, (index) => Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.paddingS,
            vertical: AppSpacing.paddingXS,
          ),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(AppRadius.radiusM),
            ),
          ).animate().shimmer(
            delay: Duration(milliseconds: index * 100),
            duration: 1000.ms,
          ),
        )),
      ],
    );
  }

  Widget _buildReceiptItem(Beneficiary beneficiary, int index) {
    final bool isInvited = invitedUsers.contains(beneficiary.id);
    
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppRadius.radiusM),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: () {
            ref.read(selectedBeneficiaryProvider.notifier).state = beneficiary;
          },
          borderRadius: BorderRadius.circular(AppRadius.radiusM),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.paddingM),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: _getAvatarColor(index + 10),
                      child: Text(
                        beneficiary.displayName.isNotEmpty
                            ? beneficiary.displayName.substring(0, 1).toUpperCase()
                            : '?',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: AppSpacing.marginM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            beneficiary.displayName,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              Text(
                                _getCountryFlag(beneficiary.country),
                                style: const TextStyle(fontSize: 16),
                              ),
                              SizedBox(width: AppSpacing.marginXS),
                              Expanded(
                                child: Text(
                                  beneficiary.country,
                                  style: AppTextStyles.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Select button
                TextButton(
                  onPressed: () {
                    if (!isInvited) {
                      setState(() {
                        invitedUsers.add(beneficiary.id);
                      });
                      ref.read(selectedBeneficiaryProvider.notifier).state = beneficiary;
                    }
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: isInvited
                        ? AppColors.iconBackground
                        : AppColors.primaryBlue,
                    foregroundColor: isInvited
                        ? AppColors.textSecondary
                        : Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.paddingM,
                      vertical: AppSpacing.paddingXS,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.radiusS),
                    ),
                    minimumSize: const Size(80, 32),
                  ),
                  child: Text(
                    isInvited ? 'Selected' : 'Select',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isInvited ? AppColors.textSecondary : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate()
      .fadeIn(
        delay: AppAnimations.staggered(index),
        duration: AppAnimations.normalAnimation,
      )
      .slideY(
        begin: 0.1,
        end: 0,
        delay: AppAnimations.staggered(index),
        duration: AppAnimations.normalAnimation,
        curve: AppAnimations.standardCurve,
      );
  }

  String _getCountryFlag(String country) {
    // Simple mapping of countries to flags
    final countryFlags = {
      'USA': '🇺🇸',
      'United States': '🇺🇸',
      'France': '🇫🇷',
      'Germany': '🇩🇪',
      'India': '🇮🇳',
      'UK': '🇬🇧',
      'United Kingdom': '🇬🇧',
      'Canada': '🇨🇦',
      'Australia': '🇦🇺',
      'Japan': '🇯🇵',
      'China': '🇨🇳',
      'Brazil': '🇧🇷',
    };
    
    return countryFlags[country] ?? '🌍';
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.paddingS),
      child: Column(
        children: [
          // Confirm button
          ElevatedButton(
            onPressed: () => context.push('/receiver-info'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryYellow,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
              padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingM),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.buttonRadius),
              ),
              minimumSize: const Size(double.infinity, 56),
            ),
            child: Text(
              'Confirm',
              style: AppTextStyles.buttonMedium,
            ),
          ),
          
          SizedBox(height: AppSpacing.marginM),
          
          // Cancel button
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: BorderSide(color: AppColors.textSecondary),
              padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingM),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.buttonRadius),
              ),
              minimumSize: const Size(double.infinity, 56),
            ),
            child: Text(
              'Cancel',
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to generate consistent avatar colors
  Color _getAvatarColor(int index) {
    final colors = [
      AppColors.primaryBlue,
      AppColors.success,
      AppColors.primaryYellow.withValues(alpha: 0.8),
      AppColors.error,
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF607D8B), // Blue Grey
      const Color(0xFF795548), // Brown
      const Color(0xFFFF5722), // Deep Orange
    ];
    return colors[index % colors.length];
  }
}