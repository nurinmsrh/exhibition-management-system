import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/exhibitor/screens/guest_home_screen.dart';
import '../features/exhibitor/screens/exhibitor_home_screen.dart';
import '../features/exhibitor/screens/exhibition_detail_screen.dart';
import '../features/exhibitor/screens/application_form_screen.dart';
import '../features/exhibitor/screens/my_applications_screen.dart';
import '../features/exhibitor/providers/exhibitor_provider.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final authProvider = context.read<AuthProvider>();
    final isLoggedIn = authProvider.isLoggedIn;
    final role = authProvider.userRole;
    final location = state.matchedLocation;

    if (!isLoggedIn) {
      if (location.startsWith('/admin') ||
          location.startsWith('/organizer') ||
          location.startsWith('/exhibitor')) {
        return '/login';
      }
    }

    if (isLoggedIn) {
      if (location == '/login' || location == '/register') {
        if (role == 'admin') return '/admin';
        if (role == 'organizer') return '/organizer';
        return '/exhibitor';
      }
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const GuestHomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/organizer',
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: const Text('Organizer Home'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                context.go('/');
              },
            ),
          ],
        ),
        body: const Center(child: Text('Organizer Home - Coming Soon')),
      ),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: const Text('Admin Home'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                context.go('/');
              },
            ),
          ],
        ),
        body: const Center(child: Text('Admin Home - Coming Soon')),
      ),
    ),
    GoRoute(
      path: '/exhibitor',
      builder: (context, state) => ChangeNotifierProvider(
        create: (_) => ExhibitorProvider(),
        child: const ExhibitorHomeScreen(),
      ),
      routes: [
        GoRoute(
          path: 'exhibition/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return ChangeNotifierProvider(
              create: (_) => ExhibitorProvider(),
              child: ExhibitionDetailScreen(exhibitionId: id),
            );
          },
        ),
        GoRoute(
          path: 'exhibition/:id/apply',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return ChangeNotifierProvider(
              create: (_) => ExhibitorProvider(),
              child: ApplicationFormScreen(exhibitionId: id),
            );
          },
        ),
        GoRoute(
          path: 'applications',
          builder: (context, state) => ChangeNotifierProvider(
            create: (_) => ExhibitorProvider(),
            child: const MyApplicationsScreen(),
          ),
        ),
      ],
    ),
  ],
);