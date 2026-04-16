import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF1F6FEB);
  static const Color secondaryColor = Color(0xFF6CB8FF);
  static const Color accentColor = Color(0xFF9AD7FF);
  static const Color ink = Color(0xFF10233F);
  static const Color mutedText = Color(0xFF6D7B91);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color pageBg = Color(0xFFF8FAFC);
  static const Color pageTint = Color(0xFFF4F8FF);
  static const Color pageTintStrong = Color(0xFFEAF3FF);

  static const Color proteinColor = Color(0xFF2F80ED);
  static const Color carbsColor = Color(0xFF3BA7FF);
  static const Color fatColor = Color(0xFF5B6CFF);
  static const Color waterColor = Color(0xFF1DB4FF);
  static const Color calorieColor = Color(0xFF1F6FEB);

  static const Color success = Color(0xFF14AE5C);
  static const Color warning = Color(0xFFFFA62B);
  static const Color error = Color(0xFFFF5A67);

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(32));
  static const BorderRadius innerRadius = BorderRadius.all(Radius.circular(22));
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

  static Color macroBg(Color source) => source.withOpacity(0.1);
  static Color macroBorder(Color source) => source.withOpacity(0.16);

  static List<BoxShadow> softShadow(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.08),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: color.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
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
          tint.withOpacity(0.14),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: cardRadius,
      border: Border.all(color: tint.withOpacity(0.18)),
      boxShadow: softShadow(tint),
    );
  }

  static LinearGradient pageBackground() {
    return const LinearGradient(
      colors: [
        Color(0xFFF9FBFF),
        Color(0xFFF0F6FF),
        Color(0xFFE8F2FF),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  static ThemeData themeData() {
    final baseTextTheme = GoogleFonts.notoSansThaiTextTheme();
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
        headlineLarge: GoogleFonts.notoSansThai(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: ink,
          height: 1.1,
        ),
        headlineMedium: GoogleFonts.notoSansThai(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: ink,
          height: 1.15,
        ),
        titleLarge: GoogleFonts.notoSansThai(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        titleMedium: GoogleFonts.notoSansThai(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        bodyLarge: GoogleFonts.notoSansThai(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: ink,
          height: 1.45,
        ),
        bodyMedium: GoogleFonts.notoSansThai(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: ink,
          height: 1.45,
        ),
        bodySmall: GoogleFonts.notoSansThai(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: mutedText,
          height: 1.4,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white.withOpacity(0.92),
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: primaryColor),
        titleTextStyle: GoogleFonts.notoSansThai(
          color: ink,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: const CardTheme(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: cardRadius,
          side: BorderSide(color: Color(0xFFE4EEFB)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: pageTint,
        hintStyle: GoogleFonts.notoSansThai(
          color: mutedText.withOpacity(0.9),
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
        enabledBorder: OutlineInputBorder(
          borderRadius: innerRadius,
          borderSide: BorderSide(color: primaryColor.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: innerRadius,
          borderSide: BorderSide(color: primaryColor.withOpacity(0.24)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(buttonHeight),
          shape: const RoundedRectangleBorder(borderRadius: innerRadius),
          textStyle: GoogleFonts.notoSansThai(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor.withOpacity(0.16)),
          shape: const RoundedRectangleBorder(borderRadius: innerRadius),
          textStyle: GoogleFonts.notoSansThai(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: const RoundedRectangleBorder(borderRadius: innerRadius),
          textStyle: GoogleFonts.notoSansThai(
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
        labelStyle: GoogleFonts.notoSansThai(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        secondaryLabelStyle: GoogleFonts.notoSansThai(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        side: BorderSide(color: primaryColor.withOpacity(0.1)),
        shape: const StadiumBorder(),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle: GoogleFonts.notoSansThai(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dividerColor: const Color(0xFFE6EEF9),
      splashColor: primaryColor.withOpacity(0.06),
      highlightColor: primaryColor.withOpacity(0.03),
    );
  }
}
