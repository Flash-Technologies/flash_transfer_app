import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flash_transfer_app/config/theme.dart';

class DropdownField extends StatefulWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final Function(String?) onChanged;

  const DropdownField({
    Key? key,
    required this.hint,
    this.value,
    required this.items,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<DropdownField> createState() => _DropdownFieldState();
}

class _DropdownFieldState extends State<DropdownField> {
  bool _isDropdownOpen = false;

  void _toggleDropdown() {
    setState(() {
      _isDropdownOpen = !_isDropdownOpen;
    });
  }

  void _selectItem(String item) {
    widget.onChanged(item);
    _toggleDropdown();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Dropdown header
        InkWell(
          onTap: _toggleDropdown,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEBECED),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isDropdownOpen
                    ? AppTheme.primaryColor
                    : const Color(0xFFD3D8DD),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.value ?? widget.hint,
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.value != null ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ),
                Image.asset(
                  'assets/icons/arrow-short-down.png',
                  width: 12,
                  height: 6,
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
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final isSelected = widget.value == item;
                
                return InkWell(
                  onTap: () => _selectItem(item),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor.withOpacity(0.05) : null,
                      border: Border(
                        bottom: BorderSide(
                          color: index == widget.items.length - 1
                              ? Colors.transparent
                              : Colors.grey[200]!,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? AppTheme.primaryColor : Colors.black87,
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
                  ),
                )
                .animate()
                .fadeIn(duration: 200.ms, delay: Duration(milliseconds: 25 * index))
                .slideY(begin: 0.1, end: 0, duration: 200.ms);
              },
            ),
          )
          .animate()
          .fadeIn(duration: 200.ms)
          .slideY(begin: -0.1, end: 0, duration: 200.ms),
      ],
    );
  }
}