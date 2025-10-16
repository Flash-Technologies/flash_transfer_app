import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/language_provider.dart';
import '../../core/models/transaction_model.dart';
import '../../core/models/sample_data.dart';
import 'widgets/invite_header_widget.dart';
import 'widgets/invite_card_widget.dart';
import 'widgets/share_options_widget.dart';

class InviteScreen extends ConsumerStatefulWidget {
  const InviteScreen({super.key});

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _contentAnimationController;
  late AnimationController _celebrationController;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _contentFadeAnimation;
  late Animation<double> _celebrationAnimation;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  bool _isLoading = false;
  List<InviteModel> _invites = [];
  Map<String, dynamic> _referralStats = {};
  String _selectedTab = 'friends';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  }

  void _initializeAnimations() {
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutBack,
    ));

    _contentFadeAnimation = CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeInOut,
    );

    _celebrationAnimation = CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.elasticOut,
    );

    // Start animations
    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _contentAnimationController.forward();
    });
  }

  void _loadData() {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _invites = SampleData.sampleInvites;
          _referralStats = SampleData.referralStats;
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _contentAnimationController.dispose();
    _celebrationController.dispose();
    _scrollController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationHelperProvider);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header with Animation
          SlideTransition(
            position: _headerSlideAnimation,
            child: InviteHeaderWidget(
              onBackPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // Content
          Expanded(
            child: FadeTransition(
              opacity: _contentFadeAnimation,
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFEFF0F1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Tab Navigation
          _buildTabNavigation().animate().slideX(
            begin: -1,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
          ),

          // Content based on selected tab
          Expanded(
            child: _selectedTab == 'friends' 
                ? _buildFriendsTab()
                : _buildStatsTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabNavigation() {
    final tr = ref.watch(translationHelperProvider);
    
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(4),
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
        children: [
          Expanded(
            child: _buildTabButton(
              'friends',
              '${tr('invite.actions.invite')} Friends',
              Icons.people,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              'stats',
              'My Stats',
              Icons.bar_chart,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tab, String label, IconData icon) {
    final isSelected = _selectedTab == tab;
    
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          setState(() {
            _selectedTab = tab;
          });
          HapticFeedback.selectionClick();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2475FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF6E757D),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF6E757D),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsTab() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        children: [
          // Lottie Animation Placeholder
          _buildAnimationPlaceholder().animate().scale(
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
          ),

          const SizedBox(height: 20),

          // Invite New Friend Section
          _buildInviteNewSection().animate().slideX(
            begin: 1,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
          ),

          const SizedBox(height: 20),

          // Share Options
          ShareOptionsWidget(
            referralCode: _referralStats['referralCode'] ?? '',
            referralLink: _referralStats['referralLink'] ?? '',
            onShare: _onShare,
          ).animate().slideX(
            begin: -1,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutBack,
          ),

          const SizedBox(height: 20),

          // Friends List
          // _buildFriendsList(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Referral Stats
            // ReferralStatsWidget(
            //   stats: _referralStats,
            // ).animate().fadeIn(
            //   duration: const Duration(milliseconds: 600),
            // ),

            // const SizedBox(height: 20),

            // How It Works Section
            _buildHowItWorksSection().animate().slideY(
              begin: 1,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutBack,
            ),

            const SizedBox(height: 20),

            // Recent Activity
            // _buildRecentActivity().animate().slideY(
            //   begin: 1,
            //   duration: const Duration(milliseconds: 1000),
            //   curve: Curves.easeOutBack,
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimationPlaceholder() {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4DABF7),
            Color(0xFF2475FF),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2475FF).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative elements
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
              ),
            ).animate(
              onPlay: (controller) => controller.repeat(),
            ).scale(
              duration: const Duration(seconds: 3),
              curve: Curves.easeInOut,
            ),
          ),
          
          Positioned(
            bottom: 30,
            right: 30,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.15),
              ),
            ).animate(
              onPlay: (controller) => controller.repeat(reverse: true),
            ).scale(
              duration: const Duration(seconds: 2),
              curve: Curves.easeInOut,
            ),
          ),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.celebration,
                  size: 64,
                  color: Colors.white,
                ).animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                ).rotate(
                  duration: const Duration(seconds: 4),
                  curve: Curves.easeInOut,
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  ref.watch(translationHelperProvider)('invite.screen.title'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  ref.watch(translationHelperProvider)('invite.screen.subtitle'),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteNewSection() {
    final tr = ref.watch(translationHelperProvider);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${tr('invite.actions.invite')} New Friend',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF181F30),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Email Input
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: tr('invite.friends.enterEmail'),
              hintText: 'friend@example.com',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF2475FF),
                  width: 2,
                ),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          
          const SizedBox(height: 12),
          
          // Phone Input
          TextField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: '${tr('invite.friends.enterPhone')} (Optional)',
              hintText: '+1 234 567 8900',
              prefixIcon: const Icon(Icons.phone_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF2475FF),
                  width: 2,
                ),
              ),
            ),
            keyboardType: TextInputType.phone,
          ),
          
          const SizedBox(height: 16),
          
          // Send Invite Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _sendInvite,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2475FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                tr('invite.actions.sendInvite'),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
    final tr = ref.watch(translationHelperProvider);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${tr('invite.actions.invited')} Friends',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF181F30),
                ),
              ),
              
              const Spacer(),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2475FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_invites.length} friends',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2475FF),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          if (_invites.isEmpty)
            _buildEmptyFriendsList()
          else
            ..._invites.asMap().entries.map((entry) {
              final index = entry.key;
              final invite = entry.value;
              return InviteCardWidget(
                invite: invite,
                onResendTap: () => _resendInvite(invite),
                onRemoveTap: () => _removeInvite(invite),
              ).animate(delay: Duration(milliseconds: 100 * index))
               .fadeIn(duration: const Duration(milliseconds: 400))
               .slideX(begin: 1, curve: Curves.easeOutBack);
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildEmptyFriendsList() {
    final tr = ref.watch(translationHelperProvider);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            
            const SizedBox(height: 16),
            
            Text(
              tr('invite.empty.noInvites'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              tr('invite.empty.description'),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ).animate()
     .fadeIn(duration: const Duration(milliseconds: 400))
     .scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildHowItWorksSection() {
    final tr = ref.watch(translationHelperProvider);
    final steps = [
      {'title': 'Share your code', 'desc': 'Send your referral code to friends'},
      {'title': 'Friend signs up', 'desc': 'They create an account using your code'},
      {'title': 'First transaction', 'desc': 'Friend makes their first money transfer'},
      {'title': 'Earn rewards', 'desc': 'You both get bonus rewards!'},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('invite.rewards.howItWorks'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF181F30),
            ),
          ),
          
          const SizedBox(height: 20),
          
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isLast = index == steps.length - 1;
            
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2475FF),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 40,
                        color: Colors.grey[300],
                        margin: const EdgeInsets.symmetric(vertical: 8),
                      ),
                  ],
                ),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step['title']!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF181F30),
                          ),
                        ),
                        
                        const SizedBox(height: 4),
                        
                        Text(
                          step['desc']!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6E757D),
                          ),
                        ),
                        
                        if (!isLast) const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ).animate(delay: Duration(milliseconds: 200 * index))
             .fadeIn(duration: const Duration(milliseconds: 400))
             .slideX(begin: 0.5);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    final recentInvites = _invites.take(3).toList();
    
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF181F30),
            ),
          ),
          
          const SizedBox(height: 16),
          
          if (recentInvites.isEmpty)
            Center(
              child: Text(
                'No recent activity',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
            )
          else
            ...recentInvites.map((invite) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: invite.avatar != null 
                          ? AssetImage(invite.avatar!)
                          : null,
                      child: invite.avatar == null
                          ? Text(
                              invite.name.substring(0, 1),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    
                    const SizedBox(width: 12),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invite.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF181F30),
                            ),
                          ),
                          
                          Text(
                            _getStatusText(invite.status),
                            style: TextStyle(
                              fontSize: 12,
                              color: _getStatusColor(invite.status),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    if (invite.rewardAmount != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C735).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '+\$${invite.rewardAmount!.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF00C735),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    final tr = ref.watch(translationHelperProvider);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2475FF)),
          ),
          const SizedBox(height: 16),
          Text(
            '${tr('invite.errors.loadFailed')}...',
            style: TextStyle(
              color: Color(0xFF6E757D),
              fontSize: 14,
            ),
          ),
        ],
      ),
    ).animate()
     .fadeIn(duration: const Duration(milliseconds: 300))
     .scale(begin: const Offset(0.8, 0.8));
  }

  String _getStatusText(InviteStatus status) {
    final tr = ref.watch(translationHelperProvider);
    switch (status) {
      case InviteStatus.pending:
        return tr('invite.status.pending');
      case InviteStatus.accepted:
        return tr('invite.status.accepted');
      case InviteStatus.completed:
        return tr('invite.status.completed');
      case InviteStatus.expired:
        return tr('invite.status.expired');
    }
  }

  Color _getStatusColor(InviteStatus status) {
    switch (status) {
      case InviteStatus.pending:
        return const Color(0xFFFFC000);
      case InviteStatus.accepted:
        return const Color(0xFF2475FF);
      case InviteStatus.completed:
        return const Color(0xFF00C735);
      case InviteStatus.expired:
        return const Color(0xFF6E757D);
    }
  }

  void _sendInvite() {
    final tr = ref.watch(translationHelperProvider);
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('invite.errors.invalidEmail')),
          backgroundColor: Color(0xFFFF3E24),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    
    // Trigger celebration animation
    _celebrationController.forward().then((_) {
      _celebrationController.reverse();
    });

    // Clear inputs
    _emailController.clear();
    _phoneController.clear();

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(tr('invite.notifications.inviteSent')),
          ],
        ),
        backgroundColor: const Color(0xFF00C735),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _onShare(String type, String content) {
    final tr = ref.watch(translationHelperProvider);
    HapticFeedback.lightImpact();
    
    // Handle different share types
    switch (type) {
      case 'copy_code':
        Clipboard.setData(ClipboardData(text: content));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('invite.notifications.codeCopied')),
            duration: Duration(seconds: 2),
          ),
        );
        break;
      case 'copy_link':
        Clipboard.setData(ClipboardData(text: content));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('invite.notifications.linkCopied')),
            duration: Duration(seconds: 2),
          ),
        );
        break;
      default:
        // Handle social sharing (would integrate with share_plus package)
        break;
    }
  }

  void _resendInvite(InviteModel invite) {
    final tr = ref.watch(translationHelperProvider);
    HapticFeedback.lightImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr('invite.notifications.inviteResent').replaceAll('{name}', invite.name)),
        backgroundColor: const Color(0xFF2475FF),
      ),
    );
  }

  void _removeInvite(InviteModel invite) {
    HapticFeedback.lightImpact();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${invite.name}?'),
        content: const Text('This will remove them from your invited friends list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _invites.removeWhere((i) => i.id == invite.id);
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${invite.name} removed from list'),
                  backgroundColor: const Color(0xFF6E757D),
                ),
              );
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
