import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF6F2DBD); // purple banner
  static const accent  = Color(0xFF7ED957); // green approve/cta
  static const bg      = Color(0xFFF7F7FA);
}

class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      background: AppColors.bg,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.background,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      chipTheme: const ChipThemeData(shape: StadiumBorder()),
    );
  }

  static ThemeData get dark {
    final scheme = const ColorScheme.dark(primary: AppColors.primary);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      chipTheme: const ChipThemeData(shape: StadiumBorder()),
    );
  }
}
