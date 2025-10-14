import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/services/translation_service.dart';
import '../../providers/language_provider.dart';
import '../../core/models/transaction_model.dart';
import '../../core/models/sample_data.dart';
import 'widgets/privacy_section_widget.dart';
import 'widgets/privacy_header_widget.dart';
import 'widgets/reading_progress_widget.dart';

class PrivacyScreen extends ConsumerStatefulWidget {
  const PrivacyScreen({super.key});

  @override
  ConsumerState<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends ConsumerState<PrivacyScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _contentAnimationController;
  late AnimationController _progressAnimationController;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _contentFadeAnimation;
  late Animation<double> _progressAnimation;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  List<PrivacySectionModel> _privacySections = [];
  String _searchQuery = '';
  double _readingProgress = 0.0;
  int _currentSection = 0;
  bool _isSearchMode = false;
  List<int> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadPrivacyData();
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

    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
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

    _progressAnimation = CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeInOut,
    );

    // Start animations
    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _contentAnimationController.forward();
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      _updateReadingProgress();
    });
  }

  void _updateReadingProgress() {
    if (_scrollController.hasClients && _privacySections.isNotEmpty) {
      final maxScrollExtent = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;

      if (maxScrollExtent > 0) {
        final progress = (currentScroll / maxScrollExtent).clamp(0.0, 1.0);
        setState(() {
          _readingProgress = progress;
          _currentSection = (_privacySections.length * progress).floor().clamp(
            0,
            _privacySections.length - 1,
          );
        });
      }
    }
  }

  void _loadPrivacyData() {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _privacySections = SampleData.samplePrivacySections;
          _isLoading = false;
        });
      }
    });
  }


  void _searchContent(String query) {
    setState(() {
      _searchQuery = query;
      _isSearchMode = query.isNotEmpty;
    });

    if (query.isNotEmpty) {
      final results = <int>[];
      for (int i = 0; i < _privacySections.length; i++) {
        final section = _privacySections[i];
        if (section.title.toLowerCase().contains(query.toLowerCase()) ||
            section.content.toLowerCase().contains(query.toLowerCase())) {
          results.add(i);
        }

        // Search in subsections
        if (section.subsections != null) {
          for (final subsection in section.subsections!) {
            if (subsection.title.toLowerCase().contains(query.toLowerCase()) ||
                subsection.content.toLowerCase().contains(
                  query.toLowerCase(),
                )) {
              if (!results.contains(i)) {
                results.add(i);
              }
            }
          }
        }
      }

      setState(() {
        _searchResults = results;
      });
    } else {
      setState(() {
        _searchResults = [];
      });
    }
  }

  void _jumpToSection(int index) {
    if (_scrollController.hasClients && index < _privacySections.length) {
      // Calculate approximate position
      final sectionHeight = 200.0; // Approximate height per section
      final targetOffset = index * sectionHeight;

      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );

      HapticFeedback.lightImpact();
    }
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _contentAnimationController.dispose();
    _progressAnimationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final translationService = TranslationService.instance;
    final tr = ref.watch(translationHelperProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFEFF0F1),
      body: Column(
        children: [
          // Header
          SlideTransition(
            position: _headerSlideAnimation,
            child: PrivacyHeaderWidget(
              onBackPressed: () => Navigator.of(context).pop(),
              onSearchPressed: _toggleSearch,
              isSearchMode: _isSearchMode,
              searchController: _searchController,
              onSearchChanged: _searchContent,
            ),
          ),

          // Reading Progress
          ReadingProgressWidget(
            progress: _readingProgress,
            currentSection: _currentSection,
            totalSections: _privacySections.length,
            onSectionTap: _jumpToSection,
          ).animate().slideY(
            begin: -1,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
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

      // Floating Action Button for quick actions
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_isSearchMode && _searchResults.isEmpty && _searchQuery.isNotEmpty) {
      return _buildNoSearchResults();
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Privacy sections
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final sectionIndex =
                    _isSearchMode ? _searchResults[index] : index;
                final section = _privacySections[sectionIndex];

                return PrivacySectionWidget(
                      section: section,
                      isHighlighted: _isSearchMode && _searchQuery.isNotEmpty,
                      searchQuery: _searchQuery,
                      onToggleExpanded: () => _toggleSection(sectionIndex),
                    )
                    .animate(delay: Duration(milliseconds: 100 * index))
                    .fadeIn(duration: const Duration(milliseconds: 400))
                    .slideY(begin: 0.5, curve: Curves.easeOutBack);
              },
              childCount:
                  _isSearchMode
                      ? _searchResults.length
                      : _privacySections.length,
            ),
          ),
        ),

        // Footer
        SliverToBoxAdapter(
          child: _buildFooter().animate().fadeIn(
            delay: const Duration(milliseconds: 800),
            duration: const Duration(milliseconds: 600),
          ),
        ),
      ],
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
                TranslationService.instance.translate('privacy.screen.loading'),
                style: const TextStyle(color: Color(0xFF6E757D), fontSize: 14),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 300))
        .scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildNoSearchResults() {
    return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),

                const SizedBox(height: 16),

                const Text(
                  'No results found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF181F30),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Try different keywords or browse all sections',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: () {
                    _searchController.clear();
                    _searchContent('');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2475FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Clear Search'),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 400))
        .scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildFooter() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
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
        children: [
          Text(
            TranslationService.instance.translate('privacy.footer.questionsTitle'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF181F30),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          Text(
            TranslationService.instance.translate('privacy.footer.contactText'),
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _downloadPolicy,
                  icon: const Icon(Icons.download),
                  label: Text(TranslationService.instance.translate('privacy.actions.downloadPDF')),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _contactSupport,
                  icon: const Icon(Icons.support_agent),
                  label: Text(TranslationService.instance.translate('privacy.actions.contactSupport')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2475FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            TranslationService.instance.translate('privacy.footer.lastUpdated'),
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    if (_readingProgress < 0.1) return null;

    return FloatingActionButton(
          onPressed: _scrollToTop,
          backgroundColor: const Color(0xFF2475FF),
          foregroundColor: Colors.white,
          mini: true,
          child: const Icon(Icons.keyboard_arrow_up),
        )
        .animate()
        .scale(
          duration: const Duration(milliseconds: 200),
          curve: Curves.elasticOut,
        )
        .then()
        .shimmer(
          delay: const Duration(seconds: 2),
          duration: const Duration(milliseconds: 1000),
          color: Colors.white.withOpacity(0.3),
        );
  }

  void _toggleSearch() {
    setState(() {
      _isSearchMode = !_isSearchMode;
    });

    if (!_isSearchMode) {
      _searchController.clear();
      _searchContent('');
    }

    HapticFeedback.lightImpact();
  }

  void _toggleSection(int index) {
    setState(() {
      _privacySections[index] = _privacySections[index].copyWith(
        isExpanded: !_privacySections[index].isExpanded,
      );
    });

    HapticFeedback.selectionClick();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );

    HapticFeedback.mediumImpact();
  }

  void _downloadPolicy() {
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.download, color: Colors.white),
            SizedBox(width: 12),
            Text('Privacy Policy download started'),
          ],
        ),
        backgroundColor: Color(0xFF2475FF),
      ),
    );
  }

  void _contactSupport() {
    HapticFeedback.lightImpact();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Contact Support'),
            content: const Text(
              'Would you like to contact our privacy team about this policy?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Open email client or support form
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2475FF),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Contact'),
              ),
            ],
          ),
    );
  }
}
