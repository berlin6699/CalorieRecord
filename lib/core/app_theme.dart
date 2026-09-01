import 'package:flutter/material.dart';

const brandGreen = Color(0xFF22A06B);
const deepGreen = Color(0xFF116149);
const canvasColor = Color(0xFFF4F7F5);
const inkColor = Color(0xFF17211C);

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
    fontFamilyFallback: const ['Microsoft YaHei', 'Noto Sans CJK SC'],
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        color: inkColor,
      ),
      titleLarge: TextStyle(fontWeight: FontWeight.w800, color: inkColor),
      titleMedium: TextStyle(fontWeight: FontWeight.w700, color: inkColor),
      bodyLarge: TextStyle(height: 1.35, color: inkColor),
      bodyMedium: TextStyle(height: 1.35, color: Color(0xFF4D5B54)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: canvasColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: inkColor,
        fontSize: 23,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0.5,
      shadowColor: const Color(0x1A14392B),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0x0D173D2D)),
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
      height: 72,
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
      fillColor: const Color(0xFFF1F5F3),
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
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 46),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        side: const BorderSide(color: Color(0x3322A06B)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
