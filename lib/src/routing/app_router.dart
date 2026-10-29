import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:artora/src/middleware/app_route_observer.dart';
import 'package:artora/src/routing/global_navigator.dart';
import 'package:artora/src/routing/app_routes.dart';
import 'package:artora/src/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:artora/src/features/auth/presentation/screens/profile_setup_screen.dart';
import 'package:artora/src/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:artora/src/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:artora/src/features/discover/model/discover_models.dart';
import 'package:artora/src/features/discover/presentation/screens/explore_screen.dart';
import 'package:artora/src/features/discover/presentation/screens/home_feed_screen.dart';
import 'package:artora/src/features/discover/presentation/screens/saved_screen.dart';
import 'package:artora/src/features/discover/presentation/screens/search_screen.dart';
import 'package:artora/src/features/onboarding/view/welcome_screen.dart';
import 'package:artora/src/features/profile/presentation/screens/profile_screen.dart';
import 'package:artora/src/routing/app_shell.dart';
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
    GoRoute(
      path: AppRoutes.profileSetup,
      name: 'profileSetup',
      builder: (context, state) => const ProfileSetupScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              name: 'home',
              builder: (context, state) => const HomeFeedScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.explore,
              name: 'explore',
              builder: (context, state) => const ExploreScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.saved,
              name: 'saved',
              builder: (context, state) => const SavedScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profile,
              name: 'profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.search,
      name: 'search',
      builder: (context, state) => SearchScreen(
        initialQuery: state.uri.queryParameters['q'] ?? '',
        initialScope:
            SearchScope.values.asNameMap()[state.uri.queryParameters['scope']] ??
            SearchScope.all,
      ),
    ),
    if (kDebugMode)
      GoRoute(
        path: AppRoutes.uiShowcase,
        name: 'uiShowcase',
        builder: (context, state) => const UiShowcaseScreen(),
      ),
  ],
);
