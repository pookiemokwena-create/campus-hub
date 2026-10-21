import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:ncv_companion/core/router/app_routes.dart';
import 'package:ncv_companion/core/router/router_refresh.dart';
import 'package:ncv_companion/core/services/supabase_service.dart';
import 'package:ncv_companion/core/widgets/app_shell.dart';
import 'package:ncv_companion/features/ai_tutor/presentation/ai_tutor_screen.dart';
import 'package:ncv_companion/features/auth/presentation/auth_screen.dart';
import 'package:ncv_companion/features/dashboard/presentation/dashboard_screen.dart';
import 'package:ncv_companion/features/icass/presentation/icass_calculator_screen.dart';
import 'package:ncv_companion/features/past_papers/presentation/past_paper_library_screen.dart';
import 'package:ncv_companion/features/past_papers/presentation/pdf_reader_screen.dart';

part 'app_router.g.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Single GoRouter instance for the app.
///
/// Auth guard: the session is read from the Supabase client, which restores it
/// from local storage. This means the guard works offline. Students who have
/// logged in before go straight to the dashboard without needing a network.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final supabase = ref.watch(supabaseProvider);
  final refresh = GoRouterRefreshStream(supabase.auth.onAuthStateChange);

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn = supabase.auth.currentSession != null;
      final onAuthScreen = state.matchedLocation == AppRoutes.auth;

      if (!loggedIn) {
        return onAuthScreen ? null : AppRoutes.auth;
      }
      if (onAuthScreen) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.auth,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: AppRoutes.pdfReaderPattern,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => PdfReaderScreen(
          paperId: state.pathParameters['paperId']!,
        ),
      ),
      // Four independent navigation stacks, one per bottom-nav tab.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.icass,
                builder: (context, state) => const IcassCalculatorScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.papers,
                builder: (context, state) => const PastPaperLibraryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.tutor,
                builder: (context, state) => const AiTutorScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });

  return router;
}
