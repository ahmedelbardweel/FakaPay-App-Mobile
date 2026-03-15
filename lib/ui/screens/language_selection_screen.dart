import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import '../../providers/language_provider.dart';
import '../../utils/translations.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String _selectedLang = 'ar';

  @override
  void initState() {
    super.initState();
    _loadCurrentLang();
  }

  Future<void> _loadCurrentLang() async {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    setState(() {
      _selectedLang = languageProvider.locale.languageCode;
    });
  }

  Future<void> _onContinue() async {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    await languageProvider.setLanguage(_selectedLang);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('language_selected', true);
    final bool showOnboarding = prefs.getBool('show_onboarding') ?? true;

    if (!mounted) return;

    if (showOnboarding) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.translate_rounded,
                      color: AppTheme.black, size: 20),
                  Text(
                    '',
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.black,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 10), // Spacer
                ],
              ),
              const Spacer(),
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryYellow.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.language_rounded,
                  size: 40,
                  color: AppTheme.primaryYellow,
                ),
              ),
              const SizedBox(height: 15),
              // Title
              Text(
                S.of(context, 'choose_language'),
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryYellow,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                S.of(context, 'choose_language_subtitle'),
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.gray400,
                ),
              ),
              const SizedBox(height: 10),
              // Options
              _LanguageCard(
                title: 'العربية',
                subtitle: 'Arabic',
                isSelected: _selectedLang == 'ar',
                onTap: () => setState(() => _selectedLang = 'ar'),
              ),
              const SizedBox(height: 10),
              _LanguageCard(
                title: 'English',
                subtitle: 'إنجليزي',
                isSelected: _selectedLang == 'en',
                onTap: () => setState(() => _selectedLang = 'en'),
              ),
              const Spacer(),
              // Footer Button
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  onPressed: _onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryYellow,
                    foregroundColor: AppTheme.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        S.of(context, 'next'),
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 15),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: AppTheme.gray600,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryYellow.withOpacity(0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(1),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryYellow
                : AppTheme.gray600.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 20,
              width: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.primaryYellow : AppTheme.gray400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Center(
                      child: CircleAvatar(
                        radius: 1,
                        backgroundColor: AppTheme.primaryYellow,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.black,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.gray500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
