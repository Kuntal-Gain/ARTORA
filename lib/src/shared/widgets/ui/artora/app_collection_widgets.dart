import 'package:artora/src/imports/imports.dart';

/// A rounded box with a dashed outline (drop zones: "Add cover", "Add artworks").
class AppDashedBox extends StatelessWidget {
  const AppDashedBox({
    super.key,
    required this.child,
    this.onTap,
    this.color = AppColors.primary,
    this.fill,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    final radius = AppBorders.lg.topLeft.x;
    return CustomPaint(
      painter: AppDashedBorderPainter(
        color: color.withValues(alpha: 0.6),
        radius: radius,
      ),
      child: Material(
        color: fill ?? color.withValues(alpha: 0.06),
        borderRadius: AppBorders.lg,
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: child),
      ),
    );
  }
}

class AppDashedBorderPainter extends CustomPainter {
  const AppDashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    const dash = 6.0;
    const gap = 5.0;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash + gap) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(AppDashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}

/// Two tilted cards with an image icon: the empty-state / "create" artwork.
/// [badge] adds the round "+" on the front card; [sparkles] the small "+" marks.
class AppStackedCardsArt extends StatelessWidget {
  const AppStackedCardsArt({
    super.key,
    this.badge = false,
    this.sparkles = true,
  });

  final bool badge;
  final bool sparkles;

  @override
  Widget build(BuildContext context) {
    Widget card({required double angle, required Color fill, Widget? child}) =>
        Transform.rotate(
          angle: angle,
          child: Container(
            width: 84.r,
            height: 84.r,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
              ),
            ),
            child: child,
          ),
        );
    Widget plus(Alignment at) => Align(
          alignment: at,
          child: Icon(AppIcons.add, size: 16.r, color: AppColors.primary),
        );

    return SizedBox(
      width: 200.r,
      height: 120.r,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (sparkles) ...[
            plus(const Alignment(-1, -0.4)),
            plus(const Alignment(1, -0.4)),
          ],
          Transform.translate(
            offset: Offset(-22.r, 12.r),
            child: card(
              angle: -0.17,
              fill: AppColors.primary.withValues(alpha: 0.22),
            ),
          ),
          Transform.translate(
            offset: Offset(18.r, -4.r),
            child: card(
              angle: 0.12,
              fill: AppColors.elevated,
              child: Icon(AppIcons.image, size: 38.r, color: AppColors.primary),
            ),
          ),
          if (badge)
            Transform.translate(
              offset: Offset(52.r, 30.r),
              child: Container(
                width: 34.r,
                height: 34.r,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(AppIcons.add, size: 20.r, color: AppColors.white),
              ),
            ),
        ],
      ),
    );
  }
}

/// Wide collection cover with the title and artwork count over a bottom fade.
class AppCollectionCard extends StatelessWidget {
  const AppCollectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String? imageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    return AspectRatio(
      aspectRatio: 1.8,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: AppBorders.lg,
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        ),
        child: ClipRRect(
          borderRadius: AppBorders.lg,
          child: Material(
            color: AppColors.elevated,
            child: InkWell(
              onTap: onTap,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (url == null || url.isEmpty)
                    Icon(AppIcons.layers, size: 40.r, color: AppColors.primary)
                  else
                    CommonImage(imageUrl: url, fit: BoxFit.cover),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.center,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.transparent, AppColors.scrim],
                      ),
                    ),
                  ),
                  Positioned(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    bottom: AppSpacing.ms,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.titleLarge?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: AppColors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
