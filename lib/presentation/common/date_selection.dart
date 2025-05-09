import 'package:flutter/material.dart';

class DateSelection extends StatefulWidget {
  final Function(String) onDateChange;

  const DateSelection({
    Key? key,
    required this.onDateChange,
  }) : super(key: key);

  @override
  State<DateSelection> createState() => _DateSelectionState();
}

class _DateSelectionState extends State<DateSelection> {
  String? _selectedDay;
  String? _selectedMonth;
  String? _selectedYear;
  
  String? _activeDropdown;
  
  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  
  late List<String> _days;
  late List<String> _years;
  
  @override
  void initState() {
    super.initState();
    
    _years = List.generate(
      100,
      (index) => (DateTime.now().year - index).toString(),
    );
    
    _updateDaysInMonth();
  }
  
  void _updateDaysInMonth() {
    int daysInMonth = 31;
    
    if (_selectedMonth != null && _selectedYear != null) {
      final monthIndex = _months.indexOf(_selectedMonth!) + 1;
      final year = int.parse(_selectedYear!);
      
      daysInMonth = DateTime(year, monthIndex + 1, 0).day;
    }
    
    _days = List.generate(
      daysInMonth,
      (index) => (index + 1).toString().padLeft(2, '0'),
    );
    
    // Update selected day if it's now invalid
    if (_selectedDay != null) {
      final day = int.parse(_selectedDay!);
      if (day > daysInMonth) {
        _selectedDay = daysInMonth.toString().padLeft(2, '0');
        _updateDateString();
      }
    }
  }
  
  void _updateDateString() {
    if (_selectedYear != null && _selectedMonth != null && _selectedDay != null) {
      final monthIndex = _months.indexOf(_selectedMonth!) + 1;
      final monthString = monthIndex.toString().padLeft(2, '0');
      
      final dateString = '$_selectedYear-$monthString-$_selectedDay';
      widget.onDateChange(dateString);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date of Birth',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDropdownField(
                hint: 'Day',
                value: _selectedDay,
                onTap: () => setState(() => _activeDropdown = 'day'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDropdownField(
                hint: 'Month',
                value: _selectedMonth,
                onTap: () => setState(() => _activeDropdown = 'month'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDropdownField(
                hint: 'Year',
                value: _selectedYear,
                onTap: () => setState(() => _activeDropdown = 'year'),
              ),
            ),
          ],
        ),
        if (_activeDropdown != null) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: ListView.builder(
              itemCount: _getActiveList().length,
              itemBuilder: (context, index) {
                final item = _getActiveList()[index];
                return ListTile(
                  title: Text(item),
                  onTap: () {
                    setState(() {
                      _setSelectedValue(item);
                      _activeDropdown = null;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildDropdownField({
    required String hint,
    required String? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F5F7),
          border: Border.all(
            color: value != null
                ? Theme.of(context).primaryColor
                : const Color(0xFFEBECED),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value ?? hint,
              style: TextStyle(
                color: value != null
                    ? Colors.black
                    : const Color(0xFF6E757D),
              ),
            ),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
    );
  }
  
  List<String> _getActiveList() {
    switch (_activeDropdown) {
      case 'day':
        return _days;
      case 'month':
        return _months;
      case 'year':
        return _years;
      default:
        return [];
    }
  }
  
  void _setSelectedValue(String value) {
    switch (_activeDropdown) {
      case 'day':
        _selectedDay = value;
        break;
      case 'month':
        _selectedMonth = value;
        _updateDaysInMonth();
        break;
      case 'year':
        _selectedYear = value;
        _updateDaysInMonth();
        break;
    }
    
    _updateDateString();
  }
}