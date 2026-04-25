import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════
//  MINISTRY COLOR PALETTE
// ═══════════════════════════════════════════════════════
class AppColors {
  // Primary — Deep Navy (وزاري)
  static const primary        = Color(0xFF0D1B2A);
  static const primaryDark    = Color(0xFF060D14);
  static const primaryLight   = Color(0xFF1A3A5C);

  // Accent — Gold (ذهبي رسمي)
  static const accent         = Color(0xFFD4A017);
  static const accentLight    = Color(0xFFE8C547);
  static const accentDark     = Color(0xFF9E7610);

  // Semantic
  static const success        = Color(0xFF1DB954);
  static const successLight   = Color(0xFFE6F9EE);
  static const warning        = Color(0xFFFF9F0A);
  static const warningLight   = Color(0xFFFFF3E0);
  static const error          = Color(0xFFFF3B30);
  static const errorLight     = Color(0xFFFFEBEA);
  static const info           = Color(0xFF007AFF);
  static const infoLight      = Color(0xFFE5F1FF);

  // Maintenance status
  static const maintenance    = Color(0xFFFF9500);
  static const maintenanceLight = Color(0xFFFFF8E1);

  // Surfaces
  static const surface        = Color(0xFFFFFFFF);
  static const surfaceGrey    = Color(0xFFF8F9FD);
  static const surfaceCard    = Color(0xFFFFFFFF);
  static const border         = Color(0xFFEAEFF5);
  static const borderLight    = Color(0xFFF1F5F9);

  // Text
  static const textPrimary    = Color(0xFF0D1B2A);
  static const textSecondary  = Color(0xFF6B7280);
  static const textHint       = Color(0xFFADB5BD);
  static const textOnDark     = Color(0xFFFFFFFF);

  // Gradients
  static const primaryGradient = LinearGradient(
    colors: [primaryDark, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const accentGradient = LinearGradient(
    colors: [accentDark, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const glassOverlay = Color(0x0D000000);

  static get text => null;
}

// ═══════════════════════════════════════════════════════
//  THEME
// ═══════════════════════════════════════════════════════
class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    fontFamily: 'Cairo',
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      error: AppColors.error,
    ),

    scaffoldBackgroundColor: AppColors.surfaceGrey,

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textOnDark,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      titleTextStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textOnDark,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.primary,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        elevation: 0,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.border, width: 1.5),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.accent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      hintStyle: const TextStyle(
        color: AppColors.textHint,
        fontFamily: 'Cairo',
        fontSize: 14,
      ),
    ),

    cardTheme: CardThemeData(
      color: AppColors.surfaceCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.accent,
      unselectedItemColor: AppColors.textHint,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w700),
      unselectedLabelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 11),
    ),
  );
}

// ═══════════════════════════════════════════════════════
//  TEXT STYLES
// ═══════════════════════════════════════════════════════
class AppText {
  static const h1 = TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontFamily: 'Cairo', height: 1.3);
  static const h2 = TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontFamily: 'Cairo', height: 1.35);
  static const h3 = TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontFamily: 'Cairo', height: 1.4);
  static const h4 = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontFamily: 'Cairo', height: 1.4);
  static const body = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary, fontFamily: 'Cairo', height: 1.6);
  static const bodyMed = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontFamily: 'Cairo', height: 1.6);
  static const small = TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary, fontFamily: 'Cairo', height: 1.5);
  static const smallBold = TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary, fontFamily: 'Cairo');
  static const caption = TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textHint, fontFamily: 'Cairo');
}

// ═══════════════════════════════════════════════════════
//  SPACING & RADIUS
// ═══════════════════════════════════════════════════════
class AppSpacing {
  static const xs  = 4.0;
  static const sm  = 8.0;
  static const md  = 16.0;
  static const lg  = 24.0;
  static const xl  = 32.0;
  static const xxl = 48.0;
}

class AppRadius {
  static const sm  = Radius.circular(10);
  static const md  = Radius.circular(16);
  static const lg  = Radius.circular(20);
  static const xl  = Radius.circular(30);
  static const full = Radius.circular(100);
}

// ═══════════════════════════════════════════════════════
//  SHADOWS (Premium UI)
// ═══════════════════════════════════════════════════════
class AppShadows {
  static final soft = [
    BoxShadow(color: AppColors.primaryDark.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 4)),
  ];
  static final medium = [
    BoxShadow(color: AppColors.primaryDark.withOpacity(0.06), blurRadius: 25, offset: const Offset(0, 10)),
  ];
  static final glow = [
    BoxShadow(color: AppColors.accent.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5)),
  ];
  static final deep = [
    BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 40, offset: const Offset(0, 20)),
  ];
}