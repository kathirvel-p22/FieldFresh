import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../services/language_service.dart';
import '../../generated/l10n.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  bool _isChanging = false;

  Future<void> _changeLanguage(String languageCode) async {
    if (_isChanging) return;

    setState(() => _isChanging = true);

    try {
      final languageService =
          Provider.of<LanguageService>(context, listen: false);
      await languageService.changeLanguage(languageCode);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context)?.languageChanged ?? 'Language changed successfully'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isChanging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context)?.selectLanguage ?? 'Select Language'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<LanguageService>(
        builder: (context, languageService, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.language,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              S.of(context)?.selectLanguage ?? 'Select Language',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              S.of(context)?.chooseLanguage ?? 'Choose your preferred language',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Current Language Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          languageService.isTamil
                              ? 'தற்போதைய மொழி: ${languageService.getLanguageName(languageService.currentLanguage)}'
                              : 'Current Language: ${languageService.getLanguageDisplayName(languageService.currentLanguage)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Language Options
                Text(
                  languageService.isTamil
                      ? 'கிடைக்கும் மொழிகள்'
                      : 'Available Languages',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // English Option
                _LanguageCard(
                  languageCode: 'en',
                  languageName: 'English',
                  nativeName: 'English',
                  flag: '🇺🇸',
                  description: 'International language',
                  isSelected: languageService.currentLanguage == 'en',
                  isLoading:
                      _isChanging && languageService.currentLanguage != 'en',
                  onTap: () => _changeLanguage('en'),
                ),
                const SizedBox(height: 12),

                // Tamil Option
                _LanguageCard(
                  languageCode: 'ta',
                  languageName: 'Tamil',
                  nativeName: 'தமிழ்',
                  flag: '🇮🇳',
                  description: languageService.isTamil
                      ? 'தாய்மொழி'
                      : 'Native language for farmers',
                  isSelected: languageService.currentLanguage == 'ta',
                  isLoading:
                      _isChanging && languageService.currentLanguage != 'ta',
                  onTap: () => _changeLanguage('ta'),
                ),

                const Spacer(),

                // Footer Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.tips_and_updates_outlined,
                        color: AppColors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          languageService.isTamil
                              ? 'மொழி மாற்றம் உடனடியாக பயன்படுத்தப்படும். ஆப்பை மீண்டும் தொடங்க வேண்டியதில்லை.'
                              : 'Language changes take effect immediately. No need to restart the app.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final String languageCode;
  final String languageName;
  final String nativeName;
  final String flag;
  final String description;
  final bool isSelected;
  final bool isLoading;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.languageCode,
    required this.languageName,
    required this.nativeName,
    required this.flag,
    required this.description,
    required this.isSelected,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading || isSelected ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Flag
              Text(
                flag,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 16),

              // Language Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nativeName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      languageName,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),

              // Status Icon
              if (isLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                )
              else if (isSelected)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                )
              else
                Icon(
                  Icons.radio_button_unchecked,
                  color: Colors.grey.shade400,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
