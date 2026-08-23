import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RooteryTheme {
  static final ValueNotifier<bool> highContrastMode = ValueNotifier<bool>(
    false,
  );
  static double _deviceTextScale = 1.0;

  static void setDeviceTextScaleForWidth(double width) {
    if (width < 360) {
      _deviceTextScale = 0.92;
    } else if (width < 600) {
      _deviceTextScale = 1.0;
    } else {
      _deviceTextScale = 1.08;
    }
  }

  static double get deviceTextScale => _deviceTextScale;

  static Color _adaptiveColor(Color color) {
    if (!highContrastMode.value) return color;
    if (color == textMid || color == textLow) return textHigh;
    if (color == borderLight) return borderMid;
    if (color == green400) return green900;
    return color;
  }

  // Backgrounds
  static const Color bgScaffold = Color(0xFFF5FAF6);
  static const Color bgSurface = Color(0xFFFFFFFF);
  static const Color bgSubtle = Color(0xFFEDF7F0);
  static const Color bgDark = Color(0xFF0F1F14);

  // Primary green ramp
  static const Color green50 = Color(0xFFE8F5ED);
  static const Color green100 = Color(0xFFC2E8CE);
  static const Color green400 = Color(0xFF3DBE6C);
  static const Color green600 = Color(0xFF1F8A45);
  static const Color green900 = Color(0xFF0D3D1E);

  // Semantic
  static const Color amberWarn = Color(0xFFF59E0B);
  static const Color redAlert = Color(0xFFEF4444);
  static const Color blueInfo = Color(0xFF3B82F6);
  static const Color amber50 = Color(0xFFFFFBEB);
  static const Color amber100 = Color(0xFFFDE68A);
  static const Color red50 = Color(0xFFFEF2F2);
  static const Color red100 = Color(0xFFFECACA);

  // Text
  static const Color textHigh = Color(0xFF0F1F14);
  static const Color textMid = Color(0xFF4A7A5A);
  static const Color textLow = Color(0xFF9CB8A5);

  // Borders
  static const Color borderLight = Color(0xFFD6EDE0);
  static const Color borderMid = Color(0xFFB0D4BF);

  // Shared shadow
  static const BoxShadow cardShadow = BoxShadow(
    color: Color(0x0A1F8A45),
    blurRadius: 16,
    offset: Offset(0, 4),
  );

  // Backward compatible aliases
  static const Color bgDeep = bgScaffold;
  static const Color bgCard = bgSurface;
  static const Color bgCard2 = bgSubtle;
  static const Color background = bgScaffold;
  static const Color surface = bgSurface;
  static const Color card = bgSurface;
  static const Color cardHover = bgSubtle;
  static const Color lightGreen = green400;
  static const Color textWhite = textHigh;
  static const Color subText = textMid;
  static const Color iconColor = textMid;
  static const Color success = green400;
  static const Color warning = amberWarn;
  static const Color error = redAlert;
  static const Color info = blueInfo;
  static const Color offline = textLow;
  static const Color primary = green400;
  static const Color accentSecondary = blueInfo;
  static const Color accentGreen = green400;
  static const Color accentGreenDim = green600;
  static const Color accentAmber = amberWarn;
  static const Color accentRed = redAlert;
  static const Color accentBlue = blueInfo;
  static const Color borderSubtle = borderLight;
  static const Color textPrimary = textHigh;
  static const Color textSecondary = textMid;
  static const Color textDim = textLow;

  // Spacing & Shape
  static const double screenHPadding = 16;
  static const double cardPadding = 16;
  static const double cardGap = 12;
  static const double radiusSM = 8;
  static const double radiusMD = 12;
  static const double radiusLG = 20;
  static const double radiusXL = 20;
  static const double radiusRound = 999;

  static const double spaceXS = 4;
  static const double spaceSM = 8;
  static const double spaceMD = 12;
  static const double spaceLG = 16;
  static const double spaceXL = 24;
  static const double space2XL = 32;
  static const double space3XL = 48;

  static TextStyle ui(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = textHigh,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.spaceGrotesk(
      fontSize: size * _deviceTextScale,
      fontWeight: weight,
      color: _adaptiveColor(color),
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle mono(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color color = textHigh,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: size * _deviceTextScale,
      fontWeight: weight,
      color: _adaptiveColor(color),
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle get heading1 => ui(32, weight: FontWeight.w600);
  static TextStyle get heading2 => ui(22, weight: FontWeight.w600);
  static TextStyle get heading3 =>
      ui(13, weight: FontWeight.w500, letterSpacing: 0.3);
  static TextStyle get bodyLarge => ui(16);
  static TextStyle get bodyMedium => ui(14);
  static TextStyle get bodySmall => ui(14, color: textMid);
  static TextStyle get caption => ui(11, color: textLow);
  static TextStyle get label => ui(11, weight: FontWeight.w400, color: textMid);
  static TextStyle get sensorValue =>
      mono(48, weight: FontWeight.w700, letterSpacing: -1);

  // Shadows
  static List<BoxShadow> shadowSM = [cardShadow];

  static List<BoxShadow> shadowMD = [cardShadow];

  static List<BoxShadow> shadowLG = [cardShadow];

  static List<BoxShadow> shadowGlow(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.18),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  static BoxDecoration cardDecoration({
    Color? borderColor,
    double radius = radiusLG,
  }) {
    return BoxDecoration(
      color: bgCard,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _adaptiveColor(borderColor ?? borderLight)),
      boxShadow: const [cardShadow],
    );
  }
}
