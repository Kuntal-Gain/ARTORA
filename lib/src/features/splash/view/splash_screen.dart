import 'dart:async';

import 'package:artora/src/imports/imports.dart';

/// Branded launch screen: nebula backdrop, logo, tagline and a loading bar.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _loadDuration = Duration(milliseconds: 4200);

  /// Pause on the finished state before moving on.
  static const Duration _holdDuration = Duration(milliseconds: 500);

  late final AnimationController _controller;
  late final Animation<double> _backgroundFade;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _taglineFade;
  late final Animation<Offset> _taglineSlide;
  late final Animation<double> _progressFade;
  late final Animation<double> _progress;
  Timer? _navigateTimer;

  /// Staggers an animation over [begin]..[end] of the total timeline.
  CurvedAnimation _stage(double begin, double end, Curve curve) =>
      CurvedAnimation(
        parent: _controller,
        curve: Interval(begin, end, curve: curve),
      );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _loadDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _navigateTimer = Timer(_holdDuration, () {
            if (mounted) context.go(AppRoutes.onboarding);
          });
        }
      })
      ..forward();

    _backgroundFade = _stage(0, 0.2, Curves.easeOut);
    _logoFade = _stage(0.1, 0.5, Curves.easeInOut);
    _logoScale = Tween<double>(begin: 0.85, end: 1).animate(
      _stage(0.1, 0.6, Curves.easeInOutCubic),
    );
    _taglineFade = _stage(0.4, 0.65, Curves.easeOut);
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(_stage(0.4, 0.65, Curves.easeOutCubic));
    _progressFade = _stage(0.4, 0.55, Curves.easeOut);
    _progress = _stage(0.45, 1, Curves.easeInOut);
    FlutterNativeSplash.remove();
  }

  @override
  void dispose() {
    _navigateTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          FadeTransition(
            opacity: _backgroundFade,
            child: Image.asset(AppAssets.splashBackground, fit: BoxFit.cover),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 5),
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: Semantics(
                      label: 'Artora',
                      child: Image.asset(
                        AppAssets.logo,
                        width: 260.w,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const Spacer(flex: 6),
                FadeTransition(
                  opacity: _taglineFade,
                  child: SlideTransition(
                    position: _taglineSlide,
                    child: Text(
                      LocaleKeys.splash_tagline.tr(),
                      textAlign: TextAlign.center,
                      style: context.textTheme.labelLarge?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.85),
                        letterSpacing: 3.2,
                        height: 1.8,
                      ),
                    ),
                  ),
                ),
                const Spacer(flex: 3),
                FadeTransition(
                  opacity: _progressFade,
                  child: AnimatedBuilder(
                    animation: _progress,
                    builder: (_, __) => ClipRRect(
                      borderRadius: AppBorders.full,
                      child: SizedBox(
                        width: 168.w,
                        height: 4.h,
                        child: LinearProgressIndicator(
                          value: _progress.value,
                          backgroundColor: colors.onSurface.withValues(
                            alpha: 0.18,
                          ),
                          valueColor: AlwaysStoppedAnimation(colors.primary),
                        ),
                      ),
                    ),
                  ),
                ),
                AppSpacing.vGap(AppSpacing.xxl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
