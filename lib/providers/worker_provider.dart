import 'package:flutter/foundation.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

/// Sort options for workers list
enum WorkerSortOption { rating, reviewCount, priceHigh, priceLow, name }

/// Provider for managing workers list and search
class WorkerProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<UserModel> _workers = [];
  List<UserModel> _allWorkers = []; // Keep original list for filtering
  bool _isLoading = false;
  String? _errorMessage;
  WorkerSortOption _currentSort = WorkerSortOption.rating;
  String? _selectedCity;

  List<UserModel> get workers => _workers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  WorkerSortOption get currentSort => _currentSort;
  String? get selectedCity => _selectedCity;

  /// Get unique cities from workers
  List<String> get availableCities {
    final cities = _allWorkers
        .where((w) => w.city != null && w.city!.isNotEmpty)
        .map((w) => w.city!)
        .toSet()
        .toList();
    cities.sort();
    return cities;
  }

  /// Load all workers
  void loadAllWorkers() {
    _isLoading = true;
    notifyListeners();

    _firestoreService.getAllWorkers().listen((workers) {
      // Filter out workers without complete profiles
      _allWorkers = workers
          .where(
            (w) =>
                w.name.isNotEmpty &&
                w.serviceType != null &&
                w.serviceType!.isNotEmpty,
          )
          .toList();
      _workers = List.from(_allWorkers);
      _applySorting();
      _isLoading = false;
      notifyListeners();
    });
  }

  /// Search workers by city and service type
  void searchWorkers({String? city, String? serviceType}) {
    _isLoading = true;
    _selectedCity = city;
    notifyListeners();

    // Filter from all workers locally for better performance
    _workers = _allWorkers.where((w) {
      bool matches = true;

      if (city != null && city.isNotEmpty) {
        matches =
            matches &&
            w.city != null &&
            w.city!.toLowerCase().contains(city.toLowerCase());
      }

      if (serviceType != null && serviceType.isNotEmpty) {
        matches = matches && w.serviceType == serviceType;
      }

      return matches;
    }).toList();

    _applySorting();
    _isLoading = false;
    notifyListeners();
  }

  /// Sort workers by given option
  void sortWorkers(WorkerSortOption option) {
    _currentSort = option;
    _applySorting();
    notifyListeners();
  }

  /// Apply current sorting to workers list
  void _applySorting() {
    switch (_currentSort) {
      case WorkerSortOption.rating:
        _workers.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case WorkerSortOption.reviewCount:
        _workers.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
        break;
      case WorkerSortOption.priceHigh:
        _workers.sort((a, b) => (b.rate ?? 0).compareTo(a.rate ?? 0));
        break;
      case WorkerSortOption.priceLow:
        _workers.sort((a, b) => (a.rate ?? 0).compareTo(b.rate ?? 0));
        break;
      case WorkerSortOption.name:
        _workers.sort((a, b) => a.name.compareTo(b.name));
        break;
    }
  }

  /// Filter by city
  void filterByCity(String? city) {
    _selectedCity = city;
    if (city == null || city.isEmpty) {
      _workers = List.from(_allWorkers);
    } else {
      _workers = _allWorkers
          .where(
            (w) =>
                w.city != null && w.city!.toLowerCase() == city.toLowerCase(),
          )
          .toList();
    }
    _applySorting();
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _selectedCity = null;
    _workers = List.from(_allWorkers);
    _applySorting();
    notifyListeners();
  }

  /// Refresh a specific worker's data
  Future<void> refreshWorker(String workerId) async {
    try {
      final updatedWorker = await _firestoreService.getUser(workerId);
      if (updatedWorker != null) {
        final index = _workers.indexWhere((w) => w.uid == workerId);
        if (index != -1) {
          _workers[index] = updatedWorker;
          notifyListeners();
        }
        // Also update in all workers list
        final allIndex = _allWorkers.indexWhere((w) => w.uid == workerId);
        if (allIndex != -1) {
          _allWorkers[allIndex] = updatedWorker;
        }
      }
    } catch (e) {
      debugPrint('WorkerProvider ERROR: Failed to refresh worker: $e');
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
