import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Spacing system on a 4-pt base unit (8-pt rhythm for layout).
///
/// Three layers, use the highest one that fits:
/// 1. **Semantic** (`pagePadding`, `sectionGap`, `insetCard`, …) — preferred in features.
/// 2. **Scale** (`xs`, `sm`, `md`, …) — when no semantic name fits.
/// 3. **Raw** values never appear outside this file.
///
/// ```dart
/// Padding(padding: AppSpacing.insetPage, child: ...)
/// SizedBox(height: AppSpacing.sectionGap)
/// ```
abstract final class AppSpacing {
  AppSpacing._();

  // ── Scale (4-pt base) ─────────────────────────────────────────────────────

  static const double _xxs = 2;
  static const double _xs = 4;
  static const double _sm = 8;
  static const double _ms = 12;
  static const double _md = 16;
  static const double _ml = 20;
  static const double _lg = 24;
  static const double _xl = 32;
  static const double _xxl = 48;
  static const double _xxxl = 64;

  /// 2 — hairline gap, icon-to-label spacing.
  static double get xxs => _xxs.r;

  /// 4 — tightest spacing between tightly coupled elements.
  static double get xs => _xs.r;

  /// 8 — compact component padding, minimum gap between touch targets.
  static double get sm => _sm.r;

  /// 12 — dense inner padding, input vertical padding.
  static double get ms => _ms.r;

  /// 16 — base unit: page gutter, card padding, list item gaps.
  static double get md => _md.r;

  /// 20 — comfortable grouping.
  static double get ml => _ml.r;

  /// 24 — gap between content groups.
  static double get lg => _lg.r;

  /// 32 — major section breaks, hero padding.
  static double get xl => _xl.r;

  /// 48 — empty states, top-of-page offsets.
  static double get xxl => _xxl.r;

  /// 64 — maximum: full-bleed headers, large vertical rhythm.
  static double get xxxl => _xxxl.r;

  // ── Semantic: gaps ────────────────────────────────────────────────────────

  /// Standard horizontal page margin.
  static double get pagePadding => md;

  /// Vertical gap between major page sections.
  static double get sectionGap => xl;

  /// Vertical gap between related blocks inside a section.
  static double get groupGap => lg;

  /// Gap between list/grid items.
  static double get itemGap => sm;

  /// Gap between a label/title and its supporting content.
  static double get labelGap => xs;

  /// Horizontal gap between inline elements (icon + text, chip rows).
  static double get inlineGap => sm;

  /// Vertical gap between form fields.
  static double get formFieldGap => ms;

  /// Gap between a form's last field and its primary action.
  static double get formActionGap => lg;

  /// Minimum gap between adjacent touch targets (UX: ≥ 8).
  static double get touchGap => sm;

  // ── Semantic: padding values ──────────────────────────────────────────────

  /// Inner padding for cards.
  static double get cardPadding => md;

  /// Inner padding for dialogs and bottom sheets.
  static double get sheetPadding => lg;

  /// Horizontal padding inside buttons.
  static double get buttonPaddingX => lg;

  /// Vertical padding inside buttons.
  static double get buttonPaddingY => ms;

  // ── Insets (ready-made EdgeInsets) ────────────────────────────────────────

  /// Screen content: horizontal gutter only.
  static EdgeInsets get insetPage =>
      EdgeInsets.symmetric(horizontal: pagePadding);

  /// Screen content: gutter plus vertical breathing room.
  static EdgeInsets get insetScreen =>
      EdgeInsets.symmetric(horizontal: pagePadding, vertical: md);

  /// Cards and tiles.
  static EdgeInsets get insetCard => EdgeInsets.all(cardPadding);

  /// Dense cards / list rows.
  static EdgeInsets get insetCompact =>
      EdgeInsets.symmetric(horizontal: ms, vertical: sm);

  /// List tiles: wide horizontal, tight vertical.
  static EdgeInsets get insetListTile =>
      EdgeInsets.symmetric(horizontal: md, vertical: sm);

  /// Dialogs and bottom sheets.
  static EdgeInsets get insetSheet => EdgeInsets.all(sheetPadding);

  /// Text fields content padding.
  static EdgeInsets get insetField =>
      EdgeInsets.symmetric(horizontal: md, vertical: ms);

  /// Buttons.
  static EdgeInsets get insetButton => EdgeInsets.symmetric(
        horizontal: buttonPaddingX,
        vertical: buttonPaddingY,
      );

  /// Chips, badges, tags.
  static EdgeInsets get insetChip =>
      EdgeInsets.symmetric(horizontal: ms, vertical: xs);

  // ── Gap widgets ───────────────────────────────────────────────────────────

  /// Vertical spacer: `AppSpacing.vGap(AppSpacing.md)`.
  static SizedBox vGap(double height) => SizedBox(height: height);

  /// Horizontal spacer: `AppSpacing.hGap(AppSpacing.sm)`.
  static SizedBox hGap(double width) => SizedBox(width: width);

  static SizedBox get vSection => SizedBox(height: sectionGap);
  static SizedBox get vGroup => SizedBox(height: groupGap);
  static SizedBox get vItem => SizedBox(height: itemGap);
  static SizedBox get vField => SizedBox(height: formFieldGap);
  static SizedBox get hInline => SizedBox(width: inlineGap);

  // ── Touch targets (dp, deliberately not scaled) ───────────────────────────

  /// iOS minimum touch target (HIG).
  static const double touchTargetIos = 44;

  /// Android / Material minimum touch target.
  static const double touchTargetMaterial = 48;

  /// Cross-platform minimum: use for any tappable area.
  static const double touchTarget = touchTargetMaterial;

  // ── Layout constraints ────────────────────────────────────────────────────

  /// Max readable content width on tablets / desktop / web.
  static const double maxContentWidth = 640;

  /// Max width for forms and auth screens.
  static const double maxFormWidth = 420;
}
