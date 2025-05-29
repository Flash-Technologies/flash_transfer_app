// lib/presentation/home/components/recent_receipts_section.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flash_transfer_app/config/ui_constants.dart';

class RecentReceiptsSection extends StatefulWidget {
  const RecentReceiptsSection({Key? key}) : super(key: key);

  @override
  State<RecentReceiptsSection> createState() => _RecentReceiptsSectionState();
}

class _RecentReceiptsSectionState extends State<RecentReceiptsSection> {
  final TextEditingController searchController = TextEditingController();
  final Set<int> invitedUsers = {};
  String searchQuery = '';

  // Sample data - replace with actual data from providers
  final List<Map<String, dynamic>> recentReceipts = [
    {'id': 1, 'name': 'Theresa Webb', 'country': 'USA', 'flag': '🇺🇸', 'image': 'assets/images/theresa.png', 'lastTransfer': '2 hours ago'},
    {'id': 2, 'name': 'Courtney Henry', 'country': 'France', 'flag': '🇫🇷', 'image': 'assets/images/courtney.png', 'lastTransfer': '5 hours ago'},
    {'id': 3, 'name': 'Robert Fox', 'country': 'USA', 'flag': '🇺🇸', 'image': 'assets/images/robert.png', 'lastTransfer': 'Yesterday'},
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredReceipts = recentReceipts
        .where((receipt) => receipt['name']
            .toLowerCase()
            .contains(searchQuery.toLowerCase()))
        .toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildSearchBar(),
          const SizedBox(height: 20),
          ...filteredReceipts.asMap().entries.map((entry) {
            final index = entry.key;
            final receipt = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildReceiptItem(receipt, index),
            );
          }),
          const SizedBox(height: 16),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.access_time_rounded,
            size: 20,
            color: Color(0xFF388E3C),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Recent Receipts',
          style: AppTextStyles.heading3.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF181F30),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: searchQuery.isNotEmpty 
              ? const Color(0xFF2475FF).withOpacity(0.3)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(
            Icons.search_rounded,
            size: 20,
            color: searchQuery.isNotEmpty 
                ? const Color(0xFF2475FF)
                : const Color(0xFF9E9E9E),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: searchController,
              onChanged: (value) => setState(() => searchQuery = value),
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF181F30),
              ),
              decoration: InputDecoration(
                hintText: 'Search receipts',
                hintStyle: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[500],
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (searchQuery.isNotEmpty)
            IconButton(
              onPressed: () {
                searchController.clear();
                setState(() => searchQuery = '');
              },
              icon: Icon(
                Icons.close_rounded,
                size: 18,
                color: Colors.grey[500],
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildReceiptItem(Map<String, dynamic> receipt, int index) {
    final bool isInvited = invitedUsers.contains(receipt['id']);
    
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          // Handle receipt selection
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Avatar with gradient border
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2475FF), Color(0xFFFFC000)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white,
                      backgroundImage: AssetImage(receipt['image']),
                      onBackgroundImageError: (_, __) {},
                      child: receipt['image'] == null
                          ? Text(
                              receipt['name'].substring(0, 1),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF181F30),
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        receipt['name'],
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF181F30),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            receipt['flag'],
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            receipt['country'],
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• ${receipt['lastTransfer']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              
              // Invite button
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    if (!isInvited) {
                      setState(() {
                        invitedUsers.add(receipt['id']);
                      });
                    }
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: isInvited
                        ? const Color(0xFF00C735).withOpacity(0.1)
                        : const Color(0xFF2475FF),
                    foregroundColor: isInvited
                        ? const Color(0xFF00C735)
                        : Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: const Size(80, 36),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isInvited)
                        const Icon(Icons.check_rounded, size: 16)
                      else
                        const Icon(Icons.person_add_rounded, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        isInvited ? 'Invited' : 'Invite',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate()
      .fadeIn(
        delay: Duration(milliseconds: 200 + (index * 100)),
        duration: 400.ms,
      )
      .slideY(
        begin: 0.1,
        end: 0,
        delay: Duration(milliseconds: 200 + (index * 100)),
        duration: 400.ms,
        curve: Curves.easeOutCubic,
      );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Confirm button
        ElevatedButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.push('/receiver-info');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFC000),
            foregroundColor: const Color(0xFF181F30),
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(double.infinity, 54),
          ),
          child: const Text(
            'Confirm',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Cancel button
        OutlinedButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            // Handle cancel
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF6E757D),
            side: const BorderSide(color: Color(0xFFE0E0E0)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(double.infinity, 54),
          ),
          child: const Text(
            'Cancel',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}