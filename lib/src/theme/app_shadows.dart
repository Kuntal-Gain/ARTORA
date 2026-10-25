import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Predefined box shadows aligned with Material 3 elevation tiers.
///
/// Usage:
/// ```dart
/// Container(
///   decoration: BoxDecoration(
///     boxShadow: AppShadows.card,
///   ),
/// )
/// ```
abstract final class AppShadows {
  AppShadows._();

  /// No shadow — flat, tonal surface (elevation 0).
  static const List<BoxShadow> none = [];

  /// Minimal shadow — barely lifted surfaces (elevation 1).
  /// Use for: toggle surfaces, filled cards on white background.
  static const List<BoxShadow> subtle = [
    BoxShadow(
      color: AppColors.shadow5,
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  /// Card shadow — clearly elevated content (elevation 2–3).
  /// Use for: cards, list items that are tappable, floating elements.
  static const List<BoxShadow> card = [
    BoxShadow(
      color: AppColors.shadow8,
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: AppColors.shadow4,
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  /// Elevated shadow — significantly raised surface (elevation 6–8).
  /// Use for: FABs, dropdown menus, tooltips.
  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: AppColors.shadow12,
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
    BoxShadow(
      color: AppColors.shadow6,
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  /// Modal shadow — overlay surfaces, dialogs, bottom sheets (elevation 12+).
  /// Use for: dialogs, modals, side sheets.
  static const List<BoxShadow> modal = [
    BoxShadow(
      color: AppColors.shadow16,
      blurRadius: 32,
      offset: Offset(0, 12),
    ),
    BoxShadow(
      color: AppColors.shadow8,
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];
}
