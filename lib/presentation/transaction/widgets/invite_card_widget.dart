import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/services/translation_service.dart';
// Invite Card Widget
class InviteCardWidget extends StatefulWidget {
  final InviteModel invite;
  final VoidCallback onResendTap;
  final VoidCallback onRemoveTap;

  const InviteCardWidget({
    super.key,
    required this.invite,
    required this.onResendTap,
    required this.onRemoveTap,
  });

  @override
  State<InviteCardWidget> createState() => _InviteCardWidgetState();
}

class _InviteCardWidgetState extends State<InviteCardWidget>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getBorderColor(),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: widget.invite.avatar != null 
                            ? AssetImage(widget.invite.avatar!)
                            : null,
                        backgroundColor: const Color(0xFFF4F5F7),
                        child: widget.invite.avatar == null
                            ? Text(
                                widget.invite.name.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF181F30),
                                ),
                              )
                            : null,
                      ),
                      
                      // Status indicator
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _getStatusColor(),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: _getStatusIcon(),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // User Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.invite.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF181F30),
                          ),
                        ),
                        
                        const SizedBox(height: 4),
                        
                        Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: Image.asset(
                                  widget.invite.flagAsset,
                                  width: 16,
                                  height: 16,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: Colors.grey[300],
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: 6),
                            
                            Text(
                              widget.invite.country,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6E757D),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 4),
                        
                        Text(
                          _getStatusText(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Action Button
                  _buildActionButton(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton() {
    switch (widget.invite.status) {
      case InviteStatus.pending:
        return PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'resend') {
              widget.onResendTap();
            } else if (value == 'remove') {
              widget.onRemoveTap();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'resend',
              child: Row(
                children: [
                  Icon(Icons.refresh, size: 16),
                  SizedBox(width: 8),
                  Text('Resend'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Remove', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F5F7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.more_vert,
              size: 16,
              color: Color(0xFF6E757D),
            ),
          ),
        );
        
      case InviteStatus.accepted:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF2475FF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Joined',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2475FF),
            ),
          ),
        );
        
      case InviteStatus.completed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.invite.rewardAmount != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C735).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+\$${widget.invite.rewardAmount!.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF00C735),
                  ),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(
              Icons.check_circle,
              size: 20,
              color: Color(0xFF00C735),
            ),
          ],
        );
        
      case InviteStatus.expired:
        return GestureDetector(
          onTap: widget.onResendTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFC000),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Resend',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF181F30),
              ),
            ),
          ),
        );
    }
  }

  Color _getBorderColor() {
    switch (widget.invite.status) {
      case InviteStatus.completed:
        return const Color(0xFF00C735).withOpacity(0.3);
      case InviteStatus.accepted:
        return const Color(0xFF2475FF).withOpacity(0.3);
      default:
        return const Color(0xFFEBECED);
    }
  }

  Color _getStatusColor() {
    switch (widget.invite.status) {
      case InviteStatus.pending:
        return const Color(0xFFFFC000);
      case InviteStatus.accepted:
        return const Color(0xFF2475FF);
      case InviteStatus.completed:
        return const Color(0xFF00C735);
      case InviteStatus.expired:
        return const Color(0xFF6E757D);
    }
  }

  Widget _getStatusIcon() {
    switch (widget.invite.status) {
      case InviteStatus.pending:
        return const Icon(
          Icons.access_time,
          size: 8,
          color: Colors.white,
        );
      case InviteStatus.accepted:
        return const Icon(
          Icons.person,
          size: 8,
          color: Colors.white,
        );
      case InviteStatus.completed:
        return const Icon(
          Icons.check,
          size: 8,
          color: Colors.white,
        );
      case InviteStatus.expired:
        return const Icon(
          Icons.close,
          size: 8,
          color: Colors.white,
        );
    }
  }

  String _getStatusText() {
    switch (widget.invite.status) {
      case InviteStatus.pending:
        return 'Invite sent ${_formatDate(widget.invite.dateInvited)}';
      case InviteStatus.accepted:
        return 'Joined ${_formatDate(widget.invite.dateAccepted!)}';
      case InviteStatus.completed:
        return 'Completed ${_formatDate(widget.invite.dateCompleted!)}';
      case InviteStatus.expired:
        return 'Expired';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }
}