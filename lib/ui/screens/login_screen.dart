import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../theme.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import '../../utils/device_utils.dart';
import '../widgets/pin_input_widget.dart';
import '../../utils/biometric_utils.dart';
import '../../utils/pin_utils.dart';
import '../../utils/translations.dart';
import 'scan_screen.dart';
import '../../providers/language_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final bool _isPasswordVisible = false;
  bool _biometricEnabled = false;
  bool _pinEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final bio = await BiometricUtils.isBiometricEnabled();
    final pin = await PinUtils.isPinEnabled();
    if (mounted) {
      setState(() {
        _biometricEnabled = bio;
        _pinEnabled = pin;
      });
    }
  }

  Future<void> _handleBiometricLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token == null) {
      _showError(S.of(context, 'login_pwd_first'));
      return;
    }

    final authenticated = await BiometricUtils.authenticate(
        S.of(context, 'biometric_login_reason'));
    if (authenticated && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  Future<void> _handlePinLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token == null) {
      _showError(S.of(context, 'login_pwd_first'));
      return;
    }
    // PIN Login handling
    final pin = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        String enteredPin = '';
        return AlertDialog(
          backgroundColor: AppTheme.white.withOpacity(0.8),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side:
                BorderSide(color: AppTheme.white.withOpacity(0.2), width: 1.5),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 10),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                S.of(context, 'pin_login'),
                style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.black,
                    letterSpacing: -0.2),
              ),
              const SizedBox(height: 4),
              Text(
                S.of(context, 'enter_pin_login_desc'),
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.gray500),
              ),
              const SizedBox(height: 24),
              PinInputWidget(
                onChanged: (v) => enteredPin = v,
                onCompleted: (v) {
                  enteredPin = v;
                  Navigator.pop(ctx, v);
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(S.of(context, 'cancel'),
                        style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: AppTheme.black,
                            fontWeight: FontWeight.bold)),
                  ),
                  TextButton(
                    onPressed: () {
                      if (enteredPin.length == 4) {
                        Navigator.pop(ctx, enteredPin);
                      }
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(S.of(context, 'confirm'),
                        style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: AppTheme.black,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (pin != null) {
      final isValid = await PinUtils.verifyPin(pin);
      if (isValid && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else if (mounted) {
        _showError(S.of(context, 'incorrect_pin'));
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: TextButton(
          onPressed: () {
            languageProvider.setLanguage(languageProvider.isArabic ? 'en' : 'ar');
          },
          child: Container(
            padding: const EdgeInsets.all(4),
            color: AppTheme.primaryYellow,
            child: Text(
              languageProvider.isArabic ? 'En' : 'Ar',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: AppTheme.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          // Aesthetic Background Blobs
          PositionedDirectional(
            top: -50,
            start: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryYellow.withOpacity(0.08),
              ),
            ),
          ),
          PositionedDirectional(
            bottom: 100,
            end: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentOlive.withOpacity(0.05),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      S.of(context, 'login'),
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.black,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Username Field
                  Text(
                    S.of(context, 'username'),
                    textAlign: TextAlign.start,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    textAlign: TextAlign.start,
                    decoration: InputDecoration(
                      hintText: S.of(context, 'enter_username'),
                      hintStyle: GoogleFonts.cairo(color: AppTheme.gray400),
                      filled: true,
                      fillColor: AppTheme.white,
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: () {},
                      child: Text(
                        S.of(context, 'forgot_username'),
                        style: GoogleFonts.cairo(
                          color: AppTheme.black,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 5),

                  // Password Field
                  Text(
                    S.of(context, 'password'),
                    textAlign: TextAlign.start,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    textAlign: TextAlign.start,
                    decoration: InputDecoration(
                      hintText: S.of(context, 'enter_password'),
                      hintStyle: GoogleFonts.cairo(color: AppTheme.gray400),
                      filled: true,
                      fillColor: AppTheme.white,
                    ),
                    obscureText: !_isPasswordVisible,
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: () {},
                      child: Text(
                        S.of(context, 'forgot_password_q'),
                        style: GoogleFonts.cairo(
                          color: AppTheme.black,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Login Button with Biometric shortcut
                  Row(
                    children: [
                      if (_biometricEnabled)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: GestureDetector(
                            onTap: _handleBiometricLogin,
                            child: Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryYellow,
                                borderRadius: BorderRadius.circular(1),
                              ),
                              child: const Icon(Icons.fingerprint,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      if (_pinEnabled)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: GestureDetector(
                            onTap: _handlePinLogin,
                            child: Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.black,
                                borderRadius: BorderRadius.circular(1),
                              ),
                              child: const Icon(Icons.dialpad,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            onPressed: authProvider.isLoading
                                ? null
                                : () => _handleLogin(authProvider),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryYellow,
                            ),
                            child: authProvider.isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : Text(
                                    S.of(context, 'login'),
                                    style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 13),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const RegisterScreen()),
                      ),
                      child: Text(
                        S.of(context, 'dont_have_account'),
                        style: GoogleFonts.cairo(
                          color: AppTheme.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Terms and Merchant Payment
                  Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          S.of(context, 'terms'),
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // QR Scanner Card with Glassmorphism
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(1),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                            sigmaX: AppTheme.glassBlurSigma,
                            sigmaY: AppTheme.glassBlurSigma),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const ScanScreen(isOffline: true)),
                            );
                          },
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: AppTheme.glassDecoration(
                              opacity: 0.2,
                              borderRadius: 1,
                              borderOpacity: 0.3,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.qr_code_scanner_rounded,
                                    size: 40, color: AppTheme.primaryYellow),
                                const SizedBox(height: 10),
                                Text(
                                  S.of(context, 'scan_qr'),
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin(AuthProvider authProvider) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError(S.of(context, 'enter_data'));
      return;
    }

    final deviceId = await DeviceUtils.getDeviceId();
    final success = await authProvider.login(email, password, deviceId);

    if (success && mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const HomeScreen()));
    } else if (mounted) {
      final error = authProvider.errorMessage ?? S.of(context, 'login_failed');
      _showError(error);
    }
  }

  void _showPendingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Row(
          children: [
            const Icon(Icons.pending_actions_rounded,
                color: AppTheme.offlineAmber),
            const SizedBox(width: 12),
            Text(
              S.of(context, 'account_pending'),
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.of(context, 'ok'),
                style: const TextStyle(
                    color: AppTheme.primaryYellow,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
