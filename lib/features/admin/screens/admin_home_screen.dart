import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/admin_provider.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _totalUsers = 0;
  int _totalExhibitions = 0;
  int _totalApplications = 0;
  int _pendingApplications = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboard();
    });
  }

  Future<void> _loadDashboard() async {
    final provider = context.read<AdminProvider>();
    await Future.wait([
      provider.loadUsers(),
      provider.loadExhibitions(),
      provider.loadApplications(),
    ]);

    if (mounted) {
      setState(() {
        _totalUsers = provider.users.length;
        _totalExhibitions = provider.exhibitions.length;
        _totalApplications = provider.applications.length;
        _pendingApplications = provider.applications
            .where((a) => a.status == 'pending')
            .length;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) context.go('/');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome
            Text(
              'Welcome, ${authProvider.currentUser?.name ?? 'Admin'}!',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Here\'s an overview of the system.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            // Stats grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _StatCard(
                  title: 'Total Users',
                  value: _totalUsers.toString(),
                  icon: Icons.people,
                  color: Colors.blue,
                ),
                _StatCard(
                  title: 'Exhibitions',
                  value: _totalExhibitions.toString(),
                  icon: Icons.event,
                  color: Colors.green,
                ),
                _StatCard(
                  title: 'Applications',
                  value: _totalApplications.toString(),
                  icon: Icons.assignment,
                  color: Colors.orange,
                ),
                _StatCard(
                  title: 'Pending',
                  value: _pendingApplications.toString(),
                  icon: Icons.pending_actions,
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Quick actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _ActionTile(
              icon: Icons.people,
              title: 'Manage Users',
              subtitle: 'View and manage user accounts',
              color: Colors.blue,
              onTap: () => context.go('/admin/users'),
            ),
            _ActionTile(
              icon: Icons.event,
              title: 'Manage Exhibitions',
              subtitle: 'Create, edit, publish exhibitions',
              color: Colors.green,
              onTap: () => context.go('/admin/exhibitions'),
            ),
            _ActionTile(
              icon: Icons.assignment,
              title: 'Manage Applications',
              subtitle: 'View and manage all applications',
              color: Colors.orange,
              onTap: () => context.go('/admin/applications'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}