
import 'package:flutter/material.dart';

abstract final class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF101014);
  static const Color surface = Color(0xFF1C1B23);
  static const Color elevated = Color(0xFF24242B);

  // Brand
  static const Color primary = Color(0xFFA78BFA);
  static const Color primaryPressed = Color(0xFF8B5CF6);
  static const Color secondary = Color(0xFFF0ABFC);

  // Text
  static const Color textPrimary = Color(0xFFF5F3FF);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textDisabled = Color(0xFF63636F);

  // Borders & Dividers
  static const Color border = Color(0xFF34323D);
  static const Color divider = Color(0xFF2B2933);

  // Semantic
  static const Color success = Color(0xFF4ADE80);
  static const Color error = Color(0xFFFB7185);
  static const Color warning = Color(0xFFFBBF24);
  static const Color info = Color(0xFF60A5FA);

  // Semantic containers (toasts, banners)
  static const Color successContainer = Color(0xFF14532D);
  static const Color onSuccessContainer = Color(0xFFBBF7D0);
  static const Color warningContainer = Color(0xFF78350F);
  static const Color onWarningContainer = Color(0xFFFDE68A);
  static const Color infoContainer = Color(0xFF1E3A5F);
  static const Color onInfoContainer = Color(0xFFDBEAFE);

  // Social sign-in buttons
  static const Color google = Color(0xFFEA4335);
  static const Color facebook = Color(0xFF4285F4);
  static const Color apple = Color(0xFF000000);

  // Shadows (black at increasing opacity)
  static const Color shadow4 = Color(0x0A000000);
  static const Color shadow5 = Color(0x0D000000);
  static const Color shadow6 = Color(0x0F000000);
  static const Color shadow8 = Color(0x14000000);
  static const Color shadow12 = Color(0x1F000000);
  static const Color shadow16 = Color(0x29000000);

  // Interactive States
  static const Color overlay = Color(0x1AFFFFFF);
  static const Color scrim = Color(0x99000000);
  static const Color barrier = Color(0x42000000);
  static const Color shimmer = Color(0xFF2A2932);

  // Artwork & Media
  static const Color imagePlaceholder = Color(0xFF1E1D26);
  static const Color imageOverlay = Color(0x66000000);

  // Special
  static const Color transparent = Colors.transparent;
  static const Color white = Colors.white;
  static const Color black = Colors.black;
}
