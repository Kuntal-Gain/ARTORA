import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:artora/src/middleware/app_route_observer.dart';
import 'package:artora/src/routing/global_navigator.dart';
import 'package:artora/src/routing/app_routes.dart';
import 'package:artora/src/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:artora/src/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:artora/src/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:artora/src/features/onboarding/view/welcome_screen.dart';
import 'package:artora/src/features/splash/view/splash_screen.dart';
import 'package:artora/src/shared/widgets/ui/ui_showcase_screen.dart';
import 'package:flutter/foundation.dart';

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.splash,
  observers: <NavigatorObserver>[AppRouteObserver()],
  routes: <RouteBase>[
    GoRoute(
      path: AppRoutes.splash,
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      name: 'onboarding',
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        child: const WelcomeScreen(),
        transitionDuration: const Duration(milliseconds: 800),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, secondary, child) =>
            FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            ),
      ),
    ),
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: AppRoutes.signup,
      name: 'signup',
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      name: 'forgotPassword',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    // GoRoute(
    //   path: AppRoutes.home,
    //   name: 'home',
    //   builder: (context, state) => const HomePage(),
    // ),
    if (kDebugMode)
      GoRoute(
        path: AppRoutes.uiShowcase,
        name: 'uiShowcase',
        builder: (context, state) => const UiShowcaseScreen(),
      ),
  ],
);
