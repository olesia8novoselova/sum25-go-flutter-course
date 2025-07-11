import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sum25_flutter_frontend/screens/activity/activity_history_screen.dart';
import 'package:sum25_flutter_frontend/screens/activity/activity_log_screen.dart';
import 'package:sum25_flutter_frontend/screens/nutrition/nutrition_screen.dart';
import 'screens/user/profile_screen.dart';
import 'screens/user/all_achievements_screen.dart';
import 'screens/user/auth_screen.dart';
import 'screens/user/register_screen.dart';
import 'screens/main_shell.dart';
import 'screens/activity/step_dashboard_screen.dart';
import 'screens/activity/step_history_screen.dart';


void main() {
  runApp(const ProviderScope(child: CourseApp()));
}

class CourseApp extends StatelessWidget {
  const CourseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Activity Tracker Auth',
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: Colors.white,
          secondary: const Color(0xFFF8BBD0), // Soft pink
        ),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/profile',
  routes: [
    /// Main area with bottom navigation (footer)
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        // Detect current tab index based on route
        final location = state.fullPath;
        int idx = 0;
        if (location!.startsWith('/nutrition')) idx = 0;
        else if (location.startsWith('/steps')) idx = 1;
        else if (location.startsWith('/activities')) idx = 2;
        else if (location.startsWith('/profile')) idx = 3;
        else {
          return Text('Unknown route');
        }
        return MainShell(
          child: child,
          currentIndex: idx,
          onTabTapped: (i) {
            switch (i) {
              case 0:
                context.go('/nutrition');
                break;
              case 1:
                context.go('/steps');
                break;
              case 2:
                context.go('/activities');
                break;
              case 3:
                context.go('/profile');
                break;
            }
          },
        );
      },
      routes: [
        GoRoute(
          path: '/nutrition',
          builder: (context, state) => NutritionScreen(),
        ),
        GoRoute(
          path: '/steps',
          builder: (context, state) => StepDashboardScreen(),
        ),
        GoRoute(
          path: '/activities',
          builder: (context, state) => ActivityLogScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => ProfileScreen(),
        ),
      ],
    ),
    /// Routes OUTSIDE the shell (no footer)
    GoRoute(
      path: '/',
      builder: (context, state) => AuthScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => RegisterScreen(),
    ),
    GoRoute(
      path: '/all_achievements',
      builder: (context, state) => AllAchievementsScreen(),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const ActivityHistoryScreen(),
    ),
    GoRoute(
      path: '/steps',
      builder: (context, state) => StepDashboardScreen(),
    ),
    GoRoute(
      path: '/steps/history',
      builder: (context, state) => StepHistoryScreen(),
    ),
  ],
);