import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../../utils/translations.dart';

class SuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onConfirm;
  final Color? titleColor;

  const SuccessDialog({
    super.key,
    this.title = "تم بنجاح!",
    required this.message,
    required this.onConfirm,
    this.titleColor,
  });

  static void show(BuildContext context,
      {String? title,
      required String message,
      required VoidCallback onConfirm,
      Color? titleColor}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SuccessDialog(
        title: title ?? S.of(context, "success"),
        message: message,
        onConfirm: onConfirm,
        titleColor: titleColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: AppTheme.glassBlurSigma, sigmaY: AppTheme.glassBlurSigma),
      child: AlertDialog(
        backgroundColor: AppTheme.white.withOpacity(0.2),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), // Even rounder for iOS feel
          side: BorderSide(color: AppTheme.white.withOpacity(0.3), width: 0.8),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        title: Text(
          title,
          style: GoogleFonts.cairo(
            color: titleColor ?? AppTheme.black,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: -0.2,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: GoogleFonts.inter(
                color: AppTheme.gray600,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onConfirm();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryYellow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  S.of(context, 'ok'),
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
