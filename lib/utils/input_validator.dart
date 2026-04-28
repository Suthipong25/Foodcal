// Utilities for validating and sanitizing user input.
// Prevents data corruption and potential security issues.
import '../constants/app_config.dart';

class InputValidator {
  /// Validate and sanitize food item name
  static String? validateFoodName(String? input) {
    if (input == null || input.trim().isEmpty) {
      return 'ชื่ออาหารจำเป็น';
    }

    final sanitized = _sanitize(input);

    if (sanitized.length > AppConfig.maxFoodNameLength) {
      return 'ชื่ออาหารยาวเกินไป (ได้สูงสุด ${AppConfig.maxFoodNameLength} อักขระ)';
    }

    return null;
  }

  /// Validate calorie input
  static String? validateCalories(String? input) {
    if (input == null || input.trim().isEmpty) {
      return 'แคลอรี่จำเป็น';
    }

    final calories = int.tryParse(input.trim());

    if (calories == null) {
      return 'แคลอรี่ต้องเป็นตัวเลข';
    }

    if (calories < 0) {
      return 'แคลอรี่ต้องเป็นค่าบวก';
    }

    if (calories > AppConfig.maxSingleFoodCalories) {
      return 'แคลอรี่เกินขีดจำกัด (${AppConfig.maxSingleFoodCalories} cal สูงสุด)';
    }

    return null;
  }

  /// Validate macro nutrient input (protein, carbs, fat)
  static String? validateMacro(String? input, String macroName) {
    if (input == null || input.trim().isEmpty) {
      return '$macroName จำเป็น';
    }

    final value = int.tryParse(input.trim());

    if (value == null) {
      return '$macroName ต้องเป็นตัวเลข';
    }

    if (value < 0) {
      return '$macroName ต้องเป็นค่าบวก';
    }

    if (value > AppConfig.maxSingleMacroGrams) {
      return '$macroName เกินขีดจำกัด (${AppConfig.maxSingleMacroGrams}g สูงสุด)';
    }

    return null;
  }

  /// Validate water glasses input
  static String? validateWaterGlasses(String? input) {
    if (input == null || input.trim().isEmpty) {
      return 'จำนวนแก้นจำเป็น';
    }

    final glasses = int.tryParse(input.trim());

    if (glasses == null) {
      return 'จำนวนแก้นต้องเป็นตัวเลข';
    }

    if (glasses < 0) {
      return 'จำนวนแก้นต้องเป็นค่าบวก';
    }

    if (glasses > AppConfig.maxDailyWaterGlasses) {
      return 'จำนวนแก้นเกินขีดจำกัด (${AppConfig.maxDailyWaterGlasses} แก้น สูงสุด)';
    }

    return null;
  }

  /// Validate user name
  static String? validateUserName(String? input) {
    if (input == null || input.trim().isEmpty) {
      return 'ชื่อผู้ใช้จำเป็น';
    }

    final sanitized = _sanitize(input);

    if (sanitized.length < 2) {
      return 'ชื่อผู้ใช้ต้องมีความยาวอย่างน้อย 2 อักขระ';
    }

    if (sanitized.length > 100) {
      return 'ชื่อผู้ใช้ยาวเกินไป';
    }

    return null;
  }

  /// Validate user height
  static String? validateHeight(String? input) {
    if (input == null || input.trim().isEmpty) {
      return 'ส่วนสูงจำเป็น';
    }

    final height = double.tryParse(input.trim());

    if (height == null) {
      return 'ส่วนสูงต้องเป็นตัวเลข';
    }

    if (height < 100 || height > 250) {
      return 'ส่วนสูงต้องอยู่ระหว่าง 100 ถึง 250 ซม.';
    }

    return null;
  }

  /// Validate user weight
  static String? validateWeight(String? input) {
    if (input == null || input.trim().isEmpty) {
      return 'น้ำหนักจำเป็น';
    }

    final weight = double.tryParse(input.trim());

    if (weight == null) {
      return 'น้ำหนักต้องเป็นตัวเลข';
    }

    if (weight < 20 || weight > 500) {
      return 'น้ำหนักต้องอยู่ระหว่าง 20 ถึง 500 กก.';
    }

    return null;
  }

  /// Sanitize input by removing special characters and trimming
  static String _sanitize(String input) {
    // Trim whitespace
    var sanitized = input.trim();

    // Remove multiple spaces
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');

    // Remove control characters (but allow Thai, English, numbers, and common punctuation)
    sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');

    return sanitized;
  }

  /// Sanitize a string for safe storage in Firestore
  static String sanitizeForStorage(String input) {
    final sanitized = _sanitize(input);
    // Additional check: limit length to prevent document bloat
    if (sanitized.length > AppConfig.maxFoodNameLength) {
      return sanitized.substring(0, AppConfig.maxFoodNameLength);
    }
    return sanitized;
  }
}
