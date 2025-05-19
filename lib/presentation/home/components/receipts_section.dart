import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flash_transfer_app/config/ui_constants.dart';

class ReceiptsSection extends StatefulWidget {
  const ReceiptsSection({Key? key}) : super(key: key);

  @override
  State<ReceiptsSection> createState() => _ReceiptsSectionState();
}

class _ReceiptsSectionState extends State<ReceiptsSection> {
  final TextEditingController searchController = TextEditingController();
  final Set<int> invitedUsers = {};
  String searchQuery = '';

  // Sample data for demonstration
  final List<Map<String, dynamic>> frequentReceipts = [
    {'id': 1, 'name': 'Michael', 'image': 'assets/images/micheal.png'},
    {'id': 2, 'name': 'Billy', 'image': 'assets/images/Billy.png'},
    {'id': 3, 'name': 'Mark', 'image': 'assets/images/mark.png'},
    {'id': 4, 'name': 'James', 'image': 'assets/images/james.png'},
    {'id': 5, 'name': 'Alex', 'image': 'assets/images/alex.png'},
    {'id': 6, 'name': 'Sarah', 'image': 'assets/images/Billy.png'},
  ];

  final List<Map<String, dynamic>> recentReceipts = [
    {'id': 1, 'name': 'Theresa Webb', 'country': 'USA', 'flag': '🇺🇸', 'image': 'assets/images/theresa.png'},
    {'id': 2, 'name': 'Courtney Henry', 'country': 'France', 'flag': '🇫🇷', 'image': 'assets/images/courtney.png'},
    {'id': 3, 'name': 'Robert Fox', 'country': 'USA', 'flag': '🇺🇸', 'image': 'assets/images/robert.png'},
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingL),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFrequentReceipts(),
          SizedBox(height: AppSpacing.marginL),
          _buildRecentReceipts(),
          SizedBox(height: AppSpacing.marginL),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildFrequentReceipts() {
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
            itemCount: frequentReceipts.length,
            itemBuilder: (context, index) {
              final receipt = frequentReceipts[index];
              return Padding(
                padding: EdgeInsets.only(right: AppSpacing.paddingM),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: AssetImage(receipt['image']),
                      backgroundColor: Colors.grey[200],
                    ),
                    SizedBox(height: AppSpacing.marginXS),
                    Text(
                      receipt['name'],
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
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

  Widget _buildRecentReceipts() {
    // Filter receipts based on search query
    List<Map<String, dynamic>> filteredReceipts = recentReceipts
        .where((receipt) => receipt['name']
            .toLowerCase()
            .contains(searchQuery.toLowerCase()))
        .toList();

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
              border: Border.all(color: AppColors.border.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/search.png',
                  width: 24,
                  height: 24,
                ),
                SizedBox(width: AppSpacing.marginS),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) => setState(() => searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search receipts',
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
        
        // Recent receipts list
        ...filteredReceipts.asMap().entries.map((entry) {
          final index = entry.key;
          final receipt = entry.value;
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.paddingS,
              vertical: AppSpacing.paddingXS,
            ),
            child: _buildReceiptItem(receipt, index),
          );
        }),
      ],
    );
  }

  Widget _buildReceiptItem(Map<String, dynamic> receipt, int index) {
    final bool isInvited = invitedUsers.contains(receipt['id']);
    
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppRadius.radiusM),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: () {}, // Optional tap handling
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
                      backgroundImage: AssetImage(receipt['image']),
                    ),
                    SizedBox(width: AppSpacing.marginM),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          receipt['name'],
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              receipt['flag'],
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(width: AppSpacing.marginXS),
                            Text(
                              receipt['country'],
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                
                // Invite button
                TextButton(
                  onPressed: () {
                    if (!isInvited) {
                      setState(() {
                        invitedUsers.add(receipt['id']);
                      });
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
                    minimumSize: Size(80, 32),
                  ),
                  child: Text(
                    isInvited ? 'Invited' : 'Invite',
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
}