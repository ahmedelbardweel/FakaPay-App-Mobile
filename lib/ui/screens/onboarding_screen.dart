import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import 'login_screen.dart';
import '../../utils/translations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      titleKey: 'welcome_title',
      descriptionKey: 'welcome_desc',
      icon: Icons.wallet_rounded,
      color: AppTheme.primaryYellow,
    ),
    OnboardingData(
      titleKey: 'send_money',
      descriptionKey: 'send_money_desc',
      icon: Icons.send_rounded,
      color: AppTheme.primaryYellow,
    ),
    OnboardingData(
      titleKey: 'offline_pay',
      descriptionKey: 'offline_tokens_desc',
      icon: Icons.security_rounded,
      color: AppTheme.primaryYellow,
    ),
  ];

  void _onFinished() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_onboarding', false);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              return OnboardingPage(data: _pages[index]);
            },
          ),
          Positioned(
            bottom: 30,
            left: 30,
            right: 30,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? AppTheme.primaryYellow
                            : AppTheme.gray200,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentPage == _pages.length - 1) {
                        _onFinished();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryYellow,
                      foregroundColor: AppTheme.black,
                      elevation: 0,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1
                          ? S.of(context, 'start_now')
                          : S.of(context, 'continue'),
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                if (_currentPage < _pages.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: TextButton(
                      onPressed: _onFinished,
                      child: Text(
                        S.of(context, 'skip'),
                        style: GoogleFonts.cairo(
                          color: AppTheme.gray400,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String titleKey;
  final String descriptionKey;
  final IconData icon;
  final Color color;

  OnboardingData({
    required this.titleKey,
    required this.descriptionKey,
    required this.icon,
    required this.color,
  });
}

class OnboardingPage extends StatelessWidget {
  final OnboardingData data;

  const OnboardingPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 100,
            width: 200,
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              data.icon,
              size: 100,
              color: data.color == AppTheme.black ? AppTheme.black : data.color,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            S.of(context, data.titleKey),
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppTheme.black,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            S.of(context, data.descriptionKey),
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: AppTheme.gray500,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
