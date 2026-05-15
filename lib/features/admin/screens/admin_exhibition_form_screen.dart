import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_provider.dart';
import '../../../data/models/exhibition_model.dart';

class AdminExhibitionFormScreen extends StatefulWidget {
  final String? exhibitionId;

  const AdminExhibitionFormScreen({super.key, this.exhibitionId});

  @override
  State<AdminExhibitionFormScreen> createState() =>
      _AdminExhibitionFormScreenState();
}

class _AdminExhibitionFormScreenState
    extends State<AdminExhibitionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _venueController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  String _status = 'upcoming';
  bool _isLoading = false;
  ExhibitionModel? _exhibition;

  @override
  void initState() {
    super.initState();
    if (widget.exhibitionId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadExhibition();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  void _loadExhibition() {
    final provider = context.read<AdminProvider>();
    try {
      _exhibition = provider.exhibitions.firstWhere(
            (e) => e.id == widget.exhibitionId,
      );
      _titleController.text = _exhibition!.title;
      _descriptionController.text = _exhibition!.description;
      _venueController.text = _exhibition!.venue;
      _startDate = _exhibition!.startDate;
      _endDate = _exhibition!.endDate;
      _status = _exhibition!.status;
      setState(() {});
    } catch (e) {
      // Exhibition not found
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('End date must be after start date')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final provider = context.read<AdminProvider>();
    bool success;

    if (widget.exhibitionId == null) {
      success = await provider.createExhibition(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        venue: _venueController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        organizerId: 'admin',
      );
    } else {
      success = await provider.updateExhibition(
        widget.exhibitionId!,
        {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'venue': _venueController.text.trim(),
          'startDate': _startDate,
          'endDate': _endDate,
          'status': _status,
        },
      );
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.exhibitionId == null
              ? 'Exhibition created!'
              : 'Exhibition updated!'),
        ),
      );
      context.go('/admin/exhibitions');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exhibitionId == null
            ? 'Create Exhibition'
            : 'Edit Exhibition'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin/exhibitions'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Exhibition Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.event),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _venueController,
                decoration: const InputDecoration(
                  labelText: 'Venue',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              // Start date
              InkWell(
                onTap: () => _pickDate(true),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Start Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(_formatDate(_startDate)),
                ),
              ),
              const SizedBox(height: 16),
              // End date
              InkWell(
                onTap: () => _pickDate(false),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'End Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(_formatDate(_endDate)),
                ),
              ),
              const SizedBox(height: 16),
              // Status (edit only)
              if (widget.exhibitionId != null) ...[
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.info),
                  ),
                  items: ['upcoming', 'ongoing', 'completed']
                      .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.toUpperCase()),
                  ))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _status = value!),
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                      color: Colors.white)
                      : Text(
                    widget.exhibitionId == null
                        ? 'Create Exhibition'
                        : 'Save Changes',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}