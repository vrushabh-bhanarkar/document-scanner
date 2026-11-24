import 'package:flutter/material.dart';

/// Production Design System for SleekScan
/// Dark Slate & Indigo Palette:
/// - Background: #0F172A (Dark Slate 900)
/// - Card Surface: #1E293B (Slate 800)
/// - Primary Accent: #4F46E5 (Indigo 600)
/// - Success / Pro: #10B981 (Emerald 500)
/// - Subtle Border: #E2E8F0 (Light Slate 200) / #334155 (Slate 700)
class AppTheme {
  // Brand Colors
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color cardSurface = Color(0xFF1E293B);
  static const Color surfaceElevated = Color(0xFF273549);
  static const Color indigo = Color(0xFF4F46E5);
  static const Color indigoLight = Color(0xFF6366F1);
  static const Color indigoHover = Color(0xFF4338CA);
  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldLight = Color(0xFF34D399);
  static const Color emeraldDark = Color(0xFF059669);
  static const Color subtleBorder = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF334155);

  // Neutral scale
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color warningAmber = Color(0xFFF59E0B);

  /// 1px subtle border decoration for card surfaces
  static BoxDecoration cardDecoration({
    Color? surfaceColor,
    Color? borderColor,
    double borderRadius = 14.0,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: surfaceColor ?? cardSurface,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? borderDark.withOpacity(0.6),
        width: 1.0,
      ),
      boxShadow: shadows ??
          [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
    );
  }

  /// Metadata badge helper: "PDF • 1.4 MB • 2 Pages"
  static Widget metadataBadge({
    required String format,
    required String sizeString,
    required int pageCount,
    Color? backgroundColor,
    Color? textColor,
  }) {
    final pagesLabel = pageCount == 1 ? '1 Page' : '$pageCount Pages';
    final text = '$format • $sizeString • $pagesLabel';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? darkSlate.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: subtleBorder.withOpacity(0.18),
          width: 1.0,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor ?? textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  /// Tier badge helper: "FREE" or "PRO"
  static Widget tierBadge({
    required bool isPro,
    VoidCallback? onTap,
  }) {
    final widget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isPro
            ? emerald.withOpacity(0.2)
            : indigo.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPro ? emerald : indigoLight,
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPro ? Icons.verified : Icons.lock_open,
            size: 13,
            color: isPro ? emeraldLight : Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            isPro ? 'PRO' : 'FREE',
            style: TextStyle(
              color: isPro ? emeraldLight : Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: widget,
      );
    }
    return widget;
  }

  /// Dark Theme definition for SleekScan
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkSlate,
      primaryColor: indigo,
      colorScheme: const ColorScheme.dark(
        primary: indigo,
        secondary: emerald,
        surface: cardSurface,
        background: darkSlate,
        error: errorRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onBackground: textPrimary,
      ),
      cardTheme: CardThemeData(
        color: cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: borderDark, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSlate,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardSurface,
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderDark, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderDark, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: indigo, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: indigo,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
