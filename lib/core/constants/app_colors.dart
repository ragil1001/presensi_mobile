import 'package:flutter/material.dart';

class AppColors {
  // ─── Primary (Brand Orange) ───────────────────────────────────
  static const Color primary = Color(0xFFFF9800);
  static const Color primaryDark = Color(0xFFF57C00);
  static const Color primaryLight = Color(0xFFFFB74D);
  static const Color primarySoft = Color(0xFFFFF3E0); // very light tint

  // ─── Secondary (Warm Brown — harmonizes with orange) ──────────
  static const Color secondary = Color(0xFF795548);
  static const Color secondaryDark = Color(0xFF5D4037);
  static const Color secondaryLight = Color(0xFFBCAAA4);
  static const Color secondarySoft = Color(0xFFEFEBE9);

  // ─── Status Colors ────────────────────────────────────────────
  static const Color success = Color(0xFF43A047); // warm green
  static const Color successSoft = Color(0xFFE8F5E9);
  static const Color error = Color(0xFFE53935); // warm red
  static const Color errorSoft = Color(0xFFFFEBEE);
  static const Color warning = Color(0xFFFFA726); // amber (≠ primary)
  static const Color warningSoft = Color(0xFFFFF8E1);
  static const Color info = Color(0xFF00897B); // teal (warm-compatible)
  static const Color infoSoft = Color(0xFFE0F2F1);

  // ─── Neutral Colors ───────────────────────────────────────────
  static const Color white = Colors.white;
  static const Color black = Color(0xFF212121);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color greyLight = Color(0xFFF5F5F5);
  static const Color greyDark = Color(0xFF616161);

  // ─── Background & Surface ────────────────────────────────────
  static const Color background = Color(0xFFFAFBFD);
  static const Color cardBackground = Colors.white;
  static const Color surface = Color(0xFFFFFFFF);

  // ─── Text Colors ──────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  // ─── Utility ──────────────────────────────────────────────────
  static const Color divider = Color(0xFFE0E0E0);
  static const Color shadow = Color(0x1F000000);

  // ─── CS Task Status ─────────────────────────────────────────────
  static const Color statusCompleted = Color(0xFF4CAF50);
  static const Color statusInProgress = Color(0xFFFF9800);
  static const Color statusNotStarted = Color(0xFF9E9E9E);
  static const Color statusNotDone = Color(0xFFF44336);

  // ─── CS Semantic ────────────────────────────────────────────────
  static const Color textTertiary = Color(0xFF9E9E9E);
  static const Color border = Color(0xFFE0E0E0);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color shadowLight = Color(0x0D000000);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
