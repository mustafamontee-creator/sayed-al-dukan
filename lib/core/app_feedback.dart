import 'package:flutter/services.dart';

/// Small platform-aware feedback helpers. Calls can be gated by a manager
/// setting later; keeping feedback centralized makes that switch easy.
class AppFeedback {
  static Future<void> selection() => HapticFeedback.selectionClick();
  static Future<void> lightTap() => HapticFeedback.lightImpact();
}
