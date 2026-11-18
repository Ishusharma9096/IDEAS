import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goabusconnect/features/information/presentation/information_screens.dart';
import 'package:goabusconnect/features/transit/presentation/transit_screens.dart';
import 'package:goabusconnect/features/transit/presentation/directory_screens.dart';
import 'package:goabusconnect/features/operator/operator_screen.dart';
import 'package:goabusconnect/features/owner/owner_screens.dart';
import 'package:goabusconnect/features/map/passenger_map_screen.dart';
import 'package:goabusconnect/features/auth/auth_screen.dart';
import 'package:goabusconnect/screens/main_navigation.dart';
import 'package:goabusconnect/screens/onboarding_screen.dart';
import 'package:goabusconnect/screens/profile_screen.dart';
import 'package:goabusconnect/screens/splash_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const MainNavigationScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
    GoRoute(
      path: '/roles',
      builder: (context, state) => const RoleChooserScreen(),
    ),
    GoRoute(
      path: '/operator',
      builder: (context, state) => const OperatorScreen(),
    ),
    GoRoute(
      path: '/owner',
      builder: (context, state) => const OwnerDashboardScreen(),
    ),
    GoRoute(
      path: '/owner/live-gps',
      builder: (context, state) => const OwnerGpsMonitorScreen(),
    ),
    GoRoute(
      path: '/owner/manage/:table',
      builder: (context, state) =>
          OwnerManagerScreen(table: state.pathParameters['table'] ?? 'buses'),
    ),
    GoRoute(
      path: '/stop-details',
      builder: (context, state) =>
          StopDetailScreen(id: state.uri.queryParameters['id'] ?? ''),
    ),
    GoRoute(
      path: '/results',
      builder: (context, state) => DemoResultsScreen(
        from: state.uri.queryParameters['from'] ?? '',
        to: state.uri.queryParameters['to'] ?? '',
        date: state.uri.queryParameters['date'] ?? '',
      ),
    ),
    GoRoute(
      path: '/bus-details',
      builder: (context, state) => DemoBusDetailsScreen(
        id: state.uri.queryParameters['id'] ?? '',
        from: state.uri.queryParameters['from'] ?? '',
        to: state.uri.queryParameters['to'] ?? '',
        date: state.uri.queryParameters['date'] ?? '',
      ),
    ),
    GoRoute(
      path: '/routes',
      builder: (context, state) => const RouteDirectoryScreen(),
    ),
    GoRoute(
      path: '/route-details',
      builder: (context, state) =>
          RouteDetailScreen(id: state.uri.queryParameters['id'] ?? ''),
    ),
    GoRoute(
      path: '/stops',
      builder: (context, state) => const StopDirectoryScreen(),
    ),
    GoRoute(
      path: '/tracking',
      builder: (context, state) => PassengerMapScreen(
        busId: state.uri.queryParameters['busId'],
        from: state.uri.queryParameters['from'] ?? '',
        to: state.uri.queryParameters['to'] ?? '',
      ),
    ),
    GoRoute(
      path: '/reports',
      builder: (context, state) => PassengerComplaintScreen(
        busId: state.uri.queryParameters['busId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => InformationScreens.alerts(),
    ),
    GoRoute(
      path: '/offers',
      builder: (context, state) => InformationScreens.offers(),
    ),
    GoRoute(
      path: '/about-data',
      builder: (context, state) => InformationScreens.aboutData(),
    ),
  ],
  errorBuilder: (context, state) =>
      Scaffold(body: Center(child: Text('Page not found: ${state.uri.path}'))),
);
