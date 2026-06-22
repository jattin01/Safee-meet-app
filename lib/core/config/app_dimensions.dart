/// Centralized sizing constants — corner radii and spacing — shared across
/// the app's light-theme screens so values aren't repeated/hand-typed in
/// every widget. Pair with [AppColors] for centralized color management.
abstract final class AppRadius {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 16;
  static const double xl = 18;
  static const double xxl = 20;
  static const double header = 28;
  static const double pill = 24;
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}
