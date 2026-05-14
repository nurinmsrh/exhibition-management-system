import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/exhibitor_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../data/models/exhibition_model.dart';

class ExhibitorHomeScreen extends StatefulWidget {
  const ExhibitorHomeScreen({super.key});

  @override
  State<ExhibitorHomeScreen> createState() => _ExhibitorHomeScreenState();
}

class _ExhibitorHomeScreenState extends State<ExhibitorHomeScreen> {
  final _searchController = TextEditingController();
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExhibitorProvider>().loadExhibitions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final exhibitorProvider = context.watch<ExhibitorProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exhibitions'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment),
            tooltip: 'My Applications',
            onPressed: () => context.go('/exhibitor/applications'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) context.go('/');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Welcome banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Text(
              'Welcome, ${authProvider.currentUser?.name ?? ''}!',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) =>
                  exhibitorProvider.searchExhibitions(value),
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
          // Status filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['all', 'upcoming', 'ongoing', 'completed']
                  .map((status) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(status.toUpperCase()),
                  selected: _selectedStatus == status,
                  onSelected: (selected) {
                    setState(() => _selectedStatus = status);
                    exhibitorProvider.filterByStatus(status);
                  },
                  selectedColor: Colors.blue,
                  labelStyle: TextStyle(
                    color: _selectedStatus == status
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          // Exhibition list
          Expanded(
            child: exhibitorProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : exhibitorProvider.exhibitions.isEmpty
                ? const Center(child: Text('No exhibitions found'))
                : RefreshIndicator(
              onRefresh: () =>
                  exhibitorProvider.loadExhibitions(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: exhibitorProvider.exhibitions.length,
                itemBuilder: (context, index) {
                  final exhibition =
                  exhibitorProvider.exhibitions[index];
                  return _ExhibitionCard(
                      exhibition: exhibition);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExhibitionCard extends StatelessWidget {
  final ExhibitionModel exhibition;

  const _ExhibitionCard({required this.exhibition});

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    exhibition.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                    _statusColor(exhibition.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _statusColor(exhibition.status)),
                  ),
                  child: Text(
                    exhibition.status.toUpperCase(),
                    style: TextStyle(
                      color: _statusColor(exhibition.status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(exhibition.venue,
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${_formatDate(exhibition.startDate)} - ${_formatDate(exhibition.endDate)}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              exhibition.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go(
                    '/exhibitor/exhibition/${exhibition.id}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('View & Book Booth'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}