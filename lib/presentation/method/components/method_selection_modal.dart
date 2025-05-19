import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flash_transfer_app/presentation/method/components/method_item.dart';

class MethodSelectionModal extends StatelessWidget {
  final List<MethodItem> methods;
  final String? selectedMethodId;
  final Function(MethodItem) onSelect;

  const MethodSelectionModal({
    Key? key,
    required this.methods,
    this.selectedMethodId,
    required this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Select Payment Method",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF181F30),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: methods.length,
              itemBuilder: (context, index) {
                final method = methods[index];
                final isSelected = method.id == selectedMethodId;
                
                return InkWell(
                  onTap: () {
                    onSelect(method);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                      color: isSelected ? const Color(0xFFF0F8FF) : null,
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          method.iconPath,
                          width: 40,
                          height: 40,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            method.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? const Color(0xFF2475FF) : const Color(0xFF181F30),
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF2475FF),
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                )
                .animate()
                .fadeIn(
                  duration: const Duration(milliseconds: 200),
                  delay: Duration(milliseconds: 50 * index),
                )
                .slideX(
                  begin: 0.1,
                  end: 0,
                  duration: const Duration(milliseconds: 200),
                  delay: Duration(milliseconds: 50 * index),
                  curve: Curves.easeOutQuad,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Cancel",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    )
    .animate()
    .fadeIn(duration: const Duration(milliseconds: 300))
    .slideY(
      begin: 0.1,
      end: 0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutQuad,
    );
  }
}