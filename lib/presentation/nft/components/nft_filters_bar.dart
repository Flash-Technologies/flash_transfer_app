
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/nft_model.dart';
import '../../../config/theme.dart';

class NFTFiltersBar extends StatefulWidget {
  final NFTRarity? selectedRarity;
  final Blockchain? selectedBlockchain;
  final bool showOnlyEligible;
  final Function({
    NFTRarity? rarity,
    Blockchain? blockchain,
    bool? eligibleOnly,
  }) onFilterChanged;

  const NFTFiltersBar({
    super.key,
    this.selectedRarity,
    this.selectedBlockchain,
    this.showOnlyEligible = false,
    required this.onFilterChanged,
  });

  @override
  State<NFTFiltersBar> createState() => _NFTFiltersBarState();
}

class _NFTFiltersBarState extends State<NFTFiltersBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
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
        height: 60,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          children: [
            _buildRarityFilter(),
            const SizedBox(width: 8),
            _buildBlockchainFilter(),
            const SizedBox(width: 8),
            _buildEligibilityFilter(),
            const SizedBox(width: 8),
            _buildClearFiltersButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildRarityFilter() {
    return _buildFilterChip(
      label: widget.selectedRarity?.name.toUpperCase() ?? 'Rarity',
      isSelected: widget.selectedRarity != null,
      onTap: () => _showRarityPicker(),
      icon: Icons.star_outline,
      color: widget.selectedRarity != null
          ? _getRarityColor(widget.selectedRarity!)
          : Colors.grey,
    );
  }

  Widget _buildBlockchainFilter() {
    return _buildFilterChip(
      label: widget.selectedBlockchain?.name.toUpperCase() ?? 'Chain',
      isSelected: widget.selectedBlockchain != null,
      onTap: () => _showBlockchainPicker(),
      icon: Icons.link,
      color: widget.selectedBlockchain != null
          ? _getBlockchainColor(widget.selectedBlockchain!)
          : Colors.grey,
    );
  }

  Widget _buildEligibilityFilter() {
    return _buildFilterChip(
      label: 'Eligible',
      isSelected: widget.showOnlyEligible,
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onFilterChanged(eligibleOnly: !widget.showOnlyEligible);
      },
      icon: Icons.check_circle_outline,
      color: Colors.green,
    );
  }

  Widget _buildClearFiltersButton() {
    final hasFilters = widget.selectedRarity != null ||
        widget.selectedBlockchain != null ||
        widget.showOnlyEligible;

    if (!hasFilters) return const SizedBox.shrink();

    return _buildFilterChip(
      label: 'Clear',
      isSelected: false,
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onFilterChanged(
          rarity: null,
          blockchain: null,
          eligibleOnly: false,
        );
      },
      icon: Icons.clear,
      color: Colors.red,
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? color : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey.shade700,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRarityPicker() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildRarityPickerSheet(),
    );
  }

  void _showBlockchainPicker() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildBlockchainPickerSheet(),
    );
  }

  Widget _buildRarityPickerSheet() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter by Rarity',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...NFTRarity.values.map((rarity) {
            return ListTile(
              leading: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _getRarityColor(rarity),
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(rarity.name.toUpperCase()),
              selected: widget.selectedRarity == rarity,
              onTap: () {
                Navigator.pop(context);
                widget.onFilterChanged(rarity: rarity);
              },
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildBlockchainPickerSheet() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter by Blockchain',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...Blockchain.values.map((blockchain) {
            return ListTile(
              leading: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _getBlockchainColor(blockchain),
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(blockchain.name.toUpperCase()),
              selected: widget.selectedBlockchain == blockchain,
              onTap: () {
                Navigator.pop(context);
                widget.onFilterChanged(blockchain: blockchain);
              },
            );
          }).toList(),
        ],
      ),
    );
  }

  Color _getRarityColor(NFTRarity rarity) {
    switch (rarity) {
      case NFTRarity.common:
        return Colors.grey.shade500;
      case NFTRarity.uncommon:
        return Colors.green.shade500;
      case NFTRarity.rare:
        return Colors.blue.shade500;
      case NFTRarity.epic:
        return Colors.purple.shade500;
      case NFTRarity.legendary:
        return Colors.amber.shade500;
    }
  }

  Color _getBlockchainColor(Blockchain blockchain) {
    switch (blockchain) {
      case Blockchain.ethereum:
        return const Color(0xFF627EEA);
      case Blockchain.polygon:
        return const Color(0xFF8247E5);
      case Blockchain.binance:
        return const Color(0xFFF3BA2F);
      case Blockchain.arbitrum:
        return const Color(0xFF28A0F0);
      case Blockchain.optimism:
        return const Color(0xFFFF0420);
    }
  }
}