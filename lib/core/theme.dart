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
  const bg = Color(0xFF101820);
  const surface = Color(0xFF1B2732);
  const elevated = Color(0xFF243442);
  const fg = Color(0xFFF4F7FA);
  const muted = Color(0xFFC4D0DA);
  const outline = Color(0xFF657889);
  final base = ThemeData.dark(useMaterial3: true);
  final text = lang == 'ar'
      ? GoogleFonts.tajawalTextTheme(base.textTheme)
      : GoogleFonts.interTextTheme(base.textTheme);
  final scheme = const ColorScheme.dark(
    primary: Color(0xFF8DB5D8),
    onPrimary: Color(0xFF101820),
    secondary: Color(0xFF8DB5D8),
    onSecondary: Color(0xFF101820),
    surface: surface,
    onSurface: fg,
    surfaceContainerLowest: bg,
    surfaceContainerLow: surface,
    surfaceContainer: surface,
    surfaceContainerHigh: elevated,
    surfaceContainerHighest: elevated,
    onSurfaceVariant: muted,
    outline: outline,
    outlineVariant: outline,
    inverseSurface: fg,
    onInverseSurface: bg,
    error: Color(0xFFFF8A80),
    onError: Color(0xFF202020),
    errorContainer: Color(0xFF5B2929),
    onErrorContainer: Color(0xFFFFDAD6),
    surfaceTint: surface,
  );
  return base.copyWith(
    brightness: Brightness.dark,
    colorScheme: scheme,
    primaryColor: scheme.primary,
    scaffoldBackgroundColor: bg,
    canvasColor: bg,
    cardColor: surface,
    dialogBackgroundColor: surface,
    dividerColor: outline,
    dividerTheme: const DividerThemeData(color: outline, thickness: 1, space: 1),
    textTheme: text.apply(bodyColor: fg, displayColor: fg),
    primaryTextTheme: text.apply(bodyColor: fg, displayColor: fg),
    iconTheme: const IconThemeData(color: fg),
    primaryIconTheme: const IconThemeData(color: fg),
    appBarTheme: const AppBarTheme(
      backgroundColor: bg,
      foregroundColor: fg,
      iconTheme: IconThemeData(color: fg),
      actionsIconTheme: IconThemeData(color: fg),
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: bg,
    ),
    cardTheme: CardThemeData(
      color: surface,
      surfaceTintColor: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    listTileTheme: const ListTileThemeData(textColor: fg, iconColor: fg),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      labelStyle: const TextStyle(color: muted),
      hintStyle: const TextStyle(color: muted),
      prefixIconColor: muted,
      suffixIconColor: muted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF8DB5D8), width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF8DB5D8),
        foregroundColor: bg,
        disabledBackgroundColor: const Color(0xFF52697C),
        disabledForegroundColor: fg,
        elevation: 0,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF8DB5D8),
        foregroundColor: bg,
        disabledBackgroundColor: const Color(0xFF52697C),
        disabledForegroundColor: fg,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: fg,
        disabledForegroundColor: muted,
        side: const BorderSide(color: outline, width: 1.2),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: const Color(0xFFB8D8F2)),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? const Color(0xFF8DB5D8) : surface),
      checkColor: WidgetStateProperty.all(bg),
      side: const BorderSide(color: outline),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? const Color(0xFF8DB5D8) : muted),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? const Color(0xFF52697C) : surface),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Color(0xFF8DB5D8),
      linearTrackColor: elevated,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: elevated,
      contentTextStyle: TextStyle(color: fg),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: Color(0xFFB8D8F2),
      unselectedItemColor: muted,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: const Color(0xFF354B5E),
      labelTextStyle: WidgetStateProperty.all(const TextStyle(color: fg)),
      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
        color: states.contains(WidgetState.selected) ? const Color(0xFFB8D8F2) : muted,
      )),
    ),
  );
}
