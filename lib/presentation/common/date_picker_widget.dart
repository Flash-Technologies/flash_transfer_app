
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DatePickerWidget extends StatefulWidget {
  final DateTime? initialDate;
  final ValueChanged<DateTime>? onDateChanged;
  final String? label;
  final String? hintText;
  final bool isRequired;

  const DatePickerWidget({
    super.key,
    this.initialDate,
    this.onDateChanged,
    this.label,
    this.hintText,
    this.isRequired = false,
  });

  @override
  State<DatePickerWidget> createState() => _DatePickerWidgetState();
}

class _DatePickerWidgetState extends State<DatePickerWidget> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 100)),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)),
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

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
      widget.onDateChanged?.call(date);
    }
  }

  String get _formattedDate {
    if (_selectedDate == null) {
      return widget.hintText ?? 'Select Date';
    }
    return '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label! + (widget.isRequired ? '*' : ''),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF181F30),
            ),
          ),
          const SizedBox(height: 8),
        ],
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border.all(color: const Color(0xFFEBECED)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _formattedDate,
                    style: TextStyle(
                      fontSize: 14,
                      color: _selectedDate != null
                          ? const Color(0xFF181F30)
                          : const Color(0xFF6E757D),
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate().slideX(
      begin: -1,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
    );
  }
}
