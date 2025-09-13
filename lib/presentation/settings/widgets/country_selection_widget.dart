
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../common/accessibility_widget.dart';
import '../../common/error_boundary_widget.dart';
import 'dart:async';

// Hardcoded XOF Countries
class XOFCountries {
  static const List<CountryData> countries = [
    CountryData(
      name: "Benin",
      code: "BJ",
      flagEmoji: "🇧🇯",
      currency: "XOF",
    ),
    CountryData(
      name: "Burkina Faso",
      code: "BF",
      flagEmoji: "🇧🇫",
      currency: "XOF",
    ),
    CountryData(
      name: "Cote d'Ivoire",
      code: "CI",
      flagEmoji: "🇨🇮",
      currency: "XOF",
    ),
    CountryData(
      name: "Guinea-Bissau",
      code: "GW",
      flagEmoji: "🇬🇼",
      currency: "XOF",
    ),
    CountryData(
      name: "Mali",
      code: "ML",
      flagEmoji: "🇲🇱",
      currency: "XOF",
    ),
    CountryData(
      name: "Niger",
      code: "NE",
      flagEmoji: "🇳🇪",
      currency: "XOF",
    ),
    CountryData(
      name: "Senegal",
      code: "SN",
      flagEmoji: "🇸🇳",
      currency: "XOF",
    ),
    CountryData(
      name: "Togo",
      code: "TG",
      flagEmoji: "🇹🇬",
      currency: "XOF",
    ),
  ];
  
  static List<CountryData> getXOFCountries() => countries;
}

class CountrySelectionWidget extends ConsumerStatefulWidget {
  final List<CountryData> countries;
  final CountryData? selectedCountry;
  final ValueChanged<CountryData> onCountrySelected;
  final String? label;
  final String? hint;
  final bool showFavorites;
  final bool showRecentlyUsed;
  final List<String>? favoriteCountryCodes;
  final bool isRequired;

  const CountrySelectionWidget({
    super.key,
    required this.countries,
    this.selectedCountry,
    required this.onCountrySelected,
    this.label,
    this.hint,
    this.showFavorites = true,
    this.showRecentlyUsed = true,
    this.favoriteCountryCodes,
    this.isRequired = false,
  });

  @override
  ConsumerState<CountrySelectionWidget> createState() => _CountrySelectionWidgetState();
}

