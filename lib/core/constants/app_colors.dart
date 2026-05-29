import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const primary = Color(0xFF0D47A1);
  static const primaryVariant = Color(0xFF1565C0);
  static const primaryLight = Color(0xFF2979FF);

  // Light surfaces
  static const bgLight = Color(0xFFF3F7FE);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const cardLight = Color(0xFFFFFFFF);
  static const borderLight = Color(0xFFE5ECF7);
  static const fillLight = Color(0xFFF6F9FF);

  // Light text
  static const textPrimaryLight = Color(0xFF10243E);
  static const textSecondaryLight = Color(0xFF6B7A90);
  static const textHintLight = Color(0xFF9AA8BB);

  // Dark surfaces
  static const bgDark = Color(0xFF05101F);
  static const surfaceDark = Color(0xFF0D1B2E);
  static const cardDark = Color(0xFF0F2040);
  static const borderDark = Color(0xFF1A3356);
  static const fillDark = Color(0xFF0D1B2E);

  // Dark text
  static const textPrimaryDark = Color(0xFFEAF0FB);
  static const textSecondaryDark = Color(0xFF7B9CBD);
  static const textHintDark = Color(0xFF4A6A8A);

  // Semantic — income
  static const income = Color(0xFF00C896);
  static const incomeSubtle = Color(0xFF003D2D);
  static const incomeSubtleLight = Color(0xFFE6FAF4);

  // Semantic — expense
  static const expense = Color(0xFFFF5252);
  static const expenseSubtle = Color(0xFF3D0D0D);
  static const expenseSubtleLight = Color(0xFFFFEBEB);

  // Semantic — misc
  static const warning = Color(0xFFFFB300);
  static const warningSubtleLight = Color(0xFFFFF8E1);
  static const error = Color(0xFFE53935);
  static const success = Color(0xFF43A047);

  // Gradient helpers
  static const List<Color> gradientPrimary = [
    Color(0xFF0D47A1),
    Color(0xFF1565C0),
    Color(0xFF2979FF),
  ];
  static const List<Color> gradientIncome = [
    Color(0xFF00A876),
    Color(0xFF00C896),
  ];
  static const List<Color> gradientExpense = [
    Color(0xFFE04040),
    Color(0xFFFF5252),
  ];
  static const List<Color> gradientDark = [
    Color(0xFF0D1B2E),
    Color(0xFF050D1A),
  ];

  // Premium balance card gradient (always dark)
  static const List<Color> gradientCard = [
    Color(0xFF040D1C),
    Color(0xFF082040),
    Color(0xFF040D1C),
  ];

  // Electric accent for glow/highlight effects
  static const electricBlue = Color(0xFF00B4FF);
}

extension ThemeColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get bg => isDark ? AppColors.bgDark : AppColors.bgLight;
  Color get surface => isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
  Color get card => isDark ? AppColors.cardDark : AppColors.cardLight;
  Color get border => isDark ? AppColors.borderDark : AppColors.borderLight;
  Color get fill => isDark ? AppColors.fillDark : AppColors.fillLight;
  Color get textPrimary => isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
  Color get textSecondary => isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
  Color get textHint => isDark ? AppColors.textHintDark : AppColors.textHintLight;
  Color get accent => isDark ? AppColors.primaryLight : AppColors.primary;
}
