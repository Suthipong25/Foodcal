import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF1F6FEB);
  static const Color secondaryColor = Color(0xFF6CB8FF);
  static const Color accentColor = Color(0xFF9AD7FF);
  static const Color ink = Color(0xFF10233F);
  static const Color mutedText = Color(0xFF6D7B91);
  static const Color surface = Color(0xFFFFFFFF);
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
}
