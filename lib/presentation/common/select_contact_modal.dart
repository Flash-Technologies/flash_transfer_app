import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flash_transfer_app/config/ui_constants.dart';
import 'package:flash_transfer_app/providers/beneficiary_provider.dart';
import 'package:flash_transfer_app/core/models/beneficiary.dart';

class SelectContactModal extends ConsumerStatefulWidget {
  final Function(Beneficiary?) onContactSelected;
  final VoidCallback onClose;

  const SelectContactModal({
    Key? key,
    required this.onContactSelected,
    required this.onClose,
  }) : super(key: key);

  @override
  ConsumerState<SelectContactModal> createState() => _SelectContactModalState();
}

class _SelectContactModalState extends ConsumerState<SelectContactModal>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadBeneficiaries();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadBeneficiaries() async {
    // Use Future.microtask to avoid provider modification during build
    await Future.microtask(() async {
      await ref.read(beneficiariesProvider.notifier).loadBeneficiaries();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _closeModal() async {
    await _slideController.reverse();
    await _fadeController.reverse();
    widget.onClose();
  }

  void _onSearchChanged(String query) {
    // Use Future.microtask to avoid provider modification during build
    Future.microtask(() {
      ref.read(beneficiariesProvider.notifier).setSearchQuery(query);
    });
  }

  void _selectContact(Beneficiary beneficiary) {
    HapticFeedback.selectionClick();
    ref.read(selectedBeneficiaryProvider.notifier).state = beneficiary;
  }

  void _onContinue() {
    final selectedBeneficiary = ref.read(selectedBeneficiaryProvider);
    widget.onContactSelected(selectedBeneficiary);
    _closeModal();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final modalHeight = screenHeight * 0.65;
    final modalWidth = screenWidth * 0.85;

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Material(
          color: Colors.black.withOpacity(0.5 * _fadeAnimation.value),
          child: GestureDetector(
            onTap: _closeModal,
            child: Center(
              child: GestureDetector(
                onTap: () {}, // Prevent closing when tapping inside modal
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    height: modalHeight,
                    width: modalWidth,
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(AppRadius.radiusXL),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildHeader(),
                        _buildSearchSection(),
                        Expanded(child: _buildContactsList()),
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.paddingL,
        AppSpacing.paddingL,
        AppSpacing.paddingL,
        AppSpacing.paddingM,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.radiusXL),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Contact',
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: AppSpacing.marginXS),
                Text(
                  'Choose from your saved beneficiaries',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _closeModal,
            icon: Container(
              padding: EdgeInsets.all(AppSpacing.paddingS),
              decoration: BoxDecoration(
                color: AppColors.iconBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 300.ms);
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.paddingL),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.radiusM),
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search contacts...',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: AppColors.textSecondary,
              size: 20,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                    icon: Icon(
                      Icons.clear,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSpacing.paddingM,
              vertical: AppSpacing.paddingM,
            ),
          ),
          style: AppTextStyles.bodyMedium,
        ),
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 300.ms).slideY(
          begin: -0.1,
          end: 0,
          delay: 300.ms,
          duration: 300.ms,
        );
  }

  Widget _buildContactsList() {
    return Consumer(
      builder: (context, ref, child) {
        final beneficiariesState = ref.watch(beneficiariesProvider);
        final selectedBeneficiary = ref.watch(selectedBeneficiaryProvider);

        if (beneficiariesState.isLoading && beneficiariesState.beneficiaries.isEmpty) {
          return _buildLoadingState();
        }

        if (beneficiariesState.error != null) {
          return _buildErrorState(beneficiariesState.error!);
        }

        final filteredBeneficiaries = beneficiariesState.filteredBeneficiaries;

        if (filteredBeneficiaries.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(beneficiariesProvider.notifier).refresh(),
          child: ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.paddingL,
              vertical: AppSpacing.paddingM,
            ),
            itemCount: filteredBeneficiaries.length,
            itemBuilder: (context, index) {
              final beneficiary = filteredBeneficiaries[index];
              final isSelected = selectedBeneficiary?.id == beneficiary.id;

              return _buildContactItem(
                beneficiary: beneficiary,
                isSelected: isSelected,
                index: index,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildContactItem({
    required Beneficiary beneficiary,
    required bool isSelected,
    required int index,
  }) {
    return GestureDetector(
      onTap: () => _selectContact(beneficiary),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: AppSpacing.marginM),
        padding: EdgeInsets.all(AppSpacing.paddingM),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.radiusL),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.border.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? AppColors.primaryBlue.withOpacity(0.1) 
                  : Colors.black.withOpacity(0.03),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryBlue.withOpacity(0.8),
                    AppColors.primaryBlue.withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  beneficiary.firstName.isNotEmpty 
                      ? beneficiary.firstName[0].toUpperCase()
                      : 'U',
                  style: AppTextStyles.heading3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            SizedBox(width: AppSpacing.marginM),

            // Contact Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    beneficiary.displayName,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.primaryBlue : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: AppSpacing.marginXS),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: AppSpacing.marginXS),
                      Expanded(
                        child: Text(
                          '${beneficiary.city}, ${beneficiary.country}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (beneficiary.email.isNotEmpty) ...[
                    SizedBox(height: AppSpacing.marginXS),
                    Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: AppSpacing.marginXS),
                        Expanded(
                          child: Text(
                            beneficiary.email,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Selection indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primaryBlue : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.primaryBlue : AppColors.border,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
      delay: Duration(milliseconds: 400 + (index * 50)),
      duration: 300.ms,
    ).slideY(
      begin: 0.1,
      end: 0,
      delay: Duration(milliseconds: 400 + (index * 50)),
      duration: 300.ms,
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.primaryBlue,
            strokeWidth: 2,
          ),
          SizedBox(height: AppSpacing.marginM),
          Text(
            'Loading contacts...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error,
            ),
            SizedBox(height: AppSpacing.marginM),
            Text(
              'Failed to load contacts',
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.marginS),
            Text(
              error,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.marginL),
            ElevatedButton(
              onPressed: () => ref.read(beneficiariesProvider.notifier).refresh(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            SizedBox(height: AppSpacing.marginL),
            Text(
              'No contacts found',
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.marginS),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Try adjusting your search terms'
                  : 'Add some beneficiaries to get started',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Consumer(
      builder: (context, ref, child) {
        final selectedBeneficiary = ref.watch(selectedBeneficiaryProvider);
        final isEnabled = selectedBeneficiary != null;

        return Container(
          padding: EdgeInsets.all(AppSpacing.paddingL),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(AppRadius.radiusXL),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _closeModal,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(color: AppColors.border),
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingM),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.buttonRadius),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.marginM),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: isEnabled ? _onContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEnabled ? AppColors.primaryYellow : AppColors.iconBackground,
                    foregroundColor: isEnabled ? AppColors.textPrimary : AppColors.textSecondary,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.paddingM),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.buttonRadius),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: isEnabled ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).animate().fadeIn(delay: 600.ms, duration: 300.ms);
  }
}