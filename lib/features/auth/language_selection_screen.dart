import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../services/language_service.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String? _selectedLanguage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();

    // Get current language as default selection
    final languageService =
        Provider.of<LanguageService>(context, listen: false);
    _selectedLanguage = languageService.currentLanguage;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectLanguage(String languageCode) async {
    if (_isLoading) return;

    setState(() {
      _selectedLanguage = languageCode;
      _isLoading = true;
    });

    try {
      final languageService =
          Provider.of<LanguageService>(context, listen: false);
      await languageService.changeLanguage(languageCode);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              languageCode == 'ta'
                  ? 'மொழி வெற்றிகரமாக மாற்றப்பட்டது'
                  : 'Language changed successfully',
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate to role selection after a short delay
        await Future.delayed(const Duration(milliseconds: 1500));

        if (mounted) {
          context.go(AppRoutes.roleSelect);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4CAF50),
              Color(0xFF2E7D32),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo and Title
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.language,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // App Name
                    const Text(
                      'FieldFresh',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Tagline
                    Text(
                      _selectedLanguage == 'ta'
                          ? 'விவசாயத்திலிருந்து வாடிக்கையாளர் வரை நேரடியாக'
                          : 'Farm to Customer Direct',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w300,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // Language Selection Title
                    Text(
                      _selectedLanguage == 'ta'
                          ? 'உங்கள் விருப்பமான மொழியைத் தேர்வு செய்யவும்'
                          : 'Choose your preferred language',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Language Options
                    Column(
                      children: [
                        _LanguageOption(
                          languageCode: 'en',
                          languageName: 'English',
                          nativeName: 'English',
                          flag: '🇺🇸',
                          isSelected: _selectedLanguage == 'en',
                          onTap: () => _selectLanguage('en'),
                          isLoading: _isLoading && _selectedLanguage == 'en',
                        ),
                        const SizedBox(height: 16),
                        _LanguageOption(
                          languageCode: 'ta',
                          languageName: 'Tamil',
                          nativeName: 'தமிழ்',
                          flag: '🇮🇳',
                          isSelected: _selectedLanguage == 'ta',
                          onTap: () => _selectLanguage('ta'),
                          isLoading: _isLoading && _selectedLanguage == 'ta',
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),

                    // Info Text
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.white.withValues(alpha: 0.8),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedLanguage == 'ta'
                                  ? 'நீங்கள் எப்போது வேண்டுமானாலும் அமைப்புகளில் மொழியை மாற்றலாம்'
                                  : 'You can change the language anytime in settings',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String languageCode;
  final String languageName;
  final String nativeName;
  final String flag;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isLoading;

  const _LanguageOption({
    required this.languageCode,
    required this.languageName,
    required this.nativeName,
    required this.flag,
    required this.isSelected,
    required this.onTap,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Flag
                Text(
                  flag,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 16),

                // Language Names
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nativeName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.primary : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        languageName,
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected
                              ? AppColors.textSecondary
                              : Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                // Loading or Check Icon
                if (isLoading)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isSelected ? AppColors.primary : Colors.white,
                      ),
                    ),
                  )
                else if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 28,
                  )
                else
                  Icon(
                    Icons.radio_button_unchecked,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 28,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
