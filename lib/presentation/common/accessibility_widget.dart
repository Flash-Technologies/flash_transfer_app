
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

class AccessibilityWidget extends StatelessWidget {
  final Widget child;
  final String? label;
  final String? hint;
  final String? value;
  final bool excludeSemantics;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool button;
  final bool focusable;
  final bool selected;
  final bool checked;
  final bool toggleable;

  const AccessibilityWidget({
    super.key,
    required this.child,
    this.label,
    this.hint,
    this.value,
    this.excludeSemantics = false,
    this.onTap,
    this.onLongPress,
    this.button = false,
    this.focusable = false,
    this.selected = false,
    this.checked = false,
    this.toggleable = false,
  });

  @override
  Widget build(BuildContext context) {
    if (excludeSemantics) {
      return ExcludeSemantics(child: child);
    }

    return Semantics(
      label: label,
      hint: hint,
      value: value,
      onTap: onTap,
      onLongPress: onLongPress,
      button: button,
      focusable: focusable,
      selected: selected,
      checked: checked,
      toggled: toggleable ? checked : null,
      child: child,
    );
  }
}