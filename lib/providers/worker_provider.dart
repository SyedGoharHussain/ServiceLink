import 'package:flutter/foundation.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

/// Provider for managing workers list and search
class WorkerProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<UserModel> _workers = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<UserModel> get workers => _workers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Load all workers
  void loadAllWorkers() {
    _isLoading = true;
    notifyListeners();

    _firestoreService.getAllWorkers().listen((workers) {
      _workers = workers;
      _isLoading = false;
      notifyListeners();
    });
  }

  /// Search workers by city and service type
  void searchWorkers({String? city, String? serviceType}) {
    _isLoading = true;
    notifyListeners();

    _firestoreService
        .searchWorkers(city: city, serviceType: serviceType)
        .listen((workers) {
          _workers = workers;
          _isLoading = false;
          notifyListeners();
        });
  }

  /// Refresh a specific worker's data
  Future<void> refreshWorker(String workerId) async {
    try {
      print('WorkerProvider: Refreshing worker $workerId');
      final updatedWorker = await _firestoreService.getUser(workerId);
      if (updatedWorker != null) {
        print(
          'WorkerProvider: Worker data fetched - Rating: ${updatedWorker.rating}, Reviews: ${updatedWorker.reviewCount}',
        );
        final index = _workers.indexWhere((w) => w.uid == workerId);
        if (index != -1) {
          _workers[index] = updatedWorker;
          print('WorkerProvider: Worker updated at index $index');
          notifyListeners();
        } else {
          print('WorkerProvider: Worker not found in list, adding...');
          _workers.add(updatedWorker);
          notifyListeners();
        }
      } else {
        print('WorkerProvider: Worker data is null');
      }
    } catch (e) {
      print('WorkerProvider ERROR: Failed to refresh worker: $e');
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
