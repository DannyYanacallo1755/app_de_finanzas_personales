import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class AppTheme {
  // ─── Dark palette ─────────────────────────────────────────────────────────
  static const Color background  = Color(0xFF0A0A0F);
  static const Color cardBg      = Color(0xFF16161E);
  static const Color surface     = Color(0xFF22222E);
  static const Color border      = Color(0xFF2C2C3A);
  static const Color primary     = Color(0xFF7B6CF6);  // violet suave
  static const Color primaryGlow = Color(0xFF9D8FF8);
  static const Color success     = Color(0xFF2ECC71);
  static const Color danger      = Color(0xFFE74C3C);
  static const Color warning     = Color(0xFFF39C12);
  static const Color income      = Color(0xFF00CEC9);  // teal para ingresos
  static const Color cash        = Color(0xFF55EFC4);  // verde menta (efectivo)
  static const Color bank        = Color(0xFF74B9FF);  // azul (banco)
  static const Color textPrimary   = Color(0xFFF0F0F5);
  static const Color textSecondary = Color(0xFF8E8EA0);

  // ─── Formatting ──────────────────────────────────────────────────────────
  static String formatCurrency(double amount) =>
      NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 2)
          .format(amount);

  static String formatCurrencyCompact(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}k\$';
    }
    return '\$${amount.toStringAsFixed(0)}';
  }

  static String formatMonth(DateTime d) =>
      DateFormat('MMMM yyyy', 'es_ES').format(d);

  static String formatDate(DateTime d) =>
      DateFormat('d MMM yyyy', 'es_ES').format(d);

  static String formatShortDate(DateTime d) =>
      DateFormat('d MMM', 'es_ES').format(d);

  // ─── Theme ───────────────────────────────────────────────────────────────
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.dark(
        primary: primary,
        surface: cardBg,
        onPrimary: Colors.white,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardBg,
        indicatorColor: primary.withOpacity(0.25),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryGlow);
          }
          return const IconThemeData(color: textSecondary);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
                color: primaryGlow, fontWeight: FontWeight.w600, fontSize: 12);
          }
          return const TextStyle(color: textSecondary, fontSize: 12);
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textSecondary),
        prefixStyle: const TextStyle(color: textPrimary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          elevation: 0,
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textPrimary),
        bodySmall: TextStyle(color: textSecondary),
        titleLarge:
            TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        titleMedium:
            TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
      ),
      dividerTheme:
          const DividerThemeData(color: border, thickness: 1),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? primary : textSecondary),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? primary.withOpacity(0.4)
                : surface),
      ),
    );
  }

  // ─── Light (kept for reference but not used) ─────────────────────────────
  static ThemeData get light => dark;
}
