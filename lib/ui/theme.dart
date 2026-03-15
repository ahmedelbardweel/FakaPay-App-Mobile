import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Faka Palette
  static const Color primaryYellow = Color(0xFF4B5563);
  static const Color accentOlive = Color(0xFF6B7280);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF4B5563);
  static const Color background = Color(0xFFFFFFFF);

  static const Color gray100 = Color(0xFFF9FAFB);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);

  static const Color danger = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);
  static const Color offlineAmber = Color(0xFF442E04);

  static const double glassBlurSigma = 18.0;
  static BoxDecoration glassDecoration({
    Color? color,
    double opacity = 0.1,
    double borderRadius = 8,
    double borderOpacity = 0.2,
  }) {
    return BoxDecoration(
      color: (color ?? white).withOpacity(opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: (color ?? white).withOpacity(borderOpacity),
        width: 0.8, // Thinner, more elegant border like iOS
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          spreadRadius: 2,
        ),
      ],
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primaryYellow,
        onPrimary: white,
        secondary: accentOlive,
        onSecondary: white,
        surface: white,
        error: danger,
      ),
      scaffoldBackgroundColor: background,

      // Inter is the closest to iPhone (SF Pro), Cairo for Arabic
      textTheme: GoogleFonts.interTextTheme().copyWith(
        headlineMedium: GoogleFonts.cairo(
          color: black,
          fontWeight: FontWeight.w900,
          fontSize: 16,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.cairo(
          color: black,
          fontWeight: FontWeight.w900,
          fontSize: 16,
          letterSpacing: -0.2,
        ),
        bodyLarge: GoogleFonts.inter(
          color: black,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
        bodyMedium: GoogleFonts.inter(
          color: black,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        labelLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w900,
          fontSize: 13,
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: white,
        foregroundColor: black,
        elevation: 0,
        centerTitle: true, 
        titleTextStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: black,
        ),
      ),

      cardTheme: ThemeData.light().cardTheme.copyWith(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(1)),
            ),
            elevation: 2,
            shadowColor: const Color(0x20000000),
            color: white,
            surfaceTintColor: Colors.transparent,
          ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryYellow,
          foregroundColor: white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(1),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(1),
          borderSide: const BorderSide(color: gray200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(1),
          borderSide: const BorderSide(color: gray200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(1),
          borderSide: const BorderSide(color: primaryYellow, width: 2),
        ),
        labelStyle: GoogleFonts.inter(color: gray600, fontSize: 13),
        hintStyle: GoogleFonts.inter(color: gray400, fontSize: 13),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(5),
            topRight: Radius.circular(5),
          ),
        ),
      ),

      drawerTheme: const DrawerThemeData(
        backgroundColor: white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(5),
            bottomRight: Radius.circular(5),
          ),
        ),
      ),
    );
  }
}
