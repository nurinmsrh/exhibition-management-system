import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/exhibitor_provider.dart';
import '../../../data/models/exhibition_model.dart';

class ExhibitionDetailScreen extends StatefulWidget {
  final String exhibitionId;

  const ExhibitionDetailScreen({super.key, required this.exhibitionId});

  @override
  State<ExhibitionDetailScreen> createState() =>
      _ExhibitionDetailScreenState();
}

class _ExhibitionDetailScreenState extends State<ExhibitionDetailScreen> {
  ExhibitionModel? _exhibition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final provider = context.read<ExhibitorProvider>();
    // Find exhibition from already loaded list
    final exhibitions = provider.exhibitions;
    try {
      _exhibition = exhibitions.firstWhere(
            (e) => e.id == widget.exhibitionId,
      );
      setState(() {});
    } catch (e) {
      // Exhibition not found
    }
    provider.loadBooths(widget.exhibitionId);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExhibitorProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_exhibition?.title ?? 'Exhibition Detail'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _exhibition == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exhibition info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _exhibition!.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(_exhibition!.venue,
                          style:
                          const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${_formatDate(_exhibition!.startDate)} - ${_formatDate(_exhibition!.endDate)}',
                        style:
                        const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_exhibition!.description),
                ],
              ),
            ),
            // Floor plan section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Floor Plan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height:8),
                  // Color legend
                  Row(
                    children: [
                      _LegendItem(
                          color: Colors.green, label: 'Available'),
                      const SizedBox(width: 16),
                      _LegendItem(
                          color: Colors.red, label: 'Booked'),
                      const SizedBox(width: 16),
                      _LegendItem(
                          color: Colors.blue, label: 'Selected'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Booth grid
                  provider.isLoading
                      ? const Center(
                      child: CircularProgressIndicator())
                      : provider.booths.isEmpty
                      ? const Center(
                      child: Text('No booths available'))
                      : _BoothGrid(
                    booths: provider.booths,
                    provider: provider,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: provider.selectedBooths.isEmpty
          ? null
          : Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${provider.selectedBooths.length} booth(s) selected',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Total: \$${provider.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.blue),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => context.go(
                  '/exhibitor/exhibition/${widget.exhibitionId}/apply'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Apply Now'),
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

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _BoothGrid extends StatelessWidget {
  final provider;
  final booths;

  const _BoothGrid({required this.booths, required this.provider});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: booths.length,
      itemBuilder: (context, index) {
        final booth = booths[index];
        final isSelected = provider.isBoothSelected(booth.id);

        Color boothColor;
        if (isSelected) {
          boothColor = Colors.blue;
        } else if (booth.status == 'available') {
          boothColor = Colors.green;
        } else {
          boothColor = Colors.red;
        }

        return GestureDetector(
          onTap: () {
            if (booth.status == 'available') {
              provider.toggleBoothSelection(booth);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('This booth is not available')),
              );
            }
            // Show booth details
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Booth ${booth.boothNumber}'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Type: ${booth.type}'),
                    Text('Size: ${booth.size}'),
                    Text('Price: \$${booth.price}'),
                    Text('Status: ${booth.status}'),
                    Text('Amenities: ${booth.amenities.join(', ')}'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  if (booth.status == 'available')
                    ElevatedButton(
                      onPressed: () {
                        provider.toggleBoothSelection(booth);
                        Navigator.pop(context);
                      },
                      child: Text(
                          isSelected ? 'Deselect' : 'Select Booth'),
                    ),
                ],
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: boothColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                booth.boothNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}