class _CountrySelectionWidgetState extends ConsumerState<CountrySelectionWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  
  List<CountryData> _filteredCountries = [];
  List<CountryData> _favoriteCountries = [];
  List<CountryData> _recentCountries = [];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeCountries();
    _setupSearchListener();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  void _initializeCountries() {
    // Use provided countries or default to XOF countries
    final countriesList = widget.countries.isNotEmpty ? widget.countries : XOFCountries.getXOFCountries();
    _filteredCountries = countriesList;
    
    // Setup favorites
    if (widget.showFavorites && widget.favoriteCountryCodes != null) {
      _favoriteCountries = countriesList
          .where((country) => widget.favoriteCountryCodes!.contains(country.code))
          .toList();
    }
    
    // Setup recent countries (would normally come from preferences)
    if (widget.showRecentlyUsed) {
      _recentCountries = countriesList.take(3).toList();
    }
  }

  void _setupSearchListener() {
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _filterCountries(_searchController.text);
    });
  }

  void _filterCountries(String query) {
    final countriesList = widget.countries.isNotEmpty ? widget.countries : XOFCountries.getXOFCountries();
    
    if (query.isEmpty) {
      setState(() {
        _filteredCountries = countriesList;
      });
      return;
    }

    final lowercaseQuery = query.toLowerCase();
    setState(() {
      _filteredCountries = countriesList.where((country) {
        return country.name.toLowerCase().contains(lowercaseQuery) ||
               country.code.toLowerCase().contains(lowercaseQuery) ||
               (country.dialCode?.toLowerCase().contains(lowercaseQuery) ?? false);
      }).toList();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _showCountryPicker() {
    HapticFeedback.lightImpact();
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CountryPickerModal(
        countries: widget.countries.isNotEmpty ? widget.countries : XOFCountries.getXOFCountries(),
        filteredCountries: _filteredCountries,
        favoriteCountries: _favoriteCountries,
        recentCountries: _recentCountries,
        selectedCountry: widget.selectedCountry,
        onCountrySelected: (country) {
          widget.onCountrySelected(country);
          Navigator.pop(context);
        },
        searchController: _searchController,
        searchFocus: _searchFocus,
        onSearchChanged: _filterCountries,
        showFavorites: widget.showFavorites,
        showRecentlyUsed: widget.showRecentlyUsed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWidget(
      child: AccessibilityWidget(
        label: widget.label ?? 'Country Selection',
        hint: 'Tap to select a country',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.label != null) ...[
              Text(
                widget.label! + (widget.isRequired ? ' *' : ''),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF181F30),
                ),
              ),
              const SizedBox(height: 8),
            ],
            
            ScaleTransition(
              scale: _scaleAnimation,
              child: GestureDetector(
                onTap: _showCountryPicker,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border.all(color: const Color(0xFFEBECED)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Flag or placeholder
                      Container(
                        width: 32,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: widget.selectedCountry != null
                            ? Center(
                                child: Text(
                                  widget.selectedCountry!.flagEmoji,
                                  style: const TextStyle(fontSize: 18),
                                ),
                              )
                            : Icon(
                                Icons.flag,
                                size: 16,
                                color: Colors.grey[500],
                              ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Country name and dial code
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.selectedCountry?.name ?? widget.hint ?? 'Select Country',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: widget.selectedCountry != null
                                    ? const Color(0xFF181F30)
                                    : const Color(0xFF6E757D),
                              ),
                            ),
                            if (widget.selectedCountry?.dialCode != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.selectedCountry!.dialCode!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      // Dropdown icon
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Country Picker Modal
class _CountryPickerModal extends StatefulWidget {
  final List<CountryData> countries;
  final List<CountryData> filteredCountries;
  final List<CountryData> favoriteCountries;
  final List<CountryData> recentCountries;
  final CountryData? selectedCountry;
  final ValueChanged<CountryData> onCountrySelected;
  final TextEditingController searchController;
  final FocusNode searchFocus;
  final ValueChanged<String> onSearchChanged;
  final bool showFavorites;
  final bool showRecentlyUsed;

  const _CountryPickerModal({
    required this.countries,
    required this.filteredCountries,
    required this.favoriteCountries,
    required this.recentCountries,
    this.selectedCountry,
    required this.onCountrySelected,
    required this.searchController,
    required this.searchFocus,
    required this.onSearchChanged,
    required this.showFavorites,
    required this.showRecentlyUsed,
  });

  @override
  State<_CountryPickerModal> createState() => _CountryPickerModalState();
}

class _CountryPickerModalState extends State<_CountryPickerModal>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Select Country',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                controller: widget.searchController,
                focusNode: widget.searchFocus,
                decoration: InputDecoration(
                  hintText: 'Search XOF countries...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFEBECED)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFEBECED)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFFC000), width: 2),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _isSearching = value.trim().isNotEmpty;
                  });
                  widget.onSearchChanged(value);
                },
              ),
            ),

            // Countries list
            Expanded(
              child: _isSearching 
                ? ListView(
                    children: [
                      if (widget.filteredCountries.isNotEmpty) ...[
                        _buildSectionHeader('Search Results'),
                        ...widget.filteredCountries.map((country) => _buildCountryTile(country)),
                      ] else ...[
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'No countries found',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ],
                  )
                : ListView(
                    children: [
                      // Recently used
                      if (widget.showRecentlyUsed && widget.recentCountries.isNotEmpty) ...[
                        _buildSectionHeader('Recently Used'),
                        ...widget.recentCountries.map((country) => _buildCountryTile(country, isRecent: true)),
                        const Divider(),
                      ],

                      // Favorites
                      if (widget.showFavorites && widget.favoriteCountries.isNotEmpty) ...[
                        _buildSectionHeader('Favorites'),
                        ...widget.favoriteCountries.map((country) => _buildCountryTile(country, isFavorite: true)),
                        const Divider(),
                      ],

                      // All countries
                      _buildSectionHeader('All Countries'),
                      ...widget.filteredCountries.map((country) => _buildCountryTile(country)),
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildCountryTile(CountryData country, {bool isFavorite = false, bool isRecent = false}) {
    final isSelected = widget.selectedCountry?.code == country.code;
    
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onCountrySelected(country);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // Flag
            Container(
              width: 32,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  country.flagEmoji,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Country info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          country.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? const Color(0xFFFFC000) : const Color(0xFF181F30),
                          ),
                        ),
                      ),
                      if (isFavorite) Icon(Icons.star, size: 16, color: Colors.amber),
                      if (isRecent) Icon(Icons.history, size: 16, color: Colors.blue),
                    ],
                  ),
                  if (country.dialCode != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${country.dialCode} • ${country.code}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Selection indicator
            if (isSelected)
              Icon(
                Icons.check,
                color: const Color(0xFFFFC000),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

// Country Data Model
class CountryData {
  final String name;
  final String code;
  final String? dialCode;
  final String? flagUrl;
  final String flagEmoji;
  final String? currency;
  final List<String>? languages;

  const CountryData({
    required this.name,
    required this.code,
    this.dialCode,
    this.flagUrl,
    required this.flagEmoji,
    this.currency,
    this.languages,
  });

  factory CountryData.fromJson(Map<String, dynamic> json) {
    return CountryData(
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      dialCode: json['dialCode'],
      flagUrl: json['flagUrl'],
      flagEmoji: json['flagEmoji'] ?? '',
      currency: json['currency'],
      languages: json['languages'] != null ? List<String>.from(json['languages']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'dialCode': dialCode,
      'flagUrl': flagUrl,
      'flagEmoji': flagEmoji,
      'currency': currency,
      'languages': languages,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CountryData && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'CountryData(name: $name, code: $code)';
}