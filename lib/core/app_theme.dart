import 'package:flutter/material.dart';

const brandGreen = Color(0xFF23866B);
const deepGreen = Color(0xFF174C3E);
const canvasColor = Color(0xFFF5F6F2);
const inkColor = Color(0xFF20362E);
const mutedColor = Color(0xFF738079);
const lineColor = Color(0xFFE5EAE4);
const warmColor = Color(0xFFAC7538);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: brandGreen,
    brightness: Brightness.light,
    primary: brandGreen,
    secondary: const Color(0xFF6C8F7E),
    surface: Colors.white,
    error: const Color(0xFFD14343),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: canvasColor,
    fontFamily: 'Microsoft YaHei',
    fontFamilyFallback: const ['Microsoft YaHei', 'Noto Sans CJK SC'],
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: inkColor,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: inkColor,
        letterSpacing: -0.5,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: inkColor,
      ),
      titleMedium: TextStyle(fontWeight: FontWeight.w700, color: inkColor),
      bodyLarge: TextStyle(height: 1.35, color: inkColor),
      bodyMedium: TextStyle(height: 1.35, color: Color(0xFF4D5B54)),
      bodySmall: TextStyle(height: 1.4, color: mutedColor, fontSize: 12),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: canvasColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: inkColor,
        fontSize: 23,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shadowColor: const Color(0x1A14392B),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: lineColor),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFDDF4E9),
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      selectedIconTheme: const IconThemeData(color: deepGreen),
      selectedLabelTextStyle: const TextStyle(
        color: deepGreen,
        fontWeight: FontWeight.w700,
      ),
      unselectedIconTheme: const IconThemeData(color: Color(0xFF738079)),
      unselectedLabelTextStyle: const TextStyle(color: Color(0xFF66736D)),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0x14708078),
      thickness: 1,
      space: 1,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 70,
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFDDF4E9),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? deepGreen
              : const Color(0xFF66736D),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF3F5F1),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: brandGreen, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        textStyle: const TextStyle(
          fontFamily: 'Microsoft YaHei',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 46),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        side: const BorderSide(color: Color(0x3322A06B)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: 'Microsoft YaHei',
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: inkColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFFE2EEE5),
      side: const BorderSide(color: lineColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      labelStyle: const TextStyle(
        fontFamily: 'Microsoft YaHei',
        fontSize: 12,
        color: deepGreen,
      ),
      showCheckmark: false,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        side: const WidgetStatePropertyAll(BorderSide(color: lineColor)),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontFamily: 'Microsoft YaHei',
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? const Color(0xFFE2EEE5)
              : Colors.white,
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: deepGreen,
      foregroundColor: Colors.white,
      elevation: 3,
      extendedTextStyle: TextStyle(fontWeight: FontWeight.w600),
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 450),
      decoration: BoxDecoration(
        color: inkColor,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(color: Colors.white),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thickness: WidgetStateProperty.all(7),
      radius: const Radius.circular(99),
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.hovered)
            ? const Color(0x6653655C)
            : const Color(0x3353655C),
      ),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}
