// Application theme: preserves the agreed indigo desktop colors, typography and component styles.
import 'package:flutter/material.dart';

const indigo = Color(0xFF493FCA);
const ink = Color(0xFF171827);
const secondaryInk = Color(0xFF4B5563);
const workspaceBackground = Color(0xFFF6F7FC);
const outline = Color(0xFF858399);
const danger = Color(0xFFB42318);

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: indigo).copyWith(
    primary: indigo,
    onPrimary: Colors.white,
    surface: Colors.white,
    error: danger,
    outline: outline,
  );
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: outline),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: workspaceBackground,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      bodyLarge: TextStyle(fontSize: 15, color: ink),
      bodyMedium: TextStyle(fontSize: 14, color: ink),
      bodySmall: TextStyle(fontSize: 12, color: secondaryInk),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: indigo, width: 2),
      ),
      errorBorder: border.copyWith(borderSide: const BorderSide(color: danger)),
      focusedErrorBorder: border.copyWith(
        borderSide: const BorderSide(color: danger, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      labelStyle: const TextStyle(color: secondaryInk),
      errorMaxLines: 3,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 46),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 46),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        side: const BorderSide(color: outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    dividerColor: const Color(0xFFE1E3EF),
    focusColor: indigo.withValues(alpha: .18),
    hoverColor: indigo.withValues(alpha: .06),
    dataTableTheme: const DataTableThemeData(
      headingRowColor: WidgetStatePropertyAll(Color(0xFFF7F7FC)),
      headingTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      dataTextStyle: TextStyle(fontFamily: 'Inter', color: ink, fontSize: 13),
      horizontalMargin: 20,
      columnSpacing: 24,
    ),
  );
}
