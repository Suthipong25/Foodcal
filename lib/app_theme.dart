import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color secondaryColor = Color(0xFF16A34A);
  static const Color accentColor = Color(0xFFFF5A7A);
  static const Color ink = Color(0xFF111318);
  static const Color mutedText = Color(0xFF667085);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color pageBg = Color(0xFFF7F8FB);
  static const Color pageTint = Color(0xFFF1F5F9);
  static const Color pageTintStrong = Color(0xFFE8EEF8);

  static const Color proteinColor = Color(0xFF16A34A);
  static const Color carbsColor = Color(0xFFFFB020);
  static const Color fatColor = Color(0xFF7C3AED);
  static const Color waterColor = Color(0xFF0284C7);
  static const Color calorieColor = Color(0xFFFF5A7A);

  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFFFB020);
  static const Color error = Color(0xFFE23B52);
  static const Color aiColor = Color(0xFF7C3AED);
  static const Color aiBgColor = Color(0xFFF2EDFF);
  static const Color cardBorder = Color(0xFFE2E8F0);

  static const Color warmPeach = Color(0xFFFFD8C7);
  static const Color warmMint = Color(0xFFDDF8EA);
  static const Color leafGreen = Color(0xFF12B886);
  static const Color leafDark = Color(0xFF087F5B);
  static const Color coralLight = Color(0xFFFFB6C5);
  static const Color warmOrange = Color(0xFFFF922B);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF38BDF8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFF5A7A), Color(0xFFFFB020)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient aiGradient = LinearGradient(
    colors: [Color(0xFF7C4DFF), Color(0xFF0BA7D7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient calorieRingGradient = LinearGradient(
    colors: [Color(0xFF2555FF), Color(0xFF12B886), Color(0xFFFFB020)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFEFF6FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient glassGradient({double opacity = 0.1}) {
    return LinearGradient(
      colors: [
        Colors.white.withValues(alpha: 0.98),
        const Color(0xFFF8FAFC).withValues(alpha: 0.96),
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
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.96),
      borderRadius: borderRadius ?? cardRadius,
      border: Border.all(color: borderColor ?? cardBorder),
    );
  }

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(8));
  static const BorderRadius innerRadius = BorderRadius.all(Radius.circular(8));
  static const BorderRadius pillRadius = BorderRadius.all(Radius.circular(999));

  static const double pagePadding = 16;
  static const double sectionGap = 16;
  static const double cardPadding = 18;
  static const double largeTitle = 30;
  static const double title = 18;
  static const double body = 14;
  static const double meta = 11;
  static const double buttonHeight = 54;

  static bool isCompactWidth(double width) => width < 380;

  static bool isTabletWidth(double width) => width >= 700;

  static double horizontalPaddingForWidth(double width) {
    if (width < 360) return 12;
    if (width < 700) return 16;
    return 28;
  }

  static double cardPaddingForWidth(double width) {
    if (width < 360) return 14;
    if (width < 700) return 18;
    return 22;
  }

  static double maxContentWidth(double width) {
    if (width < 700) return width;
    if (width < 1100) return 720;
    return 860;
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
  static Color macroBorder(Color source) => source.withValues(alpha: 0.2);

  static List<BoxShadow> softShadow(Color color) => [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.08),
          blurRadius: 22,
          spreadRadius: -10,
          offset: const Offset(0, 16),
        ),
      ];

  static BoxDecoration elevatedCard({
    Color color = surface,
    Color borderColor = cardBorder,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: cardRadius,
      border: Border.all(color: borderColor),
      boxShadow: boxShadow ?? softShadow(ink),
    );
  }

  static BoxDecoration tintedCard(Color tint) {
    return BoxDecoration(
      color: surface,
      borderRadius: cardRadius,
      border: Border.all(color: tint.withValues(alpha: 0.22)),
      boxShadow: softShadow(tint),
    );
  }

  static BoxDecoration subtleCard({
    Color background = surface,
    Color borderColor = cardBorder,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      color: background,
      borderRadius: cardRadius,
      border: Border.all(color: borderColor),
      boxShadow: boxShadow ?? softShadow(ink),
    );
  }

  static BoxDecoration iconBubble(Color color, {double opacity = 0.12}) {
    return BoxDecoration(
      color: color.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(8),
    );
  }

  static LinearGradient pageBackground() {
    return const LinearGradient(
      colors: [
        Color(0xFFF7F8FB),
        Color(0xFFFFFFFF),
        Color(0xFFF2F6FF),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  static ThemeData themeData() {
    final baseTextTheme = GoogleFonts.ibmPlexSansThaiLoopedTextTheme();
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
        headlineLarge: GoogleFonts.ibmPlexSansThaiLooped(
          fontSize: 30,
          fontWeight: FontWeight.w900,
          color: ink,
          height: 1.12,
          letterSpacing: 0,
        ),
        headlineMedium: GoogleFonts.ibmPlexSansThaiLooped(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          color: ink,
          height: 1.16,
          letterSpacing: 0,
        ),
        titleLarge: GoogleFonts.ibmPlexSansThaiLooped(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: ink,
          letterSpacing: 0,
        ),
        titleMedium: GoogleFonts.ibmPlexSansThaiLooped(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: ink,
          letterSpacing: 0,
        ),
        bodyLarge: GoogleFonts.ibmPlexSansThaiLooped(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: ink,
          height: 1.45,
          letterSpacing: 0,
        ),
        bodyMedium: GoogleFonts.ibmPlexSansThaiLooped(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: ink,
          height: 1.45,
          letterSpacing: 0,
        ),
        bodySmall: GoogleFonts.ibmPlexSansThaiLooped(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: mutedText,
          height: 1.4,
          letterSpacing: 0,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: pageBg,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: ink),
        titleTextStyle: GoogleFonts.ibmPlexSansThaiLooped(
          color: ink,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
      cardTheme: const CardThemeData(
        color: surface,
        elevation: 0.0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: cardRadius,
          side: BorderSide(color: cardBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: GoogleFonts.ibmPlexSansThaiLooped(
          color: mutedText.withValues(alpha: 0.82),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: const OutlineInputBorder(
          borderRadius: innerRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: innerRadius,
          borderSide: BorderSide(color: cardBorder),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: innerRadius,
          borderSide: BorderSide(color: primaryColor, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(buttonHeight),
          shape: const RoundedRectangleBorder(borderRadius: innerRadius),
          textStyle: GoogleFonts.ibmPlexSansThaiLooped(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: const BorderSide(color: cardBorder),
          shape: const RoundedRectangleBorder(borderRadius: innerRadius),
          textStyle: GoogleFonts.ibmPlexSansThaiLooped(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: const RoundedRectangleBorder(borderRadius: innerRadius),
          textStyle: GoogleFonts.ibmPlexSansThaiLooped(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: pageTint,
        selectedColor: primaryColor,
        secondarySelectedColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        labelStyle: GoogleFonts.ibmPlexSansThaiLooped(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: ink,
          letterSpacing: 0,
        ),
        secondaryLabelStyle: GoogleFonts.ibmPlexSansThaiLooped(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0,
        ),
        side: const BorderSide(color: cardBorder),
        shape: const StadiumBorder(),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle: GoogleFonts.ibmPlexSansThaiLooped(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerColor: cardBorder,
      splashColor: primaryColor.withValues(alpha: 0.06),
      highlightColor: primaryColor.withValues(alpha: 0.03),
    );
  }
}
