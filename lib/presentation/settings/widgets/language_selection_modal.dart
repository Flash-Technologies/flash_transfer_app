import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/models/language_model.dart';
import '../../../../providers/language_provider.dart';
import './language_list_item.dart';
import './language_search_bar.dart';
import './language_confirmation_dialog.dart';

class LanguageSelectionModal extends ConsumerStatefulWidget {
  const LanguageSelectionModal({super.key});

  @override
  ConsumerState<LanguageSelectionModal> createState() =>
      _LanguageSelectionModalState();
}

class _LanguageSelectionModalState extends ConsumerState<LanguageSelectionModal>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _backdropAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    _backdropAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _closeModal() {
    _animationController.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  Future<void> _onLanguageSelected(LanguageModel language) async {
    final currentLanguage = ref.read(currentLanguageProvider);

    if (language.code == currentLanguage.code) {
      _closeModal();
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => LanguageConfirmationDialog(language: language),
    );

    if (confirmed == true) {
      final success = await ref
          .read(languageProvider.notifier)
          .changeLanguage(language);

      if (success && mounted) {
        _closeModal();

        // Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Language changed to ${language.name}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredLanguages = ref.watch(filteredLanguagesProvider);
    final currentLanguage = ref.watch(currentLanguageProvider);
    final isLoading = ref.watch(isLanguageLoadingProvider);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          children: [
            // Backdrop
            GestureDetector(
              onTap: _closeModal,
              child: Container(
                color: Colors.black.withOpacity(0.5 * _backdropAnimation.value),
                width: double.infinity,
                height: double.infinity,
              ),
            ),

            // Modal content
            Align(
              alignment: Alignment.bottomCenter,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.1),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.language,
                              color: Theme.of(context).primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Choose Language',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _closeModal,
                              icon: const Icon(Icons.close),
                              color: Theme.of(context).primaryColor,
                            ),
                          ],
                        ),
                      ),

                      // Search bar
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: LanguageSearchBar(
                          onChanged: (query) {
                            ref
                                .read(languageProvider.notifier)
                                .searchLanguages(query);
                          },
                        ),
                      ),

                      // Language list
                      Flexible(
                        child:
                            isLoading
                                ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                                : filteredLanguages.isEmpty
                                ? Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No languages found',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                )
                                : ListView.separated(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  shrinkWrap: true,
                                  itemCount: filteredLanguages.length,
                                  separatorBuilder:
                                      (context, index) =>
                                          const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final language = filteredLanguages[index];
                                    return LanguageListItem(
                                      language: language,
                                      isSelected:
                                          language.code == currentLanguage.code,
                                      onTap:
                                          () => _onLanguageSelected(language),
                                    );
                                  },
                                ),
                      ),

                      // Bottom padding
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Helper function to show the modal
Future<void> showLanguageSelectionModal(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.transparent,
    builder: (context) => const LanguageSelectionModal(),
  );
}
