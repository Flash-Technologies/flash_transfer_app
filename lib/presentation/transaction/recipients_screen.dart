import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/translation_service.dart';
import '../../core/models/beneficiary.dart';
import '../../providers/beneficiary_provider.dart';
import 'widgets/promo_banner_widget.dart';
import 'widgets/recipient_search_widget.dart';

class RecipientsScreen extends ConsumerStatefulWidget {
  const RecipientsScreen({super.key});

  @override
  ConsumerState<RecipientsScreen> createState() => _RecipientsScreenState();
}

class _RecipientsScreenState extends ConsumerState<RecipientsScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _contentAnimationController;
  late AnimationController _fabAnimationController;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _contentFadeAnimation;
  late Animation<double> _fabScaleAnimation;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  String _sortBy = 'recent';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadBeneficiaries();
    _setupScrollListener();
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

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
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

    _fabScaleAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    );

    // Start animations
    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _contentAnimationController.forward();
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      _fabAnimationController.forward();
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      // Hide/show FAB based on scroll direction
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        _fabAnimationController.reverse();
      } else if (_scrollController.position.userScrollDirection ==
          ScrollDirection.forward) {
        _fabAnimationController.forward();
      }
      
      // Load more beneficiaries when scrolling near bottom
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 200) {
        // Use Future.microtask to avoid provider modification during scroll events
        Future.microtask(() {
          ref.read(beneficiariesProvider.notifier).loadMoreBeneficiaries();
        });
      }
    });
  }

  Future<void> _loadBeneficiaries() async {
    // Use Future.microtask to avoid provider modification during build
    await Future.microtask(() async {
      await ref.read(beneficiariesProvider.notifier).loadBeneficiaries();
    });
  }

  void _searchBeneficiaries(String query) {
    // Use Future.microtask to avoid provider modification during build
    Future.microtask(() {
      ref.read(beneficiariesProvider.notifier).setSearchQuery(query);
    });
    HapticFeedback.selectionClick();
  }

  void _sortBeneficiaries(String sortBy) {
    setState(() {
      _sortBy = sortBy;
    });
    // Note: Server-side sorting would be implemented here in a real app
    HapticFeedback.selectionClick();
  }

  Future<void> _refreshBeneficiaries() async {
    HapticFeedback.mediumImpact();
    await ref.read(beneficiariesProvider.notifier).refresh();
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _contentAnimationController.dispose();
    _fabAnimationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final translationService = TranslationService.instance;

    return Scaffold(
      backgroundColor: const Color(0xFFEFF0F1),
      body: Column(
        children: [
          // Header
          SlideTransition(
            position: _headerSlideAnimation,
            child: _buildHeader(),
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

      // Floating Action Button
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnimation,
        child: FloatingActionButton.extended(
          onPressed: _onAddNewRecipient,
          backgroundColor: const Color(0xFF2475FF),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.person_add),
          label: Text(
            translationService.translate('recipients.screen.addNew'),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ).animate().shimmer(
          delay: const Duration(seconds: 2),
          duration: const Duration(seconds: 2),
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final translationService = TranslationService.instance;

    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back_ios,
                        size: 20,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        translationService.translate('recipients.screen.back'),
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(
                delay: const Duration(milliseconds: 400),
                duration: const Duration(milliseconds: 400),
              ),

              const SizedBox(width: 16),

              // Title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      translationService.translate('recipients.screen.title'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF181F30),
                      ),
                    ).animate().fadeIn(
                      delay: const Duration(milliseconds: 500),
                      duration: const Duration(milliseconds: 400),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      translationService.translate(
                        'recipients.screen.subtitle',
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6E757D),
                      ),
                    ).animate().fadeIn(
                      delay: const Duration(milliseconds: 600),
                      duration: const Duration(milliseconds: 400),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final translationService = TranslationService.instance;

    return Column(
      children: [
        // Promotional Banner
        PromoBannerWidget(
          onTap: () {
            HapticFeedback.lightImpact();
            // Navigate to referral program
          },
        ).animate().slideX(
          begin: -1,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutBack,
        ),

        const SizedBox(height: 20),

        // Search and Sort Controls
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // Search Bar
              RecipientSearchWidget(
                controller: _searchController,
                onChanged: _searchBeneficiaries,
                hintText: translationService.translate(
                  'recipients.screen.search',
                ),
              ).animate().slideX(
                begin: 1,
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutBack,
              ),

              const SizedBox(height: 12),

              // Sort Options
              _buildSortOptions(),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Recipients List
        Expanded(
          child: SafeArea(
            top: false,
            child: _buildRecipientsList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSortOptions() {
    final translationService = TranslationService.instance;
    final sortOptions = [
      // {
      //   'key': 'recent',
      //   'label': translationService.translate(
      //     'recipients.sorting.recentlyAdded',
      //   ),
      // },
      // {
      //   'key': 'alphabetical',
      //   'label': translationService.translate(
      //     'recipients.sorting.alphabetical',
      //   ),
      // },
      // {
      //   'key': 'mostUsed',
      //   'label': translationService.translate('recipients.sorting.mostUsed'),
      // },
      // {
      //   'key': 'favorites',
      //   'label': translationService.translate('recipients.filters.favorites'),
      // },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            sortOptions.map((option) {
              final isSelected = _sortBy == option['key'];
              return GestureDetector(
                onTap: () => _sortBeneficiaries(option['key']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF2475FF) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          isSelected
                              ? const Color(0xFF2475FF)
                              : const Color(0xFFEBECED),
                    ),
                  ),
                  child: Text(
                    option['label']!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color:
                          isSelected ? Colors.white : const Color(0xFF6E757D),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    ).animate().fadeIn(
      delay: const Duration(milliseconds: 700),
      duration: const Duration(milliseconds: 400),
    );
  }

  Widget _buildRecipientsList() {
    return Consumer(
      builder: (context, ref, child) {
        final beneficiariesState = ref.watch(beneficiariesProvider);

        if (beneficiariesState.isLoading && beneficiariesState.beneficiaries.isEmpty) {
          return _buildLoadingState();
        }

        if (beneficiariesState.error != null) {
          return _buildErrorState(beneficiariesState.error!);
        }

        final beneficiaries = beneficiariesState.filteredBeneficiaries;

        if (beneficiaries.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: _refreshBeneficiaries,
          color: const Color(0xFF2475FF),
          backgroundColor: Colors.white,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: beneficiaries.length + (beneficiariesState.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              // Show loading indicator at the end when loading more
              if (index == beneficiaries.length) {
                return _buildLoadMoreIndicator();
              }

              final beneficiary = beneficiaries[index];
              return _buildBeneficiaryCard(beneficiary, index);
            },
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2475FF)),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading recipients...',
                style: const TextStyle(color: Color(0xFF6E757D), fontSize: 14),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 300))
        .scale(begin: const Offset(0.8, 0.8));
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
                Icons.people_outline,
                size: 60,
                color: Color(0xFF6E757D),
              ),
            ).animate().scale(
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
            ),

            const SizedBox(height: 24),

            Text(
                  _searchController.text.isNotEmpty
                      ? 'No recipients found'
                      : translationService.translate(
                        'recipients.screen.emptyState',
                      ),
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
                  _searchController.text.isNotEmpty
                      ? 'Try adjusting your search terms'
                      : translationService.translate(
                        'recipients.screen.emptyDescription',
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
                  onPressed: _onAddNewRecipient,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2475FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    translationService.translate('recipients.screen.addNew'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
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




  void _onAddNewRecipient() {
    HapticFeedback.mediumImpact();
    // Navigate to add recipient screen with flag to return to recipients list
    context.push('/add-new', extra: {'returnToRecipients': true});
  }

  Widget _buildBeneficiaryCard(Beneficiary beneficiary, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
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
              color: const Color(0xFFFFC000),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                beneficiary.firstName.isNotEmpty 
                    ? beneficiary.firstName[0].toUpperCase()
                    : beneficiary.name[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF181F30),
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  beneficiary.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF181F30),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        beneficiary.country,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Last sent: ${_getTimeAgo(beneficiary.updatedAt)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),

          // Send button
          ElevatedButton(
            onPressed: () => _onSendMoney(beneficiary),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2475FF),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Send',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    )
    .animate(delay: Duration(milliseconds: 100 * index))
    .fadeIn(duration: const Duration(milliseconds: 400))
    .slideX(begin: 1, curve: Curves.easeOutBack);
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF181F30),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _refreshBeneficiaries(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2475FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2475FF)),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Loading more recipients...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSendMoney(Beneficiary beneficiary) {
    HapticFeedback.mediumImpact();
    // Navigate to send money flow
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Send money to ${beneficiary.displayName}'),
        backgroundColor: const Color(0xFF2475FF),
      ),
    );
  }
}
