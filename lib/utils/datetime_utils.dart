// Utilities for handling dates and times consistently across the app.
// Centralizes timezone handling to prevent bugs from scattered UTC/local conversion.
import 'package:intl/intl.dart';
import '../constants/app_config.dart';

class DateTimeUtils {
  /// Get current Bangkok time
  static DateTime now() {
    return DateTime.now();
  }

  /// Get current Bangkok date in YYYY-MM-DD format
  static String todayKey() {
    return dateKey(now());
  }

  /// Convert DateTime to date string key (YYYY-MM-DD)
  /// Always uses Bangkok timezone
  static String dateKey(DateTime date) {
    final localDate = date.toLocal();
    return '${localDate.year.toString().padLeft(4, '0')}'
        '-${localDate.month.toString().padLeft(2, '0')}'
        '-${localDate.day.toString().padLeft(2, '0')}';
  }

  /// Parse date string key (YYYY-MM-DD) back to DateTime
  static DateTime? parseDateKey(String? key) {
    if (key == null || key.isEmpty) return null;
    try {
      final parts = key.split('-');
      if (parts.length != 3) return null;
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } catch (e) {
      return null;
    }
  }

  /// Convert DateTime to ISO 8601 string for Firestore storage
  static String toIsoString(DateTime date) {
    return date.toUtc().toIso8601String();
  }

  /// Parse ISO 8601 string from Firestore
  static DateTime? parseIsoString(String? isoString) {
    if (isoString == null || isoString.isEmpty) return null;
    try {
      return DateTime.parse(isoString).toLocal();
    } catch (e) {
      return null;
    }
  }

  /// Check if two dates are the same day (ignoring time)
  static bool isSameDay(DateTime date1, DateTime date2) {
    return dateKey(date1) == dateKey(date2);
  }

  /// Calculate days between two dates
  static int daysBetween(DateTime from, DateTime to) {
    return to.difference(from).inDays;
  }

  /// Get the start of day (00:00:00)
  static DateTime startOfDay(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  /// Get the end of day (23:59:59)
  static DateTime endOfDay(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day, 23, 59, 59);
  }

  /// Get current meal type based on hour
  static String getCurrentMealType() {
    final hour = now().hour;
    if (hour < 10) return AppConfig.mealTypeBreakfast;
    if (hour < 15) return AppConfig.mealTypeLunch;
    if (hour < 20) return AppConfig.mealTypeDinner;
    return AppConfig.mealTypeSnack;
  }

  /// Format DateTime for display (e.g., "28 เม.ย. 2026")
  static String formatDateForDisplay(DateTime date) {
    final format = DateFormat('d MMM yyyy', 'th');
    return format.format(date.toLocal());
  }

  /// Format time for display (e.g., "14:30")
  static String formatTimeForDisplay(DateTime date) {
    final format = DateFormat('HH:mm');
    return format.format(date.toLocal());
  }

  /// Format DateTime and time for display (e.g., "28 เม.ย. 14:30")
  static String formatDateTimeForDisplay(DateTime date) {
    final dateFormat = DateFormat('d MMM yyyy', 'th');
    final timeFormat = DateFormat('HH:mm');
    final localDate = date.toLocal();
    return '${dateFormat.format(localDate)} ${timeFormat.format(localDate)}';
  }
}
