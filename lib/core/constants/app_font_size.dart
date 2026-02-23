/// Centralized responsive font scale for the entire app.
///
/// Every page should use these helpers instead of ad-hoc
/// `(screenWidth * X).clamp(Y, Z)` formulas.  This guarantees
/// consistent sizing across all screens.
class AppFontSize {
  // ─── Page-level header title (e.g. "Pengajuan Izin", "Detail Lembur") ──
  static double title(double sw) => (sw * 0.048).clamp(16.0, 20.0);

  // ─── Body / primary content text ──────────────────────────────────────
  static double body(double sw) => (sw * 0.035).clamp(12.0, 15.0);

  // ─── Small / secondary captions, hints, badges ────────────────────────
  static double small(double sw) => (sw * 0.030).clamp(10.0, 13.0);

  // ─── Button labels ────────────────────────────────────────────────────
  static double button(double sw) => (sw * 0.038).clamp(13.0, 15.0);

  // ─── Header back-icon inner size ──────────────────────────────────────
  static double headerIcon(double sw) => (sw * 0.045).clamp(16.0, 18.0);

  // ─── Header icon-box size (width & height) ────────────────────────────
  static double headerIconBox(double sw) => (sw * 0.1).clamp(36.0, 44.0);

  // ─── CS additional scales ─────────────────────────────────────────────
  static double caption(double sw) => (sw * 0.028).clamp(9.0, 12.0);
  static double paddingH(double sw) => (sw * 0.042).clamp(14.0, 20.0);
  static double paddingV(double sw) => (sw * 0.035).clamp(12.0, 18.0);
  static double cardRadius(double sw) => (sw * 0.035).clamp(12.0, 16.0);
  static double iconSize(double sw) => (sw * 0.060).clamp(20.0, 28.0);
}
