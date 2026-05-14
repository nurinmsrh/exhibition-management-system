import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/exhibitor_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../data/models/application_model.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() =>
      _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      context
          .read<ExhibitorProvider>()
          .loadApplications(authProvider.currentUser!.uid);
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Future<void> _cancelApplication(
      BuildContext context, ApplicationModel application) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Application'),
        content:
        const Text('Are you sure you want to cancel this application?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style:
            ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await context
          .read<ExhibitorProvider>()
          .cancelApplication(application.id);
    }
  }

  void _editApplication(
      BuildContext context, ApplicationModel application) {
    final companyDescController =
    TextEditingController(text: application.companyDescription);
    final exhibitDescController =
    TextEditingController(text: application.exhibitDescription);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Application'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: companyDescController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Company Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: exhibitDescController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Exhibit Description',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await context.read<ExhibitorProvider>().updateApplication(
                application.id,
                {
                  'companyDescription': companyDescController.text.trim(),
                  'exhibitDescription': exhibitDescController.text.trim(),
                },
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExhibitorProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Applications'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/exhibitor'),
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.applications.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_outlined,
                size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No applications yet'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/exhibitor'),
              child: const Text('Browse Exhibitions'),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: () {
          final authProvider = context.read<AuthProvider>();
          return provider
              .loadApplications(authProvider.currentUser!.uid);
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.applications.length,
          itemBuilder: (context, index) {
            final application = provider.applications[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            application.companyName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor(application.status)
                                .withOpacity(0.1),
                            borderRadius:
                            BorderRadius.circular(20),
                            border: Border.all(
                                color: _statusColor(
                                    application.status)),
                          ),
                          child: Text(
                            application.status.toUpperCase(),
                            style: TextStyle(
                              color: _statusColor(
                                  application.status),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Booths: ${application.boothIds.length}',
                      style:
                      const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Submitted: ${_formatDate(application.createdAt)}',
                      style:
                      const TextStyle(color: Colors.grey),
                    ),
                    if (application.rejectionReason.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius:
                            BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Reason: ${application.rejectionReason}',
                            style: const TextStyle(
                                color: Colors.red),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    // Action buttons
                    if (application.status == 'pending')
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _editApplication(
                                  context, application),
                              icon: const Icon(Icons.edit,
                                  size: 16),
                              label: const Text('Edit'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _cancelApplication(
                                      context, application),
                              icon: const Icon(Icons.cancel,
                                  size: 16),
                              label: const Text('Cancel'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(
                                    color: Colors.red),
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (application.status == 'approved')
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _cancelApplication(
                              context, application),
                          icon: const Icon(Icons.cancel,
                              size: 16),
                          label: const Text('Cancel Booking'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(
                                color: Colors.red),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}