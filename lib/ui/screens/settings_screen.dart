import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import '../widgets/pin_input_widget.dart';
import '../../utils/biometric_utils.dart';
import '../../utils/pin_utils.dart';
import '../../utils/device_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../utils/translations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
    setState(() {
      _biometricEnabled = bio;
      _pinEnabled = pin;
    });
  }

  Future<bool> _verifyPassword() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('auth_email');
    if (email == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context, 'relogin_required'))),
        );
      }
      return false;
    }

    final passwordController = TextEditingController();
    bool isVisible = false;
    bool isLoading = false;

    final String? password = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.white,
              surfaceTintColor: Colors.transparent,
              shape:
                  const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              insetPadding: const EdgeInsets.symmetric(horizontal: 10),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    S.of(context, 'confirm_password'),
                    style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.black,
                        letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    S.of(context, 'enter_password_to_change'),
                    style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: AppTheme.gray500,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: passwordController,
                    obscureText: !isVisible,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: S.of(context, 'password'),
                      prefixIcon: const Icon(Icons.lock_outline_rounded,
                          size: 18, color: AppTheme.gray400),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isVisible ? Icons.visibility : Icons.visibility_off,
                          size: 18,
                          color: AppTheme.gray400,
                        ),
                        onPressed: () =>
                            setDialogState(() => isVisible = !isVisible),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: isLoading ? null : () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(S.of(context, 'cancel'),
                            style: GoogleFonts.cairo(
                                fontSize: 14,
                                color: AppTheme.black,
                                fontWeight: FontWeight.bold)),
                      ),
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                if (passwordController.text.isEmpty) return;
                                setDialogState(() => isLoading = true);
                                final deviceId =
                                    await DeviceUtils.getDeviceId();
                                final authProvider = Provider.of<AuthProvider>(
                                    context,
                                    listen: false);
                                final success = await authProvider.login(
                                    email, passwordController.text, deviceId);

                                if (success) {
                                  Navigator.pop(ctx, passwordController.text);
                                } else {
                                  setDialogState(() => isLoading = false);
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              authProvider.errorMessage ??
                                                  S.of(context, 'password_incorrect')),
                                          backgroundColor: AppTheme.danger,
                                          behavior: SnackBarBehavior.floating));
                                }
                              },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppTheme.white))
                            : Text(S.of(context, 'confirm'),
                                style: GoogleFonts.cairo(
                                    fontSize: 14,
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
      },
    );

    return password != null;
  }

  Future<void> _handleBiometricToggle(bool value) async {
    if (value) {
      final isAvailable = await BiometricUtils.isBiometricAvailable();
      if (!isAvailable) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(S.of(context, 'biometric_not_available'))));
        }
        return;
      }
      final verified = await _verifyPassword();
      if (!verified) return;

      final authenticated =
          await BiometricUtils.authenticate(S.of(context, 'biometric_login'));
      if (authenticated) {
        await BiometricUtils.setBiometricEnabled(true);
        setState(() => _biometricEnabled = true);
      }
    } else {
      final verified = await _verifyPassword();
      if (!verified) return;

      await BiometricUtils.setBiometricEnabled(false);
      setState(() => _biometricEnabled = false);
    }
  }

  Future<void> _handlePinToggle(bool value) async {
    if (value) {
      final verified = await _verifyPassword();
      if (!verified) return;

      final pin = await _showPinSetupDialog();
      if (pin != null && pin.length == 4) {
        await PinUtils.setPin(pin);
        setState(() => _pinEnabled = true);
      }
    } else {
      final verified = await _verifyPassword();
      if (!verified) return;

      await PinUtils.disablePin();
      setState(() => _pinEnabled = false);
    }
  }

  Future<String?> _showPinSetupDialog() async {
    String enteredPin = '';
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.white,
          surfaceTintColor: Colors.transparent,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          insetPadding: const EdgeInsets.symmetric(horizontal: 10),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                S.of(context, 'setup_pin'),
                style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.black,
                    letterSpacing: -0.5),
              ),
              const SizedBox(height: 4),
              Text(
                S.of(context, 'enter_4_digit_pin'),
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppTheme.gray500,
                    fontWeight: FontWeight.w600),
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
                            fontSize: 14,
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
                    child: Text(S.of(context, 'save'),
                        style: GoogleFonts.cairo(
                            fontSize: 14,
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          S.of(context, 'settings'),
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            _buildSectionHeader(S.of(context, 'quick_access_settings')),
            _buildSecurityCard(
              S.of(context, 'biometric_login'),
              S.of(context, 'quick_login_subtitle'),
              Icons.fingerprint_rounded,
              _biometricEnabled,
              _handleBiometricToggle,
            ),
            const SizedBox(height: 12),
            _buildSecurityCard(
              S.of(context, 'pin_login'),
              S.of(context, 'pin_login_subtitle'),
              Icons.password_rounded,
              _pinEnabled,
              _handlePinToggle,
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(S.of(context, 'general')),
            Consumer<LanguageProvider>(
              builder: (context, langProvider, child) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.gray100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.language_rounded, color: AppTheme.black, size: 22),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          S.of(context, 'language'),
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.black,
                          ),
                        ),
                      ),
                      DropdownButton<String>(
                        value: langProvider.locale.languageCode,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.black),
                        style: GoogleFonts.cairo(
                          color: AppTheme.black,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'ar',
                            child: Text('العربية'),
                          ),
                          DropdownMenuItem(
                            value: 'en',
                            child: Text('English'),
                          ),
                        ],
                        onChanged: (String? value) {
                          if (value != null) {
                            langProvider.setLanguage(value);
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: AppTheme.gray500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSecurityCard(String title, String subtitle, IconData icon,
      bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.gray100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.black, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.black,
                    height: 1.2,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.cairo(
                    color: AppTheme.gray500,
                    fontSize: 11,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppTheme.white,
              activeTrackColor: AppTheme.primaryYellow,
              inactiveThumbColor: AppTheme.white,
              inactiveTrackColor: AppTheme.gray200,
            ),
          ),
        ],
      ),
    );
  }
}
