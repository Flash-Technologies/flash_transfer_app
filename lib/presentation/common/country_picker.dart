import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flash_transfer_app/core/models/country_model.dart';
import 'package:flash_transfer_app/config/theme.dart';

class CountryPicker extends StatefulWidget {
  final List<CountryModel> countries;
  final CountryModel? selectedCountry;
  final Function(CountryModel) onSelect;

  const CountryPicker({
    Key? key,
    required this.countries,
    this.selectedCountry,
    required this.onSelect,
  }) : super(key: key);

  @override
  State<CountryPicker> createState() => _CountryPickerState();
}

class _CountryPickerState extends State<CountryPicker> {
  bool _isDropdownOpen = false;
  late TextEditingController _searchController;
  List<CountryModel> _filteredCountries = [];

  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredCountries = List.from(widget.countries);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _filterCountries(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCountries = List.from(widget.countries);
      } else {
        _filteredCountries =
            widget.countries
                .where(
                  (country) =>
                      country.name.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
      }
    });
  }

  void _toggleDropdown() {
    setState(() {
      _isDropdownOpen = !_isDropdownOpen;
      if (_isDropdownOpen) {
        _filteredCountries = List.from(widget.countries);
        _searchController.clear();
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_searchFocusNode.canRequestFocus) {
            _searchFocusNode.requestFocus();
          }
        });
      }
    });
  }

  void _selectCountry(CountryModel country) {
    widget.onSelect(country);
    _toggleDropdown();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Selected country display / dropdown trigger
        InkWell(
          onTap: _toggleDropdown,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F5F7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    _isDropdownOpen
                        ? AppTheme.primaryColor
                        : const Color(0xFFEBECED),
              ),
              boxShadow:
                  _isDropdownOpen
                      ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                      : null,
            ),
            child: Row(
              children: [
                if (widget.selectedCountry != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      'https://flagcdn.com/w80/${widget.selectedCountry!.code.toLowerCase()}.png',
                      width: 24,
                      height: 16,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.network(
                          widget.selectedCountry!.flagUrl,
                          width: 24,
                          height: 16,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 24,
                              height: 16,
                              color: Colors.grey[300],
                              child: Center(
                                child: Text(
                                  widget.selectedCountry!.code.length >= 2
                                      ? widget.selectedCountry!.code.substring(
                                        0,
                                        2,
                                      )
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.selectedCountry!.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF181F30),
                      ),
                    ),
                  ),
                ] else
                  Expanded(
                    child: Text(
                      'Select Country',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ),
                Icon(
                  _isDropdownOpen
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.grey[600],
                  size: 16,
                ),
              ],
            ),
          ),
        ),

        // Dropdown content
        if (_isDropdownOpen)
          Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Search input
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Search country',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        onChanged: _filterCountries,
                      ),
                    ),

                    // Countries list
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.3,
                      ),
                      child:
                          _filteredCountries.isEmpty
                              ? _buildEmptyState()
                              : _buildCountriesList(),
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(duration: 200.ms)
              .slideY(
                begin: -0.1,
                end: 0,
                duration: 200.ms,
                curve: Curves.easeOutQuad,
              ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No countries found',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  Widget _buildCountriesList() {
    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: _filteredCountries.length,
      itemBuilder: (context, index) {
        final country = _filteredCountries[index];
        final isSelected = widget.selectedCountry?.code == country.code;

        return InkWell(
          onTap: () => _selectCountry(country),
          child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? AppTheme.primaryColor.withOpacity(0.05)
                          : null,
                  border: Border(
                    bottom: BorderSide(
                      color:
                          index == _filteredCountries.length - 1
                              ? Colors.transparent
                              : Colors.grey[200]!,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        'https://flagcdn.com/w80/${country.code.toLowerCase()}.png',
                        width: 24,
                        height: 16,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.network(
                            country.flagUrl,
                            width: 24,
                            height: 16,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 24,
                                height: 16,
                                color: Colors.grey[300],
                                child: Center(
                                  child: Text(
                                    country.code.length >= 2 ? country.code.substring(0, 2) : '?',
                                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        country.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color:
                              isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.black87,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                  ],
                ),
              )
              .animate()
              .fadeIn(
                duration: 200.ms,
                delay: Duration(milliseconds: 50 * index % 10),
              )
              .slideX(begin: 0.05, end: 0, duration: 200.ms),
        );
      },
    );
  }
}
