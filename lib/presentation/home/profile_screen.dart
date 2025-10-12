import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flash_transfer_app/presentation/common/app_button.dart';
import 'package:flash_transfer_app/presentation/common/notification_modal.dart';
import 'package:flash_transfer_app/providers/user_provider.dart';
import 'package:flash_transfer_app/providers/auth_provider.dart';
import 'package:flash_transfer_app/providers/language_provider.dart';
import 'package:flash_transfer_app/presentation/home/components/profile_menu_item.dart';
import 'package:flash_transfer_app/config/constants.dart';
import 'package:flash_transfer_app/core/models/user.dart';

// Enhanced Profile Screen with modern UI/UX
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
  }

  void _startAnimations() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  // Helper method to get display name based on available data
  String _getDisplayName(User? user) {
    if (user == null) return 'User';

    if (user.firstName != null && user.firstName!.isNotEmpty) {
      if (user.lastName != null && user.lastName!.isNotEmpty) {
        return '${user.firstName} ${user.lastName}';
      }
      return user.firstName!;
    }

    // If no name available, show auth method
    if (user.authMethod != null) {
      return user.authMethod!.toUpperCase();
    }

    return 'User';
  }

  // Helper method to get display email/identifier
  String _getDisplayIdentifier(User? user) {
    if (user == null) return '';

    // If email is available, show it
    if (user.email != null && user.email!.isNotEmpty) {
      return user.email!;
    }

    // If no email but wallet address available, show wallet address
    if (user.walletAddress != null && user.walletAddress!.isNotEmpty) {
      return user.walletAddress!;
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final user = userState.user;
    final isLoading = userState.isLoading;
    final tr = ref.watch(translationHelperProvider);

    // Create menu items with translations
    final featuresMenuItems = [
      ProfileMenuItemData(
        icon: Icons.view_in_ar_outlined,
        title: tr('menu.nft'),
        onTap: () => context.push('/nft'),
      ),
      ProfileMenuItemData(
        icon: Icons.share_outlined,
        title: tr('menu.referFriend'),
        onTap: () => context.push('/invite'),
      ),
    ];

    final settingsMenuItems = [
      ProfileMenuItemData(
        icon: Icons.notifications_outlined,
        title: tr('menu.settings'), // Use generic settings or add notifications key
        onTap: () => context.push('/notification'),
      ),
      ProfileMenuItemData(
        icon: Icons.language_outlined,
        title: 'Language', // Keep as is since this is Language specific
        onTap: () => context.push('/language'),
      ),
      ProfileMenuItemData(
        icon: Icons.privacy_tip_outlined,
        title: 'Privacy Policy', // Keep as is
        onTap: () => context.push('/privacy'),
      ),
      ProfileMenuItemData(
        icon: Icons.contact_support_outlined,
        title: 'Contact Us', // Keep as is
        onTap: () => context.push('/contact'),
      ),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: isLoading && user == null
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : Column(
                  children: [
                    _buildHeader(context),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: Column(
                          children: [
                            _buildProfileHeader(context, user),
                            const SizedBox(height: AppSizes.spacingSmall),
                            _buildMenuItems(context),
                            const SizedBox(height: AppSizes.spacingXLarge),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMedium,
        vertical: AppSizes.paddingMedium,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildBackButton(context),
          const Expanded(
            child: Text(
              'Profile',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          _buildNotificationButton(context),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.pop();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.arrow_back_ios_new,
          size: 20,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showNotificationModal(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Icon(
              Icons.notifications_outlined,
              size: 24,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            // Notification badge
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, user) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.all(AppSizes.paddingMedium),
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Stack(
              children: [
                Hero(
                  tag: 'profile-avatar',
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: user?.profileImage != null
                          ? Image.network(
                              user!.profileImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // Handle image load errors
                                return const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.white,
                                );
                              },
                              loadingBuilder: (
                                context,
                                child,
                                loadingProgress,
                              ) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                );
                              },
                            )
                          : const Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ),
                // Rank badge
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacingMedium),
            Text(
              _getDisplayName(user),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
            ),
            const SizedBox(height: AppSizes.spacingSmall),
            Text(
              _getDisplayIdentifier(user),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildMenuSection(
                'Account',
                [
                  ProfileMenuItemData(
                    icon: Icons.person_outline,
                    title: 'My Profile',
                    onTap: () => context.push('/edit-profile'),
                  ),
                  ProfileMenuItemData(
                    icon: Icons.receipt_long_outlined,
                    title: 'My Transactions',
                    onTap: () => context.push('/transaction'),
                  ),
                  ProfileMenuItemData(
                    icon: Icons.people_outline,
                    title: 'My Recipients',
                    onTap: () => context.push('/recipients'),
                  ),
                  ProfileMenuItemData(
                    icon: Icons.track_changes_outlined,
                    title: 'Track a Transfer',
                    onTap: () => context.push('/track-transfer'),
                  ),
                  ProfileMenuItemData(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Wallet',
                    onTap: () => context.push('/wallet'),
                  ),
                ],
                0),
            _buildMenuSection(
                'Features',
                [
                  ProfileMenuItemData(
                    icon: Icons.view_in_ar_outlined,
                    title: 'NFT',
                    onTap: () => context.push('/nft'),
                  ),
                  ProfileMenuItemData(
                    icon: Icons.share_outlined,
                    title: 'Refer a Friend',
                    onTap: () => context.push('/invite'),
                  ),
                ],
                200),
            _buildMenuSection(
                'Settings',
                [
                  ProfileMenuItemData(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    onTap: () => context.push('/notification'),
                  ),
                  ProfileMenuItemData(
                    icon: Icons.language_outlined,
                    title: 'Language',
                    onTap: () => context.push('/language'),
                  ),
                  ProfileMenuItemData(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () => context.push('/privacy'),
                  ),
                  ProfileMenuItemData(
                    icon: Icons.contact_support_outlined,
                    title: 'Contact Us',
                    onTap: () => context.push('/contact'),
                  ),
                ],
                400),
            const Divider(height: 1),
            ProfileMenuItem(
              data: ProfileMenuItemData(
                icon: Icons.logout_outlined,
                title: 'Log out',
                isDestructive: true,
                isLoading: _isLoggingOut,
                onTap: () => _handleLogout(context),
              ),
              delay: 650,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(
    String title,
    List<ProfileMenuItemData> items,
    int startDelay,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 0.8,
                ),
          ),
        ),
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return ProfileMenuItem(data: item, delay: startDelay + (index * 50));
        }),
        if (title != 'Settings') const SizedBox(height: 12),
      ],
    );
  }

  void _showNotificationModal(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NotificationModal(
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    HapticFeedback.mediumImpact();

    final confirmed = await _showLogoutConfirmation(context);
    if (!confirmed) return;

    setState(() => _isLoggingOut = true);

    try {
      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        context.go('/sign-in');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${error.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  Future<bool> _showLogoutConfirmation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Log Out'),
            content: const Text('Are you sure you want to log out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Log Out'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
