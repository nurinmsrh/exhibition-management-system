import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_provider.dart';
import '../../../data/models/exhibition_model.dart';

class AdminExhibitionsScreen extends StatefulWidget {
  const AdminExhibitionsScreen({super.key});

  @override
  State<AdminExhibitionsScreen> createState() =>
      _AdminExhibitionsScreenState();
}

class _AdminExhibitionsScreenState extends State<AdminExhibitionsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadExhibitions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteExhibition(
      BuildContext context, ExhibitionModel exhibition) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exhibition'),
        content: Text(
            'Are you sure you want to delete "${exhibition.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style:
            ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await context.read<AdminProvider>().deleteExhibition(exhibition.id);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ongoing':
        return Colors.green;
      case 'upcoming':
        return Colors.blue;
      case 'completed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Exhibitions'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/admin/exhibitions/create'),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) =>
                  provider.searchExhibitions(value),
              decoration: InputDecoration(
                hintText: 'Search exhibitions...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.exhibitions.isEmpty
                ? const Center(child: Text('No exhibitions found'))
                : RefreshIndicator(
              onRefresh: () => provider.loadExhibitions(),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16),
                itemCount: provider.exhibitions.length,
                itemBuilder: (context, index) {
                  final exhibition =
                  provider.exhibitions[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  exhibition.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets
                                    .symmetric(
                                    horizontal: 8,
                                    vertical: 2),
                                decoration: BoxDecoration(
                                  color: _statusColor(
                                      exhibition.status)
                                      .withOpacity(0.1),
                                  borderRadius:
                                  BorderRadius.circular(12),
                                  border: Border.all(
                                      color: _statusColor(
                                          exhibition.status)),
                                ),
                                child: Text(
                                  exhibition.status
                                      .toUpperCase(),
                                  style: TextStyle(
                                    color: _statusColor(
                                        exhibition.status),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            exhibition.venue,
                            style: const TextStyle(
                                color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatDate(exhibition.startDate)} - ${_formatDate(exhibition.endDate)}',
                            style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          // Published toggle
                          Row(
                            children: [
                              const Text('Published:'),
                              Switch(
                                value: exhibition.isPublished,
                                onChanged: (value) =>
                                    provider.togglePublish(
                                        exhibition.id, value),
                                activeColor: Colors.deepPurple,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => context.go(
                                      '/admin/exhibitions/${exhibition.id}/booths'),
                                  icon: const Icon(
                                      Icons.map_outlined,
                                      size: 16),
                                  label:
                                  const Text('Booths'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => context.go(
                                      '/admin/exhibitions/${exhibition.id}/edit'),
                                  icon: const Icon(Icons.edit,
                                      size: 16),
                                  label: const Text('Edit'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _deleteExhibition(
                                          context, exhibition),
                                  icon: const Icon(
                                      Icons.delete,
                                      size: 16),
                                  label:
                                  const Text('Delete'),
                                  style:
                                  OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(
                                        color: Colors.red),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}