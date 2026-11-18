import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Approved identity colours ONLY:
///   blue  #4E759C (from the logo background), white, black.
///   red   is reserved for the cart circle on the Dukan header and nowhere else.
/// No greys, tints, gradients or shadows are used anywhere in the app.
class AppColors {
  static const blue = Color(0xFF4E759C);
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
  static const cartRed = Color(0xFFE53935); // cart circle ONLY
}

ThemeData buildTheme(String lang) {
  const w = AppColors.white;
  const b = AppColors.black;
  final base = ThemeData(
    useMaterial3: true,
    // Every Material surface/outline role is forced to white or black so that
    // no default grey/lavender tint can leak into the UI.
    colorScheme: const ColorScheme.light(
      primary: b,
      onPrimary: w,
      secondary: AppColors.blue,
      onSecondary: w,
      surface: w,
      onSurface: b,
      onSurfaceVariant: b,
      outline: b,
      outlineVariant: b,
      surfaceTint: w,
      surfaceContainerLowest: w,
      surfaceContainerLow: w,
      surfaceContainer: w,
      surfaceContainerHigh: w,
      surfaceContainerHighest: w,
      inverseSurface: b,
      onInverseSurface: w,
      error: b,
      onError: w,
    ),
    scaffoldBackgroundColor: w,
    dividerColor: b,
    dividerTheme: const DividerThemeData(color: b, thickness: 1, space: 1),
    appBarTheme: const AppBarTheme(
      backgroundColor: w,
      foregroundColor: b,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: w,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: b,
        foregroundColor: w,
        // disabled look == enabled look (no default grey); callers ignore taps
        disabledBackgroundColor: b,
        disabledForegroundColor: w,
        elevation: 0,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: b,
        disabledForegroundColor: b,
        side: const BorderSide(color: b, width: 1.5),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: b, disabledForegroundColor: b),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: b)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: b)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: b, width: 2)),
      labelStyle: const TextStyle(color: b),
      hintStyle: const TextStyle(color: b),
    ),
  );
  final text = lang == 'ar'
      ? GoogleFonts.tajawalTextTheme(base.textTheme)
      : GoogleFonts.interTextTheme(base.textTheme).apply(displayColor: b, bodyColor: b);
  return base.copyWith(textTheme: text.apply(bodyColor: b, displayColor: b));
}

 
ThemeData buildDarkTheme(String lang) {
  const bg = Color(0xFF121820);
  const surface = Color(0xFF1D2732);
  const fg = Color(0xFFF3F6F8);
  const outline = Color(0xFF647383);
  final light = buildTheme(lang);
  final text = lang == 'ar'
      ? GoogleFonts.tajawalTextTheme(ThemeData.dark().textTheme)
      : GoogleFonts.interTextTheme(ThemeData.dark().textTheme);
  return light.copyWith(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.blue,
      onPrimary: Colors.white,
      secondary: Color(0xFF8DB5D8),
      onSecondary: Color(0xFF101820),
      surface: surface,
      onSurface: fg,
      onSurfaceVariant: Color(0xFFD0D9E1),
      outline: outline,
      outlineVariant: outline,
      surfaceTint: surface,
      inverseSurface: fg,
      onInverseSurface: bg,
      error: Color(0xFFFF8A80),
      onError: Color(0xFF202020),
    ),
    scaffoldBackgroundColor: bg,
    canvasColor: bg,
    dividerColor: outline,
    dividerTheme: const DividerThemeData(color: outline, thickness: 1, space: 1),
    appBarTheme: const AppBarTheme(
      backgroundColor: bg,
      foregroundColor: fg,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: bg,
    ),
    cardColor: surface,
    dialogBackgroundColor: surface,
    textTheme: text.apply(bodyColor: fg, displayColor: fg),
    listTileTheme: const ListTileThemeData(textColor: fg, iconColor: fg),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: outline)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: outline)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.blue, width: 2)),
      labelStyle: const TextStyle(color: Color(0xFFD0D9E1)),
      hintStyle: const TextStyle(color: Color(0xFFB0BBC6)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: fg,
        disabledForegroundColor: fg,
        side: const BorderSide(color: outline, width: 1.5),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: fg)),
  );
}
