import 'package:flutter/widgets.dart';

/// Scrollable screens across the app pad their last child with a fixed
/// bottom value (e.g. 32) that only accounts for visual breathing room —
/// not the device's own bottom inset (gesture bar / 3-button nav). On a
/// device where that inset is tall, the fixed value alone isn't enough and
/// the last widget (an End Meeting / Subscribe button, etc.) ends up
/// partially hidden behind the system nav area.
extension SafeBottomPadding on BuildContext {
  /// [visual] is the breathing room the screen already wants below its last
  /// child; the device's bottom inset is added on top of it, never instead
  /// of it, so screens keep their existing spacing on devices with no
  /// gesture bar and gain exactly enough extra room on devices that do.
  double bottomSafePadding(double visual) =>
      visual + MediaQuery.of(this).padding.bottom;
}
