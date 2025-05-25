import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/services/translation_service.dart';

class RecipientCardWidget extends StatefulWidget {
  final RecipientModel recipient;
  final VoidCallback onSendTap;
  final VoidCallback onFavoriteTap;
  final VoidCallback onMoreTap;

  const RecipientCardWidget({
    super.key,
    required this.recipient,
    required this.onSendTap,
    required this.onFavoriteTap,
    required this.onMoreTap,
  });

  @override
  State<RecipientCardWidget> createState() => _RecipientCardWidgetState();
}

class _RecipientCardWidgetState extends State<RecipientCardWidget>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _favoriteController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _favoriteAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _favoriteController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _favoriteAnimation = CurvedAnimation(
      parent: _favoriteController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _favoriteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final translationService = TranslationService.instance;
    
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: widget.recipient.isFavorite
                    ? Border.all(
                        color: const Color(0xFFFFC000).withOpacity(0.3),
                        width: 1,
                      )
                    : null,
              ),
              child: Row(
                children: [
                  // Avatar and Flag
                  Stack(
                    children: [
                      // Avatar
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFFC000),
                            width: 2,
                          ),
                        ),
                        child: widget.recipient.avatar != null
                            ? ClipOval(
                                child: Image.asset(
                                  widget.recipient.avatar!,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
                                ),
                              )
                            : _buildDefaultAvatar(),
                      ),
                      
                      // Country Flag
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              widget.recipient.flagAsset,
                              width: 16,
                              height: 16,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.flag,
                                  size: 8,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ).animate()
                         .scale(
                           delay: const Duration(milliseconds: 200),
                           duration: const Duration(milliseconds: 400),
                           curve: Curves.elasticOut,
                         ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Recipient Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.recipient.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF181F30),
                                ),
                              ),
                            ),
                            
                            // Favorite button
                            GestureDetector(
                              onTap: () {
                                _favoriteController.forward().then((_) {
                                  _favoriteController.reverse();
                                });
                                widget.onFavoriteTap();
                              },
                              child: AnimatedBuilder(
                                animation: _favoriteAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: 1 + (_favoriteAnimation.value * 0.3),
                                    child: Icon(
                                      widget.recipient.isFavorite 
                                          ? Icons.favorite 
                                          : Icons.favorite_border,
                                      color: widget.recipient.isFavorite 
                                          ? const Color(0xFFFF3E24) 
                                          : const Color(0xFF6E757D),
                                      size: 20,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 4),
                        
                        Row(
                          children: [
                            // Country info
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
                                      widget.recipient.flagAsset,
                                      width: 16,
                                      height: 16,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: Colors.grey[300],
                                      ),
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(width: 4),
                                
                                Text(
                                  widget.recipient.country,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6E757D),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(width: 12),
                            
                            // Last sent info
                            if (widget.recipient.lastSentDate != null)
                              Text(
                                '${translationService.translate('recipients.recipient.lastSent')}: ${_formatDate(widget.recipient.lastSentDate!)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF6E757D),
                                ),
                              )
                            else
                              Text(
                                translationService.translate('recipients.recipient.never'),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF6E757D),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Send Button
                  GestureDetector(
                    onTap: widget.onSendTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2475FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        translationService.translate('recipients.recipient.send'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ).animate()
                   .scale(
                     delay: const Duration(milliseconds: 300),
                     duration: const Duration(milliseconds: 200),
                     curve: Curves.elasticOut,
                   )
                   .then()
                   .shimmer(
                     delay: const Duration(seconds: 3),
                     duration: const Duration(milliseconds: 1000),
                     color: Colors.white.withOpacity(0.3),
                   ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: Color(0xFFF4F5F7),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          widget.recipient.name.isNotEmpty 
              ? widget.recipient.name.substring(0, 1).toUpperCase()
              : '?',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF181F30),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else {
      return '${(difference.inDays / 30).floor()}m ago';
    }
  }

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    _scaleController.reverse();
  }

  void _onTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _scaleController.reverse();
  }
}
