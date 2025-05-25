
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/models/user.dart';
import '../../../providers/profile_provider.dart';

class ProfileAvatarWidget extends ConsumerStatefulWidget {
  final User? user;
  final bool isEditable;
  final double size;
  final VoidCallback? onImageChanged;

  const ProfileAvatarWidget({
    super.key,
    this.user,
    this.isEditable = true,
    this.size = 120,
    this.onImageChanged,
  });

  @override
  ConsumerState<ProfileAvatarWidget> createState() => _ProfileAvatarWidgetState();
}

class _ProfileAvatarWidgetState extends ConsumerState<ProfileAvatarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  
  XFile? _selectedImage;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 0.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (!widget.isEditable) return;
    
    HapticFeedback.lightImpact();
    
    final ImagePicker picker = ImagePicker();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Title
            Text(
              'Change Profile Picture',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Options
            _buildImageOption(
              icon: Icons.camera_alt,
              title: 'Take Photo',
              subtitle: 'Use camera to take a new photo',
              onTap: () async {
                Navigator.pop(context);
                final image = await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 80,
                  maxWidth: 800,
                  maxHeight: 800,
                );
                if (image != null) {
                  _handleImageSelected(image);
                }
              },
            ),
            
            _buildImageOption(
              icon: Icons.photo_library,
              title: 'Choose from Gallery',
              subtitle: 'Select from your photo library',
              onTap: () async {
                Navigator.pop(context);
                final image = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 80,
                  maxWidth: 800,
                  maxHeight: 800,
                );
                if (image != null) {
                  _handleImageSelected(image);
                }
              },
            ),
            
            if (widget.user?.profileImage != null)
              _buildImageOption(
                icon: Icons.delete,
                title: 'Remove Photo',
                subtitle: 'Use default avatar',
                onTap: () {
                  Navigator.pop(context);
                  _removeImage();
                },
                isDestructive: true,
              ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _handleImageSelected(XFile image) async {
    setState(() {
      _selectedImage = image;
    });
    
    // Upload image
    final success = await ref.read(profileProvider.notifier).uploadProfileImage(image);
    
    if (success) {
      widget.onImageChanged?.call();
      HapticFeedback.mediumImpact();
    } else {
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
    // TODO: Implement remove profile image API call
    widget.onImageChanged?.call();
  }

  Widget _buildImageOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDestructive 
                    ? Colors.red.shade50 
                    : Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isDestructive 
                    ? Colors.red.shade600 
                    : Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? Colors.red.shade600 : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final uploadProgress = ref.watch(imageUploadProgressProvider);
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: GestureDetector(
              onTap: widget.isEditable ? _pickImage : null,
              onTapDown: widget.isEditable ? (_) => _animationController.forward() : null,
              onTapUp: widget.isEditable ? (_) => _animationController.reverse() : null,
              onTapCancel: widget.isEditable ? () => _animationController.reverse() : null,
              child: Stack(
                children: [
                  // Avatar Container
                  Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: (widget.size - 8) / 2,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _getImageProvider(),
                      child: _getImageProvider() == null
                          ? Icon(
                              Icons.person,
                              size: widget.size * 0.5,
                              color: Colors.grey[400],
                            )
                          : null,
                    ),
                  ),
                  
                  // Loading Overlay
                  if (profileState.isImageUploading)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.5),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  value: uploadProgress > 0 ? uploadProgress : null,
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              if (uploadProgress > 0) ...[
                                const SizedBox(height: 8),
                                Text(
                                  '${(uploadProgress * 100).round()}%',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  
                  // Edit Button
                  if (widget.isEditable && !profileState.isImageUploading)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: widget.size * 0.25,
                        height: widget.size * 0.25,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC000),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          size: widget.size * 0.12,
                          color: const Color(0xFF181F30),
                        ),
                      ).animate().scale(
                        delay: const Duration(milliseconds: 400),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.elasticOut,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    ).animate().scale(
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
    );
  }

  ImageProvider? _getImageProvider() {
    if (_selectedImage != null) {
      return FileImage(File(_selectedImage!.path));
    } else if (widget.user?.profileImage != null) {
      return NetworkImage(widget.user!.profileImage!);
    }
    return null;
  }
}