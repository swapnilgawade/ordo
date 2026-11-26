import 'package:material_ui/material_ui.dart';

/// Ordo's look: dark and premium, with bold type, soft raised cards and
/// smooth motion. Monochrome surfaces with one lilac accent.
class OrdoColors {
  static const background = Color(0xFF0C0C0E);
  static const surface = Color(0xFF17171B);
  static const surfaceHigh = Color(0xFF202026);
  static const outline = Color(0xFF2C2C33);
  static const text = Color(0xFFF4F3F0);
  static const textMuted = Color(0xFF9A99A3);
  static const accent = Color(0xFFB9A8FF);
  static const accentInk = Color(0xFF15102B);
  static const danger = Color(0xFFFF7A7A);
}

ThemeData buildOrdoTheme() {
  const scheme = ColorScheme.dark(
    surface: OrdoColors.surface,
    primary: OrdoColors.accent,
    onPrimary: OrdoColors.accentInk,
    secondary: OrdoColors.accent,
    onSurface: OrdoColors.text,
    error: OrdoColors.danger,
    outline: OrdoColors.outline,
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: OrdoColors.background,
  );
  final text = base.textTheme.apply(
    bodyColor: OrdoColors.text,
    displayColor: OrdoColors.text,
  );
  return base.copyWith(
    textTheme: text.copyWith(
      displaySmall: text.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        height: 1.05,
      ),
      headlineMedium: text.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
      ),
      titleLarge: text.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      bodyMedium: text.bodyMedium?.copyWith(color: OrdoColors.textMuted),
      labelLarge: text.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: OrdoColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: OrdoColors.accent,
      foregroundColor: OrdoColors.accentInk,
      shape: StadiumBorder(),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: OrdoColors.accent,
        foregroundColor: OrdoColors.accentInk,
        minimumSize: const Size(0, 52),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: OrdoColors.text,
        minimumSize: const Size(0, 52),
        side: const BorderSide(color: OrdoColors.outline),
        shape: const StadiumBorder(),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: OrdoColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: OrdoColors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: OrdoColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: OrdoColors.accent, width: 1.5),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: OrdoColors.surfaceHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: OrdoColors.surfaceHigh,
      contentTextStyle: TextStyle(color: OrdoColors.text),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
