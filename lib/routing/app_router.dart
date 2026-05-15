import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/guest/screens/guest_home_screen.dart';
import '../features/exhibitor/screens/exhibitor_home_screen.dart';
import '../features/exhibitor/screens/exhibition_detail_screen.dart';
import '../features/exhibitor/screens/application_form_screen.dart';
import '../features/exhibitor/screens/my_applications_screen.dart';
import '../features/exhibitor/providers/exhibitor_provider.dart';
import '../features/admin/screens/admin_home_screen.dart';
import '../features/admin/screens/admin_users_screen.dart';
import '../features/admin/screens/admin_exhibitions_screen.dart';
import '../features/admin/screens/admin_exhibition_form_screen.dart';
import '../features/admin/screens/admin_booths_screen.dart';
import '../features/admin/screens/admin_booth_form_screen.dart';
import '../features/admin/screens/admin_applications_screen.dart';
import '../features/admin/providers/admin_provider.dart';

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
    // Exhibitor routes
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
    // Organizer routes
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
    // Admin routes
    GoRoute(
      path: '/admin',
      builder: (context, state) => ChangeNotifierProvider(
        create: (_) => AdminProvider(),
        child: const AdminHomeScreen(),
      ),
      routes: [
        GoRoute(
          path: 'users',
          builder: (context, state) => ChangeNotifierProvider(
            create: (_) => AdminProvider(),
            child: const AdminUsersScreen(),
          ),
        ),
        GoRoute(
          path: 'exhibitions',
          builder: (context, state) => ChangeNotifierProvider(
            create: (_) => AdminProvider(),
            child: const AdminExhibitionsScreen(),
          ),
        ),
        GoRoute(
          path: 'exhibitions/create',
          builder: (context, state) => ChangeNotifierProvider(
            create: (_) => AdminProvider(),
            child: const AdminExhibitionFormScreen(),
          ),
        ),
        GoRoute(
          path: 'exhibitions/:id/edit',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return ChangeNotifierProvider(
              create: (_) => AdminProvider(),
              child: AdminExhibitionFormScreen(exhibitionId: id),
            );
          },
        ),
        GoRoute(
          path: 'exhibitions/:id/booths',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return ChangeNotifierProvider(
              create: (_) => AdminProvider(),
              child: AdminBoothsScreen(exhibitionId: id),
            );
          },
        ),
        GoRoute(
          path: 'exhibitions/:id/booths/create',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return ChangeNotifierProvider(
              create: (_) => AdminProvider(),
              child: AdminBoothFormScreen(exhibitionId: id),
            );
          },
        ),
        GoRoute(
          path: 'exhibitions/:id/booths/:boothId/edit',
          builder: (context, state) {
            final exhibitionId = state.pathParameters['id']!;
            final boothId = state.pathParameters['boothId']!;
            return ChangeNotifierProvider(
              create: (_) => AdminProvider(),
              child: AdminBoothFormScreen(
                exhibitionId: exhibitionId,
                boothId: boothId,
              ),
            );
          },
        ),
        GoRoute(
          path: 'applications',
          builder: (context, state) => ChangeNotifierProvider(
            create: (_) => AdminProvider(),
            child: const AdminApplicationsScreen(),
          ),
        ),
      ],
    ),
  ],
);