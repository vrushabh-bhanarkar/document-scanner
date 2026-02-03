import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Colors - Material 3 Specification (PDF ScanPro)
  // Deep Blue (#0052D4) as primary color for trust and professionalism
  static const Color primaryBlue = Color(0xFF0052D4);
  static const Color primaryBlueLight = Color(0xFF4A7FDB);
  static const Color primaryBlueDark = Color(0xFF003A9F);
  static const Color primaryBlueAccent = Color(0xFF7FA8E8);
  static const Color primaryBlueExtraLight = Color(0xFFE3EDFF);

  // Teal Secondary (#00B4DB) for accent elements
  static const Color secondaryTeal = Color(0xFF00B4DB);
  static const Color secondaryTealLight = Color(0xFF4DD4EB);
  static const Color secondaryTealDark = Color(0xFF008FA6);
  static const Color secondaryTealExtraLight = Color(0xFFE0F8FF);

  // Secondary Colors
  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldLight = Color(0xFF34D399);
  static const Color emeraldDark = Color(0xFF059669);
  static const Color emeraldExtraLight = Color(0xFFD1FAE5);

  static const Color amber = Color(0xFFF59E0B);
  static const Color amberLight = Color(0xFFFBBF24);
  static const Color amberDark = Color(0xFFD97706);
  static const Color amberExtraLight = Color(0xFFFEF3C7);

  static const Color purple = Color(0xFF8B5CF6);
  static const Color purpleLight = Color(0xFFA78BFA);
  static const Color purpleDark = Color(0xFF7C3AED);
  static const Color purpleExtraLight = Color(0xFFEDE9FE);

  static const Color rose = Color(0xFFF43F5E);
  static const Color roseLight = Color(0xFFFB7185);
  static const Color roseDark = Color(0xFFE11D48);
  static const Color roseExtraLight = Color(0xFFFFE4E6);

  // Neutral Colors - Modern Gray Scale with white background priority
  static const Color white = Color(0xFFFFFFFF);
  static const Color gray50 = Color(0xFFFAFAFA); // Softer light gray background
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray200 = Color(0xFFEEEEEE);
  static const Color gray300 = Color(0xFFE0E0E0);
  static const Color gray400 = Color(0xFFBDBDBD);
  static const Color gray500 = Color(0xFF9E9E9E);
  static const Color gray600 = Color(0xFF757575);
  static const Color gray700 = Color(0xFF616161);
  static const Color gray800 = Color(0xFF424242);
  static const Color gray900 = Color(0xFF212121);
  static const Color black = Color(0xFF0A0A0A);

  // Surface Colors - Enhanced for white background with subtle depth
  static const Color background =
      Color(0xFFFAFAFA); // Softer white for less eye strain
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFF87171);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFF60A5FA);

  // Gradients - Updated for Material 3 specification
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, primaryBlueLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient HeroSectionGradient = LinearGradient(
    colors: [
      Color.fromARGB(255, 132, 158, 202),
      Color.fromARGB(255, 82, 86, 95)
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient primaryGradientVibrant = LinearGradient(
    colors: [
      Color.fromARGB(255, 99, 153, 255), // Softer, more modern blue
      Color.fromARGB(255, 74, 108, 188), // Mid-tone blue
      Color.fromARGB(255, 55, 75, 100) // Deeper accent
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient heroSectionGradientVibrant = LinearGradient(
      colors: [
        Color.fromRGBO(11, 49, 114, 1),
        Color.fromARGB(6, 56, 103, 185),
        Color.fromARGB(255, 7, 17, 36)
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      stops: [0.1, 0.5, 1.0]);

  static const LinearGradient secondaryTealGradient = LinearGradient(
    colors: [secondaryTeal, secondaryTealLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [emerald, emeraldLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGradientVibrant = LinearGradient(
    colors: [
      Color.fromARGB(255, 76, 194, 110), // Lighter, modern emerald
      Color.fromARGB(255, 52, 140, 85), // Mid-tone emerald
      Color.fromARGB(255, 38, 92, 60) // Deeper accent
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [purple, purpleLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradientVibrant = LinearGradient(
    colors: [
      Color.fromARGB(255, 184, 152, 205), // Lighter, modern purple
      Color.fromARGB(255, 130, 92, 157), // Mid-tone purple
      Color.fromARGB(255, 90, 60, 110) // Deeper accent
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient emberGradientVibrant = LinearGradient(
    colors: [
      Color.fromARGB(255, 202, 175, 94),
      Color.fromRGBO(118, 110, 26, 1),
      Color.fromARGB(255, 66, 66, 14)
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient tealGradientVibrant = LinearGradient(
    colors: [
      Color.fromRGBO(64, 158, 186, 1),
      Color.fromARGB(255, 23, 94, 107),
      Color.fromARGB(255, 6, 44, 47)
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient amberGradient = LinearGradient(
    colors: [amber, amberLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient roseGradient = LinearGradient(
    colors: [rose, roseLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shimmer gradient for loading states
  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [
      Color(0xFFE5E7EB),
      Color(0xFFF3F4F6),
      Color(0xFFE5E7EB),
    ],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment(-1.0, 0.0),
    end: Alignment(1.0, 0.0),
  );
}

class AppTextStyles {
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.gray900,
    letterSpacing: -0.8,
    height: 1.2,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.gray900,
    letterSpacing: -0.6,
    height: 1.3,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.gray900,
    letterSpacing: -0.5,
    height: 1.3,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.gray900,
    letterSpacing: -0.3,
    height: 1.4,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.gray900,
    letterSpacing: -0.2,
    height: 1.4,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.gray900,
    height: 1.5,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.gray700,
    height: 1.6,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.gray600,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.gray500,
    height: 1.4,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.gray700,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.gray600,
    letterSpacing: 0.5,
  );
}

class AppShadows {
  // Soft shadows for subtle elevation
  static const BoxShadow soft = BoxShadow(
    color: Color(0x08000000),
    blurRadius: 10,
    offset: Offset(0, 2),
    spreadRadius: 0,
  );

  // Medium shadows for cards and elevated surfaces
  static const BoxShadow medium = BoxShadow(
    color: Color(0x0F000000),
    blurRadius: 20,
    offset: Offset(0, 4),
    spreadRadius: 0,
  );

  // Large shadows for modals and important elements
  static const BoxShadow large = BoxShadow(
    color: Color(0x15000000),
    blurRadius: 30,
    offset: Offset(0, 8),
    spreadRadius: 0,
  );

  // Extra large for maximum depth
  static const BoxShadow extraLarge = BoxShadow(
    color: Color(0x1A000000),
    blurRadius: 40,
    offset: Offset(0, 12),
    spreadRadius: -4,
  );

  // Card shadow with layered effect
  static List<BoxShadow> cardShadow = [
    const BoxShadow(
      color: Color(0x08000000),
      blurRadius: 20,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
    const BoxShadow(
      color: Color(0x05000000),
      blurRadius: 40,
      offset: Offset(0, 12),
      spreadRadius: -8,
    ),
  ];

  // Elevated card shadow for hover or selected states
  static List<BoxShadow> cardShadowElevated = [
    const BoxShadow(
      color: Color(0x12000000),
      blurRadius: 25,
      offset: Offset(0, 8),
      spreadRadius: 0,
    ),
    const BoxShadow(
      color: Color(0x08000000),
      blurRadius: 50,
      offset: Offset(0, 16),
      spreadRadius: -8,
    ),
  ];

  // Button shadow
  static List<BoxShadow> buttonShadow = [
    const BoxShadow(
      color: Color(0x15000000),
      blurRadius: 15,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> primaryShadow = [
    const BoxShadow(
      color: Color(0x300052D4),
      blurRadius: 20,
      offset: Offset(0, 8),
      spreadRadius: -4,
    ),
  ];

  // Inner shadow effect
  static const BoxShadow innerShadow = BoxShadow(
    color: Color(0x08000000),
    blurRadius: 4,
    offset: Offset(0, 2),
    spreadRadius: -2,
  );
}

class AppThemes {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppColors.primaryBlue,
    scaffoldBackgroundColor: AppColors.background,

    // Color Scheme
    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryBlue,
      primaryContainer: AppColors.primaryBlueLight,
      secondary: AppColors.emerald,
      secondaryContainer: AppColors.emeraldLight,
      tertiary: AppColors.purple,
      tertiaryContainer: AppColors.purpleLight,
      surface: AppColors.surface,
      surfaceVariant: AppColors.surfaceVariant,
      error: AppColors.error,
      onPrimary: Colors.white,
      onPrimaryContainer: AppColors.primaryBlueDark,
      onSecondary: Colors.white,
      onSecondaryContainer: AppColors.emeraldDark,
      onSurface: AppColors.gray900,
      onSurfaceVariant: AppColors.gray700,
      onError: Colors.white,
      outline: AppColors.gray300,
      outlineVariant: AppColors.gray200,
      shadow: AppColors.gray400,
      scrim: AppColors.black,
    ),

    // App Bar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.gray900,
      elevation: 0,
      scrolledUnderElevation: 2,
      shadowColor: AppColors.gray200,
      surfaceTintColor: AppColors.primaryBlueExtraLight,
      centerTitle: false,
      titleTextStyle: AppTextStyles.headlineMedium,
      iconTheme: const IconThemeData(color: AppColors.gray700, size: 24),
      actionsIconTheme: const IconThemeData(color: AppColors.gray700, size: 24),
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: AppColors.primaryBlue.withOpacity(0.3),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),

    // Text Theme
    textTheme: const TextTheme(
      displayLarge: AppTextStyles.displayLarge,
      displayMedium: AppTextStyles.displayMedium,
      headlineLarge: AppTextStyles.headlineLarge,
      headlineMedium: AppTextStyles.headlineMedium,
      titleLarge: AppTextStyles.titleLarge,
      titleMedium: AppTextStyles.titleMedium,
      bodyLarge: AppTextStyles.bodyLarge,
      bodyMedium: AppTextStyles.bodyMedium,
      bodySmall: AppTextStyles.bodySmall,
      labelLarge: AppTextStyles.labelLarge,
      labelMedium: AppTextStyles.labelMedium,
    ),

    // Card Theme
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: AppColors.surface,
      shadowColor: Colors.black.withOpacity(0.08),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.gray50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.gray200, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.gray200, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
    ),

    // Dialog Theme
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      elevation: 24,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
    ),

    // Bottom Sheet Theme
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      elevation: 16,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
    ),

    // Floating Action Button Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryBlue,
      foregroundColor: Colors.white,
      elevation: 6,
      highlightElevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
  );
}

// Border Radius Utilities
class AppBorderRadius {
  static const BorderRadius small = BorderRadius.all(Radius.circular(8));
  static const BorderRadius medium = BorderRadius.all(Radius.circular(12));
  static const BorderRadius large = BorderRadius.all(Radius.circular(16));
  static const BorderRadius extraLarge = BorderRadius.all(Radius.circular(24));
  static const BorderRadius round = BorderRadius.all(Radius.circular(999));

  static const BorderRadius topSmall =
      BorderRadius.vertical(top: Radius.circular(8));
  static const BorderRadius topMedium =
      BorderRadius.vertical(top: Radius.circular(12));
  static const BorderRadius topLarge =
      BorderRadius.vertical(top: Radius.circular(16));
  static const BorderRadius topExtraLarge =
      BorderRadius.vertical(top: Radius.circular(24));
}

// Spacing Utilities
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}

// Animation Durations
class AppDurations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);
}

// Animation Curves
class AppCurves {
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeIn = Curves.easeIn;
  static const Curve bounceOut = Curves.bounceOut;
  static const Curve elasticOut = Curves.elasticOut;
}

// Modern Card Elevations
class AppElevations {
  static const double none = 0;
  static const double low = 2;
  static const double medium = 4;
  static const double high = 8;
  static const double extraHigh = 16;
}

// Modern Glass Morphism Effect
class AppGlassMorphism {
  static BoxDecoration light({double blur = 10, Color? color}) {
    return BoxDecoration(
      color: (color ?? Colors.white).withOpacity(0.7),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.white.withOpacity(0.3),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static BoxDecoration dark({double blur = 10}) {
    return BoxDecoration(
      color: Colors.black.withOpacity(0.3),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.white.withOpacity(0.1),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}
