import 'package:flutter/material.dart';

/// Masar's brand colors for رفيق's welcome (design/README.md, design/mentor/rafeeq2d.mjs).
// TODO(salah): move these into AppColors in presentation/themes/tokens.dart
// (this branch may only touch screens/mentor/), then point this file at them.
abstract final class RafeeqColors {
  static const navy = Color(0xFF24477B);
  static const teal = Color(0xFF44BFB7);

  /// The very soft halo behind رفيق, fading to nothing at the edge.
  static final glow = teal.withValues(alpha: 0.22);
  static final glowEdge = teal.withValues(alpha: 0);
}
