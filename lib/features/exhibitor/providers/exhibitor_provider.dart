import 'package:flutter/material.dart';
import '../../../data/models/exhibition_model.dart';
import '../../../data/models/booth_model.dart';
import '../../../data/models/application_model.dart';
import '../../../data/services/exhibition_service.dart';
import '../../../data/services/booth_service.dart';
import '../../../data/services/application_service.dart';

class ExhibitorProvider extends ChangeNotifier {
  final ExhibitionService _exhibitionService = ExhibitionService();
  final BoothService _boothService = BoothService();
  final ApplicationService _applicationService = ApplicationService();

  List<ExhibitionModel> _exhibitions = [];
  List<ExhibitionModel> _filteredExhibitions = [];
  List<BoothModel> _booths = [];
  List<BoothModel> _selectedBooths = [];
  List<ApplicationModel> _applications = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _searchQuery = '';
  String _statusFilter = 'all';

  List<ExhibitionModel> get exhibitions => _filteredExhibitions;
  List<BoothModel> get booths => _booths;
  List<BoothModel> get selectedBooths => _selectedBooths;
  List<ApplicationModel> get applications => _applications;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  double get totalPrice =>
      _selectedBooths.fold(0, (sum, booth) => sum + booth.price);

  // Load published exhibitions
  Future<void> loadExhibitions() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _exhibitions = await _exhibitionService.getPublishedExhibitions();
      _applyFilter();
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Search and filter
  void searchExhibitions(String query) {
    _searchQuery = query;
    _applyFilter();
    notifyListeners();
  }

  void filterByStatus(String status) {
    _statusFilter = status;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    _filteredExhibitions = _exhibitions.where((e) {
      final matchesSearch =
          e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              e.venue.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus =
          _statusFilter == 'all' || e.status == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  // Load booths for an exhibition
  Future<void> loadBooths(String exhibitionId) async {
    _isLoading = true;
    _selectedBooths = [];
    notifyListeners();

    try {
      _booths = await _boothService.getBoothsByExhibition(exhibitionId);
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Select/deselect booth
  void toggleBoothSelection(BoothModel booth) {
    if (booth.status != 'available') return;

    if (_selectedBooths.any((b) => b.id == booth.id)) {
      _selectedBooths.removeWhere((b) => b.id == booth.id);
    } else {
      _selectedBooths.add(booth);
    }
    notifyListeners();
  }

  bool isBoothSelected(String boothId) {
    return _selectedBooths.any((b) => b.id == boothId);
  }

  void clearSelectedBooths() {
    _selectedBooths = [];
    notifyListeners();
  }

  // Load exhibitor applications
  Future<void> loadApplications(String exhibitorId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _applications =
      await _applicationService.getExhibitorApplications(exhibitorId);
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Submit application
  Future<bool> submitApplication({
    required String exhibitorId,
    required String exhibitionId,
    required String companyName,
    required String companyDescription,
    required String exhibitDescription,
    required List<String> additems,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final boothIds = _selectedBooths.map((b) => b.id).toList();

      await _applicationService.submitApplication(
        exhibitorId: exhibitorId,
        exhibitionId: exhibitionId,
        boothIds: boothIds,
        companyName: companyName,
        companyDescription: companyDescription,
        exhibitDescription: exhibitDescription,
        additems: additems,
      );

      // Update booth status to booked
      for (final booth in _selectedBooths) {
        await _boothService.updateBoothStatus(booth.id, 'booked');
      }

      _selectedBooths = [];
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Cancel application
  Future<bool> cancelApplication(String applicationId) async {
    try {
      await _applicationService.cancelApplication(applicationId);
      await loadApplications(
          _applications.first.exhibitorId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update application
  Future<bool> updateApplication(
      String id, Map<String, dynamic> data) async {
    try {
      await _applicationService.updateApplication(id, data);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}