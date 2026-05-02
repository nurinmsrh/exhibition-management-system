import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/guest/screens/guest_home_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final authProvider = context.read<AuthProvider>();
    final isLoggedIn = authProvider.isLoggedIn;
    final role = authProvider.userRole;
    final location = state.matchedLocation;

    // If not logged in and trying to access protected routes
    if (!isLoggedIn) {
      if (location.startsWith('/admin') ||
          location.startsWith('/organizer') ||
          location.startsWith('/exhibitor')) {
        return '/login';
      }
    }

    // If logged in and trying to access auth screens
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
      builder: (context, state) => const Scaffold(
        body: Center(child: Text('Organizer Home - Coming Soon')),
      ),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const Scaffold(
        body: Center(child: Text('Admin Home - Coming Soon')),
      ),
    ),
    GoRoute(
      path: '/exhibitor',
      builder: (context, state) => const Scaffold(
        body: Center(child: Text('Exhibitor Home - Coming Soon')),
      ),
    ),
  ],
);