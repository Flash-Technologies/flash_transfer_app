
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import '../../../providers/tracking_provider.dart';
import '../../common/animated_button.dart';
import '../../common/error_boundary_widget.dart';
import '../../common/accessibility_widget.dart';
import 'dart:async';

class AdvancedTransferSearchWidget extends ConsumerStatefulWidget {
  final Function(SearchCriteria)? onSearch;
  final Function(String)? onQuickSearch;
  final List<String>? recentSearches;
  final bool showFilters;
  final bool showSuggestions;
  final SearchCriteria? initialCriteria;

  const AdvancedTransferSearchWidget({
    super.key,
    this.onSearch,
    this.onQuickSearch,
    this.recentSearches,
    this.showFilters = true,
    this.showSuggestions = true,
    this.initialCriteria,
  });

  @override
  ConsumerState<AdvancedTransferSearchWidget> createState() => _AdvancedTransferSearchWidgetState();
}

class _AdvancedTransferSearchWidgetState extends ConsumerState<AdvancedTransferSearchWidget>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _searchAnimationController;
  late AnimationController _filtersAnimationController;
  late AnimationController _suggestionsAnimationController;
  
  // Animations
  late Animation<double> _searchFadeAnimation;
  late Animation<double> _filtersSlideAnimation;
  late Animation<double> _suggestionsFadeAnimation;

  // Controllers
  final _searchController = TextEditingController();
  final _senderController = TextEditingController();
  final _receiverController = TextEditingController();
  final _searchFocus = FocusNode();

  // State Variables
  bool _showFilters = false;
  bool _showSuggestions = false;
  bool _isSearching = false;
  DateTimeRange? _dateRange;
  TransferStatus? _selectedStatus;
  String _sortBy = 'date';
  bool _sortAscending = false;
  List<String> _searchSuggestions = [];
  Timer? _debounceTimer;

  // Search History
  List<String> _searchHistory = [];
  List<SearchCriteria> _savedSearches = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _populateInitialData();
    _setupSearchListeners();
    _loadSearchHistory();
    _startAnimations();
  }

  void _initializeAnimations() {
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _filtersAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _suggestionsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _searchFadeAnimation = CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeInOut,
    );

    _filtersSlideAnimation = CurvedAnimation(
      parent: _filtersAnimationController,
      curve: Curves.easeOutBack,
    );

    _suggestionsFadeAnimation = CurvedAnimation(
      parent: _suggestionsAnimationController,
      curve: Curves.easeInOut,
    );
  }

  void _populateInitialData() {
    if (widget.initialCriteria != null) {
      final criteria = widget.initialCriteria!;
      _searchController.text = criteria.query ?? '';
      _senderController.text = criteria.senderName ?? '';
      _receiverController.text = criteria.receiverName ?? '';
      _dateRange = criteria.dateRange;
      _selectedStatus = criteria.status;
      _sortBy = criteria.sortBy ?? 'date';
      _sortAscending = criteria.sortAscending ?? false;
    }
  }

  void _setupSearchListeners() {
    _searchController.addListener(_onSearchTextChanged);
    _searchFocus.addListener(_onSearchFocusChanged);
  }

  void _onSearchTextChanged() {
    final query = _searchController.text;
    
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (query.isNotEmpty) {
        _generateSuggestions(query);
        if (widget.showSuggestions && !_showSuggestions) {
          _toggleSuggestions(true);
        }
      } else {
        if (_showSuggestions) {
          _toggleSuggestions(false);
        }
      }
    });
  }

  void _onSearchFocusChanged() {
    if (_searchFocus.hasFocus && _searchController.text.isNotEmpty) {
      if (widget.showSuggestions && !_showSuggestions) {
        _toggleSuggestions(true);
      }
    }
  }

  void _loadSearchHistory() {
    // Load from local storage or provider
    setState(() {
      _searchHistory = widget.recentSearches ?? [];
    });
  }

  void _startAnimations() {
    _searchAnimationController.forward();
  }

  @override
  void dispose() {
    _searchAnimationController.dispose();
    _filtersAnimationController.dispose();
    _suggestionsAnimationController.dispose();
    
    _searchController.dispose();
    _senderController.dispose();
    _receiverController.dispose();
    _searchFocus.dispose();
    
    _debounceTimer?.cancel();
    
    super.dispose();
  }

  void _generateSuggestions(String query) {
    final suggestions = <String>[];
    
    // Add tracking number suggestions if format matches
    if (RegExp(r'^[A-Z]{0,2}[0-9]*$').hasMatch(query.toUpperCase())) {
      suggestions.add('${query.toUpperCase()} - Tracking Number');
    }
    
    // Add name suggestions
    if (query.length >= 2) {
      suggestions.add('Search sender: "$query"');
      suggestions.add('Search receiver: "$query"');
    }
    
    // Add recent searches that match
    for (final recent in _searchHistory) {
      if (recent.toLowerCase().contains(query.toLowerCase()) && !suggestions.contains(recent)) {
        suggestions.add(recent);
      }
    }
    
    setState(() {
      _searchSuggestions = suggestions.take(5).toList();
    });
  }

  void _toggleFilters(bool show) {
    setState(() {
      _showFilters = show;
    });
    
    if (show) {
      _filtersAnimationController.forward();
    } else {
      _filtersAnimationController.reverse();
    }
  }

  void _toggleSuggestions(bool show) {
    setState(() {
      _showSuggestions = show;
    });
    
    if (show) {
      _suggestionsAnimationController.forward();
    } else {
      _suggestionsAnimationController.reverse();
    }
  }

  void _performQuickSearch(String query) {
    _searchController.text = query;
    _toggleSuggestions(false);
    
    HapticFeedback.selectionClick();
    widget.onQuickSearch?.call(query);
    
    _addToSearchHistory(query);
  }

  void _performAdvancedSearch() {
    if (_searchController.text.isEmpty && 
        _senderController.text.isEmpty && 
        _receiverController.text.isEmpty &&
        _dateRange == null &&
        _selectedStatus == null) {
      _showEmptySearchError();
      return;
    }

    setState(() {
      _isSearching = true;
    });
    
    HapticFeedback.lightImpact();
    
    final criteria = SearchCriteria(
      query: _searchController.text.isNotEmpty ? _searchController.text : null,
      senderName: _senderController.text.isNotEmpty ? _senderController.text : null,
      receiverName: _receiverController.text.isNotEmpty ? _receiverController.text : null,
      dateRange: _dateRange,
      status: _selectedStatus,
      sortBy: _sortBy,
      sortAscending: _sortAscending,
    );
    
    widget.onSearch?.call(criteria);
    
    if (_searchController.text.isNotEmpty) {
      _addToSearchHistory(_searchController.text);
    }
    
    _toggleSuggestions(false);
    _searchFocus.unfocus();
    
    // Reset searching state after delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    });
  }

  void _addToSearchHistory(String query) {
    if (query.isNotEmpty && !_searchHistory.contains(query)) {
      setState(() {
        _searchHistory.insert(0, query);
        if (_searchHistory.length > 10) {
          _searchHistory.removeLast();
        }
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _senderController.clear();
    _receiverController.clear();
    setState(() {
      _dateRange = null;
      _selectedStatus = null;
      _sortBy = 'date';
      _sortAscending = false;
    });
    
    _toggleSuggestions(false);
    _toggleFilters(false);
    
    HapticFeedback.lightImpact();
  }

  void _showEmptySearchError() {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Please enter at least one search criteria'),
        backgroundColor: Colors.orange[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFFFFC000),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (dateRange != null) {
      setState(() {
        _dateRange = dateRange;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ErrorBoundaryWidget(
      child: AccessibilityWidget(
        label: 'Transfer Search',
        hint: 'Search for transfers by tracking number, names, or filters',
        child: FadeTransition(
          opacity: _searchFadeAnimation,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Search Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Search Input
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _searchFocus.hasFocus 
                                ? const Color(0xFFFFC000) 
                                : Colors.grey.shade300,
                            width: _searchFocus.hasFocus ? 2 : 1,
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocus,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search transfers, tracking numbers...',
                            hintStyle: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_searchController.text.isNotEmpty)
                                  IconButton(
                                    icon: Icon(Icons.clear, size: 20, color: Colors.grey[600]),
                                    onPressed: () {
                                      _searchController.clear();
                                      _toggleSuggestions(false);
                                    },
                                  ),
                                if (widget.showFilters)
                                  IconButton(
                                    icon: Icon(
                                      _showFilters ? Icons.filter_list_off : Icons.filter_list,
                                      size: 20,
                                      color: _showFilters ? theme.primaryColor : Colors.grey[600],
                                    ),
                                    onPressed: () => _toggleFilters(!_showFilters),
                                  ),
                              ],
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          onSubmitted: (_) => _performQuickSearch(_searchController.text),
                        ),
                      ),

                      // Quick Action Buttons
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: AnimatedButton(
                              onPressed: _isSearching ? null : _performAdvancedSearch,
                              isLoading: _isSearching,
                              backgroundColor: const Color(0xFFFFC000),
                              foregroundColor: const Color(0xFF181F30),
                              height: 44,
                              borderRadius: 10,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (!_isSearching) ...[
                                    Icon(Icons.search, size: 18),
                                    const SizedBox(width: 8),
                                  ],
                                  Text(
                                    _isSearching ? 'Searching...' : 'Search',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 12),
                          
                          OutlinedButton(
                            onPressed: _clearSearch,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Clear',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Search Suggestions
                if (_showSuggestions && _searchSuggestions.isNotEmpty)
                  FadeTransition(
                    opacity: _suggestionsFadeAnimation,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(
                              'Suggestions',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          ...(_searchSuggestions.map((suggestion) => ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.history,
                              size: 16,
                              color: Colors.grey[500],
                            ),
                            title: Text(
                              suggestion,
                              style: const TextStyle(fontSize: 14),
                            ),
                            onTap: () => _performQuickSearch(suggestion),
                          ))),
                        ],
                      ),
                    ),
                  ),

                // Advanced Filters
                if (_showFilters)
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.3),
                      end: Offset.zero,
                    ).animate(_filtersSlideAnimation),
                    child: FadeTransition(
                      opacity: _filtersSlideAnimation,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Advanced Filters',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF181F30),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Sender/Receiver Fields
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Sender Name',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      TextField(
                                        controller: _senderController,
                                        decoration: InputDecoration(
                                          hintText: 'Enter sender name',
                                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                        ),
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(width: 12),
                                
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Receiver Name',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      TextField(
                                        controller: _receiverController,
                                        decoration: InputDecoration(
                                          hintText: 'Enter receiver name',
                                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                        ),
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Date Range and Status
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Date Range',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      GestureDetector(
                                        onTap: _selectDateRange,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey.shade300),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.date_range, size: 16, color: Colors.grey[600]),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  _dateRange != null
                                                      ? '${_dateRange!.start.day}/${_dateRange!.start.month} - ${_dateRange!.end.day}/${_dateRange!.end.month}'
                                                      : 'Select dates',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: _dateRange != null ? Colors.black87 : Colors.grey[500],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(width: 12),
                                
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Status',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      DropdownButtonFormField<TransferStatus>(
                                        value: _selectedStatus,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                        ),
                                        hint: Text(
                                          'Any status',
                                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                        ),
                                        items: TransferStatus.values.map((status) {
                                          return DropdownMenuItem(
                                            value: status,
                                            child: Text(
                                              status.name.toUpperCase(),
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (status) {
                                          setState(() {
                                            _selectedStatus = status;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Sort Options
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Sort By',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      DropdownButtonFormField<String>(
                                        value: _sortBy,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                        ),
                                        items: [
                                          DropdownMenuItem(value: 'date', child: Text('Date', style: TextStyle(fontSize: 12))),
                                          DropdownMenuItem(value: 'amount', child: Text('Amount', style: TextStyle(fontSize: 12))),
                                          DropdownMenuItem(value: 'status', child: Text('Status', style: TextStyle(fontSize: 12))),
                                        ],
                                        onChanged: (value) {
                                          setState(() {
                                            _sortBy = value!;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(width: 12),
                                
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Order',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      DropdownButtonFormField<bool>(
                                        value: _sortAscending,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                        ),
                                        items: [
                                          DropdownMenuItem(value: false, child: Text('Newest First', style: TextStyle(fontSize: 12))),
                                          DropdownMenuItem(value: true, child: Text('Oldest First', style: TextStyle(fontSize: 12))),
                                        ],
                                        onChanged: (value) {
                                          setState(() {
                                            _sortAscending = value!;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().slideY(
                        begin: -0.3,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutBack,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Search Criteria Model
class SearchCriteria {
  final String? query;
  final String? senderName;
  final String? receiverName;
  final DateTimeRange? dateRange;
  final TransferStatus? status;
  final String? sortBy;
  final bool? sortAscending;

  const SearchCriteria({
    this.query,
    this.senderName,
    this.receiverName,
    this.dateRange,
    this.status,
    this.sortBy,
    this.sortAscending,
  });

  SearchCriteria copyWith({
    String? query,
    String? senderName,
    String? receiverName,
    DateTimeRange? dateRange,
    TransferStatus? status,
    String? sortBy,
    bool? sortAscending,
  }) {
    return SearchCriteria(
      query: query ?? this.query,
      senderName: senderName ?? this.senderName,
      receiverName: receiverName ?? this.receiverName,
      dateRange: dateRange ?? this.dateRange,
      status: status ?? this.status,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'senderName': senderName,
      'receiverName': receiverName,
      'dateRange': dateRange != null ? {
        'start': dateRange!.start.toIso8601String(),
        'end': dateRange!.end.toIso8601String(),
      } : null,
      'status': status?.name,
      'sortBy': sortBy,
      'sortAscending': sortAscending,
    };
  }

  @override
  String toString() {
    return 'SearchCriteria(query: $query, senderName: $senderName, receiverName: $receiverName, status: $status)';
  }
}
 