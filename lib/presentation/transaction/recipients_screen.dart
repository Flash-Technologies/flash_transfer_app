import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/services/translation_service.dart';
import '../../core/models/transaction_model.dart';
import '../../core/models/sample_data.dart';
import 'widgets/promo_banner_widget.dart';
import 'widgets/recipient_card_widget.dart';
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
  
  bool _isLoading = false;
  String _searchQuery = '';
  List<RecipientModel> _filteredRecipients = [];
  String _sortBy = 'recent';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadRecipients();
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
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutBack,
    ));

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
      if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
        _fabAnimationController.reverse();
      } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
        _fabAnimationController.forward();
      }
    });
  }

  void _loadRecipients() {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _filteredRecipients = SampleData.sampleRecipients;
          _isLoading = false;
        });
        _applyFiltersAndSort();
      }
    });
  }

  void _searchRecipients(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFiltersAndSort();
  }

  void _sortRecipients(String sortBy) {
    setState(() {
      _sortBy = sortBy;
    });
    _applyFiltersAndSort();
    HapticFeedback.selectionClick();
  }

  void _applyFiltersAndSort() {
    List<RecipientModel> filtered = SampleData.sampleRecipients;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((recipient) {
        return recipient.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               recipient.country.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case 'alphabetical':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'mostUsed':
        filtered.sort((a, b) => b.totalTransactions.compareTo(a.totalTransactions));
        break;
      case 'lastSent':
        filtered.sort((a, b) {
          if (a.lastSentDate == null && b.lastSentDate == null) return 0;
          if (a.lastSentDate == null) return 1;
          if (b.lastSentDate == null) return -1;
          return b.lastSentDate!.compareTo(a.lastSentDate!);
        });
        break;
      case 'country':
        filtered.sort((a, b) => a.country.compareTo(b.country));
        break;
      case 'favorites':
        filtered = filtered.where((r) => r.isFavorite).toList();
        break;
      default: // recent
        filtered.sort((a, b) {
          if (a.lastSentDate == null && b.lastSentDate == null) return 0;
          if (a.lastSentDate == null) return 1;
          if (b.lastSentDate == null) return -1;
          return b.lastSentDate!.compareTo(a.lastSentDate!);
        });
    }

    setState(() {
      _filteredRecipients = filtered;
    });
  }

  Future<void> _refreshRecipients() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (mounted) {
      setState(() {
        _filteredRecipients = SampleData.sampleRecipients;
        _isLoading = false;
      });
      _applyFiltersAndSort();
    }
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
        ).animate()
         .shimmer(
           delay: const Duration(seconds: 2),
           duration: const Duration(seconds: 2),
           color: Colors.white.withOpacity(0.3),
         ),
      ),
    );
  }

  Widget _buildHeader() {
    final translationService = TranslationService.instance;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 56, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                      translationService.translate('recipients.screen.subtitle'),
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
                onChanged: _searchRecipients,
                hintText: translationService.translate('recipients.screen.search'),
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
          child: _buildRecipientsList(),
        ),
      ],
    );
  }

  Widget _buildSortOptions() {
    final translationService = TranslationService.instance;
    final sortOptions = [
      {'key': 'recent', 'label': translationService.translate('recipients.sorting.recentlyAdded')},
      {'key': 'alphabetical', 'label': translationService.translate('recipients.sorting.alphabetical')},
      {'key': 'mostUsed', 'label': translationService.translate('recipients.sorting.mostUsed')},
      {'key': 'favorites', 'label': translationService.translate('recipients.filters.favorites')},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: sortOptions.map((option) {
          final isSelected = _sortBy == option['key'];
          return GestureDetector(
            onTap: () => _sortRecipients(option['key']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2475FF) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFF2475FF) : const Color(0xFFEBECED),
                ),
              ),
              child: Text(
                option['label']!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF6E757D),
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
    final translationService = TranslationService.instance;

    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_filteredRecipients.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshRecipients,
      color: const Color(0xFF2475FF),
      backgroundColor: Colors.white,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filteredRecipients.length,
        itemBuilder: (context, index) {
          final recipient = _filteredRecipients[index];
          return RecipientCardWidget(
            recipient: recipient,
            onSendTap: () => _onSendMoney(recipient),
            onFavoriteTap: () => _onToggleFavorite(recipient),
            onMoreTap: () => _onShowMoreOptions(recipient),
          ).animate(delay: Duration(milliseconds: 100 * index))
           .fadeIn(duration: const Duration(milliseconds: 400))
           .slideX(begin: 1, curve: Curves.easeOutBack);
        },
      ),
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
            style: const TextStyle(
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
            ).animate()
             .scale(
               duration: const Duration(milliseconds: 600),
               curve: Curves.elasticOut,
             ),
            
            const SizedBox(height: 24),
            
            Text(
              _searchQuery.isNotEmpty 
                  ? 'No recipients found'
                  : translationService.translate('recipients.screen.emptyState'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF181F30),
              ),
              textAlign: TextAlign.center,
            ).animate(delay: const Duration(milliseconds: 200))
             .fadeIn(duration: const Duration(milliseconds: 400))
             .slideY(begin: 0.3),
            
            const SizedBox(height: 12),
            
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search terms'
                  : translationService.translate('recipients.screen.emptyDescription'),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6E757D),
              ),
              textAlign: TextAlign.center,
            ).animate(delay: const Duration(milliseconds: 400))
             .fadeIn(duration: const Duration(milliseconds: 400))
             .slideY(begin: 0.3),
            
            const SizedBox(height: 32),
            
            ElevatedButton(
              onPressed: _onAddNewRecipient,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2475FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
            ).animate(delay: const Duration(milliseconds: 600))
             .fadeIn(duration: const Duration(milliseconds: 400))
             .scale(begin: const Offset(0.8, 0.8), curve: Curves.elasticOut),
          ],
        ),
      ),
    );
  }

  void _onSendMoney(RecipientModel recipient) {
    HapticFeedback.mediumImpact();
    
    // Show send money modal or navigate to send screen
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSendMoneyModal(recipient),
    );
  }

  Widget _buildSendMoneyModal(RecipientModel recipient) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Send Money to ${recipient.name}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF181F30),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Quick amount buttons
                  Text(
                    'Quick amounts',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF181F30),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [50, 100, 200, 500].map((amount) {
                      return ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Navigate to send screen with preset amount
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF4F5F7),
                          foregroundColor: const Color(0xFF181F30),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('\$$amount'),
                      );
                    }).toList(),
                  ),
                  
                  const Spacer(),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            // Navigate to send screen
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2475FF),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Send Money'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate()
     .slideY(begin: 1, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  void _onToggleFavorite(RecipientModel recipient) {
    HapticFeedback.selectionClick();
    
    // Update favorite status (in real app, this would update via provider/API)
    setState(() {
      final index = _filteredRecipients.indexWhere((r) => r.id == recipient.id);
      if (index != -1) {
        _filteredRecipients[index] = recipient.copyWith(
          isFavorite: !recipient.isFavorite,
        );
      }
    });

    // Show snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          recipient.isFavorite
              ? 'Removed from favorites'
              : 'Added to favorites',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF2475FF),
      ),
    );
  }

  void _onShowMoreOptions(RecipientModel recipient) {
    HapticFeedback.lightImpact();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildMoreOptionsModal(recipient),
    );
  }

  Widget _buildMoreOptionsModal(RecipientModel recipient) {
    final options = [
      {'icon': Icons.edit, 'title': 'Edit Recipient', 'color': const Color(0xFF2475FF)},
      {'icon': Icons.history, 'title': 'View History', 'color': const Color(0xFF6E757D)},
      {'icon': Icons.share, 'title': 'Share Contact', 'color': const Color(0xFF6E757D)},
      {'icon': Icons.block, 'title': 'Block Recipient', 'color': const Color(0xFFFF3E24)},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Header
          Text(
            recipient.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF181F30),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Options
          ...options.map((option) {
            return ListTile(
              leading: Icon(
                option['icon'] as IconData,
                color: option['color'] as Color,
              ),
              title: Text(
                option['title'] as String,
                style: TextStyle(
                  color: option['color'] as Color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                HapticFeedback.lightImpact();
                // Handle option tap
              },
            );
          }).toList(),
          
          const SizedBox(height: 20),
        ],
      ),
    ).animate()
     .slideY(begin: 1, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  void _onAddNewRecipient() {
    HapticFeedback.mediumImpact();
    // Navigate to add recipient screen
  }
}
