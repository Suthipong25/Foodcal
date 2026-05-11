import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF58A6FF);
  static const Color secondaryColor = Color(0xFF86C5FF);
  static const Color accentColor = Color(0xFFB7E1FF);
  static const Color ink = Color(0xFF24324A);
  static const Color mutedText = Color(0xFF72819A);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color pageBg = Color(0xFFFFFCFF);
  static const Color pageTint = Color(0xFFF8FBFF);
  static const Color pageTintStrong = Color(0xFFEEF7FF);

  static const Color proteinColor = Color(0xFF2F80ED);
  static const Color carbsColor = Color(0xFF3BA7FF);
  static const Color fatColor = Color(0xFF5B6CFF);
  static const Color waterColor = Color(0xFF1DB4FF);
  static const Color calorieColor = Color(0xFF1F6FEB);

  static const Color success = Color(0xFF39B980);
  static const Color warning = Color(0xFFFFB84D);
  static const Color error = Color(0xFFFF6F7D);
  static const Color aiColor = Color(0xFF8B73FF);
  static const Color aiBgColor = Color(0xFFF4F0FF);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF63B2FF), Color(0xFF8FD2FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF9DD8FF), Color(0xFFCDEBFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient aiGradient = LinearGradient(
    colors: [Color(0xFFA58CFF), aiColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient glassGradient({double opacity = 0.1}) {
    final int alpha = (opacity * 255).toInt();
    final int heavyAlpha = (opacity * 1.5 * 255).toInt().clamp(0, 255);
    return LinearGradient(
      colors: [
        Color.fromARGB(heavyAlpha, 255, 255, 255),
        Color.fromARGB(alpha, 255, 255, 255),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static BoxDecoration glassDecoration({
    double blur = 12.0,
    double opacity = 0.1,
    BorderRadius? borderRadius,
    Color? borderColor,
  }) {
    final int alpha = (opacity * 255).toInt();
    return BoxDecoration(
      color: Color.fromARGB(alpha, 255, 255, 255),
      borderRadius: borderRadius ?? cardRadius,
      border: Border.all(
        color: borderColor ?? const Color(0x3DFFFFFF), // 0.24 opacity
        width: 1.5,
      ),
    );
  }

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(20));
  static const BorderRadius innerRadius = BorderRadius.all(Radius.circular(16));
  static const BorderRadius pillRadius = BorderRadius.all(Radius.circular(999));

  static const double pagePadding = 16;
  static const double sectionGap = 18;
  static const double cardPadding = 20;
  static const double largeTitle = 28;
  static const double title = 18;
  static const double body = 14;
  static const double meta = 11;
  static const double buttonHeight = 56;

  static bool isCompactWidth(double width) => width < 380;

  static bool isTabletWidth(double width) => width >= 700;

  static double horizontalPaddingForWidth(double width) {
    if (width < 360) return 14;
    if (width < 700) return 16;
    return 24;
  }

  static double cardPaddingForWidth(double width) {
    if (width < 360) return 16;
    if (width < 700) return 20;
    return 24;
  }

  static double maxContentWidth(double width) {
    if (width < 700) return width;
    if (width < 1100) return 640;
    return 720;
  }

  static EdgeInsets pageInsetsForWidth(
    double width, {
    double top = pagePadding,
    double bottom = pagePadding,
  }) {
    final horizontal = horizontalPaddingForWidth(width);
    return EdgeInsets.fromLTRB(horizontal, top, horizontal, bottom);
  }

  static Color macroBg(Color source) => source.withValues(alpha: 0.1);
  static Color macroBorder(Color source) => source.withValues(alpha: 0.16);

  static List<BoxShadow> softShadow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static BoxDecoration elevatedCard({
    Color color = surface,
    Color borderColor = const Color(0xFFE4EEFB),
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: cardRadius,
      border: Border.all(color: borderColor),
      boxShadow: boxShadow ?? softShadow(primaryColor),
    );
  }

  static BoxDecoration tintedCard(Color tint) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.white,
          tint.withValues(alpha: 0.14),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: cardRadius,
      border: Border.all(color: tint.withValues(alpha: 0.18)),
      boxShadow: softShadow(tint),
    );
  }

  static BoxDecoration subtleCard({
    Color background = Colors.white,
    Color borderColor = const Color(0xFFE7EDF4),
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      color: background,
      borderRadius: cardRadius,
      border: Border.all(color: borderColor),
      boxShadow: boxShadow ?? softShadow(primaryColor),
    );
  }

  static BoxDecoration iconBubble(Color color, {double opacity = 0.12}) {
    return BoxDecoration(
      color: color.withValues(alpha: opacity),
      shape: BoxShape.circle,
    );
  }

  static LinearGradient pageBackground() {
    return const LinearGradient(
        colors: [
          Color(0xFFF8FBFF),
          Color(0xFFF2F7FE),
          Color(0xFFECF3FC),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
    );
  }

  static ThemeData themeData() {
    final baseTextTheme = GoogleFonts.baiJamjureeTextTheme();
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surface,
      error: error,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: pageBg,
      textTheme: baseTextTheme.copyWith(
        headlineLarge: GoogleFonts.baiJamjuree(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: ink,
          height: 1.1,
        ),
        headlineMedium: GoogleFonts.baiJamjuree(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: ink,
          height: 1.15,
        ),
        titleLarge: GoogleFonts.baiJamjuree(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        titleMedium: GoogleFonts.baiJamjuree(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        bodyLarge: GoogleFonts.baiJamjuree(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: ink,
          height: 1.45,
        ),
        bodyMedium: GoogleFonts.baiJamjuree(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: ink,
          height: 1.45,
        ),
        bodySmall: GoogleFonts.baiJamjuree(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: mutedText,
          height: 1.4,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: primaryColor),
        titleTextStyle: GoogleFonts.baiJamjuree(
          color: ink,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: const CardThemeData(
        color: surface,
        elevation: 0.0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: cardRadius,
          side: BorderSide(color: Color(0xFFE4EEFB)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: GoogleFonts.baiJamjuree(
          color: mutedText.withValues(alpha: 0.9),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: const OutlineInputBorder(
          borderRadius: innerRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: innerRadius,
          borderSide: BorderSide(color: Color(0xFFE3EAF2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: innerRadius,
          borderSide: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(buttonHeight),
          shape: const RoundedRectangleBorder(borderRadius: innerRadius),
          textStyle: GoogleFonts.baiJamjuree(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor.withValues(alpha: 0.16)),
          shape: const RoundedRectangleBorder(borderRadius: innerRadius),
          textStyle: GoogleFonts.baiJamjuree(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: const RoundedRectangleBorder(borderRadius: innerRadius),
          textStyle: GoogleFonts.baiJamjuree(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: pageTintStrong,
        selectedColor: primaryColor,
        secondarySelectedColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        labelStyle: GoogleFonts.baiJamjuree(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        secondaryLabelStyle: GoogleFonts.baiJamjuree(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        side: BorderSide(color: primaryColor.withValues(alpha: 0.1)),
        shape: const StadiumBorder(),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle: GoogleFonts.baiJamjuree(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dividerColor: const Color(0xFFE6EEF9),
      splashColor: primaryColor.withValues(alpha: 0.06),
      highlightColor: primaryColor.withValues(alpha: 0.03),
    );
  }
}
