import 'package:flutter/material.dart';

class AppTheme {
  static const Color noirBlack = Color(0xFF0A0A0A);
  static const Color noirDarkGrey = Color(0xFF1A1A1A);
  static const Color noirMediumGrey = Color(0xFF2A2A2A);
  static const Color noirLightGrey = Color(0xFF3A3A3A);
  static const Color goldAccent = Color(0xFFD4A843);
  static const Color goldDark = Color(0xFFB8923A);
  static const Color bloodRed = Color(0xFF8B1A1A);
  static const Color paperWhite = Color(0xFFF5F0E8);
  static const Color paperDark = Color(0xFFD4C9B8);
  static const Color mutedGreen = Color(0xFF2D5A2D);
  static const Color mutedBlue = Color(0xFF1A3A5C);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: noirBlack,
      colorScheme: const ColorScheme.dark(
        primary: goldAccent,
        secondary: goldDark,
        surface: noirDarkGrey,
        surfaceContainerHighest: noirMediumGrey,
        onPrimary: noirBlack,
        onSecondary: noirBlack,
        onSurface: paperWhite,
        onSurfaceVariant: paperDark,
        error: bloodRed,
        onError: paperWhite,
        outline: noirLightGrey,
        outlineVariant: noirMediumGrey,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: noirDarkGrey,
        foregroundColor: goldAccent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Cinzel',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: goldAccent,
          letterSpacing: 1.5,
        ),
        iconTheme: IconThemeData(color: goldAccent),
      ),
      cardTheme: CardThemeData(
        color: noirDarkGrey,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shadowColor: goldAccent.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: goldAccent, width: 0.5),
        ),
        margin: const EdgeInsets.all(12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: goldAccent,
          foregroundColor: noirBlack,
          elevation: 2,
          shadowColor: goldAccent.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: goldAccent,
          side: const BorderSide(color: goldAccent, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: goldAccent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: noirMediumGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: noirLightGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: noirLightGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: goldAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: bloodRed),
        ),
        labelStyle: const TextStyle(color: paperDark),
        hintStyle: const TextStyle(color: Color(0xFF888888)),
        prefixIconColor: goldAccent,
        suffixIconColor: goldAccent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Cinzel',
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: goldAccent,
          letterSpacing: 2.0,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Cinzel',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: goldAccent,
          letterSpacing: 1.5,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Cinzel',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: goldAccent,
          letterSpacing: 1.0,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Cinzel',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: paperWhite,
          letterSpacing: 1.0,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Cinzel',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: paperWhite,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Cinzel',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: paperWhite,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: paperWhite,
          letterSpacing: 0.5,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: paperWhite,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: paperDark,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: paperWhite,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: paperDark,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Color(0xFFBBBBBB),
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: noirBlack,
          letterSpacing: 0.5,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: noirLightGrey,
        thickness: 0.5,
        space: 24,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: noirMediumGrey,
        selectedColor: goldAccent.withValues(alpha: 0.2),
        labelStyle: const TextStyle(color: paperWhite),
        secondaryLabelStyle: const TextStyle(color: noirBlack),
        side: const BorderSide(color: noirLightGrey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: noirDarkGrey,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: goldAccent, width: 1),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: 'Cinzel',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: goldAccent,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 15,
          color: paperDark,
          height: 1.5,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: noirDarkGrey,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: noirDarkGrey,
        surfaceTintColor: Colors.transparent,
        indicatorColor: goldAccent.withValues(alpha: 0.1),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: goldAccent,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            );
          }
          return const TextStyle(
            color: paperDark,
            fontWeight: FontWeight.w400,
            fontSize: 12,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: goldAccent, size: 24);
          }
          return const IconThemeData(color: paperDark, size: 24);
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: goldAccent,
        foregroundColor: noirBlack,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: goldAccent,
        linearTrackColor: noirMediumGrey,
        circularTrackColor: noirMediumGrey,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: goldAccent,
        inactiveTrackColor: noirLightGrey,
        thumbColor: goldAccent,
        overlayColor: goldAccent.withValues(alpha: 0.2),
        valueIndicatorColor: goldAccent,
        valueIndicatorTextStyle: const TextStyle(color: noirBlack),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: noirMediumGrey,
          border: Border.all(color: goldAccent),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: paperWhite, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  static TextStyle get noirTitle => const TextStyle(
        fontFamily: 'Cinzel',
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: goldAccent,
        letterSpacing: 2.0,
        shadows: [
          Shadow(
            color: Colors.black87,
            offset: Offset(2, 2),
            blurRadius: 4,
          ),
        ],
      );

  static TextStyle get noirSubtitle => const TextStyle(
        fontFamily: 'Cinzel',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: paperDark,
        letterSpacing: 2.0,
      );

  static TextStyle get typewriter => const TextStyle(
        fontFamily: 'SpaceMono',
        fontSize: 14,
        color: paperWhite,
        height: 1.6,
      );

  static TextStyle get evidenceText => const TextStyle(
        fontFamily: 'SpaceMono',
        fontSize: 13,
        color: paperDark,
        height: 1.5,
      );

  static BoxDecoration get caseFileDecoration => BoxDecoration(
        color: noirDarkGrey,
        border: Border.all(color: goldAccent.withValues(alpha: 0.3), width: 1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: goldAccent.withValues(alpha: 0.05),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      );

  static BoxDecoration get paperDecoration => BoxDecoration(
        color: const Color(0xFF1E1A15),
        border: Border.all(color: goldAccent.withValues(alpha: 0.2), width: 0.5),
        borderRadius: BorderRadius.circular(8),
        image: const DecorationImage(
          image: AssetImage('assets/images/paper_texture.png'),
          opacity: 0.03,
          repeat: ImageRepeat.repeat,
        ),
      );
}