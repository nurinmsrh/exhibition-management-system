import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_provider.dart';
import '../../../data/models/booth_model.dart';

class AdminBoothsScreen extends StatefulWidget {
  final String exhibitionId;

  const AdminBoothsScreen({super.key, required this.exhibitionId});

  @override
  State<AdminBoothsScreen> createState() => _AdminBoothsScreenState();
}

class _AdminBoothsScreenState extends State<AdminBoothsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadBooths(widget.exhibitionId);
    });
  }

  Future<void> _deleteBooth(
      BuildContext context, BoothModel booth) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Booth'),
        content: Text(
            'Are you sure you want to delete booth ${booth.boothNumber}?'),
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
      await context
          .read<AdminProvider>()
          .deleteBooth(booth.id, widget.exhibitionId);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'booked':
        return Colors.red;
      case 'unavailable':
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
        title: const Text('Manage Booths'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin/exhibitions'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go(
            '/admin/exhibitions/${widget.exhibitionId}/booths/create'),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.booths.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.store_outlined,
                size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No booths yet'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(
                  '/admin/exhibitions/${widget.exhibitionId}/booths/create'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add First Booth'),
            ),
          ],
        ),
      )
          : Column(
        children: [
          // Floor plan preview
          Container(
            height: 300,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Container(color: Colors.grey.shade100),
                  ...provider.booths.map((booth) {
                    return Positioned(
                      left: booth.positionX,
                      top: booth.positionY,
                      child: GestureDetector(
                        onTap: () => context.go(
                            '/admin/exhibitions/${widget.exhibitionId}/booths/${booth.id}/edit'),
                        child: Container(
                          width: booth.width,
                          height: booth.height,
                          decoration: BoxDecoration(
                            color: _statusColor(booth.status)
                                .withOpacity(0.7),
                            border: Border.all(
                                color:
                                _statusColor(booth.status)),
                            borderRadius:
                            BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              booth.boothNumber,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          // Booth list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  provider.loadBooths(widget.exhibitionId),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16),
                itemCount: provider.booths.length,
                itemBuilder: (context, index) {
                  final booth = provider.booths[index];
                  return Card(
                    margin:
                    const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _statusColor(booth.status)
                              .withOpacity(0.2),
                          borderRadius:
                          BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            booth.boothNumber,
                            style: TextStyle(
                              color:
                              _statusColor(booth.status),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        'Booth ${booth.boothNumber}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${booth.type} • ${booth.size} • \$${booth.price}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _statusColor(booth.status)
                                  .withOpacity(0.1),
                              borderRadius:
                              BorderRadius.circular(12),
                              border: Border.all(
                                  color: _statusColor(
                                      booth.status)),
                            ),
                            child: Text(
                              booth.status.toUpperCase(),
                              style: TextStyle(
                                color:
                                _statusColor(booth.status),
                                fontSize: 10,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit,
                                size: 18),
                            onPressed: () => context.go(
                                '/admin/exhibitions/${widget.exhibitionId}/booths/${booth.id}/edit'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                size: 18, color: Colors.red),
                            onPressed: () =>
                                _deleteBooth(context, booth),
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
}