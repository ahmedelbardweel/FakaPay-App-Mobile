import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import '../../utils/translations.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../../utils/notification_service.dart';
import 'language_selection_screen.dart';

class PermissionsOnboardingScreen extends StatefulWidget {
  const PermissionsOnboardingScreen({super.key});

  @override
  State<PermissionsOnboardingScreen> createState() => _PermissionsOnboardingScreenState();
}

class _PermissionsOnboardingScreenState extends State<PermissionsOnboardingScreen> {
  bool _isRequesting = false;

  Future<void> _requestAllPermissions() async {
    setState(() => _isRequesting = true);

    // Request system permissions via permission_handler
    final List<Permission> permissions = [Permission.camera];

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        // Android 13+ uses individual permissions for media
        permissions.add(Permission.photos);
      } else {
        // Older versions use general storage
        permissions.add(Permission.storage);
      }
    } else {
      // iOS
      permissions.add(Permission.photos);
    }

    await permissions.request();

    // Specially handle notifications via our service wrapper
    await NotificationService().requestPermission();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('permissions_onboarding_done', true);

    if (!mounted) return;

    // Navigate to language selection
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LanguageSelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Background Blobs for premium feel
          PositionedDirectional(
            top: -100,
            end: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryYellow.withOpacity(0.08),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  // Icon & Header
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryYellow.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.security_rounded,
                        size: 48,
                        color: AppTheme.primaryYellow,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    S.of(context, 'permissions_title'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    S.of(context, 'permissions_desc'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: AppTheme.gray500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Permission Items
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildPermissionItem(
                          icon: Icons.camera_alt_rounded,
                          title: S.of(context, 'permission_camera'),
                          desc: S.of(context, 'permission_camera_desc'),
                        ),
                        const SizedBox(height: 16),
                        _buildPermissionItem(
                          icon: Icons.notifications_active_rounded,
                          title: S.of(context, 'permission_notifications'),
                          desc: S.of(context, 'permission_notifications_desc'),
                        ),
                        const SizedBox(height: 16),
                        _buildPermissionItem(
                          icon: Icons.fingerprint_rounded,
                          title: S.of(context, 'permission_biometrics'),
                          desc: S.of(context, 'permission_biometrics_desc'),
                        ),
                        const SizedBox(height: 16),
                        _buildPermissionItem(
                          icon: Icons.photo_library_rounded,
                          title: S.of(context, 'permission_storage'),
                          desc: S.of(context, 'permission_storage_desc'),
                        ),
                      ],
                    ),
                  ),
                  // Action Button
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isRequesting ? null : _requestAllPermissions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryYellow,
                          foregroundColor: AppTheme.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isRequesting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                S.of(context, 'grant_permissions'),
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primaryYellow.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryYellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primaryYellow, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.black,
                      ),
                    ),
                    Text(
                      desc,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: AppTheme.gray500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
