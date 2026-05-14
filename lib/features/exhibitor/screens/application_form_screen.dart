import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/exhibitor_provider.dart';
import '../../auth/providers/auth_provider.dart';

class ApplicationFormScreen extends StatefulWidget {
  final String exhibitionId;

  const ApplicationFormScreen({super.key, required this.exhibitionId});

  @override
  State<ApplicationFormScreen> createState() =>
      _ApplicationFormScreenState();
}

class _ApplicationFormScreenState extends State<ApplicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _companyDescController = TextEditingController();
  final _exhibitDescController = TextEditingController();
  final List<String> _selectedAdditems = [];

  final List<String> _availableAdditems = [
    'Extra Furniture',
    'Promotional Spot',
    'Extended WiFi',
    'Extra Power Outlets',
    'Display Screen',
    'Storage Space',
  ];

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyDescController.dispose();
    _exhibitDescController.dispose();
    super.dispose();
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    final exhibitorProvider = context.read<ExhibitorProvider>();
    final authProvider = context.read<AuthProvider>();

    if (exhibitorProvider.selectedBooths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one booth')),
      );
      return;
    }

    final success = await exhibitorProvider.submitApplication(
      exhibitorId: authProvider.currentUser!.uid,
      exhibitionId: widget.exhibitionId,
      companyName: _companyNameController.text.trim(),
      companyDescription: _companyDescController.text.trim(),
      exhibitDescription: _exhibitDescController.text.trim(),
      additems: _selectedAdditems,
    );

    if (success && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Application Submitted!'),
          content: const Text(
              'Your application is now pending review. You will be notified once the organizer reviews it.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/exhibitor/applications');
              },
              child: const Text('View My Applications'),
            ),
          ],
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(exhibitorProvider.errorMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final exhibitorProvider = context.watch<ExhibitorProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Form'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selected booths summary
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selected Booths',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: exhibitorProvider.selectedBooths
                            .map((booth) => Chip(
                          label: Text(booth.boothNumber),
                          backgroundColor: Colors.blue,
                          labelStyle: const TextStyle(
                              color: Colors.white),
                        ))
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total: \$${exhibitorProvider.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Company Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _companyNameController,
                decoration: const InputDecoration(
                  labelText: 'Company Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _companyDescController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Company Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              const Text(
                'Exhibit Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _exhibitDescController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'What will you showcase?',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.store),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              const Text(
                'Additional Items',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select any additional items you need:',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableAdditems
                    .map((item) => FilterChip(
                  label: Text(item),
                  selected: _selectedAdditems.contains(item),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedAdditems.add(item);
                      } else {
                        _selectedAdditems.remove(item);
                      }
                    });
                  },
                  selectedColor: Colors.blue,
                  labelStyle: TextStyle(
                    color: _selectedAdditems.contains(item)
                        ? Colors.white
                        : Colors.black,
                  ),
                ))
                    .toList(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: exhibitorProvider.isLoading
                      ? null
                      : _submitApplication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: exhibitorProvider.isLoading
                      ? const CircularProgressIndicator(
                      color: Colors.white)
                      : const Text('Submit Application',
                      style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}