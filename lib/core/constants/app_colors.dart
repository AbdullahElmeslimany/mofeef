import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ==========================================
  // NEW FIGMA DESIGN PALETTE (MODEEF-E 2.0)
  // ==========================================

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0E0B12);
  static const Color darkBackgroundSecondary = Color(0xFF140F1B);
  static const Color darkSurface = Color(0xFF181321);
  static const Color darkCard = Color(0xFF181321);
  static const Color darkCardAlt = Color(0xFF201A2C);
  static const Color darkBorder = Color(0xFF282035);
  static const Color darkBorderLight = Color(0x26FFFFFF);

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF1ECF5);
  static const Color lightBackgroundSecondary = Color(0xFFE9E2EE);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardAlt = Color(0xFFFAF7FC);
  static const Color lightBorder = Color(0xFFE5DFEB);
  static const Color lightBorderLight = Color(0x330E0B12);

  // Primary Brand Colors (Royal Mauve from Figma)
  static const Color primaryMauve = Color(0xFF654D71);
  static const Color primaryBrand = primaryMauve;
  static const Color primaryMauveDark = Color(0xFF533C5E);
  static const Color primaryMauveLight = Color(0xFF7D628B);
  static const Color primaryMauveSoft = Color(0x1F654D71);

  // Accent Colors (Heritage Amber Gold from Figma)
  static const Color accentGold = Color(0xFFF5A623);
  static const Color accentGoldLight = Color(0xFFFBBF24);
  static const Color accentGoldDark = Color(0xFFD97706);
  static const Color goldGlow = Color(0x33F5A623);

  // Secondary Accents
  static const Color accentTeal = Color(0xFF00BFB8);
  static const Color accentEmerald = Color(0xFF10B981);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentRose = Color(0xFFF43F5E);

  // Text Colors (Dark Mode)
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF9E97A6);
  static const Color darkTextMuted = Color(0xFF686073);

  // Text Colors (Light Mode)
  static const Color lightTextPrimary = Color(0xFF1A1224);
  static const Color lightTextSecondary = Color(0xFF736980);
  static const Color lightTextMuted = Color(0xFF9D94A8);

  // Status Colors
  static const Color success = Color(0xFF34A853);
  static const Color warning = Color(0xFFFBBC05);
  static const Color error = Color(0xFFEA4335);
  static const Color info = Color(0xFF4285F4);

  // Gradients
  static const LinearGradient mauveGradient = LinearGradient(
    colors: [Color(0xFF654D71), Color(0xFF7D628B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF5A623), Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF201A2C), Color(0xFF181321)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient lightCardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFAF7FC)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ==========================================
  // BACKWARD-COMPATIBLE ALIASES
  // (Ensures unmodified code continues to function seamlessly)
  // ==========================================
  static const Color background = darkBackground;
  static const Color backgroundSecondary = darkBackgroundSecondary;
  static const Color surface = darkSurface;
  static const Color card = darkCard;
  static const Color cardAlt = darkCardAlt;
  static const Color border = darkBorder;
  static const Color borderLight = darkBorderLight;

  static const Color primaryGold = accentGold;
  static const Color primaryGoldLight = accentGoldLight;
  static const Color primaryGoldDark = accentGoldDark;

  static const Color textPrimary = darkTextPrimary;
  static const Color textSecondary = darkTextSecondary;
  static const Color textMuted = darkTextMuted;
  static const Color textDark = Color(0xFF0E0B12);
  static const Color textGold = accentGold;

  static const LinearGradient cardGradient = darkCardGradient;
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF1A1224), Color(0xFF0E0B12)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Dynamic Theme Helpers
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color bg(BuildContext context) =>
      isDark(context) ? darkBackground : lightBackground;

  static Color cardBg(BuildContext context) =>
      isDark(context) ? darkCard : lightCard;

  static Color cardAltBg(BuildContext context) =>
      isDark(context) ? darkCardAlt : lightCardAlt;

  static Color borderColor(BuildContext context) =>
      isDark(context) ? darkBorder : lightBorder;

  static Color text(BuildContext context) =>
      isDark(context) ? darkTextPrimary : lightTextPrimary;

  static Color textSub(BuildContext context) =>
      isDark(context) ? darkTextSecondary : lightTextSecondary;

  static Color textSubMuted(BuildContext context) =>
      isDark(context) ? darkTextMuted : lightTextMuted;
}
